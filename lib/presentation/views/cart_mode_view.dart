import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/styles.dart';
import '../../core/utils.dart';
import '../../domain/entities/food.dart';
import '../../domain/entities/shopping_list.dart';
import '../../domain/errors/domain_errors.dart';
import '../../domain/services/aisle_grouping.dart';
import '../../domain/services/barcode.dart';
import '../../domain/services/cart_matching.dart';
import '../../domain/services/scale_barcode.dart';
import '../../domain/usecases/food_registration.dart';
import '../../domain/usecases/scale_labels.dart';
import '../providers/foods_provider.dart';
import '../providers/shopping_provider.dart';
import '../widgets/cart_price_sheet.dart';
import 'barcode_scanner_view.dart';
import 'food_picker_view.dart';

/// Construye el lector de códigos; permite sustituir la cámara en tests.
typedef CartScannerBuilder =
    Widget Function(BuildContext context, ValueChanged<String> onCode);

/// «Modo carrito»: cámara siempre abierta para ir escaneando lo que se mete
/// en el carrito. Cada producto se confirma con su precio (precargado si hay
/// historial; si no, se pide), suma al total, marca la lista y registra la
/// compra en el historial con la tienda elegida al entrar.
///
/// Un código desconocido NO pide la tabla nutricional: avisa y da de alta lo
/// básico (nombre, marca, presentación); se completa luego en casa.
class CartModeView extends ConsumerStatefulWidget {
  final int listaId;
  final CartScannerBuilder? scannerBuilder;

  const CartModeView({super.key, required this.listaId, this.scannerBuilder});

  @override
  ConsumerState<CartModeView> createState() => _CartModeViewState();
}

class _CartModeViewState extends ConsumerState<CartModeView> {
  /// Espera antes de aceptar otra vez el mismo código (la cámara lo detecta
  /// en varios fotogramas seguidos). Escanearlo de nuevo = una unidad más.
  static const _esperaMismoCodigo = Duration(milliseconds: 2500);

  String? _tienda;
  bool _busy = false;
  String? _lastCode;
  DateTime? _lastAt;

  /// Alimentos dados de alta en esta compra (pendientes de completar).
  final Set<int> _nuevos = {};

  ShoppingItemsNotifier get _notifier =>
      ref.read(shoppingItemsProvider(widget.listaId).notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _chooseStore());
  }

  Future<void> _chooseStore() async {
    List<String> tiendas;
    try {
      tiendas = await ref.read(purchaseRepositoryProvider).getStoreNames();
    } catch (_) {
      tiendas = const [];
    }
    if (!mounted) return;
    final tienda = await askStore(
      context,
      tiendas: tiendas,
      inicial: _tienda ?? (tiendas.isEmpty ? null : tiendas.first),
    );
    if (!mounted) return;
    if (tienda == null) {
      // Sin tienda no se puede registrar nada: al entrar, cancelar = salir.
      if (_tienda == null) Navigator.pop(context);
      return;
    }
    setState(() => _tienda = tienda);
  }

  void _toast(String text) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(milliseconds: 1800),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onCode(String code) async {
    if (_busy || _tienda == null) return;
    final now = DateTime.now();
    if (code == _lastCode &&
        _lastAt != null &&
        now.difference(_lastAt!) < _esperaMismoCodigo) {
      return;
    }
    _busy = true;
    try {
      if (isVariableMeasure(code)) {
        await _onScaleLabel(code);
        return;
      }
      final match = await ref.read(foodRepositoryProvider).findByBarcode(code);
      if (!mounted) return;
      if (match == null) {
        await _addNewProduct(code);
      } else {
        await _addKnown(match.food, presentacion: match.package);
      }
    } catch (e) {
      if (mounted) _toast('No se pudo añadir: $e');
    } finally {
      // La espera cuenta desde que se cierra la tarjeta.
      _lastCode = code;
      _lastAt = DateTime.now();
      _busy = false;
    }
  }

  // Etiquetas de báscula ----------------------------------------------------

  /// Primera etiqueta de báscula de la tienda: ¿el valor es importe o peso?
  Future<ScaleFormat?> _learnFormat(ScaleLabel l) {
    final euros = AppUtils.formatPrecioCent(l.comoPrecioCent);
    final kg = (l.comoPesoG / 1000).toStringAsFixed(3).replaceAll('.', ',');
    return showModalBottomSheet<ScaleFormat>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text(
                'Etiqueta de báscula',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Es la primera de $_tienda. Mira la etiqueta: ¿qué indica?',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.euro),
              title: Text('Importe: $euros'),
              onTap: () => Navigator.pop(ctx, ScaleFormat.precio),
            ),
            ListTile(
              leading: const Icon(Icons.scale_outlined),
              title: Text('Peso: $kg kg'),
              onTap: () => Navigator.pop(ctx, ScaleFormat.peso),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Ninguna de las dos'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onScaleLabel(String code) async {
    final scale = ref.read(scaleRepositoryProvider);
    var tienda = await scale.ensureStore(_tienda!);
    var formato = tienda.formatoBascula;
    if (formato == null) {
      final probe = ScaleLabel.parse(code);
      if (probe == null) {
        _toast('Código de báscula no válido: vuelve a escanearlo.');
        return;
      }
      if (!mounted) return;
      formato = await _learnFormat(probe);
      if (formato == null) {
        _toast(
          'No se reconoce el formato: añade el producto desde «Te falta» '
          'o escribe su precio.',
        );
        return;
      }
      await scale.setScaleFormat(tienda.id!, formato);
      tienda = (await scale.getStore(_tienda!))!;
    }
    var label = ScaleLabel.parse(code, longitudClave: tienda.longitudClave);
    if (label == null) {
      _toast('Código de báscula no válido: vuelve a escanearlo.');
      return;
    }
    var match = await scale.findCode(tienda.id!, label.clave);

    // ¿La tienda usa dígito de control del precio? Mismo producto con otra
    // cifra 7 → pasar a claves de 6 dígitos.
    if (match == null && tienda.longitudClave == 7) {
      final cortos = await scale.findByShortKey(tienda.id!, label.claveCorta);
      if (cortos.length == 1 && mounted) {
        final si = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('¿Es el mismo producto?'),
            content: Text(
              '¿Esta etiqueta es de «${cortos.single.alimento.nombre}»?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Sí'),
              ),
            ],
          ),
        );
        if (si == true) {
          await scale.useShortKeys(tienda.id!);
          tienda = (await scale.getStore(_tienda!))!;
          label = ScaleLabel.parse(code, longitudClave: 6)!;
          match = await scale.findCode(tienda.id!, label.clave);
        }
      }
    }

    if (match == null) {
      if (!mounted) return;
      final food = await FoodPickerView.pick(
        context,
        title: '¿Qué producto es esta etiqueta?',
      );
      if (food == null || !mounted) return;
      match = await ref.read(linkScaleCodeProvider)(
        tienda: tienda,
        clave: label.clave,
        alimento: food,
      );
      if (food.pendiente) _nuevos.add(food.id!);
    }
    if (!mounted) return;

    final kilo = formato == ScaleFormat.peso
        ? await scale.lastPricePerKiloCent(
            match.presentacion.id!,
            storeId: tienda.id,
          )
        : null;
    final lectura = readScaleLabel(label, formato, precioKiloCent: kilo);
    final items = ref.read(shoppingItemsProvider(widget.listaId)).items;
    final target = findItemForFood(items, match.alimento);
    final peso = lectura.pesoG;
    if (!mounted) return;
    final res = await CartPriceSheet.show(
      context,
      CartPriceSheet(
        titulo: match.alimento.nombre,
        detalle: [
          if (peso != null)
            '${(peso / 1000).toStringAsFixed(3).replaceAll('.', ',')} kg',
          if (kilo != null) '${AppUtils.formatPrecioCent(kilo)}/kg',
          if (peso == null) 'Importe leído de la etiqueta',
        ].join(' · '),
        precioInicialCent: lectura.precioCent,
        alPeso: true,
        yaEnCarrito: target != null && target.enCarrito ? 1 : 0,
        marcaraItem:
            target != null &&
                !target.comprado &&
                target.texto != match.alimento.nombre
            ? target.texto
            : null,
        fueraDeLista: target == null,
      ),
    );
    if (res == null || !mounted) return;
    await _notifier.addToCart(
      alimento: match.alimento,
      presentacionId: match.presentacion.id,
      itemId: target?.id,
      precioCent: res.precioCent,
      alPeso: true,
      pesoG: peso,
      establecimiento: _tienda!,
    );
    HapticFeedback.lightImpact();
    if (mounted) {
      _toast(
        '✓ ${match.alimento.nombre} · ${AppUtils.formatPrecioCent(res.precioCent)}',
      );
    }
  }

  Future<void> _addKnown(
    Food food, {
    FoodPackage? presentacion,
    int? itemId,
  }) async {
    final items = ref.read(shoppingItemsProvider(widget.listaId)).items;
    ShoppingItem? target;
    if (itemId != null) {
      target = items.where((i) => i.id == itemId).firstOrNull;
    }
    target ??= findItemForFood(items, food);
    final enCarrito = target != null && target.enCarrito;
    final last = await ref
        .read(purchaseRepositoryProvider)
        .lastPurchaseForFood(food.id!, establecimiento: _tienda);
    if (!mounted) return;
    final detalle = [
      if (food.marca.isNotEmpty) food.marca,
      if ((presentacion?.descripcion ?? '').isNotEmpty)
        presentacion!.descripcion,
    ].join(' · ');

    final res = await CartPriceSheet.show(
      context,
      CartPriceSheet(
        titulo: food.nombre,
        detalle: detalle,
        ultima: last?.compra,
        precioInicialCent: enCarrito
            ? target.precioCent
            : last?.compra.precioCent,
        yaEnCarrito: enCarrito ? target.unidades : 0,
        marcaraItem:
            target != null && !target.comprado && target.texto != food.nombre
            ? target.texto
            : null,
        fueraDeLista: target == null,
      ),
    );
    if (res == null || !mounted) return;
    await _notifier.addToCart(
      alimento: food,
      presentacionId: presentacion?.id,
      itemId: target?.id,
      precioCent: res.precioCent,
      unidades: res.unidades,
      establecimiento: _tienda!,
    );
    HapticFeedback.lightImpact();
    if (mounted) {
      _toast(
        '✓ ${food.nombre} · '
        '${AppUtils.formatPrecioCent(res.precioCent * res.unidades)}',
      );
    }
  }

  Future<void> _addNewProduct(String code) async {
    final res = await NewProductSheet.show(context, code);
    if (res == null || !mounted) return;
    int? existenteId;
    if (res.otraPresentacion) {
      final food = await FoodPickerView.pick(
        context,
        title: '¿De qué alimento es este código?',
      );
      if (food == null || !mounted) return;
      existenteId = food.id;
    }
    final BarcodeMatch match;
    try {
      match = await ref.read(registerFoodInStoreProvider)(
        nombre: res.nombre,
        marca: res.marca,
        unidad: FoodUnit.fromClave(res.unidad),
        alimentoExistenteId: existenteId,
        esAlimento: res.esAlimento,
        presentacion: PackageDraft(
          codigoBarras: code,
          descripcion: res.presentacion,
          contenido: res.contenido,
        ),
      );
    } on DuplicateBarcodeException catch (e) {
      if (mounted) _toast(e.toString());
      return;
    }
    if (!mounted) return;
    if (match.food.pendiente) _nuevos.add(match.food.id!);
    await _notifier.addToCart(
      alimento: match.food,
      presentacionId: match.package.id,
      precioCent: res.precioCent,
      unidades: res.unidades,
      establecimiento: _tienda!,
    );
    HapticFeedback.lightImpact();
    if (mounted) {
      _toast(
        '✓ ${match.food.nombre} · '
        '${AppUtils.formatPrecioCent(res.precioCent * res.unidades)}',
      );
    }
  }

  /// Tocar un artículo del carrito: corregir precio/unidades o quitarlo.
  Future<void> _editCartItem(ShoppingItem item) async {
    if (item.compraId == null) return _addPendingItem(item);
    _busy = true;
    try {
      final res = await CartPriceSheet.show(
        context,
        CartPriceSheet(
          titulo: item.texto,
          precioInicialCent: item.precioCent,
          unidadesIniciales: item.unidades,
          edicion: true,
          alPeso: item.pesoG != null,
        ),
      );
      if (res == null || !mounted) return;
      if (res.quitar) {
        await _notifier.removeFromCart(item);
        if (mounted) _toast('${item.texto} quitado del carrito');
      } else {
        await _notifier.updateCartItem(
          item,
          precioCent: res.precioCent,
          unidades: res.unidades,
        );
      }
    } finally {
      _busy = false;
    }
  }

  /// Tocar un pendiente: meterlo en el carrito sin escanear (fruta a granel,
  /// productos sin código...). Si no está vinculado a un alimento se elige o
  /// se crea (todo lo comprado entra en el repertorio).
  Future<void> _addPendingItem(ShoppingItem item) async {
    _busy = true;
    try {
      Food? food;
      if (item.alimentoId != null) {
        food = await ref.read(foodRepositoryProvider).getFood(item.alimentoId!);
      }
      if (food == null) {
        if (!mounted) return;
        food = await FoodPickerView.pick(
          context,
          initialQuery: item.texto,
          title: '¿Qué es «${item.texto}»?',
        );
      }
      if (food == null || !mounted) return;
      if (food.pendiente) _nuevos.add(food.id!);
      await _addKnown(food, itemId: item.id);
    } finally {
      _busy = false;
    }
  }

  Future<void> _finish(ShoppingItemsState state) async {
    final pendientesNuevos = _nuevos.length;
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terminar compra'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppUtils.formatPrecioCent(state.totalCarritoCent),
              style: Theme.of(
                ctx,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              '${state.articulosEnCarrito} '
              '${state.articulosEnCarrito == 1 ? 'artículo' : 'artículos'} '
              'en $_tienda',
            ),
            if (state.compradosSinPrecio > 0)
              Text(
                '${state.compradosSinPrecio} marcados sin precio (no suman)',
                style: const TextStyle(color: AppStyles.semaphOrange),
              ),
            if (state.pendientes.isNotEmpty)
              Text('Quedan ${state.pendientes.length} pendientes en la lista.'),
            if (pendientesNuevos > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  pendientesNuevos == 1
                      ? 'Has añadido 1 producto nuevo sin tabla nutricional: '
                            'lo verás en Alimentos → Pendientes para '
                            'completarlo en casa.'
                      : 'Has añadido $pendientesNuevos productos nuevos sin '
                            'tabla nutricional: los verás en Alimentos → '
                            'Pendientes para completarlos en casa.',
                  style: const TextStyle(color: AppStyles.semaphBlue),
                ),
              ),
            const SizedBox(height: 8),
            const Text(
              'Los precios ya están guardados en el historial.',
              style: AppStyles.labelText,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Seguir comprando'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'mantener'),
            child: const Text('Mantener la lista'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'quitar'),
            child: const Text('Quitar comprados'),
          ),
        ],
      ),
    );
    if (action == null || !mounted) return;
    if (action == 'quitar') await _notifier.deleteBought();
    if (mounted) Navigator.pop(context);
  }

  Widget _cartTile(ShoppingItem item) {
    final precio = item.precioCent;
    final peso = item.pesoG;
    final kilo = precio == null ? null : pricePerKilo(precio, peso);
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: AppStyles.primary.withValues(alpha: 0.12),
        child: Text(
          '${item.unidades}×',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(item.texto, style: const TextStyle(fontSize: 16)),
      subtitle: precio == null
          ? const Text(
              'Sin precio · toca para añadirlo',
              style: TextStyle(color: AppStyles.semaphOrange),
            )
          : Text(
              peso != null
                  ? '${(peso / 1000).toStringAsFixed(3).replaceAll('.', ',')} kg'
                        '${kilo == null ? '' : ' · ${AppUtils.formatPrecioCent(kilo)}/kg'}'
                  : '${AppUtils.formatPrecioCent(precio)} / ud.',
            ),
      trailing: Text(
        precio == null ? '—' : AppUtils.formatPrecioCent(item.subtotalCent!),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      onTap: () => _editCartItem(item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shoppingItemsProvider(widget.listaId));
    final comprados = state.comprados;
    final pendientes = state.pendientes;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modo carrito'),
        backgroundColor: AppStyles.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_tienda != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                avatar: const Icon(Icons.storefront_outlined, size: 18),
                label: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(_tienda!, overflow: TextOverflow.ellipsis),
                ),
                tooltip: 'Cambiar de tienda',
                onPressed: _chooseStore,
              ),
            ),
        ],
      ),
      body: _tienda == null
          ? Center(
              child: TextButton.icon(
                onPressed: _chooseStore,
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('Elige la tienda para empezar'),
              ),
            )
          : Column(
              children: [
                SizedBox(
                  height: 210,
                  child:
                      widget.scannerBuilder?.call(context, _onCode) ??
                      BarcodeScannerPanel(
                        onCode: _onCode,
                        compacto: true,
                        instrucciones: 'Escanea cada producto al meterlo',
                      ),
                ),
                Material(
                  color: theme.colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shopping_cart, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'En el carrito · ${state.articulosEnCarrito} '
                                '${state.articulosEnCarrito == 1 ? 'artículo' : 'artículos'}',
                              ),
                              if (pendientes.isNotEmpty)
                                Text(
                                  'Te faltan ${pendientes.length}'
                                  '${state.estimadoPendienteCent > 0 ? ' (≈ ${AppUtils.formatPrecioCent(state.estimadoPendienteCent)})' : ''}',
                                  style: AppStyles.labelText,
                                ),
                            ],
                          ),
                        ),
                        Text(
                          AppUtils.formatPrecioCent(state.totalCarritoCent),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      if (comprados.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(AppStyles.paddingLarge),
                          child: Text(
                            'Escanea el código de barras de cada producto al '
                            'meterlo en el carrito. Lo que no tenga código '
                            '(fruta a granel...) añádelo tocándolo en '
                            '«Te falta».',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ...comprados.map(_cartTile),
                      if (pendientes.isNotEmpty)
                        ExpansionTile(
                          initiallyExpanded: comprados.isEmpty,
                          leading: const Icon(Icons.checklist),
                          title: Text('Te falta (${pendientes.length})'),
                          children: [
                            for (final g in groupByAisle(
                              pendientes,
                              ref
                                      .watch(categoriesProvider(_tienda))
                                      .valueOrNull ??
                                  const [],
                            )) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  0,
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    g.titulo,
                                    style: const TextStyle(
                                      color: AppStyles.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              for (final i in g.items)
                                ListTile(
                                  dense: true,
                                  leading: const Icon(
                                    Icons.check_box_outline_blank,
                                  ),
                                  title: Text(i.texto),
                                  subtitle: (i.cantidad ?? '').isEmpty
                                      ? null
                                      : Text(i.cantidad!),
                                  trailing: const Icon(Icons.add_shopping_cart),
                                  onTap: () => _addPendingItem(i),
                                ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: FilledButton.icon(
                      onPressed: () => _finish(state),
                      icon: const Icon(Icons.check),
                      label: const Text('Terminar compra'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
