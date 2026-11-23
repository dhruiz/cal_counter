import 'package:cal_counter/domain/services/nutrition_label_parser.dart';
import 'package:cal_counter/presentation/widgets/label_reader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<LabelReviewAction?> open(
    WidgetTester tester,
    LabelParseResult result,
  ) async {
    LabelReviewAction? action;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  action = await LabelReviewSheet.show(
                    ctx,
                    result: result,
                    unidad: result.unidad ?? 'g',
                  );
                },
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return action;
  }

  testWidgets('muestra lo leído, marca dudosos y permite usarlo', (
    tester,
  ) async {
    final r = NutritionLabelParser.parseText('''
Valores medios por 100 ml
Valor energético 194 kJ / 46 kcal
Grasas (g) 1,6
Hidratos de carbono 4,7 g
Proteínas 3,1 g
''');
    await open(tester, r);
    expect(find.text('Lectura de la etiqueta'), findsOneWidget);
    expect(find.textContaining('Por 100 ml'), findsOneWidget);
    expect(find.text('46 kcal'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber), findsOneWidget); // grasas sin "g"
    expect(find.text('no leído'), findsWidgets);
    await tester.tap(find.text('Usar estos valores'));
    await tester.pumpAndSettle();
    expect(find.text('Lectura de la etiqueta'), findsNothing);
  });

  testWidgets('sin tabla reconocida solo ofrece repetir', (tester) async {
    await open(tester, NutritionLabelParser.parseText('Ingredientes: leche'));
    expect(find.textContaining('No se reconoció la tabla'), findsOneWidget);
    expect(find.text('Usar estos valores'), findsNothing);
    expect(find.text('Repetir la foto'), findsOneWidget);
  });
}
