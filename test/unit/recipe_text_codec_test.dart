import 'package:cal_counter/data/parsers/recipe_text_codec.dart';
import 'package:cal_counter/domain/entities/recipe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('texto', () {
    test('la plantilla de ejemplo produce 2 recetas completas', () {
      final res = RecipeTextCodec.parseText(RecipeTextCodec.plantilla);
      expect(res.length, 2);
      final t = res.first;
      expect(t.nombre, 'Tortilla de patatas');
      expect(t.categoria, 'Plato principal');
      expect(t.porciones, 4);
      expect(t.tiempoMin, 40);
      expect(t.lineas, [
        '4 huevos',
        '500 g de patatas',
        '1 cebolla (opcional)',
        'Aceite de oliva',
        'Sal',
      ]);
      expect(t.pasos.length, 4);
      expect(t.pasos.first, 'Pelar las patatas y cortarlas en láminas finas.');
      expect(t.notas, startsWith('Queda más jugosa'));
      expect(res[1].nombre, 'Ensalada de garbanzos');
    });

    test('encabezados alternativos, sin tildes, viñetas y numeración', () {
      const txt = '''
titulo: Arroz con leche
Raciones: 6 personas
tiempo: 1 h 15 min
ingredientes
• 1 l de leche
* 200 g de arroz
1) 1.5 cucharadas de canela
Elaboracion:
Paso 1: Hervir la leche.
2- Añadir el arroz.
nombre: Segunda
Ingredientes: huevo, harina, 1,5 kg de azúcar
''';
      final res = RecipeTextCodec.parseText(txt);
      expect(res.length, 2);
      final a = res.first;
      expect(a.nombre, 'Arroz con leche');
      expect(a.porciones, 6);
      expect(a.tiempoMin, 75);
      expect(a.lineas, [
        '1 l de leche',
        '200 g de arroz',
        '1.5 cucharadas de canela',
      ]);
      expect(a.pasos, ['Hervir la leche.', 'Añadir el arroz.']);
      expect(res[1].lineas, ['huevo', 'harina', '1,5 kg de azúcar']);
    });

    test('texto pegado sin encabezados (p. ej. desde WhatsApp)', () {
      const txt = '''
*Crema de calabaza*
- 1 kg de calabaza
2 zanahorias
Una cebolla
Cocer todo 20 minutos en agua.
Triturar y servir caliente.
''';
      final res = RecipeTextCodec.parseText(txt);
      expect(res.length, 1);
      final r = res.first;
      expect(r.nombre, 'Crema de calabaza');
      expect(r.lineas, [
        '1 kg de calabaza',
        '2 zanahorias',
        'Una cebolla',
      ]);
      expect(r.pasos, [
        'Cocer todo 20 minutos en agua.',
        'Triturar y servir caliente.',
      ]);
    });

    test('comentarios y líneas en blanco se ignoran; vacío → sin recetas', () {
      expect(RecipeTextCodec.parseText('# solo comentario\n\n---\n'), isEmpty);
    });

    test('"Tiempo:" largo dentro de los pasos no pisa el tiempo', () {
      const txt =
          'RECETA: X\nTIEMPO: 30 min\nPASOS:\nTiempo: 10 minutos en el horno a 180\n';
      final r = RecipeTextCodec.parseText(txt).single;
      expect(r.tiempoMin, 30);
      expect(r.pasos, ['Tiempo: 10 minutos en el horno a 180']);
    });
  });

  test('ida y vuelta formatRecipes → parseText', () {
    final original = [
      Recipe.desdeLineas(
        nombre: 'Gazpacho',
        categoria: 'Sopa fría',
        porciones: 4,
        tiempoMin: 90,
        lineas: ['1 kg de tomates', '1 pimiento verde', 'Sal'],
        elaboracion: 'Lavar y trocear.\nTriturar todo.\nEnfriar.',
        notas: 'Mejor de un día para otro.\nServir con picatostes.',
      ),
      Recipe.desdeLineas(nombre: 'Tostada', lineas: ['Pan', 'Tomate']),
    ];
    final text = RecipeTextCodec.formatRecipes(original);
    expect(text, contains('TIEMPO: 1 h 30 min'));
    final parsed = RecipeTextCodec.parseText(text);
    expect(parsed, original);
  });

  group('JSON', () {
    test('lista con claves flexibles', () {
      const json = '''
[
  {"Nombre": "Batido", "Categoría": "Bebida", "porciones": 2, "tiempo": "5 min",
   "ingredientes": ["1 plátano", "250 ml de leche"],
   "elaboración": ["Pelar el plátano", "Batir todo"]},
  {"titulo": "Café", "ingredientes": "café, agua", "pasos": "Preparar el café"}
]''';
      final res = RecipeTextCodec.parse(json, fileName: 'recetas.json');
      expect(res.length, 2);
      expect(res[0].nombre, 'Batido');
      expect(res[0].categoria, 'Bebida');
      expect(res[0].tiempoMin, 5);
      expect(res[0].pasos, ['Pelar el plátano', 'Batir todo']);
      expect(res[1].lineas, ['café', 'agua']);
    });

    test('objeto con "recetas" y detección por contenido', () {
      const json = '{"recetas": [{"nombre": "A", "ingredientes": ["x"]}]}';
      expect(RecipeTextCodec.parse(json).single.nombre, 'A');
    });
  });

  group('CSV', () {
    test('punto y coma, celdas entre comillas y multilínea', () {
      const csv =
          'nombre;categoria;porciones;ingredientes;preparacion\n'
          'Pancakes;Desayuno;2;"1 huevo\n200 ml de leche\n100 g de harina";"Mezclar|Cocinar en sartén"\n'
          'Té;Bebida;1;agua, té;Hervir el agua\n';
      final res = RecipeTextCodec.parse(csv, fileName: 'mis recetas.csv');
      expect(res.length, 2);
      expect(res[0].nombre, 'Pancakes');
      expect(res[0].porciones, 2);
      expect(res[0].lineas, [
        '1 huevo',
        '200 ml de leche',
        '100 g de harina',
      ]);
      expect(res[0].pasos, ['Mezclar', 'Cocinar en sartén']);
      expect(res[1].lineas, ['agua', 'té']);
    });

    test('coma como delimitador', () {
      const csv =
          'Nombre,Ingredientes\nSopa,"agua | fideos | 1,5 l de caldo"\n';
      final r = RecipeTextCodec.parseCsv(csv).single;
      expect(r.lineas, ['agua', 'fideos', '1,5 l de caldo']);
    });
  });

  test('parseMinutes', () {
    expect(RecipeTextCodec.parseMinutes('40 min'), 40);
    expect(RecipeTextCodec.parseMinutes('1h30'), 90);
    expect(RecipeTextCodec.parseMinutes('1,5 horas'), 90);
    expect(RecipeTextCodec.parseMinutes('2 horas'), 120);
    expect(RecipeTextCodec.parseMinutes('45'), 45);
    expect(RecipeTextCodec.parseMinutes('rápido'), isNull);
  });
}
