import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/styles.dart';

/// Lector de códigos de barras con la cámara. Devuelve el código leído
/// (`Navigator.pop(context, codigo)`) o null si se cancela. Permite escribir
/// el código a mano si la cámara no está disponible.
class BarcodeScannerView extends StatefulWidget {
  final String title;

  const BarcodeScannerView({super.key, this.title = 'Escanear código'});

  /// Abre el lector y devuelve el código, o null.
  static Future<String?> scan(
    BuildContext context, {
    String title = 'Escanear código',
  }) {
    return Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => BarcodeScannerView(title: title)),
    );
  }

  @override
  State<BarcodeScannerView> createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends State<BarcodeScannerView> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.itf14,
    ],
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final b in capture.barcodes) {
      final code = b.rawValue?.trim();
      if (code != null && code.isNotEmpty) {
        _handled = true;
        HapticFeedback.mediumImpact();
        Navigator.pop(context, code);
        return;
      }
    }
  }

  Future<void> _typeManually() async {
    final ctrl = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Escribir código'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Números bajo las barras',
            hintText: 'Ej: 8410000000000',
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (!mounted || code == null || code.isEmpty) return;
    _handled = true;
    Navigator.pop(context, code);
  }

  Widget _buildError(BuildContext context, MobileScannerException error) {
    final String message;
    switch (error.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        message =
            'La app no tiene permiso para usar la cámara.\n\n'
            'Actívalo en Ajustes del teléfono → Aplicaciones → cal_counter → '
            'Permisos → Cámara, o escribe el código a mano.';
      case MobileScannerErrorCode.unsupported:
        message =
            'Este dispositivo no tiene una cámara compatible. '
            'Puedes escribir el código a mano.';
      default:
        message =
            'No se pudo abrir la cámara (${error.errorCode.name}). '
            'Puedes escribir el código a mano.';
    }
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography, color: Colors.white70, size: 64),
              const SizedBox(height: AppStyles.paddingMedium),
              Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, state, _) {
              if (state.torchState == TorchState.unavailable) {
                return const SizedBox.shrink();
              }
              final on = state.torchState == TorchState.on;
              return IconButton(
                tooltip: on ? 'Apagar linterna' : 'Encender linterna',
                icon: Icon(on ? Icons.flash_on : Icons.flash_off),
                onPressed: _controller.toggleTorch,
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: _buildError,
          ),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 280,
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(AppStyles.paddingMedium),
                padding: const EdgeInsets.all(AppStyles.paddingMedium),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Apunta al código de barras del envase',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppStyles.paddingSmall),
                    OutlinedButton.icon(
                      onPressed: _typeManually,
                      icon: const Icon(Icons.keyboard),
                      label: const Text('Escribir el código a mano'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
