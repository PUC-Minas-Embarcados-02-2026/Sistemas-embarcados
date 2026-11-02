"""Baixa somente os pesos necessários do pacote oficial InsightFace buffalo_sc."""
from hashlib import sha256
from io import BytesIO
from pathlib import Path
from urllib.request import urlopen
from zipfile import ZipFile

URL = "https://github.com/deepinsight/insightface/releases/download/model-zoo/buffalo_sc.zip"
SHA256_ZIP = "57d31b56b6ffa911c8a73cfc1707c73cab76efe7f13b675a05223bf42de47c72"


def main():
    print("Baixando modelo oficial (~15 MB). Uso acadêmico não comercial.")
    with urlopen(URL, timeout=120) as resposta:
        conteudo = resposta.read()
    if sha256(conteudo).hexdigest() != SHA256_ZIP:
        raise RuntimeError("O arquivo baixado não corresponde ao modelo esperado.")
    with ZipFile(BytesIO(conteudo)) as arquivo:
        nomes = [n for n in arquivo.namelist() if Path(n).name == "w600k_mbf.onnx"]
        if len(nomes) != 1:
            raise RuntimeError("Pacote não contém o modelo esperado.")
        destino = Path(__file__).parent / "modelos" / "w600k_mbf.onnx"
        destino.parent.mkdir(exist_ok=True)
        destino.write_bytes(arquivo.read(nomes[0]))
    print(f"Modelo salvo: {destino}")


if __name__ == "__main__":
    main()
