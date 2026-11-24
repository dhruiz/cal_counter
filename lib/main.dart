import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/styles.dart';
import 'presentation/views/onboarding_view.dart';
import 'presentation/providers/theme_provider.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      // Nombre en la lista de apps recientes de Android.
      title: 'Contador de calorías',
      debugShowCheckedModeBanner: false,
      theme: AppStyles.lightTheme,
      darkTheme: AppStyles.darkTheme,
      themeMode: themeMode,
      // Sin esto los widgets de Material (p. ej. el selector de fecha de las
      // compras) aparecían en inglés en una app en español.
      locale: const Locale('es', 'ES'),
      supportedLocales: const [Locale('es', 'ES')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const StartupGate(),
    );
  }
}
