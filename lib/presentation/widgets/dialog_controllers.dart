import 'package:flutter/material.dart';

/// Crea controladores de texto para un diálogo y los libera cuando el
/// diálogo desaparece de verdad (al acabar la animación de cierre), no
/// antes: liberarlos justo tras `await showDialog` provoca "used after
/// being disposed" mientras el diálogo aún se está cerrando.
class DialogControllers extends StatefulWidget {
  final List<String> iniciales;
  final Widget Function(BuildContext context, List<TextEditingController> c)
  builder;

  const DialogControllers({
    super.key,
    required this.iniciales,
    required this.builder,
  });

  @override
  State<DialogControllers> createState() => _DialogControllersState();
}

class _DialogControllersState extends State<DialogControllers> {
  late final List<TextEditingController> _c = [
    for (final t in widget.iniciales)
      TextEditingController(text: t)
        ..selection = TextSelection(baseOffset: 0, extentOffset: t.length),
  ];

  @override
  void dispose() {
    for (final c in _c) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _c);
}
