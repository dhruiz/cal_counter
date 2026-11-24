#!/usr/bin/env python3
"""Genera assets/semilla/frutas_verduras.json desde CIQUAL 2025 y USDA SR Legacy.

Ningún valor nutricional ni peso de porción se escribe a mano: todos se leen
de los archivos oficiales. Este script solo decide QUÉ alimentos entran, CÓMO
se llaman (español / alemán) y de qué fuente sale cada uno.

Fuentes:

  1. CIQUAL 2025 (fuente preferida). "Anses. 2025. Ciqual French food
     composition table", https://doi.org/10.5281/zenodo.17550133, Licence
     Ouverte. Mismo criterio que las etiquetas de la UE: carbohidratos
     disponibles (sin la fibra), proteína bruta (N × 6,25), energía según el
     Reglamento (UE) 1169/2011 y sal publicada directamente.
  2. USDA SR Legacy. U.S. Department of Agriculture, Agricultural Research
     Service. FoodData Central, "SR Legacy" (abril de 2018), la edición final
     de la National Nutrient Database for Standard Reference. Dominio
     público. Carbohidratos totales por diferencia (incluyen la fibra).

Regla: un alimento usa CIQUAL si tiene equivalente (mismo alimento y misma
preparación) y CIQUAL publica una cifra para kcal, proteínas, grasas y
carbohidratos. Si alguno de esos cuatro es "traces", "< x" o falta, el
alimento entero sale de USDA, que sí los publica. Los nutrientes opcionales
sin cifra en la fuente quedan vacíos (nunca 0). Nunca se mezclan fuentes en la
tabla de un mismo alimento; las porciones (pesos de piezas) son de USDA.

Integridad: los archivos se descargan de las fuentes oficiales y se
comprueban con un sha256 fijado: CIQUAL de Zenodo (ANSES, que además publica
su md5) y SR Legacy de FoodData Central (USDA).

Uso:
    python3 tool/semilla/generar_frutas_verduras.py [--cache DIR]
"""

import argparse
import csv
import hashlib
import io
import json
import os
import re
import sys
import tempfile
import urllib.parse
import urllib.request
import uuid
import xml.etree.ElementTree as ET
import zipfile
from decimal import Decimal

RAIZ = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SALIDA = os.path.join(RAIZ, 'assets', 'semilla', 'frutas_verduras.json')
DOC = os.path.join(RAIZ, 'docs', 'FRUTAS_VERDURAS.md')

USDA_URL = ('https://fdc.nal.usda.gov/fdc-datasets/'
            'FoodData_Central_sr_legacy_food_csv_2018-04.zip')
USDA_SHA256 = 'b80817294b8850530aaedf2e515c02593b1824f763a0ff356e5c2081643e6fd0'
USDA_PREFIJO = 'FoodData_Central_sr_legacy_food_csv_2018-04/'

CIQUAL_DOI = '10.5281/zenodo.17550133'
CIQUAL_URL = 'https://zenodo.org/api/records/17550133/files/{}/content'
CIQUAL_ARCHIVOS = {
    'alim_2025_11_03.xml': (
        '8e1171d63cee4b6010cfce25dd29243d',
        'e0b1de25b3039028205e9d54a96892e403e1b313c2efeb41180fabe132627478'),
    'compo_2025_11_03.xml': (
        '2da725585946434df320d8041631998b',
        '8c46a9032ece4eab4ffccc9dfcb0c490ec2f416aa664cc1ee013b241c6bdd4af'),
    'const_2025_11_03.xml': (
        'd8f2f25fdacb887bc993a6eeaf80f203',
        '3a231ea3e9836e4ac0b6ff94511e010210b2523d1b8b486c6b29e211066ba3f3'),
}

# Componentes de CIQUAL → clave del repertorio, con el nombre inglés que debe
# tener cada código en const_2025_11_03.xml (se comprueba).
CIQUAL_COMPONENTES = {
    '328': ('kcal', 'Energy, Regulation EU No 1169/2011 (kcal/100g)'),
    '25003': ('proteinas', 'Protein, crude, N x 6.25 (g/100g)'),
    '40000': ('grasas', 'Fat (g/100g)'),
    '40302': ('grasas_saturadas', 'FA saturated (g/100g)'),
    '31000': ('carbohidratos', 'Carbohydrate (g/100g)'),
    '32000': ('azucares', 'Sugars (g/100g)'),
    '34100': ('fibra', 'Fibres (g/100g)'),
    '10004': ('sal', 'Salt (g/100g)'),
}

# Identificadores de nutriente de FoodData Central (nutrient.csv) → clave.
NUTRIENTES = {
    '1008': 'kcal',              # Energy (KCAL)
    '1003': 'proteinas',         # Protein
    '1004': 'grasas',            # Total lipid (fat)
    '1258': 'grasas_saturadas',  # Fatty acids, total saturated
    '1005': 'carbohidratos',     # Carbohydrate, by difference
    '2000': 'azucares',          # Sugars, Total
    '1079': 'fibra',             # Fiber, total dietary
    '1093': 'sodio_mg',          # Sodium, Na (MG)
}

ESENCIALES = ('kcal', 'proteinas', 'grasas', 'carbohidratos')
ORDEN = ('kcal', 'proteinas', 'grasas', 'grasas_saturadas', 'carbohidratos',
         'azucares', 'fibra', 'sal')
ETIQUETAS = {
    'kcal': 'kcal', 'proteinas': 'proteínas', 'grasas': 'grasas',
    'grasas_saturadas': 'grasas saturadas', 'carbohidratos': 'carbohidratos',
    'azucares': 'azúcares', 'fibra': 'fibra', 'sodio_mg': 'sodio (sal)',
    'sal': 'sal',
}

FV = 'Frutas y verduras'
DESP = 'Despensa'

# (NDB, nombre en español, nombre en alemán, categoría). El nombre que ve la
# app es "español / alemán" para poder buscar en los dos idiomas. Los valores
# salen de la fuente.
SELECCION = [
    # ── Frutas frescas comunes ──────────────────────────────────────────
    ('09003', 'Manzana con piel, cruda', 'Apfel mit Schale, roh', FV),
    ('09004', 'Manzana sin piel, cruda', 'Apfel ohne Schale, roh', FV),
    ('09252', 'Pera, cruda', 'Birne, roh', FV),
    ('09040', 'Cambur (banano, banana), crudo', 'Banane, roh', FV),
    ('09200', 'Naranja, cruda', 'Orange (Apfelsine), roh', FV),
    ('09206', 'Jugo de naranja natural (recién exprimido)', 'Orangensaft, frisch gepresst', FV),
    ('09218', 'Mandarina, cruda', 'Mandarine, roh', FV),
    ('09433', 'Clementina, cruda', 'Clementine, roh', FV),
    ('09111', 'Toronja (pomelo), cruda', 'Grapefruit, roh', FV),
    ('09150', 'Limón amarillo, sin cáscara, crudo', 'Zitrone, ohne Schale, roh', FV),
    ('09152', 'Jugo de limón amarillo, natural', 'Zitronensaft, frisch gepresst', FV),
    ('09159', 'Lima ácida (limón verde), cruda', 'Limette, roh', FV),
    ('09160', 'Jugo de lima ácida (limón verde), natural', 'Limettensaft, frisch gepresst', FV),
    ('09132', 'Uvas rojas o verdes (tipo europeo), crudas', 'Weintrauben, rot oder grün, roh', FV),
    ('09316', 'Fresas (frutillas), crudas', 'Erdbeeren, roh', FV),
    ('09050', 'Arándanos, crudos', 'Heidelbeeren (Blaubeeren), roh', FV),
    ('09302', 'Frambuesas, crudas', 'Himbeeren, roh', FV),
    ('09042', 'Moras (zarzamoras), crudas', 'Brombeeren, roh', FV),
    ('09084', 'Grosellas rojas y blancas, crudas', 'Rote und weiße Johannisbeeren, roh', FV),
    ('09083', 'Grosellas negras (casis), crudas', 'Schwarze Johannisbeeren, roh', FV),
    ('09107', 'Grosellas espinosas (uva espina), crudas', 'Stachelbeeren, roh', FV),
    ('09070', 'Cerezas dulces, crudas', 'Süßkirschen, roh', FV),
    ('09063', 'Guindas (cerezas ácidas), crudas', 'Sauerkirschen, roh', FV),
    ('09279', 'Ciruelas, crudas', 'Pflaumen, roh', FV),
    ('09021', 'Albaricoques (damascos), crudos', 'Aprikosen, roh', FV),
    ('09236', 'Durazno amarillo (melocotón), crudo', 'Gelber Pfirsich, roh', FV),
    ('09191', 'Nectarina, cruda', 'Nektarine, roh', FV),
    ('09089', 'Higos, crudos', 'Feigen, roh', FV),
    ('09286', 'Granada, cruda', 'Granatapfel, roh', FV),
    ('09263', 'Caqui (kaki, persimón), crudo', 'Kaki (Persimone), roh', FV),
    ('09296', 'Membrillo, crudo', 'Quitte, roh', FV),
    ('09148', 'Kiwi verde, crudo', 'Grüne Kiwi, roh', FV),
    ('09307', 'Ruibarbo, crudo', 'Rhabarber, roh', FV),
    ('09326', 'Patilla (sandía), cruda', 'Wassermelone, roh', FV),
    ('09181', 'Melón cantalupo, crudo', 'Cantaloupe-Melone, roh', FV),
    ('09184', 'Melón verde (honeydew), crudo', 'Honigmelone, roh', FV),
    ('09266', 'Piña (ananá), cruda', 'Ananas, roh', FV),
    ('09176', 'Mango, crudo', 'Mango, roh', FV),
    ('09226', 'Lechoza (papaya), cruda', 'Papaya, roh', FV),
    ('09037', 'Aguacate (palta), crudo, promedio de variedades comerciales', 'Avocado, roh, Durchschnitt der Handelssorten', FV),
    ('09038', 'Aguacate de California (palta), crudo', 'Avocado aus Kalifornien, roh', FV),
    ('09039', 'Aguacate de Florida (palta), crudo', 'Avocado aus Florida, roh', FV),
    ('12104', 'Coco, pulpa cruda', 'Kokosnuss, Fruchtfleisch, roh', FV),
    ('12119', 'Agua de coco', 'Kokoswasser', FV),

    # ── Frutas latinoamericanas ─────────────────────────────────────────
    ('09139', 'Guayaba, cruda', 'Guave, roh', FV),
    ('09315', 'Guanábana, cruda', 'Stachelannone (Guanábana), roh', FV),
    ('09062', 'Chirimoya, cruda', 'Cherimoya, roh', FV),
    ('09321', 'Anón (saramuyo), crudo', 'Zimtapfel, roh', FV),
    ('09231', 'Maracuyá morado (gulupa, parchita morada), crudo', 'Violette Passionsfrucht, roh', FV),
    ('09233', 'Jugo de maracuyá amarillo (parchita), natural', 'Saft der gelben Maracuja, frisch', FV),
    ('09175', 'Mamey, crudo', 'Mammiapfel (Mamey), roh', FV),
    ('09314', 'Zapote (mamey colorado), crudo', 'Mamey-Sapote, roh', FV),
    ('09313', 'Níspero (sapodilla, zapote chico), crudo', 'Sapotille (Breiapfel), roh', FV),
    ('09174', 'Níspero del Japón (níspero de España), crudo', 'Japanische Wollmispel (Loquat), roh', FV),
    ('09322', 'Tamarindo, crudo', 'Tamarinde, roh', FV),
    ('09138', 'Uchuva (aguaymanto, physalis), cruda', 'Physalis (Kapstachelbeere), roh', FV),
    ('09450', 'Lulo (naranjilla), pulpa congelada sin azúcar', 'Lulo (Naranjilla), Fruchtmark, tiefgekühlt, ungesüßt', FV),
    ('09060', 'Carambola (fruta estrella), cruda', 'Karambole (Sternfrucht), roh', FV),
    ('09001', 'Semeruco (acerola), crudo', 'Acerola, roh', FV),
    ('09312', 'Pomarrosa, cruda', 'Rosenapfel, roh', FV),
    ('09334', 'Feijoa, cruda', 'Feijoa (Ananasguave), roh', FV),
    ('09449', 'Nance (chaparro manteco), congelado sin azúcar', 'Nance, tiefgekühlt, ungesüßt', FV),
    ('09287', 'Tuna (higo chumbo), cruda', 'Kaktusfeige, roh', FV),
    ('09277', 'Plátano macho (plátano para cocinar), crudo', 'Kochbanane, roh', FV),
    ('09278', 'Plátano macho, cocido', 'Kochbanane, gekocht', FV),
    ('09446', 'Tostones o patacones (plátano verde frito)', 'Frittierte grüne Kochbanane (Tostones)', FV),
    ('09447', 'Plátano maduro frito (tajadas), de restaurante latino', 'Frittierte reife Kochbanane (Latino-Restaurant)', FV),

    # ── Frutas secas y conservas ────────────────────────────────────────
    ('09298', 'Uvas pasas sin semillas', 'Rosinen, kernlos', DESP),
    ('09291', 'Ciruelas pasas (secas)', 'Trockenpflaumen', DESP),
    ('09032', 'Orejones de albaricoque (secos)', 'Getrocknete Aprikosen', DESP),
    ('09094', 'Higos secos', 'Getrocknete Feigen', DESP),
    ('09087', 'Dátiles Deglet Noor', 'Datteln, Deglet Noor', DESP),
    ('09421', 'Dátiles Medjool', 'Datteln, Medjool', DESP),
    ('09079', 'Arándanos rojos deshidratados, endulzados', 'Cranberries, getrocknet, gesüßt', DESP),
    ('09178', 'Mango deshidratado, endulzado', 'Mango, getrocknet, gesüßt', DESP),
    ('09193', 'Aceitunas negras maduras, en lata', 'Schwarze Oliven, reif, aus der Dose', DESP),
    ('09195', 'Aceitunas verdes, encurtidas, en conserva', 'Grüne Oliven, eingelegt', DESP),
    ('02054', 'Alcaparras, en conserva', 'Kapern, eingelegt', DESP),

    # ── Tomate, cebollas y aromáticos ───────────────────────────────────
    ('11529', 'Tomate rojo maduro, crudo', 'Tomate, rot, reif, roh', FV),
    ('11531', 'Tomate en lata, en su jugo', 'Tomaten aus der Dose, in Tomatensaft', DESP),
    ('11693', 'Tomate triturado, en lata', 'Tomaten, zerkleinert, aus der Dose', DESP),
    ('11546', 'Pasta de tomate (concentrado), sin sal añadida', 'Tomatenmark, ohne Salzzusatz', DESP),
    ('11547', 'Puré de tomate en lata, sin sal añadida', 'Tomatenpüree aus der Dose, ohne Salzzusatz', DESP),
    ('11955', 'Tomates secos (deshidratados)', 'Getrocknete Tomaten', DESP),
    ('11956', 'Tomates secos en aceite, escurridos', 'Getrocknete Tomaten in Öl, abgetropft', DESP),
    ('11282', 'Cebolla, cruda', 'Zwiebel, roh', FV),
    ('11283', 'Cebolla, cocida (hervida, sin sal)', 'Zwiebel, gekocht, ohne Salz', FV),
    ('11677', 'Chalota, cruda', 'Schalotte, roh', FV),
    ('11291', 'Cebollín (cebolla larga, cebolleta), crudo', 'Frühlingszwiebel, roh', FV),
    ('11156', 'Cebollino (ciboulette), crudo', 'Schnittlauch, roh', FV),
    ('11246', 'Ajoporro (puerro), crudo', 'Lauch (Porree), roh', FV),
    ('11247', 'Ajoporro (puerro), cocido (hervido, sin sal)', 'Lauch (Porree), gekocht, ohne Salz', FV),
    ('11215', 'Ajo, crudo', 'Knoblauch, roh', FV),
    ('11216', 'Jengibre, raíz cruda', 'Ingwer, roh', FV),

    # ── Hortalizas de fruto ─────────────────────────────────────────────
    ('11205', 'Pepino con piel, crudo', 'Gurke mit Schale, roh', FV),
    ('11206', 'Pepino pelado, crudo', 'Gurke, geschält, roh', FV),
    ('11937', 'Pepinillos encurtidos al eneldo', 'Dillgurken, eingelegt', DESP),
    ('11477', 'Calabacín (zucchini), crudo', 'Zucchini, roh', FV),
    ('11478', 'Calabacín (zucchini), cocido (hervido, sin sal)', 'Zucchini, gekocht, ohne Salz', FV),
    ('11209', 'Berenjena, cruda', 'Aubergine, roh', FV),
    ('11210', 'Berenjena, cocida (hervida, sin sal)', 'Aubergine, gekocht, ohne Salz', FV),
    ('11333', 'Pimentón verde (pimiento verde), crudo', 'Grüne Paprika, roh', FV),
    ('11821', 'Pimentón rojo (pimiento rojo), crudo', 'Rote Paprika, roh', FV),
    ('11951', 'Pimentón amarillo (pimiento amarillo), crudo', 'Gelbe Paprika, roh', FV),
    ('11670', 'Ají picante verde (chile verde), crudo', 'Grüne Chili, roh', FV),
    ('11819', 'Ají picante rojo (chile rojo), crudo', 'Rote Chili, roh', FV),
    ('11979', 'Jalapeño, crudo', 'Jalapeño, roh', FV),
    ('11278', 'Quimbombó (okra), crudo', 'Okra, roh', FV),
    ('11279', 'Quimbombó (okra), cocido (hervido, sin sal)', 'Okra, gekocht, ohne Salz', FV),
    ('11422', 'Auyama (ahuyama, calabaza), cruda', 'Kürbis, roh', FV),
    ('11423', 'Auyama (ahuyama, calabaza), cocida (hervida, sin sal)', 'Kürbis, gekocht, ohne Salz', FV),
    ('11485', 'Calabaza butternut, cruda', 'Butternutkürbis, roh', FV),
    ('11486', 'Calabaza butternut, horneada (sin sal)', 'Butternutkürbis, gebacken, ohne Salz', FV),
    ('11149', 'Chayota (chayote, guatila, cidra), cruda', 'Chayote, roh', FV),
    ('11150', 'Chayota (chayote), cocida (hervida, sin sal)', 'Chayote, gekocht, ohne Salz', FV),

    # ── Legumbres frescas y maíz tierno ─────────────────────────────────
    ('11052', 'Vainitas (judías verdes, habichuelas), crudas', 'Grüne Bohnen, roh', FV),
    ('11053', 'Vainitas (judías verdes), cocidas (hervidas, sin sal)', 'Grüne Bohnen, gekocht, ohne Salz', FV),
    ('11304', 'Arvejas (guisantes), crudas', 'Grüne Erbsen, roh', FV),
    ('11305', 'Arvejas (guisantes), cocidas (hervidas, sin sal)', 'Grüne Erbsen, gekocht, ohne Salz', FV),
    ('11300', 'Arvejas chinas (tirabeques), crudas', 'Zuckerschoten, roh', FV),
    ('11088', 'Habas tiernas, crudas', 'Dicke Bohnen, frisch, roh', FV),
    ('11089', 'Habas tiernas, cocidas (hervidas, sin sal)', 'Dicke Bohnen, frisch, gekocht, ohne Salz', FV),
    ('11344', 'Quinchoncho tierno (guandú), crudo', 'Straucherbsen (Taubenerbsen), frisch, roh', FV),
    ('11345', 'Quinchoncho tierno (guandú), cocido (hervido, sin sal)', 'Straucherbsen (Taubenerbsen), frisch, gekocht, ohne Salz', FV),
    ('11191', 'Frijol tierno (caupí, ojo negro), crudo', 'Augenbohnen, frisch, roh', FV),
    ('11192', 'Frijol tierno (caupí, ojo negro), cocido (hervido, sin sal)', 'Augenbohnen, frisch, gekocht, ohne Salz', FV),
    ('11167', 'Jojoto amarillo (maíz tierno, mazorca), crudo', 'Gelber Zuckermais, roh', FV),
    ('11168', 'Jojoto amarillo (maíz tierno), cocido (hervido, sin sal)', 'Gelber Zuckermais, gekocht, ohne Salz', FV),
    ('11900', 'Jojoto blanco (maíz tierno, mazorca), crudo', 'Weißer Zuckermais, roh', FV),
    ('11901', 'Jojoto blanco (maíz tierno), cocido (hervido, sin sal)', 'Weißer Zuckermais, gekocht, ohne Salz', FV),
    ('11172', 'Maíz dulce en lata, escurrido', 'Zuckermais aus der Dose, abgetropft', DESP),

    # ── Coles y crucíferas ──────────────────────────────────────────────
    ('11090', 'Brócoli, crudo', 'Brokkoli, roh', FV),
    ('11091', 'Brócoli, cocido (hervido, sin sal)', 'Brokkoli, gekocht, ohne Salz', FV),
    ('11135', 'Coliflor, cruda', 'Blumenkohl, roh', FV),
    ('11136', 'Coliflor, cocida (hervida, sin sal)', 'Blumenkohl, gekocht, ohne Salz', FV),
    ('11098', 'Repollitos de Bruselas, crudos', 'Rosenkohl, roh', FV),
    ('11099', 'Repollitos de Bruselas, cocidos (hervidos, sin sal)', 'Rosenkohl, gekocht, ohne Salz', FV),
    ('11109', 'Repollo blanco (col), crudo', 'Weißkohl, roh', FV),
    ('11110', 'Repollo blanco (col), cocido (hervido, sin sal)', 'Weißkohl, gekocht, ohne Salz', FV),
    ('11112', 'Repollo morado (lombarda), crudo', 'Rotkohl, roh', FV),
    ('11113', 'Repollo morado (lombarda), cocido (hervido, sin sal)', 'Rotkohl, gekocht, ohne Salz', FV),
    ('11114', 'Col de Milán (repollo crespo), cruda', 'Wirsing, roh', FV),
    ('11115', 'Col de Milán, cocida (hervida, sin sal)', 'Wirsing, gekocht, ohne Salz', FV),
    ('11233', 'Col rizada (kale), cruda', 'Grünkohl, roh', FV),
    ('11234', 'Col rizada (kale), cocida (hervida, sin sal)', 'Grünkohl, gekocht, ohne Salz', FV),
    ('11119', 'Col china (repollo chino), cruda', 'Chinakohl, roh', FV),
    ('11116', 'Pak choi (bok choy), crudo', 'Pak Choi, roh', FV),
    ('11241', 'Colinabo, crudo', 'Kohlrabi, roh', FV),
    ('11242', 'Colinabo, cocido (hervido, sin sal)', 'Kohlrabi, gekocht, ohne Salz', FV),
    ('11439', 'Chucrut, en conserva', 'Sauerkraut, aus der Dose', DESP),

    # ── Raíces, bulbos y tallos ─────────────────────────────────────────
    ('11124', 'Zanahoria, cruda', 'Karotte (Möhre), roh', FV),
    ('11125', 'Zanahoria, cocida (hervida, sin sal)', 'Karotte (Möhre), gekocht, ohne Salz', FV),
    ('11080', 'Remolacha (betabel), cruda', 'Rote Bete, roh', FV),
    ('11081', 'Remolacha (betabel), cocida (hervida)', 'Rote Bete, gekocht', FV),
    ('11435', 'Nabo sueco (rutabaga), crudo', 'Steckrübe, roh', FV),
    ('11436', 'Nabo sueco (rutabaga), cocido (hervido, sin sal)', 'Steckrübe, gekocht, ohne Salz', FV),
    ('11564', 'Nabo, crudo', 'Weiße Rübe (Speiserübe), roh', FV),
    ('11565', 'Nabo, cocido (hervido, sin sal)', 'Weiße Rübe (Speiserübe), gekocht, ohne Salz', FV),
    ('11298', 'Chirivía (pastinaca), cruda', 'Pastinake, roh', FV),
    ('11299', 'Chirivía (pastinaca), cocida (hervida, sin sal)', 'Pastinake, gekocht, ohne Salz', FV),
    ('11141', 'Apionabo, crudo', 'Knollensellerie, roh', FV),
    ('11142', 'Apionabo, cocido (hervido, sin sal)', 'Knollensellerie, gekocht, ohne Salz', FV),
    ('11143', 'Apio España (apio de tallo), crudo', 'Staudensellerie, roh', FV),
    ('11429', 'Rábano (rabanito), crudo', 'Radieschen, roh', FV),
    ('11430', 'Rábano blanco (daikon), crudo', 'Rettich (Daikon), roh', FV),
    ('11226', 'Tupinambo, crudo', 'Topinambur, roh', FV),
    ('11957', 'Hinojo (bulbo), crudo', 'Fenchel (Knolle), roh', FV),
    ('11007', 'Alcachofa, cruda', 'Artischocke, roh', FV),
    ('11008', 'Alcachofa, cocida (hervida, sin sal)', 'Artischocke, gekocht, ohne Salz', FV),
    ('11011', 'Espárragos, crudos', 'Spargel, roh', FV),
    ('11012', 'Espárragos, cocidos (hervidos)', 'Spargel, gekocht', FV),
    ('11015', 'Espárragos en lata, escurridos', 'Spargel aus der Dose, abgetropft', DESP),
    ('11961', 'Palmito en lata', 'Palmherzen aus der Dose', DESP),
    ('11975', 'Hojas de parra en conserva', 'Weinblätter, eingelegt', DESP),
    ('11963', 'Nopal, crudo', 'Nopal (Kaktusblatt), roh', FV),
    ('11964', 'Nopal, cocido (sin sal)', 'Nopal (Kaktusblatt), gekocht, ohne Salz', FV),

    # ── Hojas verdes y ensalada ─────────────────────────────────────────
    ('11457', 'Espinaca, cruda', 'Spinat, roh', FV),
    ('11458', 'Espinaca, cocida (hervida, sin sal)', 'Spinat, gekocht, ohne Salz', FV),
    ('11147', 'Acelga, cruda', 'Mangold, roh', FV),
    ('11148', 'Acelga, cocida (hervida, sin sal)', 'Mangold, gekocht, ohne Salz', FV),
    ('11252', 'Lechuga iceberg (americana), cruda', 'Eisbergsalat, roh', FV),
    ('11251', 'Lechuga romana, cruda', 'Römersalat, roh', FV),
    ('11250', 'Lechuga mantecosa, cruda', 'Kopfsalat, roh', FV),
    ('11253', 'Lechuga de hoja verde, cruda', 'Grüner Blattsalat, roh', FV),
    ('11257', 'Lechuga de hoja roja, cruda', 'Roter Blattsalat, roh', FV),
    ('11959', 'Rúcula (rúgula), cruda', 'Rucola, roh', FV),
    ('11190', 'Canónigos, crudos', 'Feldsalat, roh', FV),
    ('11213', 'Escarola, cruda', 'Endivie, roh', FV),
    ('11151', 'Endibia belga, cruda', 'Chicorée, roh', FV),
    ('11952', 'Radicchio (achicoria roja), crudo', 'Radicchio, roh', FV),
    ('11591', 'Berro, crudo', 'Brunnenkresse, roh', FV),
    ('11203', 'Mastuerzo (berro de jardín), crudo', 'Gartenkresse, roh', FV),
    ('11043', 'Germinados de frijol mungo (brotes de soja), crudos', 'Mungobohnensprossen (Sojasprossen), roh', FV),

    # ── Hierbas frescas ─────────────────────────────────────────────────
    ('11165', 'Cilantro (hojas), crudo', 'Koriander (Blätter), frisch', FV),
    ('11297', 'Perejil, fresco', 'Petersilie, frisch', FV),
    ('02044', 'Albahaca, fresca', 'Basilikum, frisch', FV),
    ('02045', 'Eneldo, fresco', 'Dill, frisch', FV),
    ('02065', 'Hierbabuena, fresca', 'Grüne Minze, frisch', FV),
    ('02064', 'Menta piperita, fresca', 'Pfefferminze, frisch', FV),
    ('02049', 'Tomillo, fresco', 'Thymian, frisch', FV),
    ('02063', 'Romero, fresco', 'Rosmarin, frisch', FV),

    # ── Setas ───────────────────────────────────────────────────────────
    ('11260', 'Champiñones blancos, crudos', 'Weiße Champignons, roh', FV),
    ('11261', 'Champiñones blancos, cocidos (hervidos, sin sal)', 'Weiße Champignons, gekocht, ohne Salz', FV),
    ('11264', 'Champiñones en lata, escurridos', 'Champignons aus der Dose, abgetropft', DESP),
    ('11266', 'Champiñones marrones (crimini), crudos', 'Braune Champignons, roh', FV),
    ('11265', 'Portobello, crudo', 'Portobello (Riesenchampignon), roh', FV),
    ('11238', 'Shiitake, crudo', 'Shiitake, roh', FV),
    ('11987', 'Setas de ostra (gírgolas), crudas', 'Austernpilze, roh', FV),
    ('11239', 'Rebozuelos, crudos', 'Pfifferlinge, roh', FV),

    # ── Raíces y tubérculos ─────────────────────────────────────────────
    ('11352', 'Papa (patata) con piel, cruda', 'Kartoffel mit Schale, roh', FV),
    ('11367', 'Papa (patata) pelada, hervida sin sal', 'Kartoffel, geschält, gekocht, ohne Salz', FV),
    ('11365', 'Papa (patata) hervida con piel, solo pulpa, sin sal', 'Pellkartoffel, nur Fruchtfleisch, ohne Salz', FV),
    ('11674', 'Papa (patata) asada al horno, con piel, sin sal', 'Ofenkartoffel mit Schale, ohne Salz', FV),
    ('11507', 'Batata (boniato, camote), cruda', 'Süßkartoffel, roh', FV),
    ('11510', 'Batata (boniato, camote), hervida sin piel', 'Süßkartoffel, gekocht, ohne Schale', FV),
    ('11508', 'Batata (boniato, camote), asada al horno, pulpa, sin sal', 'Süßkartoffel, im Ofen gebacken, Fruchtfleisch, ohne Salz', FV),
    ('11134', 'Yuca (mandioca), cruda', 'Maniok (Cassava), roh', FV),
    ('11601', 'Ñame, crudo', 'Yamswurzel, roh', FV),
    ('11602', 'Ñame, cocido (hervido u horneado, sin sal)', 'Yamswurzel, gekocht oder gebacken, ohne Salz', FV),
    ('11991', 'Ocumo (yautía, malanga), crudo', 'Tannia (Malanga), roh', FV),
    ('11518', 'Ocumo chino (taro), crudo', 'Taro, roh', FV),
    ('11519', 'Ocumo chino (taro), cocido (sin sal)', 'Taro, gekocht, ohne Salz', FV),
]

# Porciones tomadas de food_portion.csv de SR Legacy: NDB → [(seq_num, nombre
# en español, "cantidad modificador" esperados en la fuente)]. El generador comprueba que la medida con ese
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
    '09111': [(3, '½ unidad mediana', '0.5 medium (approx 4" dia)'),
              (4, '½ unidad pequeña', '0.5 small (approx 3-1/2" dia)'),
              (2, '½ unidad grande', '0.5 large (approx 4-1/2" dia)')],
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
    '09277': [(1, '1 unidad', '1 plantain')],
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


# Equivalencias USDA → CIQUAL 2025: NDB → código CIQUAL, o (código, nombre en
# español, nombre en alemán) cuando la descripción de CIQUAL difiere de la de
# USDA (otra preparación, con o sin piel...). Se usa CIQUAL solo si publica
# cifra para los cuatro nutrientes esenciales; si no, se queda el de USDA.
MAPA_CIQUAL = {
    # Frutas
    '09003': '13039',
    '09004': '13396',
    '09252': ('13037', 'Pera con piel, cruda', 'Birne mit Schale, roh'),
    '09040': '13005',
    '09200': '13034',
    '09206': '2013',
    '09218': '13024',
    '09111': '13040',
    '09150': '13009',
    '09152': ('2007', 'Jugo de limón amarillo, hecho en casa', 'Zitronensaft, selbst gepresst'),
    '09159': '13067',
    '09160': '2030',
    '09132': ('13395', 'Uvas, crudas (promedio)', 'Weintrauben, roh (Durchschnitt)'),
    '09316': '13014',
    '09050': '13028',
    '09302': '13015',
    '09042': '13029',
    '09084': ('13019', 'Grosellas rojas, crudas', 'Rote Johannisbeeren, roh'),
    '09083': '13007',
    '09107': '13020',
    '09070': '13008',
    '09063': '13110',
    '09279': '13100',
    '09021': '13000',
    '09236': ('13043', 'Durazno (melocotón) con piel, crudo', 'Pfirsich mit Schale, roh'),
    '09191': '13399',
    '09089': '13012',
    '09286': ('13018', 'Granada, granos con semillas, cruda', 'Granatapfelkerne, roh'),
    '09263': '13066',
    '09296': '13010',
    '09148': ('13021', 'Kiwi, crudo', 'Kiwi, roh'),
    '09307': ('13047', 'Ruibarbo (tallo), crudo', 'Rhabarber (Stiel), roh'),
    '09326': '13036',
    '09181': '13026',
    '09184': '13742',
    '09266': '13002',
    '09176': '13025',
    '09226': '13035',
    '09037': '13004',
    '12104': ('15006', 'Coco, pulpa fresca', 'Kokosnuss, Fruchtfleisch, frisch'),
    '12119': '18011',
    '09139': ('13083', 'Guayaba sin piel, cruda', 'Guave ohne Schale, roh'),
    '09062': '13056',
    '09321': '13435',
    '09231': ('13016', 'Maracuyá (parchita), pulpa con semillas, cruda',
              'Passionsfrucht (Maracuja), Fruchtfleisch mit Kernen, roh'),
    '09233': ('2024', 'Jugo de maracuyá (parchita), natural', 'Maracujasaft, frisch'),
    '09175': '13401',
    '09174': '13564',
    '09322': '13080',
    '09060': '13054',
    '09001': '13055',
    '09334': '13061',
    '09287': '13063',
    '09277': '53100',
    '09278': '53101',
    # Frutas secas y conservas
    '09298': ('13046', 'Uvas pasas', 'Rosinen'),
    '09291': '13042',
    '09032': '13001',
    '09094': '13013',
    '09087': ('13011', 'Dátiles secos, sin hueso', 'Datteln, getrocknet, entsteint'),
    '09079': '13178',
    '09193': '13032',
    '09195': ('13033', 'Aceitunas verdes en salmuera, escurridas',
              'Grüne Oliven in Salzlake, abgetropft'),
    '02054': '11040',
    # Tomate, cebollas y aromáticos
    '11529': '20385',
    '11531': ('20137', 'Tomate pelado en lata, en su jugo',
              'Geschälte Tomaten aus der Dose, im eigenen Saft'),
    '11693': '20169',
    '11546': ('20068', 'Concentrado de tomate (pasta de tomate), en lata', 'Tomatenmark'),
    '11547': ('20170', 'Puré de tomate, en lata', 'Tomatenpüree aus der Dose'),
    '11955': '20189',
    '11956': '20256',
    '11282': '20034',
    '11283': ('20035', 'Cebolla, cocida', 'Zwiebel, gekocht'),
    '11677': '20097',
    '11246': '20039',
    '11247': '20327',
    '11215': '11000',
    '11216': ('11074', 'Jengibre, raíz fresca', 'Ingwer, frisch'),
    # Hortalizas de fruto
    '11205': '20019',
    '11206': '20210',
    '11477': '20020',
    '11478': ('20021', 'Calabacín (zucchini), cocido', 'Zucchini, gekocht'),
    '11209': '20053',
    '11210': ('20002', 'Berenjena, cocida', 'Aubergine, gekocht'),
    '11333': '20085',
    '11821': '20087',
    '11951': '20168',
    '11278': '58100',
    '11279': ('58103', 'Quimbombó (okra), cocido', 'Okra, gekocht'),
    '11422': ('20128', 'Auyama (calabaza moscada), cruda', 'Moschuskürbis, roh'),
    '11423': '20292',
    '11485': '20138',
    '11486': ('20141', 'Calabaza butternut, hervida', 'Butternutkürbis, gekocht'),
    '11149': '13128',
    '11150': ('13177', 'Chayota (chayote), hervida', 'Chayote, gekocht'),
    # Legumbres frescas y maíz tierno
    '11052': '20061',
    '11053': '20320',
    '11304': '20072',
    '11305': ('20326', 'Arvejas (guisantes), hervidas', 'Grüne Erbsen, gekocht'),
    '11300': '20173',
    '11088': ('20517', 'Habas frescas (para desgranar), crudas', 'Dicke Bohnen, frisch, roh'),
    '11344': '20527',
    '11345': '20833',
    '11168': ('20049', 'Jojoto (maíz dulce en mazorca), cocido',
              'Zuckermais (Maiskolben), gekocht'),
    '11172': '20066',
    # Coles y crucíferas
    '11090': '20057',
    '11091': ('20350', 'Brócoli, hervido', 'Brokkoli, gekocht'),
    '11135': '20016',
    '11136': ('20017', 'Coliflor, hervida', 'Blumenkohl, gekocht'),
    '11098': '20058',
    '11099': '20309',
    '11109': '20116',
    '11110': '20308',
    '11112': '20014',
    '11113': ('20095', 'Repollo morado (lombarda), hervido', 'Rotkohl, gekocht'),
    '11233': '20218',
    '11234': ('20219', 'Col rizada (kale), cocida', 'Grünkohl, gekocht'),
    '11119': '20167',
    '11116': '20340',
    '11241': '20065',
    '11242': ('20094', 'Colinabo, hervido', 'Kohlrabi, gekocht'),
    # Raíces, bulbos y tallos
    '11124': '20009',
    '11125': '20352',
    '11080': '20091',
    '11081': ('20003', 'Remolacha (betabel), cocida', 'Rote Bete, gekocht'),
    '11435': '20201',
    '11436': ('20165', 'Nabo sueco (rutabaga), cocido', 'Steckrübe, gekocht'),
    '11564': ('20064', 'Nabo, pelado, crudo', 'Weiße Rübe (Speiserübe), geschält, roh'),
    '11565': '20321',
    '11298': '20181',
    '11141': '20055',
    '11142': ('20315', 'Apionabo, hervido', 'Knollensellerie, gekocht'),
    '11143': '20023',
    '11429': '20045',
    '11226': '20196',
    '11957': '20028',
    '11007': '20052',
    '11008': ('20000', 'Alcachofa, cocida', 'Artischocke, gekocht'),
    '11011': ('20279', 'Espárrago verde, crudo', 'Grüner Spargel, roh'),
    '11012': ('20299', 'Espárrago verde, hervido', 'Grüner Spargel, gekocht'),
    '11015': '20076',
    '11961': ('20018', 'Palmito en lata, escurrido', 'Palmherzen aus der Dose, abgetropft'),
    # Hojas verdes y ensalada
    '11457': '20059',
    '11458': '20336',
    '11148': ('20301', 'Acelga (hoja y penca), hervida', 'Mangold, gekocht'),
    '11252': '20200',
    '11251': '20171',
    '11250': ('20031', 'Lechuga, cruda', 'Kopfsalat, roh'),
    '11959': '20217',
    '11190': '20099',
    '11213': ('20090', 'Escarola, cruda', 'Endivie (Escariol), roh'),
    '11151': '20026',
    '11952': '20162',
    '11591': '20022',
    '11203': '20199',
    '11043': '20183',
    # Hierbas frescas
    '11165': ('11094', 'Cilantro, fresco', 'Koriander, frisch'),
    '11297': '11014',
    '02044': '11033',
    '02045': '11093',
    '02065': ('11027', 'Menta (hierbabuena), fresca', 'Minze, frisch'),
    '02049': '11070',
    '02063': '11068',
    # Setas
    '11260': '20056',
    '11261': ('20102', 'Champiñones blancos, hervidos', 'Weiße Champignons, gekocht'),
    '11264': '20079',
    '11987': '20114',
    '11239': '20103',
    # Raíces y tubérculos
    '11352': ('4008', 'Papa (patata) pelada, cruda', 'Kartoffel, geschält, roh'),
    '11367': ('4003', 'Papa (patata), hervida', 'Kartoffel, gekocht'),
    '11507': '4101',
    '11510': ('4102', 'Batata (boniato, camote), cocida', 'Süßkartoffel, gekocht'),
    '11134': '54031',
    '11601': ('53502', 'Ñame, pelado, crudo', 'Yamswurzel, geschält, roh'),
    '11602': ('53503', 'Ñame, pelado, hervido', 'Yamswurzel, geschält, gekocht'),
    '11518': '53200',
    '11519': ('53201', 'Ocumo chino (taro), cocido', 'Taro, gekocht'),
}

# Las porciones de USDA no se pasan al alimento de CIQUAL cuando la pieza no es
# la misma (papa cruda con piel → pelada; dátil Deglet Noor → dátil genérico).
SIN_PORCIONES_EN_CIQUAL = {'11352', '09087'}

# Alimentos que solo están en CIQUAL: (código, español, alemán, categoría).
# Deben tener cifra para los cuatro esenciales.
NUEVOS_CIQUAL = [
    ('20238', 'Cebolla morada, cruda', 'Rote Zwiebel, roh', FV),
    ('11097', 'Pepinillos agridulces', 'Gewürzgurken, süß-sauer', DESP),
    ('20132', 'Calabaza Hokkaido (potimarrón), cruda', 'Hokkaido-Kürbis, roh', FV),
    ('20331', 'Calabaza Hokkaido (potimarrón), hervida', 'Hokkaido-Kürbis, gekocht', FV),
    ('20282', 'Espárrago blanco, pelado, crudo', 'Weißer Spargel, geschält, roh', FV),
    ('20277', 'Espárrago blanco, hervido', 'Weißer Spargel, gekocht', FV),
    ('54034', 'Yuca (mandioca), cocida', 'Maniok (Cassava), gekocht', FV),
]


# ─── Descargas y lectura de las fuentes ─────────────────────────────────────

def descargar_url(url, ruta):
    if not os.path.exists(ruta):
        print(f'Descargando {url}', file=sys.stderr)
        with urllib.request.urlopen(url, timeout=600) as r, open(ruta, 'wb') as out:
            out.write(r.read())
    with open(ruta, 'rb') as f:
        return f.read()


def numero(texto):
    d = Decimal(texto)
    if d == d.to_integral_value():
        return int(d)
    return float(d.normalize())


def cargar_usda(cache):
    """SR Legacy (CSV de FoodData Central). Devuelve, por NDB de 5 cifras:
    descripción y FDC ID, nutrientes y porciones (seq_num → (cantidad,
    modificador, gramos))."""
    datos = descargar_url(USDA_URL, os.path.join(cache, os.path.basename(USDA_URL)))
    digest = hashlib.sha256(datos).hexdigest()
    if digest != USDA_SHA256:
        sys.exit(f'ERROR: sha256 de {USDA_URL} = {digest}, se esperaba {USDA_SHA256}')

    def tabla(nombre):
        with zipfile.ZipFile(io.BytesIO(datos)) as z:
            texto = z.read(USDA_PREFIJO + nombre).decode('utf-8')
        return csv.DictReader(io.StringIO(texto))

    fdc_de = {f'{int(r["NDB_number"]):05d}': r['fdc_id']
              for r in tabla('sr_legacy_food.csv')}
    ndb_de = {f: n for n, f in fdc_de.items()}
    desc = {}
    for r in tabla('food.csv'):
        if r['fdc_id'] in ndb_de:
            desc[ndb_de[r['fdc_id']]] = {'fdc': r['fdc_id'], 'desc': r['description']}
    nut = {}
    for r in tabla('food_nutrient.csv'):
        if r['nutrient_id'] in NUTRIENTES and r['fdc_id'] in ndb_de:
            nut.setdefault(ndb_de[r['fdc_id']], {})[NUTRIENTES[r['nutrient_id']]] = r['amount']
    pesos = {}
    for r in tabla('food_portion.csv'):
        if r['fdc_id'] in ndb_de:
            pesos.setdefault(ndb_de[r['fdc_id']], {})[int(r['seq_num'])] = (
                r['amount'], r['modifier'], r['gram_weight'])
    print(f'USDA SR Legacy: {len(desc)} alimentos, sha256 correcto.', file=sys.stderr)
    return desc, nut, pesos


def _xml(e, tag):
    x = e.find(tag)
    if x is None or x.get('missing') is not None:
        return None
    return (x.text or '').strip()


def cargar_ciqual(cache):
    datos = {}
    for nombre, (md5, sha) in CIQUAL_ARCHIVOS.items():
        url = CIQUAL_URL.format(urllib.parse.quote(nombre))
        b = descargar_url(url, os.path.join(cache, nombre))
        if hashlib.md5(b).hexdigest() != md5 or hashlib.sha256(b).hexdigest() != sha:
            sys.exit(f'ERROR: {nombre} no coincide con el md5/sha256 esperado')
        datos[nombre] = b

    const = {_xml(c, 'const_code'): _xml(c, 'const_nom_eng')
             for c in ET.fromstring(datos['const_2025_11_03.xml'])}
    for cod, (_, nombre) in CIQUAL_COMPONENTES.items():
        if const.get(cod) != nombre:
            sys.exit(f'ERROR: componente CIQUAL {cod} = {const.get(cod)!r}, '
                     f'se esperaba {nombre!r}')

    alim = {_xml(a, 'alim_code'): {'fr': _xml(a, 'alim_nom_fr'),
                                   'eng': _xml(a, 'alim_nom_eng')}
            for a in ET.fromstring(datos['alim_2025_11_03.xml'])}
    compo = {}
    for _, e in ET.iterparse(io.BytesIO(datos['compo_2025_11_03.xml'])):
        if e.tag != 'COMPO':
            continue
        cod = _xml(e, 'const_code')
        if cod in CIQUAL_COMPONENTES:
            clave = CIQUAL_COMPONENTES[cod][0]
            compo.setdefault(_xml(e, 'alim_code'), {})[clave] = _xml(e, 'teneur')
        e.clear()
    print(f'CIQUAL 2025: {len(alim)} alimentos, md5 y sha256 correctos.',
          file=sys.stderr)
    return alim, compo


# ─── Construcción del repertorio ────────────────────────────────────────────

CIFRA_CIQUAL = re.compile(r'^\d+(,\d+)?$')


def valores_ciqual(compo, codigo):
    """(cifras, sin_cifra): las cifras publicadas y, para el resto de los
    8 nutrientes, el texto de la fuente ("-", "traces", "< 0,5"...)."""
    v = compo.get(codigo, {})
    cifras, sin_cifra = {}, {}
    for clave in ORDEN:
        texto = v.get(clave)
        if texto is not None and CIFRA_CIQUAL.match(texto):
            cifras[clave] = numero(texto.replace(',', '.'))
        else:
            sin_cifra[clave] = texto or '-'
    return cifras, sin_cifra


def completo_ciqual(compo, codigo):
    cifras, _ = valores_ciqual(compo, codigo)
    return all(c in cifras for c in ESENCIALES)


def texto_fuente(t):
    return {'-': 'sin dato', 'traces': 'trazas'}.get(t, t)


def nombre_app(es, de):
    """Nombre que ve la app: "español / alemán" (se busca en los dos)."""
    assert ' / ' not in es and ' / ' not in de, (es, de)
    return f'{es} / {de}'


def porciones_usda(ndb, pesos):
    out = []
    for seq, nombre_es, esperado in PORCIONES.get(ndb, []):
        amount, msre, gm = pesos[ndb][seq]
        real = f'{amount} {msre}'
        if real != esperado:
            sys.exit(f'ERROR: porción {ndb}/{seq}: {real!r} != {esperado!r}')
        out.append({'nombre': nombre_es, 'gramos': numero(gm)})
    return out


def alimento_ciqual(codigo, es, de, cat, alim, compo, porciones, fdc_porciones):
    cifras, sin_cifra = valores_ciqual(compo, codigo)
    assert all(c in cifras for c in ESENCIALES), codigo
    fr = alim[codigo]['fr']
    notas = (f'Fuente: Anses. 2025. Ciqual French food composition table '
             f'(doi:{CIQUAL_DOI}), código {codigo} «{fr}». Valores por 100 g '
             'de parte comestible. Carbohidratos disponibles (sin la fibra) y '
             'proteína bruta (N × 6,25), como en las etiquetas de la UE.')
    if sin_cifra:
        notas += ' Sin cifra en la fuente: ' + ', '.join(
            f'{ETIQUETAS[c]} ({texto_fuente(t)})' for c, t in sin_cifra.items()) + '.'
    if porciones:
        notas += (f' Porciones: pesos de USDA SR Legacy (FDC ID {fdc_porciones}, '
                  'parte comestible).')
    a = {
        'uuid': str(uuid.uuid5(uuid.NAMESPACE_URL, f'cal_counter/ciqual-2025/{codigo}')),
        'nombre': nombre_app(es, de),
        'tipo': 'generico',
        'unidad': 'g',
        'categoria': cat,
        'nutricion': {**cifras, 'origen': 'importado'},
        'notas': notas,
    }
    if porciones:
        a['porciones'] = porciones
    fila = {'fuente': f'CIQUAL {codigo}', 'descripcion': fr}
    return a, fila


def alimento_usda(ndb, es, de, cat, desc, nut, pesos, motivo):
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
    for esencial in ESENCIALES:
        assert esencial in nutricion, f'{ndb} sin {esencial}'
    nutricion['origen'] = 'importado'

    faltan = [ETIQUETAS[c] for c in NUTRIENTES.values() if c not in valores]
    notas = (f'Fuente: USDA FoodData Central, SR Legacy, FDC ID {desc[ndb]["fdc"]} '
             f'(NDB {int(ndb)}) «{desc[ndb]["desc"]}». '
             'Valores por 100 g de parte comestible. Carbohidratos totales '
             '(por diferencia, incluyen la fibra).')
    if 'sodio_mg' in valores:
        notas += ' Sal = sodio × 2,5.'
    if faltan:
        notas += f' Sin dato en la fuente: {", ".join(faltan)}.'
    porciones = porciones_usda(ndb, pesos)
    if porciones:
        notas += ' Porciones: pesos de USDA (parte comestible).'
    if motivo:
        codigo, sin_cifra = motivo
        campos = ', '.join(f'{ETIQUETAS[c]} ({texto_fuente(t)})'
                           for c, t in sin_cifra.items() if c in ESENCIALES)
        notas += (f' Se usa USDA porque CIQUAL 2025 (código {codigo}) no da '
                  f'cifra de {campos}.')
    a = {
        'uuid': str(uuid.uuid5(uuid.NAMESPACE_URL, f'cal_counter/usda-sr-legacy/{ndb}')),
        'nombre': nombre_app(es, de),
        'tipo': 'generico',
        'unidad': 'g',
        'categoria': cat,
        'nutricion': nutricion,
        'notas': notas,
    }
    if porciones:
        a['porciones'] = porciones
    fila = {'fuente': f'USDA {desc[ndb]["fdc"]}', 'descripcion': desc[ndb]['desc']}
    return a, fila


def construir(desc, nut, pesos, alim, compo):
    ndbs = [s[0] for s in SELECCION]
    assert len(set(ndbs)) == len(ndbs), 'NDB repetido'
    assert set(PORCIONES) <= set(ndbs), set(PORCIONES) - set(ndbs)
    assert set(MAPA_CIQUAL) <= set(ndbs), set(MAPA_CIQUAL) - set(ndbs)
    codigos = [m if isinstance(m, str) else m[0] for m in MAPA_CIQUAL.values()]
    codigos += [n[0] for n in NUEVOS_CIQUAL]
    assert len(set(codigos)) == len(codigos), 'código CIQUAL repetido'

    alimentos, filas_doc = [], []
    for ndb, es, de, cat in SELECCION:
        m = MAPA_CIQUAL.get(ndb)
        codigo, es_c, de_c = (m, None, None) if isinstance(m, str) else (m or (None, None, None))
        if codigo and completo_ciqual(compo, codigo):
            porciones = [] if ndb in SIN_PORCIONES_EN_CIQUAL else porciones_usda(ndb, pesos)
            a, fila = alimento_ciqual(codigo, es_c or es, de_c or de, cat, alim,
                                      compo, porciones, desc[ndb]['fdc'])
        else:
            motivo = (codigo, valores_ciqual(compo, codigo)[1]) if codigo else None
            a, fila = alimento_usda(ndb, es, de, cat, desc, nut, pesos, motivo)
        alimentos.append(a)
        filas_doc.append(fila)
    for codigo, es, de, cat in NUEVOS_CIQUAL:
        if not completo_ciqual(compo, codigo):
            sys.exit(f'ERROR: {codigo} no tiene los cuatro nutrientes esenciales')
        a, fila = alimento_ciqual(codigo, es, de, cat, alim, compo, [], None)
        alimentos.append(a)
        filas_doc.append(fila)

    nombres = [a['nombre'].lower() for a in alimentos]
    assert len(set(nombres)) == len(nombres), 'nombre repetido'
    assert len({a['uuid'] for a in alimentos}) == len(alimentos), 'uuid repetido'
    rep = {
        'formato': 'cal_counter/repertorio',
        'version': 1,
        'exportado': '2026-11-24T00:00:00Z',
        'alimentos': alimentos,
    }
    return rep, filas_doc


# ─── Documentación ──────────────────────────────────────────────────────────

def fmt(v):
    if v is None:
        return '—'
    return str(v).replace('.', ',')


def escribir_doc(rep, filas_doc):
    total = len(rep['alimentos'])
    n_ciqual = sum(1 for f in filas_doc if f['fuente'].startswith('CIQUAL'))
    lineas = [
        '# Frutas, verduras y hortalizas (CIQUAL 2025 y USDA SR Legacy)',
        '',
        '> Archivo generado por `tool/semilla/generar_frutas_verduras.py`. '
        'No editar a mano.',
        '',
        f'`assets/semilla/frutas_verduras.json` contiene **{total} alimentos** '
        f'({n_ciqual} de CIQUAL 2025 y {total - n_ciqual} de USDA SR Legacy) en '
        'formato `cal_counter/repertorio` v1. Se carga junto al catálogo base '
        'en la bienvenida y se puede añadir en cualquier momento desde *Datos y '
        'respaldos → Catálogos incluidos → Añadir frutas y verduras* (o '
        'importando el archivo). Importarlo de nuevo no duplica nada: cada '
        'alimento tiene un uuid v5 fijo derivado de su código en la fuente.',
        '',
        '## Fuentes',
        '',
        '1. **CIQUAL 2025 (fuente preferida).** Anses. 2025. *Ciqual French '
        'food composition table*. https://doi.org/10.5281/zenodo.17550133. '
        'Reutilización libre con cita de la fuente (Licence Ouverte). Mismo '
        'criterio que las etiquetas de la UE: **carbohidratos disponibles (sin '
        'la fibra)**, **proteína bruta (N × 6,25)**, energía según el Reglamento '
        '(UE) 1169/2011 y sal publicada directamente. Los archivos se '
        'descargan de Zenodo y se comprueban con el md5 publicado allí y con '
        'un sha256 fijado.',
        '2. **USDA SR Legacy.** U.S. Department of Agriculture, Agricultural '
        'Research Service. *FoodData Central: SR Legacy* (abril de 2018), la '
        'edición final de la *National Nutrient Database for Standard '
        'Reference*. Dominio público. **Carbohidratos totales por diferencia '
        '(incluyen la fibra)**; sal = sodio × 2,5 (Reglamento (UE) 1169/2011, '
        'anexo I). El archivo CSV oficial se descarga de FoodData Central y se '
        'comprueba con un sha256 fijado.',
        '',
        '## Criterios',
        '',
        '- **Ningún valor se ha escrito a mano ni estimado.** El script lee '
        'cada nutriente y cada peso de porción de los archivos oficiales.',
        '- **Qué fuente se usa**: CIQUAL si tiene el mismo alimento con la '
        'misma preparación **y** publica una cifra para kcal, proteínas, '
        'grasas y carbohidratos. Si alguno de esos cuatro aparece como '
        '«traces», «< x» o falta, el alimento entero sale de USDA, que sí los '
        'publica, y su nota explica por qué. Nunca se mezclan fuentes en la '
        'tabla nutricional de un mismo alimento.',
        '- **Datos sin cifra**: si la fuente no da una cifra (CIQUAL: «-», '
        '«traces» o «< x»; USDA: sin dato), el campo queda **vacío**, nunca '
        'en 0, y la nota lo indica con el texto original de la fuente.',
        '- **Atención al comparar**: los alimentos de USDA tienen los '
        'carbohidratos con la fibra incluida; los de CIQUAL, sin ella. La nota '
        'de cada alimento dice cuál es su caso.',
        '- **Porciones**: medidas caseras de USDA (`food_portion.csv`), solo de '
        'unidades (pieza, diente, tallo, hoja, mazorca, cucharada…), en gramos '
        'de parte comestible. Se ponen también en el alimento de CIQUAL '
        'equivalente cuando la pieza es la misma, indicando el FDC ID. Las '
        'pulgadas se han pasado a centímetros (1" = 2,54 cm) en el nombre.',
        '- **Nombre en español y en alemán** en el mismo campo («Manzana con '
        'piel, cruda / Apfel mit Schale, roh»), para buscar en cualquiera de '
        'los dos idiomas. La búsqueda ignora tildes y diéresis, y trata «ß» '
        'como «ss» («Weißkohl» = «Weisskohl»).',
        '- Categorías: *Frutas y verduras* (frescos) y *Despensa* (conservas, '
        'frutas secas y deshidratados).',
        '- **Cómo contrastar un valor**: CIQUAL en https://ciqual.anses.fr '
        '(buscar el código o el nombre francés); USDA en '
        '`https://fdc.nal.usda.gov/food-details/<FDC ID>/nutrients` (el FDC ID '
        'va en la nota de cada alimento y en la tabla).',
        '',
        '## No incluidos por no estar en ninguna de las dos fuentes',
        '',
        'Ají dulce, tomate de árbol, curuba, granadilla dulce, arracacha (apio '
        'criollo), mapuey, mamón, pitahaya y borojó no están en SR Legacy ni en '
        'CIQUAL 2025. El merey (pomme cajou), el caimito y el chou caraïbe '
        'están en CIQUAL pero sin cifra de kcal ni de carbohidratos. Se pueden '
        'añadir a mano con los datos de una etiqueta o de otra tabla oficial.',
        '',
        '## Lista',
        '',
        '| Alimento | Fuente | Descripción en la fuente | kcal | Prot. | Grasas | Carb. | Fibra | Categoría |',
        '|---|---|---|---:|---:|---:|---:|---:|---|',
    ]
    for a, f in zip(rep['alimentos'], filas_doc):
        n = a['nutricion']
        lineas.append(
            f"| {a['nombre']} | {f['fuente']} | {f['descripcion']} "
            f"| {fmt(n.get('kcal'))} | {fmt(n.get('proteinas'))} "
            f"| {fmt(n.get('grasas'))} | {fmt(n.get('carbohidratos'))} "
            f"| {fmt(n.get('fibra'))} | {a['categoria']} |")
    with open(DOC, 'w', encoding='utf-8', newline='\n') as fh:
        fh.write('\n'.join(lineas) + '\n')


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    p.add_argument('--cache', help='carpeta para guardar las descargas')
    args = p.parse_args()
    cache = args.cache or tempfile.mkdtemp(prefix='frutas_verduras_')
    os.makedirs(cache, exist_ok=True)
    desc, nut, pesos = cargar_usda(cache)
    alim, compo = cargar_ciqual(cache)
    rep, filas_doc = construir(desc, nut, pesos, alim, compo)
    with open(SALIDA, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(rep, f, ensure_ascii=False, indent=1)
        f.write('\n')
    escribir_doc(rep, filas_doc)
    n_ciqual = sum(1 for f in filas_doc if f['fuente'].startswith('CIQUAL'))
    print(f'{len(rep["alimentos"])} alimentos ({n_ciqual} CIQUAL, '
          f'{len(rep["alimentos"]) - n_ciqual} USDA) → '
          f'{os.path.relpath(SALIDA, RAIZ)} y {os.path.relpath(DOC, RAIZ)}',
          file=sys.stderr)


if __name__ == '__main__':
    main()
