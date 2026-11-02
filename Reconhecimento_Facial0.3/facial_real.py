"""Modelo real compartilhado pelo cadastro do Firebase e pela webcam.

MediaPipe localiza o rosto; MobileFaceNet/ArcFace (buffalo_s/sc) gera 512 valores.
O processamento do cadastro acontece no computador nesta versão da entrega.
"""
from dataclasses import dataclass
from hashlib import sha256
from pathlib import Path

import cv2
import numpy as np
import onnxruntime as ort

from face_utils import DetectorFacial
from config import MODELO_FACE_LANDMARKER

MODELO = Path(__file__).parent / "modelos" / "w600k_mbf.onnx"
# Referência de alinhamento ArcFace, em pixels para a imagem 112 x 112.
DESTINO = np.array([[38.2946, 51.6963], [73.5318, 51.5014],
                    [56.0252, 71.7366], [41.5493, 92.3655],
                    [70.7299, 92.2041]], dtype=np.float64)


class FotoInvalida(ValueError):
    """Problema corrigível pelo usuário capturando outra foto."""


def normalizar(vetor):
    vetor = np.asarray(vetor, dtype=np.float32)
    if vetor.shape != (512,) or not np.isfinite(vetor).all():
        raise ValueError("Embedding inválido: esperado vetor finito de 512 posições.")
    norma = float(np.linalg.norm(vetor))
    if norma < 1e-8:
        raise ValueError("Embedding com norma zero.")
    return vetor / norma


def matriz_alinhamento(origem, destino=DESTINO):
    """Ajuste de similaridade por mínimos quadrados, sem aleatoriedade/RANSAC."""
    origem = np.asarray(origem, dtype=np.float64)
    if origem.shape != (5, 2) or not np.isfinite(origem).all():
        raise FotoInvalida("Não foi possível localizar os pontos do rosto.")
    a, b = [], []
    for (x, y), (u, v) in zip(origem, destino):
        a.extend([[x, -y, 1, 0], [y, x, 0, 1]])
        b.extend([u, v])
    parametros, _, posto, _ = np.linalg.lstsq(a, b, rcond=None)
    if posto < 4:
        raise FotoInvalida("Posicione o rosto de frente para a câmera.")
    escala, giro, tx, ty = parametros
    return np.array([[escala, -giro, tx], [giro, escala, ty]], dtype=np.float32)


def preparar_entrada(frame, landmarks):
    h, w = frame.shape[:2]
    pontos = np.array([[p.x * w, p.y * h] for p in landmarks])
    olhos = sorted([(pontos[33] + pontos[133]) / 2,
                    (pontos[362] + pontos[263]) / 2], key=lambda p: p[0])
    boca = sorted([pontos[61], pontos[291]], key=lambda p: p[0])
    origem = np.array([*olhos, pontos[1], *boca])
    if np.linalg.norm(origem[0] - origem[1]) < 20:
        raise FotoInvalida("Aproxime o rosto e olhe de frente para a câmera.")
    recorte = cv2.warpAffine(frame, matriz_alinhamento(origem), (112, 112))
    # buffalo_s/sc: RGB, NCHW, float32 e (pixel - 127.5) / 127.5.
    rgb = cv2.cvtColor(recorte, cv2.COLOR_BGR2RGB).astype(np.float32)
    return np.ascontiguousarray(((rgb - 127.5) / 127.5).transpose(2, 0, 1)[None])


@dataclass
class RostoProcessado:
    vetor: np.ndarray
    bbox: tuple


class MotorFacial:
    def __init__(self, modelo=MODELO):
        modelo = Path(modelo)
        if not modelo.is_file():
            raise FileNotFoundError("Modelo ausente. Execute: python baixar_modelo.py")
        # O identificador cobre pesos, detector e pré-processamento. Nunca mistura
        # vetores do placeholder, de modelos diferentes ou de versões de recorte.
        hashes = [sha256(p.read_bytes()).hexdigest() for p in
                  [modelo, Path(MODELO_FACE_LANDMARKER)]]
        self.modelo_id = "mbf512-mp5-v1:" + ":".join(hashes)
        opcoes = ort.SessionOptions()
        opcoes.intra_op_num_threads = 2
        self.sessao = ort.InferenceSession(str(modelo), sess_options=opcoes,
                                          providers=["CPUExecutionProvider"])
        entrada = self.sessao.get_inputs()[0]
        if entrada.shape[1:] != [3, 112, 112] or entrada.type != "tensor(float)":
            raise ValueError("Modelo ONNX incompatível com buffalo_s/sc.")
        self.entrada = entrada.name
        self.detector = DetectorFacial()

    def processar(self, frame):
        rostos = self.detector.detectar_rostos(frame)
        if not rostos:
            raise FotoInvalida("Nenhum rosto encontrado. Melhore a iluminação e tire outra foto.")
        if len(rostos) != 1:
            raise FotoInvalida("Deixe somente uma pessoa na imagem.")
        rosto = rostos[0]
        x1, y1, x2, y2 = rosto.bbox
        if min(x2 - x1, y2 - y1) < 80:
            raise FotoInvalida("O rosto está pequeno. Aproxime-se da câmera.")
        entrada = preparar_entrada(frame, rosto.landmarks)
        vetor = normalizar(self.sessao.run(None, {self.entrada: entrada})[0].reshape(-1))
        return RostoProcessado(vetor, rosto.bbox)

    def processar_foto(self, foto):
        if not isinstance(foto, bytes) or not 0 < len(foto) <= 700 * 1024:
            raise FotoInvalida("Envie uma foto de até 700 KB pelo aplicativo.")
        frame = cv2.imdecode(np.frombuffer(foto, np.uint8), cv2.IMREAD_COLOR)
        if frame is None:
            raise FotoInvalida("Arquivo de imagem inválido. Capture outra foto.")
        return self.processar(frame)

    def fechar(self):
        self.detector.fechar()


def identificar(vetor, candidatos, limiar=0.60, margem=0.08):
    """Rejeita desconhecidos e resultados ambíguos; não basta ser o mais próximo."""
    vetor = normalizar(vetor)
    notas = []
    for usuario in candidatos:
        try:
            nota = float(np.dot(vetor, normalizar(usuario['vetor'])))
            notas.append((nota, usuario))
        except (ValueError, TypeError):
            continue
    notas.sort(key=lambda item: item[0], reverse=True)
    if not notas:
        return None, 0.0
    melhor, usuario = notas[0]
    segundo = notas[1][0] if len(notas) > 1 else -1.0
    if melhor < limiar or melhor - segundo < margem:
        return None, melhor
    return usuario, melhor
