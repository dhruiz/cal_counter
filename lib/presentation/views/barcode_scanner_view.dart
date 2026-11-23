import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/styles.dart';
import '../widgets/dialog_controllers.dart';

/// Lector de códigos de barras a pantalla completa. Devuelve el código leído
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
  bool _handled = false;

  void _onCode(String code) {
    if (_handled) return;
    _handled = true;
    Navigator.pop(context, code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: BarcodeScannerPanel(onCode: _onCode),
    );
  }
}

/// Pide el código escrito a mano. Devuelve null si se cancela.
Future<String?> askBarcodeManually(BuildContext context) async {
  final code = await showDialog<String>(
    context: context,
    builder: (_) => DialogControllers(
      iniciales: const [''],
      builder: (ctx, c) => _manualCodeDialog(ctx, c.first),
    ),
  );
  return (code == null || code.isEmpty) ? null : code;
}

Widget _manualCodeDialog(BuildContext ctx, TextEditingController ctrl) =>
    AlertDialog(
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
    );

/// Cámara con marco, linterna, mensajes de error y entrada manual del código.
///
/// Llama a [onCode] por cada código detectado (con vibración). No filtra
/// repeticiones: quien lo usa decide (la vista a pantalla completa se cierra
/// con el primero; el modo carrito aplica su propia espera). Con [compacto]
/// se adapta a una franja de la pantalla.
class BarcodeScannerPanel extends StatefulWidget {
  final ValueChanged<String> onCode;
  final bool compacto;
  final String instrucciones;

  const BarcodeScannerPanel({
    super.key,
    required this.onCode,
    this.compacto = false,
    this.instrucciones = 'Apunta al código de barras del envase',
  });

  @override
  State<BarcodeScannerPanel> createState() => _BarcodeScannerPanelState();
}

class _BarcodeScannerPanelState extends State<BarcodeScannerPanel> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 500,
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    for (final b in capture.barcodes) {
      final code = b.rawValue?.trim();
      if (code != null && code.isNotEmpty) {
        HapticFeedback.mediumImpact();
        widget.onCode(code);
        return;
      }
    }
  }

  Future<void> _typeManually() async {
    final code = await askBarcodeManually(context);
    if (code != null && mounted) widget.onCode(code);
  }

  Widget _buildError(BuildContext context, MobileScannerException error) {
    final String message;
    switch (error.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        message =
            'La app no tiene permiso para usar la cámara.\n'
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppStyles.paddingMedium),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.no_photography,
                color: Colors.white70,
                size: widget.compacto ? 32 : 64,
              ),
              const SizedBox(height: AppStyles.paddingSmall),
              Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.compacto ? 13 : 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _torchButton() {
    return ValueListenableBuilder<MobileScannerState>(
      valueListenable: _controller,
      builder: (context, state, _) {
        if (state.torchState == TorchState.unavailable) {
          return const SizedBox.shrink();
        }
        final on = state.torchState == TorchState.on;
        return IconButton(
          tooltip: on ? 'Apagar linterna' : 'Encender linterna',
          color: Colors.white,
          icon: Icon(on ? Icons.flash_on : Icons.flash_off),
          onPressed: _controller.toggleTorch,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final compacto = widget.compacto;
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: _buildError,
            ),
          ),
          IgnorePointer(
            child: Center(
              child: Container(
                width: compacto ? 240 : 280,
                height: compacto ? 110 : 160,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          Positioned(top: 4, right: 4, child: _torchButton()),
          if (compacto)
            Positioned(
              left: 8,
              right: 8,
              bottom: 6,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.instrucciones,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      maxLines: 2,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _typeManually,
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    icon: const Icon(Icons.keyboard, size: 18),
                    label: const Text('A mano'),
                  ),
                ],
              ),
            )
          else
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
                      Text(
                        widget.instrucciones,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
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
