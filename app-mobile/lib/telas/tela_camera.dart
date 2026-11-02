import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class TelaCamera extends StatefulWidget {
  const TelaCamera({super.key});

  @override
  State<TelaCamera> createState() => _TelaCameraState();
}

class _TelaCameraState extends State<TelaCamera> {
  CameraController? _controlador;
  bool _carregando = true;
  bool _capturando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _iniciarCamera();
  }

  Future<void> _iniciarCamera() async {
    CameraController? novoControlador;

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

      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      novoControlador = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await novoControlador.initialize();

      if (!mounted) {
        await novoControlador.dispose();
        return;
      }

      setState(() {
        _controlador = novoControlador;
        _carregando = false;
      });
    } catch (erro) {
      await novoControlador?.dispose();

      if (!mounted) return;

      setState(() {
        _carregando = false;
        _erro = 'Não foi possível abrir a câmera. '
            'Confira a permissão no Chrome e se outro aplicativo '
            'está usando a webcam.\n\nDetalhes: $erro';
      });
    }
  }

  Future<void> _capturarFoto() async {
    final controlador = _controlador;

    if (_capturando ||
        controlador == null ||
        !controlador.value.isInitialized) {
      return;
    }

    setState(() {
      _capturando = true;
    });

    try {
      final foto = await controlador.takePicture();
      final bytes = await foto.readAsBytes();

      if (!mounted) return;

      Navigator.of(context).pop<Uint8List>(bytes);
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível capturar a foto: $erro'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _capturando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controlador?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controlador = _controlador;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: const Text('Capturar rosto'),
        backgroundColor: const Color(0xFF0B4F8A),
        foregroundColor: Colors.white,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _erro!,
                      textAlign: TextAlign.center,
                    ),
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
                              const Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  'Posicione o rosto no centro da imagem '
                                  'e procure um local bem iluminado. '
                                  'Retire a máscara e deixe apenas você na imagem.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: AspectRatio(
                                    aspectRatio:
                                        controlador.value.aspectRatio,
                                    child: CameraPreview(controlador),
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
                                    icon: const Icon(Icons.camera_alt),
                                    label: Text(
                                      _capturando
                                          ? 'Capturando...'
                                          : 'Tirar foto',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color(0xFF0B4F8A),
                                      foregroundColor: Colors.white,
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