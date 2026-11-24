#!/usr/bin/env python3
"""Genera assets/semilla/frutas_verduras_usda.json desde USDA SR28.

Fuente de los datos: USDA, Agricultural Research Service, Nutrient Data
Laboratory. "USDA National Nutrient Database for Standard Reference,
Release 28" (2015, revisado en 2016). Dominio público.

Ningún valor nutricional ni peso de porción se escribe a mano: todos se leen
de los archivos oficiales por su número NDB. Este script solo decide QUÉ
alimentos entran, CÓMO se llaman en español y qué porciones de USDA se usan.

Los servidores de USDA no eran accesibles desde el entorno donde se creó, así
que el script usa dos redistribuciones independientes de los archivos
oficiales de SR28 y exige que coincidan valor por valor:

  - PyPI `django-usda-nutrition` 0.2.0: archivos ASCII completos de SR28
    (FOOD_DES, NUT_DATA, WEIGHT...).
  - npm `fda-nutrient-database` 1.0.2: archivo abreviado ABBREV de SR28.

Si alguna descarga no coincide con su sha256, si las descripciones difieren o
si un solo valor de los 8 nutrientes usados difiere entre las dos copias, el
script se detiene sin escribir nada.

Uso:
    python3 tool/semilla/generar_frutas_verduras.py [--cache DIR]
"""

import argparse
import hashlib
import io
import json
import os
import sys
import tarfile
import tempfile
import urllib.request
import uuid
from decimal import Decimal

RAIZ = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SALIDA = os.path.join(RAIZ, 'assets', 'semilla', 'frutas_verduras_usda.json')
DOC = os.path.join(RAIZ, 'docs', 'FRUTAS_VERDURAS_USDA.md')

FUENTES = {
    'pypi': {
        'url': 'https://files.pythonhosted.org/packages/83/d2/'
               '7e0720862f3e8f27cfc524b9bf4fd18f7aad7bd5ccd71c6f80dedf1b9243/'
               'django-usda-nutrition-0.2.0.tar.gz',
        'sha256': '3ed660b9e097eb97e2f063c3b18226b03aeed954d25e03847bff96967fd63c25',
        'prefijo': 'django-usda-nutrition-0.2.0/usda_nutrition/data/sr28/',
    },
    'npm': {
        'url': 'https://registry.npmjs.org/fda-nutrient-database/-/'
               'fda-nutrient-database-1.0.2.tgz',
        'sha256': '45434edd1024cba5ab7177a7171ba654281a6d363a1ec0da00594c7b19adb7cb',
        'prefijo': 'package/data/',
    },
}

# Identificadores de nutriente de SR28 (NUTR_DEF.txt) → clave del repertorio.
NUTRIENTES = {
    '208': 'kcal',              # Energy (kcal)
    '203': 'proteinas',         # Protein
    '204': 'grasas',            # Total lipid (fat)
    '606': 'grasas_saturadas',  # Fatty acids, total saturated
    '205': 'carbohidratos',     # Carbohydrate, by difference
    '269': 'azucares',          # Sugars, total
    '291': 'fibra',             # Fiber, total dietary
    '307': 'sodio_mg',          # Sodium, Na (mg)
}

# Columnas del archivo ABBREV (sr28_doc.pdf, p. 44) para los mismos nutrientes.
COLUMNAS_ABBREV = {
    'kcal': 3, 'proteinas': 4, 'grasas': 5, 'carbohidratos': 7,
    'fibra': 8, 'azucares': 9, 'sodio_mg': 15, 'grasas_saturadas': 44,
}

ETIQUETAS = {
    'kcal': 'kcal', 'proteinas': 'proteínas', 'grasas': 'grasas',
    'grasas_saturadas': 'grasas saturadas', 'carbohidratos': 'carbohidratos',
    'azucares': 'azúcares', 'fibra': 'fibra', 'sodio_mg': 'sodio (sal)',
}

FV = 'Frutas y verduras'
DESP = 'Despensa'

# (NDB, nombre en español, categoría). Los valores salen de la fuente.
SELECCION = [
    # ── Frutas frescas comunes ──────────────────────────────────────────
    ('09003', 'Manzana con piel, cruda', FV),
    ('09004', 'Manzana sin piel, cruda', FV),
    ('09252', 'Pera, cruda', FV),
    ('09040', 'Cambur (banano, banana), crudo', FV),
    ('09200', 'Naranja, cruda', FV),
    ('09206', 'Jugo de naranja natural (recién exprimido)', FV),
    ('09218', 'Mandarina, cruda', FV),
    ('09433', 'Clementina, cruda', FV),
    ('09111', 'Toronja (pomelo, Grapefruit), cruda', FV),
    ('09150', 'Limón amarillo (Zitrone), sin cáscara, crudo', FV),
    ('09152', 'Jugo de limón amarillo, natural', FV),
    ('09159', 'Lima ácida (limón verde, Limette), cruda', FV),
    ('09160', 'Jugo de lima ácida (limón verde), natural', FV),
    ('09132', 'Uvas rojas o verdes (tipo europeo), crudas', FV),
    ('09316', 'Fresas (frutillas), crudas', FV),
    ('09050', 'Arándanos (Heidelbeeren), crudos', FV),
    ('09302', 'Frambuesas, crudas', FV),
    ('09042', 'Moras (zarzamoras), crudas', FV),
    ('09084', 'Grosellas rojas y blancas (Johannisbeeren), crudas', FV),
    ('09083', 'Grosellas negras (casis), crudas', FV),
    ('09107', 'Grosellas espinosas (uva espina, Stachelbeeren), crudas', FV),
    ('09070', 'Cerezas dulces, crudas', FV),
    ('09063', 'Guindas (cerezas ácidas, Sauerkirschen), crudas', FV),
    ('09279', 'Ciruelas, crudas', FV),
    ('09021', 'Albaricoques (damascos, Aprikosen), crudos', FV),
    ('09236', 'Durazno amarillo (melocotón), crudo', FV),
    ('09191', 'Nectarina, cruda', FV),
    ('09089', 'Higos, crudos', FV),
    ('09286', 'Granada, cruda', FV),
    ('09263', 'Caqui (kaki, persimón), crudo', FV),
    ('09296', 'Membrillo, crudo', FV),
    ('09148', 'Kiwi verde, crudo', FV),
    ('09307', 'Ruibarbo (Rhabarber), crudo', FV),
    ('09326', 'Patilla (sandía), cruda', FV),
    ('09181', 'Melón cantalupo, crudo', FV),
    ('09184', 'Melón verde (honeydew), crudo', FV),
    ('09266', 'Piña (ananá), cruda', FV),
    ('09176', 'Mango, crudo', FV),
    ('09226', 'Lechoza (papaya), cruda', FV),
    ('09037', 'Aguacate (palta), crudo, promedio de variedades comerciales', FV),
    ('09038', 'Aguacate de California (palta), crudo', FV),
    ('09039', 'Aguacate de Florida (palta), crudo', FV),
    ('12104', 'Coco, pulpa cruda', FV),
    ('12119', 'Agua de coco', FV),

    # ── Frutas latinoamericanas ─────────────────────────────────────────
    ('09139', 'Guayaba, cruda', FV),
    ('09315', 'Guanábana, cruda', FV),
    ('09062', 'Chirimoya, cruda', FV),
    ('09321', 'Anón (saramuyo), crudo', FV),
    ('09231', 'Maracuyá morado (gulupa, parchita morada), crudo', FV),
    ('09233', 'Jugo de maracuyá amarillo (parchita), natural', FV),
    ('09175', 'Mamey, crudo', FV),
    ('09314', 'Zapote (mamey colorado), crudo', FV),
    ('09313', 'Níspero (sapodilla, zapote chico), crudo', FV),
    ('09174', 'Níspero del Japón (níspero de España), crudo', FV),
    ('09322', 'Tamarindo, crudo', FV),
    ('09138', 'Uchuva (aguaymanto, Physalis), cruda', FV),
    ('09450', 'Lulo (naranjilla), pulpa congelada sin azúcar', FV),
    ('09060', 'Carambola (fruta estrella), cruda', FV),
    ('09001', 'Semeruco (acerola), crudo', FV),
    ('09312', 'Pomarrosa, cruda', FV),
    ('09334', 'Feijoa, cruda', FV),
    ('09449', 'Nance (chaparro manteco), congelado sin azúcar', FV),
    ('09287', 'Tuna (higo chumbo), cruda', FV),
    ('09277', 'Plátano macho (plátano para cocinar), crudo', FV),
    ('09278', 'Plátano macho, cocido', FV),
    ('09446', 'Tostones o patacones (plátano verde frito)', FV),
    ('09447', 'Plátano maduro frito (tajadas), de restaurante latino', FV),

    # ── Frutas secas y conservas ────────────────────────────────────────
    ('09298', 'Uvas pasas sin semillas', DESP),
    ('09291', 'Ciruelas pasas (secas)', DESP),
    ('09032', 'Orejones de albaricoque (secos)', DESP),
    ('09094', 'Higos secos', DESP),
    ('09087', 'Dátiles Deglet Noor', DESP),
    ('09421', 'Dátiles Medjool', DESP),
    ('09079', 'Arándanos rojos deshidratados, endulzados', DESP),
    ('09178', 'Mango deshidratado, endulzado', DESP),
    ('09193', 'Aceitunas negras maduras, en lata', DESP),
    ('09195', 'Aceitunas verdes, encurtidas, en conserva', DESP),
    ('02054', 'Alcaparras, en conserva', DESP),

    # ── Tomate, cebollas y aromáticos ───────────────────────────────────
    ('11529', 'Tomate rojo maduro, crudo', FV),
    ('11531', 'Tomate en lata, en su jugo', DESP),
    ('11693', 'Tomate triturado, en lata', DESP),
    ('11546', 'Pasta de tomate (concentrado), sin sal añadida', DESP),
    ('11547', 'Puré de tomate en lata, sin sal añadida', DESP),
    ('11955', 'Tomates secos (deshidratados)', DESP),
    ('11956', 'Tomates secos en aceite, escurridos', DESP),
    ('11282', 'Cebolla, cruda', FV),
    ('11283', 'Cebolla, cocida (hervida, sin sal)', FV),
    ('11677', 'Chalota (Schalotte), cruda', FV),
    ('11291', 'Cebollín (cebolla larga, cebolleta), crudo', FV),
    ('11156', 'Cebollino (ciboulette, Schnittlauch), crudo', FV),
    ('11246', 'Ajoporro (puerro, Lauch), crudo', FV),
    ('11247', 'Ajoporro (puerro, Lauch), cocido (hervido, sin sal)', FV),
    ('11215', 'Ajo, crudo', FV),
    ('11216', 'Jengibre, raíz cruda', FV),

    # ── Hortalizas de fruto ─────────────────────────────────────────────
    ('11205', 'Pepino con piel, crudo', FV),
    ('11206', 'Pepino pelado, crudo', FV),
    ('11937', 'Pepinillos encurtidos al eneldo', DESP),
    ('11477', 'Calabacín (zucchini), crudo', FV),
    ('11478', 'Calabacín (zucchini), cocido (hervido, sin sal)', FV),
    ('11209', 'Berenjena, cruda', FV),
    ('11210', 'Berenjena, cocida (hervida, sin sal)', FV),
    ('11333', 'Pimentón verde (pimiento verde), crudo', FV),
    ('11821', 'Pimentón rojo (pimiento rojo), crudo', FV),
    ('11951', 'Pimentón amarillo (pimiento amarillo), crudo', FV),
    ('11670', 'Ají picante verde (chile verde), crudo', FV),
    ('11819', 'Ají picante rojo (chile rojo), crudo', FV),
    ('11979', 'Jalapeño, crudo', FV),
    ('11278', 'Quimbombó (okra), crudo', FV),
    ('11279', 'Quimbombó (okra), cocido (hervido, sin sal)', FV),
    ('11422', 'Auyama (ahuyama, calabaza, Kürbis), cruda', FV),
    ('11423', 'Auyama (ahuyama, calabaza), cocida (hervida, sin sal)', FV),
    ('11485', 'Calabaza butternut (Butternutkürbis), cruda', FV),
    ('11486', 'Calabaza butternut, horneada (sin sal)', FV),
    ('11149', 'Chayota (chayote, guatila, cidra), cruda', FV),
    ('11150', 'Chayota (chayote), cocida (hervida, sin sal)', FV),

    # ── Legumbres frescas y maíz tierno ─────────────────────────────────
    ('11052', 'Vainitas (judías verdes, habichuelas), crudas', FV),
    ('11053', 'Vainitas (judías verdes), cocidas (hervidas, sin sal)', FV),
    ('11304', 'Arvejas (guisantes), crudas', FV),
    ('11305', 'Arvejas (guisantes), cocidas (hervidas, sin sal)', FV),
    ('11300', 'Arvejas chinas (tirabeques, Zuckerschoten), crudas', FV),
    ('11088', 'Habas tiernas, crudas', FV),
    ('11089', 'Habas tiernas, cocidas (hervidas, sin sal)', FV),
    ('11344', 'Quinchoncho tierno (guandú), crudo', FV),
    ('11345', 'Quinchoncho tierno (guandú), cocido (hervido, sin sal)', FV),
    ('11191', 'Frijol tierno (caupí, ojo negro), crudo', FV),
    ('11192', 'Frijol tierno (caupí, ojo negro), cocido (hervido, sin sal)', FV),
    ('11167', 'Jojoto amarillo (maíz tierno, mazorca), crudo', FV),
    ('11168', 'Jojoto amarillo (maíz tierno), cocido (hervido, sin sal)', FV),
    ('11900', 'Jojoto blanco (maíz tierno, mazorca), crudo', FV),
    ('11901', 'Jojoto blanco (maíz tierno), cocido (hervido, sin sal)', FV),
    ('11172', 'Maíz dulce en lata, escurrido', DESP),

    # ── Coles y crucíferas ──────────────────────────────────────────────
    ('11090', 'Brócoli, crudo', FV),
    ('11091', 'Brócoli, cocido (hervido, sin sal)', FV),
    ('11135', 'Coliflor, cruda', FV),
    ('11136', 'Coliflor, cocida (hervida, sin sal)', FV),
    ('11098', 'Repollitos de Bruselas (Rosenkohl), crudos', FV),
    ('11099', 'Repollitos de Bruselas (Rosenkohl), cocidos (hervidos, sin sal)', FV),
    ('11109', 'Repollo blanco (col, Weißkohl), crudo', FV),
    ('11110', 'Repollo blanco (col, Weißkohl), cocido (hervido, sin sal)', FV),
    ('11112', 'Repollo morado (lombarda, Rotkohl), crudo', FV),
    ('11113', 'Repollo morado (lombarda, Rotkohl), cocido (hervido, sin sal)', FV),
    ('11114', 'Col de Milán (repollo crespo, Wirsing), cruda', FV),
    ('11115', 'Col de Milán (Wirsing), cocida (hervida, sin sal)', FV),
    ('11233', 'Col rizada (kale, Grünkohl), cruda', FV),
    ('11234', 'Col rizada (kale, Grünkohl), cocida (hervida, sin sal)', FV),
    ('11119', 'Col china (repollo chino, Chinakohl), cruda', FV),
    ('11116', 'Pak choi (bok choy), crudo', FV),
    ('11241', 'Colinabo (Kohlrabi), crudo', FV),
    ('11242', 'Colinabo (Kohlrabi), cocido (hervido, sin sal)', FV),
    ('11439', 'Chucrut (Sauerkraut), en conserva', DESP),

    # ── Raíces, bulbos y tallos ─────────────────────────────────────────
    ('11124', 'Zanahoria, cruda', FV),
    ('11125', 'Zanahoria, cocida (hervida, sin sal)', FV),
    ('11080', 'Remolacha (betabel, Rote Bete), cruda', FV),
    ('11081', 'Remolacha (Rote Bete), cocida (hervida)', FV),
    ('11435', 'Nabo sueco (rutabaga, Steckrübe), crudo', FV),
    ('11436', 'Nabo sueco (rutabaga, Steckrübe), cocido (hervido, sin sal)', FV),
    ('11564', 'Nabo, crudo', FV),
    ('11565', 'Nabo, cocido (hervido, sin sal)', FV),
    ('11298', 'Chirivía (pastinaca, Pastinake), cruda', FV),
    ('11299', 'Chirivía (pastinaca, Pastinake), cocida (hervida, sin sal)', FV),
    ('11141', 'Apionabo (Knollensellerie), crudo', FV),
    ('11142', 'Apionabo (Knollensellerie), cocido (hervido, sin sal)', FV),
    ('11143', 'Apio España (apio de tallo, Staudensellerie), crudo', FV),
    ('11429', 'Rábano (rabanito, Radieschen), crudo', FV),
    ('11430', 'Rábano blanco (daikon, Rettich), crudo', FV),
    ('11226', 'Tupinambo (Topinambur), crudo', FV),
    ('11957', 'Hinojo (bulbo), crudo', FV),
    ('11007', 'Alcachofa, cruda', FV),
    ('11008', 'Alcachofa, cocida (hervida, sin sal)', FV),
    ('11011', 'Espárragos, crudos', FV),
    ('11012', 'Espárragos, cocidos (hervidos)', FV),
    ('11015', 'Espárragos en lata, escurridos', DESP),
    ('11961', 'Palmito en lata', DESP),
    ('11975', 'Hojas de parra en conserva', DESP),
    ('11963', 'Nopal, crudo', FV),
    ('11964', 'Nopal, cocido (sin sal)', FV),

    # ── Hojas verdes y ensalada ─────────────────────────────────────────
    ('11457', 'Espinaca, cruda', FV),
    ('11458', 'Espinaca, cocida (hervida, sin sal)', FV),
    ('11147', 'Acelga, cruda', FV),
    ('11148', 'Acelga, cocida (hervida, sin sal)', FV),
    ('11252', 'Lechuga iceberg (americana), cruda', FV),
    ('11251', 'Lechuga romana, cruda', FV),
    ('11250', 'Lechuga mantecosa (Kopfsalat), cruda', FV),
    ('11253', 'Lechuga de hoja verde, cruda', FV),
    ('11257', 'Lechuga de hoja roja, cruda', FV),
    ('11959', 'Rúcula (rúgula, Rucola), cruda', FV),
    ('11190', 'Canónigos (Feldsalat), crudos', FV),
    ('11213', 'Escarola (Endivie), cruda', FV),
    ('11151', 'Endibia belga (Chicorée), cruda', FV),
    ('11952', 'Radicchio (achicoria roja), crudo', FV),
    ('11591', 'Berro (Brunnenkresse), crudo', FV),
    ('11203', 'Mastuerzo (berro de jardín, Gartenkresse), crudo', FV),
    ('11043', 'Germinados de frijol mungo (brotes de soja), crudos', FV),

    # ── Hierbas frescas ─────────────────────────────────────────────────
    ('11165', 'Cilantro (hojas), crudo', FV),
    ('11297', 'Perejil, fresco', FV),
    ('02044', 'Albahaca, fresca', FV),
    ('02045', 'Eneldo, fresco', FV),
    ('02065', 'Hierbabuena, fresca', FV),
    ('02064', 'Menta piperita, fresca', FV),
    ('02049', 'Tomillo, fresco', FV),
    ('02063', 'Romero, fresco', FV),

    # ── Setas ───────────────────────────────────────────────────────────
    ('11260', 'Champiñones blancos, crudos', FV),
    ('11261', 'Champiñones blancos, cocidos (hervidos, sin sal)', FV),
    ('11264', 'Champiñones en lata, escurridos', DESP),
    ('11266', 'Champiñones marrones (crimini), crudos', FV),
    ('11265', 'Portobello, crudo', FV),
    ('11238', 'Shiitake, crudo', FV),
    ('11987', 'Setas de ostra (gírgolas, Austernpilze), crudas', FV),
    ('11239', 'Rebozuelos (Pfifferlinge), crudos', FV),

    # ── Raíces y tubérculos ─────────────────────────────────────────────
    ('11352', 'Papa (patata) con piel, cruda', FV),
    ('11367', 'Papa (patata) pelada, hervida sin sal', FV),
    ('11365', 'Papa (patata) hervida con piel, solo pulpa, sin sal', FV),
    ('11674', 'Papa (patata) asada al horno, con piel, sin sal', FV),
    ('11507', 'Batata (boniato, camote, Süßkartoffel), cruda', FV),
    ('11510', 'Batata (boniato, camote), hervida sin piel', FV),
    ('11508', 'Batata (boniato, camote), asada al horno, pulpa, sin sal', FV),
    ('11134', 'Yuca (mandioca), cruda', FV),
    ('11601', 'Ñame, crudo', FV),
    ('11602', 'Ñame, cocido (hervido u horneado, sin sal)', FV),
    ('11991', 'Ocumo (yautía, malanga), crudo', FV),
    ('11518', 'Ocumo chino (taro), crudo', FV),
    ('11519', 'Ocumo chino (taro), cocido (sin sal)', FV),
]

# Porciones tomadas de WEIGHT.txt de SR28: NDB → [(Seq, nombre en español,
# descripción USDA esperada)]. El generador comprueba que la medida con ese
# número de secuencia tiene exactamente esa descripción y cantidad, y toma los
# gramos de la fuente. Las pulgadas se pasan a centímetros (1" = 2,54 cm).
PORCIONES = {
    '09003': [(4, '1 unidad mediana', '1 medium (3" dia)'),
              (5, '1 unidad pequeña', '1 small (2-3/4" dia)'),
              (3, '1 unidad grande', '1 large (3-1/4" dia)')],
    '09004': [(3, '1 unidad mediana', '1 medium (3" dia)'),
              (4, '1 unidad pequeña', '1 small (2-3/4" dia)'),
              (2, '1 unidad grande', '1 large (3-1/4" dia)')],
    '09252': [(4, '1 unidad mediana', '1 medium'),
              (3, '1 unidad pequeña', '1 small'),
              (5, '1 unidad grande', '1 large')],
    '09040': [(5, '1 unidad mediana (18-20 cm)', '1 medium (7" to 7-7/8" long)'),
              (4, '1 unidad pequeña (15-17 cm)', '1 small (6" to 6-7/8" long)'),
              (6, '1 unidad grande (20-23 cm)', '1 large (8" to 8-7/8" long)')],
    '09200': [(4, '1 unidad (6,7 cm de diámetro)', '1 fruit (2-5/8" dia)'),
              (3, '1 unidad pequeña (6 cm de diámetro)', '1 small (2-3/8" dia)'),
              (2, '1 unidad grande (7,8 cm de diámetro)', '1 large (3-1/16" dia)')],
    '09206': [(3, 'Jugo de 1 naranja', '1 fruit yields'),
              (1, '1 taza', '1 cup')],
    '09218': [(3, '1 unidad mediana', '1 medium (2-1/2" dia)'),
              (2, '1 unidad pequeña', '1 small (2-1/4" dia)'),
              (4, '1 unidad grande', '1 large (2-3/4" dia)')],
    '09433': [(1, '1 unidad', '1 fruit')],
    '09111': [(3, '½ unidad mediana', '.5 medium (approx 4" dia)'),
              (4, '½ unidad pequeña', '.5 small (approx 3-1/2" dia)'),
              (2, '½ unidad grande', '.5 large (approx 4-1/2" dia)')],
    '09150': [(2, '1 unidad (5,4 cm de diámetro)', '1 fruit (2-1/8" dia)'),
              (3, '1 unidad (6 cm de diámetro)', '1 fruit (2-3/8" dia)')],
    '09152': [(3, 'Jugo de 1 limón', '1 lemon yields')],
    '09159': [(1, '1 unidad (5 cm de diámetro)', '1 fruit (2" dia)')],
    '09160': [(3, 'Jugo de 1 lima', '1 lime yields')],
    '09132': [(2, '10 uvas', '10 grapes')],
    '09316': [(7, '1 fresa mediana', '1 medium (1-1/4" dia)'),
              (6, '1 fresa grande', '1 large (1-3/8" dia)')],
    '09050': [(2, '50 arándanos', '50 berries')],
    '09302': [(3, '10 frambuesas', '10 raspberries')],
    '09070': [(3, '1 cereza', '1 cherry')],
    '09279': [(2, '1 unidad (5,4 cm de diámetro)', '1 fruit (2-1/8" dia)')],
    '09021': [(3, '1 unidad', '1 apricot')],
    '09236': [(3, '1 unidad mediana', '1 medium (2-2/3" dia)'),
              (2, '1 unidad pequeña', '1 small (2-1/2" dia)'),
              (4, '1 unidad grande', '1 large (2-3/4" dia)')],
    '09191': [(3, '1 unidad mediana', '1 medium (2-1/2" dia)'),
              (2, '1 unidad pequeña', '1 small (2-1/3" dia)'),
              (4, '1 unidad grande', '1 large (2-3/4" dia)')],
    '09089': [(2, '1 unidad mediana', '1 medium (2-1/4" dia)'),
              (3, '1 unidad pequeña', '1 small (1-1/2" dia)'),
              (1, '1 unidad grande', '1 large (2-1/2" dia)')],
    '09286': [(2, '1 unidad (10 cm de diámetro)', '1 pomegranate (4" dia)')],
    '09263': [(1, '1 unidad (6,4 cm de diámetro)', '1 fruit (2-1/2" dia)')],
    '09296': [(1, '1 unidad', '1 fruit without refuse')],
    '09148': [(2, '1 unidad (5 cm de diámetro)', '1 fruit (2" dia)')],
    '09307': [(2, '1 tallo', '1 stalk')],
    '09326': [(4, '1 tajada (1/16 de patilla)', '1 wedge (approx 1/16 of melon)')],
    '09181': [(7, '1 tajada (1/8 de melón mediano)', '1 wedge, medium (1/8 of medium melon)')],
    '09184': [(5, '1 tajada (1/8 de melón de 13 cm)', '1 wedge (1/8 of 5-1/4" dia melon)')],
    '09266': [(4, '1 rodaja (9 cm de diámetro, 2 cm de grosor)', '1 slice (3-1/2" dia x 3/4" thick)')],
    '09176': [(2, '1 unidad', '1 fruit without refuse')],
    '09226': [(3, '1 unidad pequeña', '1 fruit, small')],
    '09037': [(4, '1 unidad', '1 avocado, NS as to Florida or California')],
    '09038': [(2, '1 unidad', '1 fruit, without skin and seed')],
    '09039': [(2, '1 unidad', '1 fruit without skin and seeds')],
    '12104': [(3, '1 trozo (5 × 5 × 1,3 cm)', '1 piece (2" x 2" x 1/2")')],
    '12119': [(3, 'Agua de 1 coco', '1 coconut yields'),
              (1, '1 taza', '1 cup')],
    '09139': [(2, '1 unidad', '1 fruit, without refuse')],
    '09315': [(2, '1 unidad (18 × 13 cm)', '1 fruit (7" x 5-1/4" dia)')],
    '09062': [(2, '1 unidad', '1 fruit without skin and seeds')],
    '09321': [(2, '1 unidad (7,3 cm de diámetro)', '1 fruit (2-7/8" dia)')],
    '09231': [(2, '1 unidad', '1 fruit without refuse')],
    '09233': [(1, '1 taza', '1 cup')],
    '09175': [(1, '1 unidad', '1 fruit without refuse')],
    '09314': [(2, '1 unidad', '1 fruit without refuse')],
    '09313': [(2, '1 unidad', '1 sapodilla')],
    '09174': [(3, '1 unidad mediana', '1 medium')],
    '09322': [(2, '1 vaina (7,6 × 2,5 cm)', '1 fruit (3" x 1")')],
    '09060': [(4, '1 unidad mediana (9 cm de largo)', '1 medium (3-5/8" long)'),
              (5, '1 unidad pequeña (8 cm de largo)', '1 small (3-1/8" long)'),
              (3, '1 unidad grande (11,4 cm de largo)', '1 large (4-1/2" long)')],
    '09001': [(2, '1 unidad', '1 fruit without refuse')],
    '09334': [(2, '1 unidad', '1 fruit without peel')],
    '09449': [(2, '3 unidades', '3 fruit without pits, thawed')],
    '09287': [(2, '1 unidad', '1 fruit without refuse')],
    '09277': [(2, '1 unidad mediana', '1 medium')],
    '09446': [(2, '10 rodajas (6 mm de grosor)', '10 slices (1/4" thick)')],
    '09298': [(5, '50 pasas', '50 raisins')],
    '09291': [(2, '1 unidad', '1 prune, pitted')],
    '09032': [(2, '1 mitad', '1 half')],
    '09094': [(2, '1 unidad', '1 fig')],
    '09087': [(2, '1 dátil', '1 date, pitted')],
    '09421': [(1, '1 dátil', '1 date, pitted')],
    '09193': [(2, '1 aceituna grande', '1 large'),
              (3, '1 aceituna pequeña', '1 small')],
    '09195': [(1, '1 aceituna', '1 olive')],
    '02054': [(1, '1 cucharada (escurridas)', '1 tbsp, drained')],
    '11529': [(6, '1 unidad mediana (6,6 cm de diámetro)', '1 medium whole (2-3/5" dia)'),
              (9, '1 unidad pequeña (6,1 cm de diámetro)', '1 small whole (2-2/5" dia)'),
              (5, '1 unidad grande (7,6 cm de diámetro)', '1 large whole (3" dia)'),
              (4, '1 tomate cherry', '1 cherry'),
              (8, '1 tomate perita', '1 plum tomato')],
    '11546': [(3, '1 cucharada', '1 tbsp')],
    '11955': [(2, '1 pieza', '1 piece')],
    '11956': [(2, '1 pieza', '1 piece')],
    '11282': [(6, '1 unidad mediana (6,4 cm de diámetro)', '1 medium (2-1/2" dia)'),
              (8, '1 unidad pequeña', '1 small'),
              (4, '1 unidad grande', '1 large'),
              (3, '1 cucharada picada', '1 tbsp chopped')],
    '11677': [(1, '1 cucharada picada', '1 tbsp chopped')],
    '11291': [(4, '1 tallo mediano (10,5 cm)', '1 medium (4-1/8" long)'),
              (2, '1 cucharada picada', '1 tbsp chopped')],
    '11156': [(1, '1 cucharada picada', '1 tbsp chopped')],
    '11246': [(2, '1 unidad', '1 leek')],
    '11215': [(3, '1 diente', '1 clove')],
    '11216': [(1, '1 cucharadita', '1 tsp')],
    '11205': [(2, '1 unidad (21 cm)', '1 cucumber (8-1/4")')],
    '11206': [(4, '1 unidad mediana', '1 medium')],
    '11937': [(3, '1 unidad grande (10 cm)', '1 large (4" long)')],
    '11477': [(4, '1 unidad mediana', '1 medium'),
              (6, '1 unidad pequeña', '1 small'),
              (3, '1 unidad grande', '1 large')],
    '11209': [(3, '1 unidad con piel', '1 eggplant, unpeeled (approx 1-1/4 lb)')],
    '11333': [(5, '1 unidad mediana', '1 medium (approx 2-3/4" long, 2-1/2" dia)'),
              (7, '1 unidad pequeña', '1 small'),
              (4, '1 unidad grande', '1 large (2-1/4 per lb, approx 3-3/4" long, 3" dia)')],
    '11821': [(5, '1 unidad mediana', '1 medium (approx 2-3/4" long, 2-1/2 dia.)'),
              (6, '1 unidad pequeña', '1 small'),
              (4, '1 unidad grande', '1 large (2-1/4 per pound, approx 3-3/4" long, 3" dia.)')],
    '11951': [(1, '1 unidad grande', '1 pepper, large (3-3/4" long, 3" dia)')],
    '11670': [(1, '1 unidad', '1 pepper')],
    '11819': [(1, '1 unidad', '1 pepper')],
    '11979': [(2, '1 unidad', '1 pepper')],
    '11278': [(2, '8 vainas (7,6 cm)', '8 pods (3" long)')],
    '11279': [(2, '8 vainas (7,6 cm)', '8 pods (3" long)')],
    '11149': [(2, '1 unidad (14,6 cm)', '1 chayote (5-3/4")')],
    '11052': [(2, '10 vainitas (10 cm)', '10 beans (4" long)')],
    '11300': [(3, '10 vainas', '10 pea pods')],
    '11167': [(3, 'Granos de 1 mazorca mediana', '1 ear, medium (6-3/4" to 7-1/2" long) yields'),
              (2, 'Granos de 1 mazorca grande', '1 ear, large (7-3/4" to 9" long) yields')],
    '11168': [(2, 'Granos de 1 mazorca mediana', '1 ear medium (6-3/4" to 7-1/2" long)'),
              (1, 'Granos de 1 mazorca pequeña', '1 ear small (5-1/2" to 6-1/2" long)'),
              (3, 'Granos de 1 mazorca grande', '1 ear large (7-3/4" to 9" long)')],
    '11900': [(2, 'Granos de 1 mazorca mediana', '1 ear, medium (6-3/4" to 7-1/2" long)'),
              (1, 'Granos de 1 mazorca pequeña', '1 ear, small (5-1/2" to 6-1/2" long)'),
              (3, 'Granos de 1 mazorca grande', '1 ear, large (7-3/4" to 9" long)')],
    '11901': [(2, 'Granos de 1 mazorca mediana', '1 ear, medium (6-3/4" to 7-1/2" long)'),
              (1, 'Granos de 1 mazorca pequeña', '1 ear, small (5-1/2" to 6-1/2" long)'),
              (3, 'Granos de 1 mazorca grande', '1 ear, large (7-3/4" to 9" long)')],
    '11090': [(3, '1 rama (13 cm)', '1 spear (about 5" long)')],
    '11091': [(5, '1 rama (13 cm)', '1 spear (about 5" long)')],
    '11135': [(2, '1 ramillete', '1 floweret'),
              (4, '1 cabeza mediana (13-15 cm)', '1 head medium (5-6" dia.)')],
    '11136': [(2, '3 ramilletes', '3 flowerets')],
    '11098': [(2, '1 unidad', '1 sprout')],
    '11099': [(1, '1 unidad', '1 sprout')],
    '11109': [(6, '1 hoja mediana', '1 leaf, medium'),
              (5, '1 cabeza mediana (14,6 cm)', '1 head, medium (about 5-3/4" dia)')],
    '11112': [(4, '1 hoja', '1 leaf'),
              (5, '1 cabeza mediana (12,7 cm)', '1 head, medium (about 5" dia)')],
    '11113': [(1, '1 hoja', '1 leaf')],
    '11116': [(3, '1 hoja', '1 leaf')],
    '11241': [(2, '1 rodaja', '1 slice')],
    '11124': [(5, '1 unidad mediana', '1 medium'),
              (6, '1 unidad pequeña (14 cm)', '1 small (5-1/2" long)'),
              (4, '1 unidad grande (18-21,5 cm)', '1 large (7-1/4" to 8-/1/2" long)')],
    '11125': [(3, '1 unidad', '1 carrot')],
    '11080': [(2, '1 unidad (5 cm de diámetro)', '1 beet (2" dia)')],
    '11081': [(2, '2 unidades (5 cm de diámetro)', '2 beets (2" dia, sphere)')],
    '11435': [(3, '1 unidad mediana', '1 medium'),
              (4, '1 unidad pequeña', '1 small'),
              (2, '1 unidad grande', '1 large')],
    '11564': [(3, '1 unidad mediana', '1 medium'),
              (5, '1 unidad pequeña', '1 small'),
              (2, '1 unidad grande', '1 large')],
    '11299': [(2, '1 unidad (23 cm)', '1 parsnip (9" long)')],
    '11143': [(5, '1 tallo mediano (19-20 cm)', '1 stalk, medium (7-1/2" - 8" long)'),
              (4, '1 tallo grande (28-30 cm)', '1 stalk, large (11"-12" long)')],
    '11429': [(3, '1 unidad mediana', '1 medium (3/4" to 1" dia)')],
    '11430': [(2, '1 unidad (18 cm)', '1 radish (7" long)')],
    '11957': [(2, '1 bulbo', '1 bulb')],
    '11007': [(1, '1 unidad mediana', '1 artichoke, medium'),
              (2, '1 unidad grande', '1 artichoke, large')],
    '11008': [(1, '1 unidad mediana', '1 artichoke, medium')],
    '11011': [(3, '1 espárrago mediano (13-18 cm)', '1 spear, medium (5-1/4" to 7" long)'),
              (4, '1 espárrago grande (18-21,5 cm)', '1 spear, large (7-1/4" to 8-1/2")')],
    '11012': [(2, '4 espárragos', '4 spears (1/2" base)')],
    '11015': [(2, '1 espárrago (13 cm)', '1 spear (about 5" long)')],
    '11961': [(2, '1 pieza', '1 piece')],
    '11975': [(1, '1 hoja', '1 leaf')],
    '11964': [(2, '1 penca', '1 pad')],
    '11457': [(3, '1 hoja', '1 leaf')],
    '11147': [(2, '1 hoja', '1 leaf')],
    '11252': [(7, '1 hoja mediana', '1 leaf, medium'),
              (4, '1 cabeza mediana (15 cm)', '1 head, medium (6" dia)')],
    '11251': [(3, '1 hoja exterior', '1 leaf outer'),
              (2, '1 hoja interior', '1 leaf inner')],
    '11250': [(4, '1 hoja mediana', '1 leaf, medium'),
              (2, '1 cabeza (12,7 cm)', '1 head (5" dia)')],
    '11253': [(4, '1 hoja exterior', '1 leaf outer')],
    '11257': [(3, '1 hoja exterior', '1 leaf outer')],
    '11959': [(1, '1 hoja', '1 leaf')],
    '11151': [(1, '1 cabeza', '1 head')],
    '11952': [(2, '1 hoja', '1 leaf')],
    '11591': [(3, '10 ramitas', '10 sprigs')],
    '11165': [(2, '9 ramitas', '9 sprigs')],
    '11297': [(2, '1 cucharada', '1 tbsp'),
              (3, '10 ramitas', '10 sprigs')],
    '02044': [(1, '5 hojas', '5 leaves'),
              (2, '2 cucharadas, picada', '2 tbsp, chopped')],
    '02045': [(1, '5 ramitas', '5 sprigs')],
    '02065': [(2, '2 cucharadas', '2 tbsp')],
    '02064': [(2, '2 cucharadas', '2 tbsp')],
    '02049': [(1, '1 cucharadita', '1 tsp')],
    '02063': [(1, '1 cucharadita', '1 tsp'),
              (2, '1 cucharada', '1 tbsp')],
    '11260': [(4, '1 unidad mediana', '1 medium'),
              (6, '1 unidad pequeña', '1 small'),
              (3, '1 unidad grande', '1 large')],
    '11261': [(3, '1 unidad', '1 mushroom')],
    '11264': [(4, '1 unidad mediana', '1 medium')],
    '11266': [(3, '1 unidad', '1 piece whole')],
    '11265': [(2, '1 unidad', '1 piece whole')],
    '11238': [(1, '1 unidad', '1 piece whole')],
    '11987': [(2, '1 unidad pequeña', '1 small'),
              (1, '1 unidad grande', '1 large')],
    '11239': [(2, '1 unidad', '1 piece')],
    '11352': [(3, '1 unidad mediana (5,7-8,3 cm)', '1 Potato medium (2-1/4" to 3-1/4" dia)'),
              (4, '1 unidad pequeña (4,4-6,4 cm)', '1 Potato small (1-3/4" to 2-1/2" dia)'),
              (2, '1 unidad grande (7,6-10,8 cm)', '1 Potato large (3" to 4-1/4" dia)')],
    '11367': [(3, '1 unidad mediana (5,7-8,3 cm)', '1 medium (2-1/4" to 3-1/4" dia.)'),
              (4, '1 unidad pequeña (4,4-6,4 cm)', '1 small (1-3/4" to 2-1/2" dia.)'),
              (2, '1 unidad grande (7,6-10,8 cm)', '1 large (3" to 4-1/4" dia.)')],
    '11365': [(2, '1 unidad (6,4 cm de diámetro)', '1 potato (2-1/2" dia, sphere)')],
    '11674': [(3, '1 unidad mediana', '1 potato medium'),
              (4, '1 unidad pequeña', '1 potato small'),
              (2, '1 unidad grande', '1 potato large')],
    '11507': [(2, '1 unidad (13 cm de largo)', '1 sweetpotato, 5" long')],
    '11510': [(2, '1 unidad mediana', '1 medium')],
    '11508': [(3, '1 unidad mediana', '1 medium (2" dia, 5" long, raw)'),
              (4, '1 unidad pequeña', '1 small'),
              (2, '1 unidad grande', '1 large')],
    '11134': [(2, '1 raíz', '1 root')],
    '11991': [(2, '1 raíz', '1 root')],
}


def descargar(nombre, cache):
    f = FUENTES[nombre]
    ruta = os.path.join(cache, os.path.basename(f['url']))
    if not os.path.exists(ruta):
        print(f'Descargando {f["url"]}', file=sys.stderr)
        with urllib.request.urlopen(f['url'], timeout=300) as r, open(ruta, 'wb') as out:
            out.write(r.read())
    datos = open(ruta, 'rb').read()
    digest = hashlib.sha256(datos).hexdigest()
    if digest != f['sha256']:
        sys.exit(f'ERROR: sha256 de {ruta} = {digest}, se esperaba {f["sha256"]}')
    return datos


def leer_archivos(nombre, datos, archivos):
    prefijo = FUENTES[nombre]['prefijo']
    out = {}
    with tarfile.open(fileobj=io.BytesIO(datos), mode='r:gz') as tar:
        for a in archivos:
            out[a] = tar.extractfile(prefijo + a).read()
    return out


def filas(contenido):
    """Formato ASCII de SR28: campos separados por ^, texto entre ~."""
    for linea in contenido.decode('latin-1').splitlines():
        if linea:
            yield [c.strip('~') for c in linea.split('^')]


def numero(texto):
    d = Decimal(texto)
    if d == d.to_integral_value():
        return int(d)
    return float(d.normalize())


def cargar(cache):
    pypi = leer_archivos('pypi', descargar('pypi', cache),
                         ['FOOD_DES.txt', 'NUT_DATA.txt', 'WEIGHT.txt'])
    npm = leer_archivos('npm', descargar('npm', cache),
                        ['FOOD_DES.txt', 'ABBREV.txt'])

    if pypi['FOOD_DES.txt'] != npm['FOOD_DES.txt']:
        sys.exit('ERROR: FOOD_DES.txt difiere entre las dos copias de SR28')

    desc = {r[0]: r for r in filas(pypi['FOOD_DES.txt'])}
    nut = {}
    for r in filas(pypi['NUT_DATA.txt']):
        if r[1] in NUTRIENTES:
            nut.setdefault(r[0], {})[NUTRIENTES[r[1]]] = r[2]
    pesos = {}
    for r in filas(pypi['WEIGHT.txt']):
        pesos.setdefault(r[0], {})[int(r[1])] = (r[2], r[3], r[4])

    # Verificación cruzada de los 8 nutrientes en TODOS los alimentos.
    comprobados = 0
    for r in filas(npm['ABBREV.txt']):
        ndb = r[0]
        for clave, col in COLUMNAS_ABBREV.items():
            a = r[col]
            b = nut.get(ndb, {}).get(clave)
            if a == '' and b is None:
                continue
            if a == '' or b is None or Decimal(a) != Decimal(b):
                sys.exit(f'ERROR: {ndb} {clave}: ABBREV={a!r} NUT_DATA={b!r}')
            comprobados += 1
    print(f'Verificación cruzada: {comprobados} valores idénticos '
          f'en {len(desc)} alimentos.', file=sys.stderr)
    return desc, nut, pesos


def construir(desc, nut, pesos):
    ndbs = [s[0] for s in SELECCION]
    nombres = [s[1].lower() for s in SELECCION]
    assert len(set(ndbs)) == len(ndbs), 'NDB repetido'
    assert len(set(nombres)) == len(nombres), 'nombre repetido'
    assert set(PORCIONES) <= set(ndbs), set(PORCIONES) - set(ndbs)

    alimentos = []
    for ndb, nombre, categoria in SELECCION:
        d = desc[ndb]
        valores = nut[ndb]
        nutricion = {}
        for clave in ('kcal', 'proteinas', 'grasas', 'grasas_saturadas',
                      'carbohidratos', 'azucares', 'fibra'):
            if clave in valores:
                nutricion[clave] = numero(valores[clave])
        if 'sodio_mg' in valores:
            # Sal = sodio × 2,5 (Reglamento (UE) 1169/2011, anexo I).
            sal = Decimal(valores['sodio_mg']) * Decimal('2.5') / Decimal(1000)
            nutricion['sal'] = float(sal.normalize()) if sal else 0
        for esencial in ('kcal', 'proteinas', 'grasas', 'carbohidratos'):
            assert esencial in nutricion, f'{ndb} sin {esencial}'
        nutricion['origen'] = 'importado'

        faltan = [ETIQUETAS[c] for c in NUTRIENTES.values() if c not in valores]
        notas = (f'Fuente: USDA SR28, NDB {ndb} «{d[2]}». '
                 'Valores por 100 g de parte comestible. Carbohidratos totales '
                 '(por diferencia, incluyen la fibra).')
        if 'sodio_mg' in valores:
            notas += ' Sal = sodio × 2,5.'
        if faltan:
            notas += f' Sin dato en la fuente: {", ".join(faltan)}.'

        porciones = []
        for seq, nombre_es, esperado in PORCIONES.get(ndb, []):
            amount, msre, gm = pesos[ndb][seq]
            real = f'{amount} {msre}'
            if real != esperado:
                sys.exit(f'ERROR: porción {ndb}/{seq}: {real!r} != {esperado!r}')
            porciones.append({'nombre': nombre_es, 'gramos': numero(gm)})
        if porciones:
            notas += ' Porciones: pesos de USDA (parte comestible).'

        a = {
            'uuid': str(uuid.uuid5(uuid.NAMESPACE_URL,
                                   f'cal_counter/usda-sr28/{ndb}')),
            'nombre': nombre,
            'tipo': 'generico',
            'unidad': 'g',
            'categoria': categoria,
            'nutricion': nutricion,
            'notas': notas,
        }
        if porciones:
            a['porciones'] = porciones
        alimentos.append(a)
    return {
        'formato': 'cal_counter/repertorio',
        'version': 1,
        'exportado': '2026-11-24T00:00:00Z',
        'alimentos': alimentos,
    }


def fmt(v):
    if v is None:
        return '—'
    return str(v).replace('.', ',')


def escribir_doc(rep, desc):
    ndb_de = {s[1]: s[0] for s in SELECCION}
    lineas = [
        '# Frutas, verduras y hortalizas (USDA SR28)',
        '',
        '> Archivo generado por `tool/semilla/generar_frutas_verduras.py`. '
        'No editar a mano.',
        '',
        f'`assets/semilla/frutas_verduras_usda.json` contiene '
        f'**{len(rep["alimentos"])} alimentos** en formato '
        '`cal_counter/repertorio` v1. Se carga junto al catálogo base en la '
        'bienvenida y se puede añadir en cualquier momento desde *Datos y '
        'respaldos → Catálogos incluidos → Añadir frutas y verduras* (o '
        'importando el archivo). Importarlo de nuevo no duplica nada: cada '
        'alimento tiene un uuid v5 fijo derivado de su número NDB '
        '(`uuid5(NAMESPACE_URL, "cal_counter/usda-sr28/<NDB>")`).',
        '',
        '## Fuente',
        '',
        'U.S. Department of Agriculture, Agricultural Research Service, '
        'Nutrient Data Laboratory. *USDA National Nutrient Database for '
        'Standard Reference, Release 28* (septiembre de 2015, revisado en '
        'mayo de 2016). Dominio público.',
        '',
        '- **Ningún valor se ha escrito a mano ni estimado.** El script lee '
        'cada nutriente y cada peso de porción de los archivos oficiales por '
        'su número NDB. Si la fuente no publica un dato, el campo queda '
        '**vacío** (nunca 0) y la nota del alimento lo dice («Sin dato en la '
        'fuente: …»).',
        '- Los servidores de USDA no eran accesibles desde el entorno en que '
        'se generó, así que el script usa dos redistribuciones independientes '
        'de los archivos de SR28 (PyPI `django-usda-nutrition` 0.2.0 con los '
        'ASCII completos y npm `fda-nutrient-database` 1.0.2 con ABBREV), con '
        'sha256 fijado, y exige que coincidan: los 67.454 valores de los 8 '
        'nutrientes usados son idénticos en ambas copias para los 8.789 '
        'alimentos de SR28.',
        '- **Cómo contrastar un valor**: buscar el número NDB (o la '
        'descripción en inglés) en [FoodData Central](https://fdc.nal.usda.gov/) '
        '(tipo de datos *SR Legacy*, que es la edición final de SR, de 2018). '
        'Cada alimento lleva en su nota el NDB y la descripción original.',
        '',
        '## Criterios',
        '',
        '- **Valores por 100 g de parte comestible**, unidad `g`.',
        '- **Carbohidratos totales por diferencia: incluyen la fibra** (criterio '
        'de USDA). Las etiquetas de la UE declaran los carbohidratos *sin* la '
        'fibra, así que estos valores son mayores que los de una etiqueta '
        'europea del mismo alimento en la cantidad de fibra. No se ha restado '
        'la fibra para no publicar un número que no está en la fuente.',
        '- **Sal = sodio × 2,5** (Reglamento (UE) 1169/2011, anexo I). Es la '
        'única conversión aplicada; si la fuente no da sodio, la sal queda '
        'vacía.',
        '- Energía: kcal publicadas por USDA. Grasas saturadas, azúcares '
        'totales y fibra dietética total, tal cual.',
        '- **Porciones**: medidas caseras de USDA (`WEIGHT.txt`), solo las de '
        'unidades (pieza, diente, tallo, hoja, mazorca, cucharada…). Los gramos '
        'son de la parte comestible; las pulgadas se han pasado a centímetros '
        '(1" = 2,54 cm) en el nombre. El script comprueba que cada porción '
        'elegida tiene exactamente la descripción esperada en la fuente.',
        '- Categorías: *Frutas y verduras* (frescos) y *Despensa* (conservas, '
        'frutas secas y deshidratados).',
        '',
        '## No incluidos por no estar en la fuente',
        '',
        'SR28 no tiene datos de estos alimentos (o solo en forma de néctar, '
        'almíbar o mezcla), así que no se incluyen: ají dulce, tomate de árbol, '
        'curuba, granadilla dulce, arracacha (apio criollo), mapuey, mamón, '
        'merey (fruto), pitahaya, borojó, mangostino fresco, espárrago blanco '
        'como entrada propia y calabaza Hokkaido. Se pueden añadir a mano con '
        'los datos de una etiqueta o de otra tabla oficial.',
        '',
        '## Lista',
        '',
        '| Alimento | NDB | Descripción USDA | kcal | Prot. | Grasas | Carb. | Fibra | Categoría |',
        '|---|---|---|---:|---:|---:|---:|---:|---|',
    ]
    for a in rep['alimentos']:
        n = a['nutricion']
        ndb = ndb_de[a['nombre']]
        lineas.append(
            f"| {a['nombre']} | {ndb} | {desc[ndb][2]} | {fmt(n.get('kcal'))} "
            f"| {fmt(n.get('proteinas'))} | {fmt(n.get('grasas'))} "
            f"| {fmt(n.get('carbohidratos'))} | {fmt(n.get('fibra'))} "
            f"| {a['categoria']} |")
    with open(DOC, 'w', encoding='utf-8', newline='\n') as f:
        f.write('\n'.join(lineas) + '\n')


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    p.add_argument('--cache', help='carpeta para guardar las descargas')
    args = p.parse_args()
    cache = args.cache or tempfile.mkdtemp(prefix='sr28_')
    os.makedirs(cache, exist_ok=True)
    desc, nut, pesos = cargar(cache)
    rep = construir(desc, nut, pesos)
    with open(SALIDA, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(rep, f, ensure_ascii=False, indent=1)
        f.write('\n')
    escribir_doc(rep, desc)
    print(f'{len(rep["alimentos"])} alimentos → {os.path.relpath(SALIDA, RAIZ)}'
          f' y {os.path.relpath(DOC, RAIZ)}', file=sys.stderr)


if __name__ == '__main__':
    main()
