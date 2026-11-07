import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../servicos/foto_util.dart';
import 'tela_orientacao_foto.dart';

class TelaCamera extends StatefulWidget {
  const TelaCamera({super.key});

  @override
  State<TelaCamera> createState() => _TelaCameraState();
}

class _TelaCameraState extends State<TelaCamera> {
  static const Color _azul = Color(0xFF0B4F8A);

  CameraController? _controlador;
  List<CameraDescription> _cameras = const [];
  CameraDescription? _cameraAtual;
  bool _orientacaoVista = false;
  bool _carregando = true;
  bool _capturando = false;
  String? _erro;

  void _continuarDaOrientacao() {
    setState(() => _orientacaoVista = true);
    _iniciarCamera();
  }

  Future<void> _iniciarCamera() async {
    try {
      final cameras = await availableCameras();

      if (!mounted) return;

      if (cameras.isEmpty) {
        setState(() {
          _erro = 'Nenhuma câmera foi encontrada neste dispositivo.';
          _carregando = false;
        });
        return;
      }

      _cameras = cameras;
      // Começa na câmera frontal, para a própria pessoa se cadastrar.
      final inicial = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      await _abrirCamera(inicial);
    } catch (erro) {
      _falhaAoAbrir(erro);
    }
  }

  Future<void> _abrirCamera(CameraDescription camera) async {
    CameraController? novoControlador;

    // Solta a câmera anterior antes de abrir a nova.
    final antigo = _controlador;
    setState(() {
      _controlador = null;
      _carregando = true;
      _erro = null;
    });
    await antigo?.dispose();

    try {
      novoControlador = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await novoControlador.initialize();

      if (!mounted) {
        await novoControlador.dispose();
        return;
      }

      setState(() {
        _controlador = novoControlador;
        _cameraAtual = camera;
        _carregando = false;
      });
    } catch (erro) {
      await novoControlador?.dispose();
      _falhaAoAbrir(erro);
    }
  }

  void _falhaAoAbrir(Object erro) {
    if (!mounted) return;

    setState(() {
      _carregando = false;
      _erro = 'Não foi possível abrir a câmera. '
          'Confira a permissão de câmera do aplicativo e se outro '
          'aplicativo está usando a câmera.\n\nDetalhes: $erro';
    });
  }

  bool get _temFrontalETraseira =>
      _cameras.any((c) => c.lensDirection == CameraLensDirection.front) &&
      _cameras.any((c) => c.lensDirection == CameraLensDirection.back);

  bool get _usandoTraseira =>
      _cameraAtual?.lensDirection == CameraLensDirection.back;

  Future<void> _alternarCamera() async {
    if (_capturando || _carregando) return;

    final destino = _usandoTraseira
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    final proxima = _cameras.firstWhere(
      (c) => c.lensDirection == destino,
      orElse: () => _cameraAtual ?? _cameras.first,
    );
    await _abrirCamera(proxima);
  }

  Future<void> _capturarFoto() async {
    final controlador = _controlador;

    if (_capturando ||
        controlador == null ||
        !controlador.value.isInitialized) {
      return;
    }

    setState(() => _capturando = true);

    try {
      final foto = await controlador.takePicture();
      final original = await foto.readAsBytes();

      // Reduz automaticamente quando passa do tamanho permitido.
      final bytes = await reduzirFotoSeNecessario(original);

      if (!mounted) return;

      Navigator.of(context).pop<Uint8List>(bytes);
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível capturar a foto: $erro')),
      );
    } finally {
      if (mounted) setState(() => _capturando = false);
    }
  }

  @override
  void dispose() {
    _controlador?.dispose();
    super.dispose();
  }

  Widget _previa(CameraController controlador) {
    // O CameraPreview já calcula a própria proporção conforme a orientação.
    // Não pode ser envolvido em outro AspectRatio, senão a imagem estica.
    final retrato = MediaQuery.orientationOf(context) == Orientation.portrait;
    final proporcao = retrato
        ? 1 / controlador.value.aspectRatio
        : controlador.value.aspectRatio;

    return AspectRatio(
      aspectRatio: 3 / 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: 1000 * proporcao,
                height: 1000,
                child: CameraPreview(controlador),
              ),
            ),
            const CustomPaint(painter: _GuiaOvalPainter()),
            if (_temFrontalETraseira)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filled(
                  onPressed: _capturando ? null : _alternarCamera,
                  tooltip: _usandoTraseira
                      ? 'Usar câmera frontal'
                      : 'Usar câmera traseira',
                  icon: const Icon(Icons.cameraswitch_outlined),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_orientacaoVista) {
      return TelaOrientacaoFoto(aoContinuar: _continuarDaOrientacao);
    }

    final controlador = _controlador;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: const Text('Capturar rosto'),
        backgroundColor: _azul,
        foregroundColor: Colors.white,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_erro!, textAlign: TextAlign.center),
                  ),
                )
              : controlador == null
                  ? const Center(child: Text('Câmera indisponível.'))
                  : SafeArea(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: Column(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(24, 16, 24, 12),
                                child: Text(
                                  _usandoTraseira
                                      ? 'Enquadre o rosto de quem está se '
                                          'cadastrando dentro do oval.'
                                      : 'Encaixe o rosto dentro do oval, de '
                                          'frente e com o rosto inteiro '
                                          'visível.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF1F2937),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  child: Center(child: _previa(controlador)),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(24, 12, 24, 4),
                                child: Text(
                                  _usandoTraseira
                                      ? 'Câmera traseira: outra pessoa pode '
                                          'tirar a foto de quem está se '
                                          'cadastrando.'
                                      : 'Sem óculos, boné ou máscara · boa '
                                          'iluminação · só você na imagem',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        _capturando ? null : _capturarFoto,
                                    icon: _capturando
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.camera_alt),
                                    label: Text(
                                      _capturando
                                          ? 'Processando foto...'
                                          : 'Tirar foto',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _azul,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
    );
  }
}

/// Escurece a área fora do oval e desenha o contorno do guia.
class _GuiaOvalPainter extends CustomPainter {
  const _GuiaOvalPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final largura = size.width * 0.72;
    final altura = largura * 1.3;
    final oval = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.46),
      width: largura,
      height: altura,
    );

    final fundo = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addOval(oval),
    );
    canvas.drawPath(fundo, Paint()..color = const Color(0x8C000000));
    canvas.drawOval(
      oval,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
