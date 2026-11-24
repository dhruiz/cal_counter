# Frutas, verduras y hortalizas (CIQUAL 2025 y USDA SR Legacy)

> Archivo generado por `tool/semilla/generar_frutas_verduras.py`. No editar a mano.

`assets/semilla/frutas_verduras.json` contiene **229 alimentos** (130 de CIQUAL 2025 y 99 de USDA SR Legacy) en formato `cal_counter/repertorio` v1. Se carga junto al catálogo base en la bienvenida; en una instalación que ya tenía datos se incorpora sola la primera vez que se abre la app tras actualizar (una vez por versión de la lista: `kProduceCatalogVersion`). También se puede añadir desde *Datos y respaldos → Catálogos incluidos → Añadir frutas y verduras* o importando el archivo. Importarlo de nuevo no duplica nada: cada alimento tiene un uuid v5 fijo derivado de su código en la fuente.

## Fuentes

1. **CIQUAL 2025 (fuente preferida).** Anses. 2025. *Ciqual French food composition table*. https://doi.org/10.5281/zenodo.17550133. Reutilización libre con cita de la fuente (Licence Ouverte). Mismo criterio que las etiquetas de la UE: **carbohidratos disponibles (sin la fibra)**, **proteína bruta (N × 6,25)**, energía según el Reglamento (UE) 1169/2011 y sal publicada directamente. Los archivos se descargan de Zenodo y se comprueban con el md5 publicado allí y con un sha256 fijado.
2. **USDA SR Legacy.** U.S. Department of Agriculture, Agricultural Research Service. *FoodData Central: SR Legacy* (abril de 2018), la edición final de la *National Nutrient Database for Standard Reference*. Dominio público. **Carbohidratos totales por diferencia (incluyen la fibra)**; sal = sodio × 2,5 (Reglamento (UE) 1169/2011, anexo I). El archivo CSV oficial se descarga de FoodData Central y se comprueba con un sha256 fijado.

## Criterios

- **Ningún valor se ha escrito a mano ni estimado.** El script lee cada nutriente y cada peso de porción de los archivos oficiales.
- **Qué fuente se usa**: CIQUAL si tiene el mismo alimento con la misma preparación **y** publica una cifra para kcal, proteínas, grasas y carbohidratos. Si alguno de esos cuatro aparece como «traces», «< x» o falta, el alimento entero sale de USDA, que sí los publica, y su nota explica por qué. Nunca se mezclan fuentes en la tabla nutricional de un mismo alimento.
- **Datos sin cifra**: si la fuente no da una cifra (CIQUAL: «-», «traces» o «< x»; USDA: sin dato), el campo queda **vacío**, nunca en 0, y la nota lo indica con el texto original de la fuente.
- **Atención al comparar**: los alimentos de USDA tienen los carbohidratos con la fibra incluida; los de CIQUAL, sin ella. La nota de cada alimento dice cuál es su caso.
- **Porciones**: medidas caseras de USDA (`food_portion.csv`), solo de unidades (pieza, diente, tallo, hoja, mazorca, cucharada…), en gramos de parte comestible. Se ponen también en el alimento de CIQUAL equivalente cuando la pieza es la misma, indicando el FDC ID. Las pulgadas se han pasado a centímetros (1" = 2,54 cm) en el nombre.
- **Nombre en español y en alemán** en el mismo campo («Manzana con piel, cruda / Apfel mit Schale, roh»), para buscar en cualquiera de los dos idiomas. La búsqueda ignora tildes y diéresis, y trata «ß» como «ss» («Weißkohl» = «Weisskohl»).
- Categorías: *Frutas y verduras* (frescos) y *Despensa* (conservas, frutas secas y deshidratados).
- **Cómo contrastar un valor**: CIQUAL en https://ciqual.anses.fr (buscar el código o el nombre francés); USDA en `https://fdc.nal.usda.gov/food-details/<FDC ID>/nutrients` (el FDC ID va en la nota de cada alimento y en la tabla).

## No incluidos por no estar en ninguna de las dos fuentes

Ají dulce, tomate de árbol, curuba, granadilla dulce, arracacha (apio criollo), mapuey, mamón, pitahaya y borojó no están en SR Legacy ni en CIQUAL 2025. El merey (pomme cajou), el caimito y el chou caraïbe están en CIQUAL pero sin cifra de kcal ni de carbohidratos. Se pueden añadir a mano con los datos de una etiqueta o de otra tabla oficial.

## Lista

| Alimento | Fuente | Descripción en la fuente | kcal | Prot. | Grasas | Carb. | Fibra | Categoría |
|---|---|---|---:|---:|---:|---:|---:|---|
| Manzana con piel, cruda / Apfel mit Schale, roh | CIQUAL 13039 | Pomme, chair et peau, crue | 54 | 0,25 | 0,25 | 11,6 | 1,4 | Frutas y verduras |
| Manzana sin piel, cruda / Apfel ohne Schale, roh | CIQUAL 13396 | Pomme, chair sans peau, crue (aliment moyen) | 51,3 | 0,26 | 0,24 | 11,9 | 2,39 | Frutas y verduras |
| Pera con piel, cruda / Birne mit Schale, roh | CIQUAL 13037 | Poire, chair et peau, crue | 56,6 | 0,36 | 0,27 | 12,3 | 2,9 | Frutas y verduras |
| Cambur (banano, banana), crudo / Banane, roh | USDA 173944 | Bananas, raw | 89 | 1,09 | 0,33 | 22,84 | 2,6 | Frutas y verduras |
| Naranja, cruda / Orange (Apfelsine), roh | USDA 169097 | Oranges, raw, all commercial varieties | 47 | 0,94 | 0,12 | 11,75 | 2,4 | Frutas y verduras |
| Jugo de naranja natural (recién exprimido) / Orangensaft, frisch gepresst | CIQUAL 2013 | Jus d'orange, frais | 44,8 | 0,7 | 0,2 | 9,19 | 0,2 | Frutas y verduras |
| Mandarina, cruda / Mandarine, roh | USDA 169105 | Tangerines, (mandarin oranges), raw | 53 | 0,81 | 0,31 | 13,34 | 1,8 | Frutas y verduras |
| Clementina, cruda / Clementine, roh | USDA 168195 | Clementines, raw | 47 | 0,85 | 0,15 | 12,02 | 1,7 | Frutas y verduras |
| Toronja (pomelo), cruda / Grapefruit, roh | USDA 173033 | Grapefruit, raw, pink and red and white, all areas | 32 | 0,63 | 0,1 | 8,08 | 1,1 | Frutas y verduras |
| Limón amarillo, sin cáscara, crudo / Zitrone, ohne Schale, roh | USDA 167746 | Lemons, raw, without peel | 29 | 1,1 | 0,3 | 9,32 | 2,8 | Frutas y verduras |
| Jugo de limón amarillo, hecho en casa / Zitronensaft, selbst gepresst | CIQUAL 2007 | Jus de citron, fait maison | 28,6 | 0,35 | 0,24 | 2,52 | 0,3 | Frutas y verduras |
| Lima ácida (limón verde), cruda / Limette, roh | USDA 168155 | Limes, raw | 30 | 0,7 | 0,2 | 10,54 | 2,8 | Frutas y verduras |
| Jugo de lima ácida (limón verde), natural / Limettensaft, frisch gepresst | CIQUAL 2030 | Jus de citron vert, frais | 9,87 | 0,42 | 0,07 | 1,69 | 0,4 | Frutas y verduras |
| Uvas, crudas (promedio) / Weintrauben, roh (Durchschnitt) | CIQUAL 13395 | Raisin cru (aliment moyen) | 71 | 0,7 | 0,25 | 16,3 | 1,11 | Frutas y verduras |
| Fresas (frutillas), crudas / Erdbeeren, roh | USDA 167762 | Strawberries, raw | 32 | 0,67 | 0,3 | 7,68 | 2 | Frutas y verduras |
| Arándanos, crudos / Heidelbeeren (Blaubeeren), roh | CIQUAL 13028 | Myrtille, crue | 57,7 | 0,87 | 0,33 | 10,6 | 2,4 | Frutas y verduras |
| Frambuesas, crudas / Himbeeren, roh | CIQUAL 13015 | Framboise, crue | 47,9 | 1,19 | 0,8 | 5,83 | 4,3 | Frutas y verduras |
| Moras (zarzamoras), crudas / Brombeeren, roh | CIQUAL 13029 | Mûre (de ronce), crue | 46 | 1,13 | 0,7 | 6,53 | 5,2 | Frutas y verduras |
| Grosellas rojas, crudas / Rote Johannisbeeren, roh | CIQUAL 13019 | Groseille, crue | 67,2 | 1,56 | 0,7 | 7,06 | 4,6 | Frutas y verduras |
| Grosellas negras (casis), crudas / Schwarze Johannisbeeren, roh | CIQUAL 13007 | Cassis, cru | 70,2 | 1,4 | 0,41 | 9,68 | 7,13 | Frutas y verduras |
| Grosellas espinosas (uva espina), crudas / Stachelbeeren, roh | CIQUAL 13020 | Groseille à maquereau, crue | 39,4 | 0,88 | 0,58 | 4,45 | 4,3 | Frutas y verduras |
| Cerezas dulces, crudas / Süßkirschen, roh | USDA 171719 | Cherries, sweet, raw | 63 | 1,06 | 0,2 | 16,01 | 2,1 | Frutas y verduras |
| Guindas (cerezas ácidas), crudas / Sauerkirschen, roh | USDA 173954 | Cherries, sour, red, raw | 50 | 1 | 0,3 | 12,18 | 1,6 | Frutas y verduras |
| Ciruelas, crudas / Pflaumen, roh | CIQUAL 13100 | Prune, sans noyau, crue | 51,6 | 0,7 | 0,28 | 9,92 | 1,4 | Frutas y verduras |
| Albaricoques (damascos), crudos / Aprikosen, roh | USDA 171697 | Apricots, raw | 48 | 1,4 | 0,39 | 11,12 | 2 | Frutas y verduras |
| Durazno (melocotón) con piel, crudo / Pfirsich mit Schale, roh | CIQUAL 13043 | Pêche, chair et peau, sans noyau, crue | 37,9 | 0,91 | 0,25 | 7,55 | 1,5 | Frutas y verduras |
| Nectarina, cruda / Nektarine, roh | USDA 169914 | Nectarines, raw | 44 | 1,06 | 0,32 | 10,55 | 1,7 | Frutas y verduras |
| Higos, crudos / Feigen, roh | USDA 173021 | Figs, raw | 74 | 0,75 | 0,3 | 19,18 | 2,9 | Frutas y verduras |
| Granada, granos con semillas, cruda / Granatapfelkerne, roh | CIQUAL 13018 | Grenade, chair sans peau, avec pépins, crue | 81 | 1,44 | 1,2 | 14,3 | 2,3 | Frutas y verduras |
| Caqui (kaki, persimón), crudo / Kaki (Persimone), roh | USDA 169941 | Persimmons, japanese, raw | 70 | 0,58 | 0,19 | 18,59 | 3,6 | Frutas y verduras |
| Membrillo, crudo / Quitte, roh | CIQUAL 13010 | Coing, cru | 59 | 0,4 | 0,1 | 12,5 | 1,9 | Frutas y verduras |
| Kiwi, crudo / Kiwi, roh | CIQUAL 13021 | Kiwi, chair sans peau, avec pépins, cru | 60,9 | 0,88 | 0,6 | 11 | 2,4 | Frutas y verduras |
| Ruibarbo (tallo), crudo / Rhabarber (Stiel), roh | CIQUAL 13047 | Rhubarbe, tige, crue | 18,1 | 0,73 | 0,16 | 1,12 | 1,8 | Frutas y verduras |
| Patilla (sandía), cruda / Wassermelone, roh | USDA 167765 | Watermelon, raw | 30 | 0,61 | 0,15 | 7,55 | 0,4 | Frutas y verduras |
| Melón cantalupo, crudo / Cantaloupe-Melone, roh | USDA 169092 | Melons, cantaloupe, raw | 34 | 0,84 | 0,19 | 8,16 | 0,9 | Frutas y verduras |
| Melón verde (honeydew), crudo / Honigmelone, roh | CIQUAL 13742 | Melon miel ou melon honeydew, chair sans peau, sans pépins, cru | 22,2 | 0,54 | 0,14 | 4,3 | 0,8 | Frutas y verduras |
| Piña (ananá), cruda / Ananas, roh | USDA 169124 | Pineapple, raw, all varieties | 50 | 0,54 | 0,12 | 13,12 | 1,4 | Frutas y verduras |
| Mango, crudo / Mango, roh | USDA 169910 | Mangos, raw | 60 | 0,82 | 0,38 | 14,98 | 1,6 | Frutas y verduras |
| Lechoza (papaya), cruda / Papaya, roh | USDA 169926 | Papayas, raw | 43 | 0,47 | 0,26 | 10,82 | 1,7 | Frutas y verduras |
| Aguacate (palta), crudo, promedio de variedades comerciales / Avocado, roh, Durchschnitt der Handelssorten | USDA 171705 | Avocados, raw, all commercial varieties | 160 | 2 | 14,66 | 8,53 | 6,7 | Frutas y verduras |
| Aguacate de California (palta), crudo / Avocado aus Kalifornien, roh | USDA 171706 | Avocados, raw, California | 167 | 1,96 | 15,41 | 8,64 | 6,8 | Frutas y verduras |
| Aguacate de Florida (palta), crudo / Avocado aus Florida, roh | USDA 171707 | Avocados, raw, Florida | 120 | 2,23 | 10,06 | 7,82 | 5,6 | Frutas y verduras |
| Coco, pulpa fresca / Kokosnuss, Fruchtfleisch, frisch | CIQUAL 15006 | Noix de coco, chair, fraîche | 369 | 4,09 | 34,7 | 4,69 | 10,6 | Frutas y verduras |
| Agua de coco / Kokoswasser | USDA 170174 | Nuts, coconut water (liquid from coconuts) | 19 | 0,72 | 0,2 | 3,71 | 1,1 | Frutas y verduras |
| Guayaba sin piel, cruda / Guave ohne Schale, roh | CIQUAL 13083 | Goyave, chair sans peau, crue | 68,3 | 2,55 | 0,95 | 9,02 | 5,4 | Frutas y verduras |
| Guanábana, cruda / Stachelannone (Guanábana), roh | USDA 167761 | Soursop, raw | 66 | 1 | 0,3 | 16,84 | 3,3 | Frutas y verduras |
| Chirimoya, cruda / Cherimoya, roh | CIQUAL 13056 | Anone ou chérimole, chair sans peau, crue | 80 | 1,57 | 0,68 | 15,4 | 3 | Frutas y verduras |
| Anón (saramuyo), crudo / Zimtapfel, roh | USDA 168175 | Sugar-apples, (sweetsop), raw | 94 | 2,06 | 0,29 | 23,64 | 4,4 | Frutas y verduras |
| Maracuyá (parchita), pulpa con semillas, cruda / Passionsfrucht (Maracuja), Fruchtfleisch mit Kernen, roh | CIQUAL 13016 | Fruit de la passion ou maracudja, chair sans peau, avec pépins, cru | 102 | 2,13 | 3 | 10,9 | 6,8 | Frutas y verduras |
| Jugo de maracuyá (parchita), natural / Maracujasaft, frisch | CIQUAL 2024 | Jus de fruit de la passion ou maracudja, frais | 61,7 | 0,67 | 0,18 | 14,3 | 0,2 | Frutas y verduras |
| Mamey, crudo / Mammiapfel (Mamey), roh | USDA 169909 | Mammy-apple, (mamey), raw | 51 | 0,5 | 0,5 | 12,5 | 3 | Frutas y verduras |
| Zapote (mamey colorado), crudo / Mamey-Sapote, roh | USDA 167760 | Sapote, mamey, raw | 124 | 1,45 | 0,46 | 32,1 | 5,4 | Frutas y verduras |
| Níspero (sapodilla, zapote chico), crudo / Sapotille (Breiapfel), roh | USDA 167759 | Sapodilla, raw | 83 | 0,44 | 1,1 | 19,96 | 5,3 | Frutas y verduras |
| Níspero del Japón (níspero de España), crudo / Japanische Wollmispel (Loquat), roh | CIQUAL 13564 | Nèfle du Japon, chair et peau, sans noyau, crue | 48,1 | 0,43 | 0,2 | 9,9 | 1,7 | Frutas y verduras |
| Tamarindo, crudo / Tamarinde, roh | USDA 167763 | Tamarinds, raw | 239 | 2,8 | 0,6 | 62,5 | 5,1 | Frutas y verduras |
| Uchuva (aguaymanto, physalis), cruda / Physalis (Kapstachelbeere), roh | USDA 173043 | Groundcherries, (cape-gooseberries or poha), raw | 53 | 1,9 | 0,7 | 11,2 | — | Frutas y verduras |
| Lulo (naranjilla), pulpa congelada sin azúcar / Lulo (Naranjilla), Fruchtmark, tiefgekühlt, ungesüßt | USDA 167790 | Naranjilla (lulo) pulp, frozen, unsweetened | 25 | 0,44 | 0,22 | 5,9 | 1,1 | Frutas y verduras |
| Carambola (fruta estrella), cruda / Karambole (Sternfrucht), roh | CIQUAL 13054 | Carambole, chair et peau, crue | 28,4 | 1,04 | 0,33 | 3,83 | 2,8 | Frutas y verduras |
| Semeruco (acerola), crudo / Acerola, roh | USDA 171686 | Acerola, (west indian cherry), raw | 32 | 0,4 | 0,3 | 7,69 | 1,1 | Frutas y verduras |
| Pomarrosa, cruda / Rosenapfel, roh | USDA 168171 | Rose-apples, raw | 25 | 0,6 | 0,3 | 5,7 | — | Frutas y verduras |
| Feijoa, cruda / Feijoa (Ananasguave), roh | USDA 168176 | Feijoa, raw | 61 | 0,71 | 0,42 | 15,21 | 6,4 | Frutas y verduras |
| Nance (chaparro manteco), congelado sin azúcar / Nance, tiefgekühlt, ungesüßt | USDA 167789 | Nance, frozen, unsweetened | 73 | 0,66 | 1,16 | 16,97 | 7,5 | Frutas y verduras |
| Tuna (higo chumbo), cruda / Kaktusfeige, roh | CIQUAL 13063 | Figue de Barbarie, chair et peau, avec pépins, crue | 51,5 | 0,12 | 0,11 | 9,79 | 5,3 | Frutas y verduras |
| Plátano macho (plátano para cocinar), crudo / Kochbanane, roh | CIQUAL 53100 | Banane plantain, crue | 132 | 1,3 | 0,37 | 29,6 | 2,3 | Frutas y verduras |
| Plátano macho, cocido / Kochbanane, gekocht | CIQUAL 53101 | Banane plantain, cuite | 125 | 0,79 | 0,18 | 28,9 | 2,3 | Frutas y verduras |
| Tostones o patacones (plátano verde frito) / Frittierte grüne Kochbanane (Tostones) | USDA 168199 | Plantains, green, fried | 309 | 1,5 | 11,81 | 49,17 | 3,5 | Frutas y verduras |
| Plátano maduro frito (tajadas), de restaurante latino / Frittierte reife Kochbanane (Latino-Restaurant) | USDA 168200 | Plantains, yellow, fried, Latino restaurant | 236 | 1,42 | 7,51 | 40,77 | 3,2 | Frutas y verduras |
| Uvas pasas / Rosinen | CIQUAL 13046 | Raisin sec | 322 | 3 | 0,9 | 73,2 | 4,2 | Despensa |
| Ciruelas pasas (secas) / Trockenpflaumen | CIQUAL 13042 | Pruneau, sans noyau, sec | 229 | 1,63 | 0,4 | 55,4 | 5,1 | Despensa |
| Orejones de albaricoque (secos) / Getrocknete Aprikosen | CIQUAL 13001 | Abricot, dénoyauté, sec | 239 | 2,88 | 0,5 | 59,1 | 8,3 | Despensa |
| Higos secos / Getrocknete Feigen | CIQUAL 13013 | Figue, sèche | 261 | 2,9 | 1,22 | 55 | 8,15 | Despensa |
| Dátiles secos, sin hueso / Datteln, getrocknet, entsteint | CIQUAL 13011 | Datte, chair et peau, sans noyau, sèche | 287 | 1,81 | 0,25 | 64,7 | 7,3 | Despensa |
| Dátiles Medjool / Datteln, Medjool | USDA 168191 | Dates, medjool | 277 | 1,81 | 0,15 | 74,97 | 6,7 | Despensa |
| Arándanos rojos deshidratados, endulzados / Cranberries, getrocknet, gesüßt | CIQUAL 13178 | Canneberge ou cranberry, séchée, sucrée | 332 | 0,25 | 1 | 76,4 | 5,7 | Despensa |
| Mango deshidratado, endulzado / Mango, getrocknet, gesüßt | USDA 169091 | Mango, dried, sweetened | 319 | 2,45 | 1,18 | 78,58 | 2,4 | Despensa |
| Aceitunas negras maduras, en lata / Schwarze Oliven, reif, aus der Dose | USDA 169094 | Olives, ripe, canned (small-extra large) | 116 | 0,84 | 10,9 | 6,04 | 1,6 | Despensa |
| Aceitunas verdes en salmuera, escurridas / Grüne Oliven in Salzlake, abgetropft | CIQUAL 13033 | Olive verte, en saumure, égouttée | 164 | 1,13 | 16,6 | 0,61 | 3,6 | Despensa |
| Alcaparras, en conserva / Kapern, eingelegt | USDA 172238 | Capers, canned | 23 | 2,36 | 0,86 | 4,89 | 3,2 | Despensa |
| Tomate rojo maduro, crudo / Tomate, rot, reif, roh | USDA 170457 | Tomatoes, red, ripe, raw, year round average | 18 | 0,88 | 0,2 | 3,89 | 1,2 | Frutas y verduras |
| Tomate pelado en lata, en su jugo / Geschälte Tomaten aus der Dose, im eigenen Saft | CIQUAL 20137 | Tomate, pelée, appertisée, au jus, non égouttée | 21,8 | 0,79 | 0,25 | 3,15 | 1,9 | Despensa |
| Tomate triturado, en lata / Tomaten, zerkleinert, aus der Dose | USDA 170501 | Tomatoes, crushed, canned | 32 | 1,64 | 0,28 | 7,29 | 1,9 | Despensa |
| Concentrado de tomate (pasta de tomate), en lata / Tomatenmark | CIQUAL 20068 | Tomate, concentré, appertisé | 99,2 | 4,4 | 0,53 | 17,1 | 4,2 | Despensa |
| Puré de tomate, en lata / Tomatenpüree aus der Dose | CIQUAL 20170 | Tomate, purée, appertisée | 47,6 | 1,5 | 0,2 | 8,42 | 1,6 | Despensa |
| Tomates secos (deshidratados) / Getrocknete Tomaten | USDA 168567 | Tomatoes, sun-dried | 258 | 14,11 | 2,97 | 55,76 | 12,3 | Despensa |
| Tomates secos en aceite, escurridos / Getrocknete Tomaten in Öl, abgetropft | USDA 169384 | Tomatoes, sun-dried, packed in oil, drained | 213 | 5,06 | 14,08 | 23,33 | 5,8 | Despensa |
| Cebolla, cruda / Zwiebel, roh | CIQUAL 20034 | Oignon, cru | 39 | 1,1 | 0,62 | 6,25 | 1,7 | Frutas y verduras |
| Cebolla, cocida / Zwiebel, gekocht | CIQUAL 20035 | Oignon, cuit | 34,6 | 1,3 | 0,2 | 6,2 | 1,4 | Frutas y verduras |
| Chalota, cruda / Schalotte, roh | USDA 170499 | Shallots, raw | 72 | 2,5 | 0,1 | 16,8 | 3,2 | Frutas y verduras |
| Cebollín (cebolla larga, cebolleta), crudo / Frühlingszwiebel, roh | USDA 170005 | Onions, spring or scallions (includes tops and bulb), raw | 32 | 1,83 | 0,19 | 7,34 | 2,6 | Frutas y verduras |
| Cebollino (ciboulette), crudo / Schnittlauch, roh | USDA 169994 | Chives, raw | 30 | 3,27 | 0,73 | 4,35 | 2,5 | Frutas y verduras |
| Ajoporro (puerro), crudo / Lauch (Porree), roh | CIQUAL 20039 | Poireau, cru | 30,4 | 1,5 | 0,3 | 4,55 | 1,8 | Frutas y verduras |
| Ajoporro (puerro), cocido (hervido, sin sal) / Lauch (Porree), gekocht, ohne Salz | USDA 168426 | Leeks, (bulb and lower leaf-portion), cooked, boiled, drained, without salt | 31 | 0,81 | 0,2 | 7,62 | 1 | Frutas y verduras |
| Ajo, crudo / Knoblauch, roh | USDA 169230 | Garlic, raw | 149 | 6,36 | 0,5 | 33,06 | 2,1 | Frutas y verduras |
| Jengibre, raíz fresca / Ingwer, frisch | CIQUAL 11074 | Gingembre, racine fraîche | 33,3 | 1,1 | 1,1 | 3,4 | 2,7 | Frutas y verduras |
| Pepino con piel, crudo / Gurke mit Schale, roh | CIQUAL 20019 | Concombre, chair et peau, cru | 16,8 | 0,65 | 0,11 | 2,87 | 0,5 | Frutas y verduras |
| Pepino pelado, crudo / Gurke, geschält, roh | USDA 169225 | Cucumber, peeled, raw | 10 | 0,59 | 0,16 | 2,16 | 0,7 | Frutas y verduras |
| Pepinillos encurtidos al eneldo / Dillgurken, eingelegt | USDA 168558 | Pickles, cucumber, dill or kosher dill | 12 | 0,5 | 0,3 | 2,41 | 1 | Despensa |
| Calabacín (zucchini), crudo / Zucchini, roh | CIQUAL 20020 | Courgette, chair et peau, crue | 16,7 | 1,21 | 0,32 | 1,75 | 1 | Frutas y verduras |
| Calabacín (zucchini), cocido / Zucchini, gekocht | CIQUAL 20021 | Courgette, chair et peau, cuite | 15,5 | 0,93 | 0,36 | 1,4 | 1,5 | Frutas y verduras |
| Berenjena, cruda / Aubergine, roh | CIQUAL 20053 | Aubergine, crue | 22,9 | 0,98 | 0,18 | 2,7 | 3 | Frutas y verduras |
| Berenjena, cocida / Aubergine, gekocht | CIQUAL 20002 | Aubergine, cuite | 27,1 | 0,83 | 0,23 | 4,17 | 2,5 | Frutas y verduras |
| Pimentón verde (pimiento verde), crudo / Grüne Paprika, roh | USDA 170427 | Peppers, sweet, green, raw | 20 | 0,86 | 0,17 | 4,64 | 1,7 | Frutas y verduras |
| Pimentón rojo (pimiento rojo), crudo / Rote Paprika, roh | USDA 170108 | Peppers, sweet, red, raw | 26 | 0,99 | 0,3 | 6,03 | 2,1 | Frutas y verduras |
| Pimentón amarillo (pimiento amarillo), crudo / Gelbe Paprika, roh | CIQUAL 20168 | Poivron jaune, cru | 29,4 | 0,94 | 0,3 | 4,73 | 1,2 | Frutas y verduras |
| Ají picante verde (chile verde), crudo / Grüne Chili, roh | USDA 170497 | Peppers, hot chili, green, raw | 40 | 2 | 0,2 | 9,46 | 1,5 | Frutas y verduras |
| Ají picante rojo (chile rojo), crudo / Rote Chili, roh | USDA 170106 | Peppers, hot chili, red, raw | 40 | 1,87 | 0,44 | 8,81 | 1,5 | Frutas y verduras |
| Jalapeño, crudo / Jalapeño, roh | USDA 168576 | Peppers, jalapeno, raw | 29 | 0,91 | 0,37 | 6,5 | 2,8 | Frutas y verduras |
| Quimbombó (okra), crudo / Okra, roh | CIQUAL 58100 | Gombo, fruit, cru | 31 | 1,93 | 0,19 | 3,8 | 3,2 | Frutas y verduras |
| Quimbombó (okra), cocido / Okra, gekocht | CIQUAL 58103 | Gombo, fruit, cuit | 22,4 | 1,87 | 0,21 | 2,01 | 2,5 | Frutas y verduras |
| Auyama (calabaza moscada), cruda / Moschuskürbis, roh | CIQUAL 20128 | Courge musquée, chair sans peau, crue | 23,5 | 0,55 | 0,1 | 4,6 | 1 | Frutas y verduras |
| Auyama (ahuyama, calabaza), cocida (hervida, sin sal) / Kürbis, gekocht, ohne Salz | USDA 168449 | Pumpkin, cooked, boiled, drained, without salt | 20 | 0,72 | 0,07 | 4,9 | 1,1 | Frutas y verduras |
| Calabaza butternut, cruda / Butternutkürbis, roh | CIQUAL 20138 | Courge butternut (doubeurre), chair sans peau, crue | 30,5 | 1 | 0,1 | 5,4 | 2 | Frutas y verduras |
| Calabaza butternut, hervida / Butternutkürbis, gekocht | CIQUAL 20141 | Courge butternut (doubeurre), chair sans peau, bouillie/cuite à l'eau | 28,2 | 0,69 | 0,2 | 4,56 | 2,4 | Frutas y verduras |
| Chayota (chayote, guatila, cidra), cruda / Chayote, roh | CIQUAL 13128 | Chayote ou christophine ou chouchou, crue | 19,1 | 0,82 | 0,13 | 2,8 | 1,7 | Frutas y verduras |
| Chayota (chayote), hervida / Chayote, gekocht | CIQUAL 13177 | Chayote ou christophine ou chouchou, bouillie/cuite à l'eau | 21,6 | 0,62 | 0,48 | 2,29 | 2,8 | Frutas y verduras |
| Vainitas (judías verdes, habichuelas), crudas / Grüne Bohnen, roh | CIQUAL 20061 | Haricot vert, cru | 31,9 | 1,83 | 0,22 | 4,14 | 2,7 | Frutas y verduras |
| Vainitas (judías verdes), cocidas (hervidas, sin sal) / Grüne Bohnen, gekocht, ohne Salz | USDA 169141 | Beans, snap, green, cooked, boiled, drained, without salt | 35 | 1,89 | 0,28 | 7,88 | 3,2 | Frutas y verduras |
| Arvejas (guisantes), crudas / Grüne Erbsen, roh | CIQUAL 20072 | Petits pois, crus | 81,2 | 5,42 | 0,4 | 11,4 | 5,1 | Frutas y verduras |
| Arvejas (guisantes), hervidas / Grüne Erbsen, gekocht | CIQUAL 20326 | Petits pois, bouillis/cuits à l'eau | 80,7 | 6,38 | 0,6 | 9,93 | 4,8 | Frutas y verduras |
| Arvejas chinas (tirabeques), crudas / Zuckerschoten, roh | CIQUAL 20173 | Pois mange-tout ou pois gourmand, cru | 43 | 2,8 | 0,2 | 6,2 | 2,6 | Frutas y verduras |
| Habas frescas (para desgranar), crudas / Dicke Bohnen, frisch, roh | CIQUAL 20517 | Fève à écosser, fraîche, crue | 61,5 | 6,76 | 0,67 | 4,2 | 5,85 | Frutas y verduras |
| Habas tiernas, cocidas (hervidas, sin sal) / Dicke Bohnen, frisch, gekocht, ohne Salz | USDA 170378 | Broadbeans, immature seeds, cooked, boiled, drained, without salt | 62 | 4,8 | 0,5 | 10,1 | 3,6 | Frutas y verduras |
| Quinchoncho tierno (guandú), crudo / Straucherbsen (Taubenerbsen), frisch, roh | CIQUAL 20527 | Pois d'Angole vert, frais, cru | 129 | 7,2 | 1,64 | 18,8 | 5,1 | Frutas y verduras |
| Quinchoncho tierno (guandú), cocido (hervido, sin sal) / Straucherbsen (Taubenerbsen), frisch, gekocht, ohne Salz | USDA 170430 | Pigeonpeas, immature seeds, cooked, boiled, drained, without salt | 111 | 5,96 | 1,36 | 19,49 | 4,2 | Frutas y verduras |
| Frijol tierno (caupí, ojo negro), crudo / Augenbohnen, frisch, roh | USDA 169220 | Cowpeas (blackeyes), immature seeds, raw | 90 | 2,95 | 0,35 | 18,83 | 5 | Frutas y verduras |
| Frijol tierno (caupí, ojo negro), cocido (hervido, sin sal) / Augenbohnen, frisch, gekocht, ohne Salz | USDA 168402 | Cowpeas (blackeyes), immature seeds, cooked, boiled, drained, without salt | 97 | 3,17 | 0,38 | 20,32 | 5 | Frutas y verduras |
| Jojoto amarillo (maíz tierno, mazorca), crudo / Gelber Zuckermais, roh | USDA 169998 | Corn, sweet, yellow, raw | 86 | 3,27 | 1,35 | 18,7 | 2 | Frutas y verduras |
| Jojoto (maíz dulce en mazorca), cocido / Zuckermais (Maiskolben), gekocht | CIQUAL 20049 | Maïs doux, en épis, cuit | 106 | 3,41 | 1,5 | 18,6 | 2,4 | Frutas y verduras |
| Jojoto blanco (maíz tierno, mazorca), crudo / Weißer Zuckermais, roh | USDA 168538 | Corn, sweet, white, raw | 86 | 3,22 | 1,18 | 19,02 | 2,7 | Frutas y verduras |
| Jojoto blanco (maíz tierno), cocido (hervido, sin sal) / Weißer Zuckermais, gekocht, ohne Salz | USDA 168539 | Corn, sweet, white, cooked, boiled, drained, without salt | 97 | 3,34 | 1,41 | 21,71 | 2,7 | Frutas y verduras |
| Maíz dulce en lata, escurrido / Zuckermais aus der Dose, abgetropft | CIQUAL 20066 | Maïs doux, appertisé, égoutté | 105 | 2,66 | 1,68 | 18,3 | 3,1 | Despensa |
| Brócoli, crudo / Brokkoli, roh | CIQUAL 20057 | Brocoli, cru | 31,9 | 2,9 | 0,36 | 2,15 | 2,6 | Frutas y verduras |
| Brócoli, hervido / Brokkoli, gekocht | CIQUAL 20350 | Brocoli, bouilli/cuit à l'eau (aliment moyen) | 21,8 | 2,19 | 0,5 | 1,03 | 3 | Frutas y verduras |
| Coliflor, cruda / Blumenkohl, roh | CIQUAL 20016 | Chou-fleur, cru | 24,9 | 1,81 | 0,7 | 2,13 | 2,2 | Frutas y verduras |
| Coliflor, hervida / Blumenkohl, gekocht | CIQUAL 20017 | Chou-fleur, bouilli/cuit à l'eau | 20,9 | 1,6 | 0,46 | 1,6 | 2 | Frutas y verduras |
| Repollitos de Bruselas, crudos / Rosenkohl, roh | CIQUAL 20058 | Chou de Bruxelles, cru | 43,9 | 3,38 | 0,3 | 4,59 | 3,8 | Frutas y verduras |
| Repollitos de Bruselas, cocidos (hervidos, sin sal) / Rosenkohl, gekocht, ohne Salz | USDA 169971 | Brussels sprouts, cooked, boiled, drained, without salt | 36 | 2,55 | 0,5 | 7,1 | 2,6 | Frutas y verduras |
| Repollo blanco (col), crudo / Weißkohl, roh | CIQUAL 20116 | Chou blanc, cru | 35,2 | 1,38 | 0,6 | 4,63 | 3,5 | Frutas y verduras |
| Repollo blanco (col), cocido (hervido, sin sal) / Weißkohl, gekocht, ohne Salz | USDA 169976 | Cabbage, cooked, boiled, drained, without salt | 23 | 1,27 | 0,06 | 5,51 | 1,9 | Frutas y verduras |
| Repollo morado (lombarda), crudo / Rotkohl, roh | USDA 169977 | Cabbage, red, raw | 31 | 1,43 | 0,16 | 7,37 | 2,1 | Frutas y verduras |
| Repollo morado (lombarda), hervido / Rotkohl, gekocht | CIQUAL 20095 | Chou rouge, bouilli/cuit à l'eau | 25,3 | 1,51 | 0,09 | 3,32 | 2,6 | Frutas y verduras |
| Col de Milán (repollo crespo), cruda / Wirsing, roh | USDA 170388 | Cabbage, savoy, raw | 27 | 2 | 0,1 | 6,1 | 3,1 | Frutas y verduras |
| Col de Milán, cocida (hervida, sin sal) / Wirsing, gekocht, ohne Salz | USDA 170389 | Cabbage, savoy, cooked, boiled, drained, without salt | 24 | 1,8 | 0,09 | 5,41 | 2,8 | Frutas y verduras |
| Col rizada (kale), cruda / Grünkohl, roh | CIQUAL 20218 | Chou frisé, cru | 49,5 | 4,28 | 0,93 | 4,2 | 3,6 | Frutas y verduras |
| Col rizada (kale), cocida / Grünkohl, gekocht | CIQUAL 20219 | Chou frisé, cuit | 29,7 | 1,9 | 0,4 | 3,63 | 2 | Frutas y verduras |
| Col china (repollo chino), cruda / Chinakohl, roh | CIQUAL 20167 | Chou chinois pé-tsaï, cru | 16,4 | 1,25 | 0,2 | 2,1 | 0,73 | Frutas y verduras |
| Pak choi (bok choy), crudo / Pak Choi, roh | CIQUAL 20340 | Chou chinois pak choï ou pak choy (feuilles vertes ressemblant à des blettes), cru | 14,6 | 1,5 | 0,2 | 1,2 | 1 | Frutas y verduras |
| Colinabo, crudo / Kohlrabi, roh | CIQUAL 20065 | Chou-rave, cru | 25,1 | 1,7 | 0,1 | 2,44 | 3,6 | Frutas y verduras |
| Colinabo, hervido / Kohlrabi, gekocht | CIQUAL 20094 | Chou-rave, bouilli/cuit à l'eau | 28 | 1,8 | 0,11 | 4,4 | 1,1 | Frutas y verduras |
| Chucrut, en conserva / Sauerkraut, aus der Dose | USDA 169279 | Sauerkraut, canned, solids and liquids | 19 | 0,91 | 0,14 | 4,28 | 2,9 | Despensa |
| Zanahoria, cruda / Karotte (Möhre), roh | USDA 170393 | Carrots, raw | 41 | 0,93 | 0,24 | 9,58 | 2,8 | Frutas y verduras |
| Zanahoria, cocida (hervida, sin sal) / Karotte (Möhre), gekocht, ohne Salz | USDA 170394 | Carrots, cooked, boiled, drained, without salt | 35 | 0,76 | 0,18 | 8,22 | 3 | Frutas y verduras |
| Remolacha (betabel), cruda / Rote Bete, roh | CIQUAL 20091 | Betterave rouge, crue | 40,2 | 1,61 | 0,17 | 6,34 | 2,8 | Frutas y verduras |
| Remolacha (betabel), cocida / Rote Bete, gekocht | CIQUAL 20003 | Betterave rouge, cuite | 41,5 | 1,44 | 0,4 | 7,13 | 2,5 | Frutas y verduras |
| Nabo sueco (rutabaga), crudo / Steckrübe, roh | CIQUAL 20201 | Rutabaga, cru | 33,2 | 1,08 | 0,16 | 5,7 | 2,3 | Frutas y verduras |
| Nabo sueco (rutabaga), cocido / Steckrübe, gekocht | CIQUAL 20165 | Rutabaga, cuit | 26 | 0,93 | 0,18 | 4,26 | 1,8 | Frutas y verduras |
| Nabo, pelado, crudo / Weiße Rübe (Speiserübe), geschält, roh | CIQUAL 20064 | Navet, pelé, cru | 25,6 | 0,9 | 0,1 | 4,39 | 1,8 | Frutas y verduras |
| Nabo, cocido (hervido, sin sal) / Weiße Rübe (Speiserübe), gekocht, ohne Salz | USDA 170058 | Turnips, cooked, boiled, drained, without salt | 22 | 0,71 | 0,08 | 5,06 | 2 | Frutas y verduras |
| Chirivía (pastinaca), cruda / Pastinake, roh | CIQUAL 20181 | Panais, cru | 67,9 | 1,2 | 0,3 | 12,6 | 4,9 | Frutas y verduras |
| Chirivía (pastinaca), cocida (hervida, sin sal) / Pastinake, gekocht, ohne Salz | USDA 170009 | Parsnips, cooked, boiled, drained, without salt | 71 | 1,32 | 0,3 | 17,01 | 3,6 | Frutas y verduras |
| Apionabo, crudo / Knollensellerie, roh | USDA 170400 | Celeriac, raw | 42 | 1,5 | 0,3 | 9,2 | 1,8 | Frutas y verduras |
| Apionabo, hervido / Knollensellerie, gekocht | CIQUAL 20315 | Céleri rave, bouilli/cuit à l'eau | 26,2 | 0,94 | 0,3 | 4,32 | 2,6 | Frutas y verduras |
| Apio España (apio de tallo), crudo / Staudensellerie, roh | USDA 169988 | Celery, raw | 14 | 0,69 | 0,17 | 2,97 | 1,6 | Frutas y verduras |
| Rábano (rabanito), crudo / Radieschen, roh | USDA 169276 | Radishes, raw | 16 | 0,68 | 0,1 | 3,4 | 1,6 | Frutas y verduras |
| Rábano blanco (daikon), crudo / Rettich (Daikon), roh | USDA 168451 | Radishes, oriental, raw | 18 | 0,6 | 0,1 | 4,1 | 1,6 | Frutas y verduras |
| Tupinambo, crudo / Topinambur, roh | CIQUAL 20196 | Topinambour, cru | 74,7 | 2 | 0,01 | 15,8 | 1,6 | Frutas y verduras |
| Hinojo (bulbo), crudo / Fenchel (Knolle), roh | USDA 169385 | Fennel, bulb, raw | 31 | 1,24 | 0,2 | 7,3 | 3,1 | Frutas y verduras |
| Alcachofa, cruda / Artischocke, roh | CIQUAL 20052 | Artichaut, cru | 45,4 | 3,27 | 0,15 | 4,84 | 5,4 | Frutas y verduras |
| Alcachofa, cocida / Artischocke, gekocht | CIQUAL 20000 | Artichaut, cuit | 33,2 | 2,53 | 0,28 | 0,99 | 8,3 | Frutas y verduras |
| Espárrago verde, crudo / Grüner Spargel, roh | CIQUAL 20279 | Asperge, verte, crue | 24,7 | 2,46 | 0,27 | 2,03 | 2,15 | Frutas y verduras |
| Espárrago verde, hervido / Grüner Spargel, gekocht | CIQUAL 20299 | Asperge verte, bouillie/cuite à l'eau | 25,3 | 2,69 | 0,3 | 1,73 | 2,2 | Frutas y verduras |
| Espárragos en lata, escurridos / Spargel aus der Dose, abgetropft | CIQUAL 20076 | Asperge, appertisée, égouttée | 20,3 | 1,57 | 0,65 | 1,2 | 1,55 | Despensa |
| Palmito en lata, escurrido / Palmherzen aus der Dose, abgetropft | CIQUAL 20018 | Coeur de palmier, appertisé, égoutté | 41,5 | 2,51 | 0,56 | 5,5 | 2,2 | Despensa |
| Hojas de parra en conserva / Weinblätter, eingelegt | USDA 169393 | Grape leaves, canned | 69 | 4,27 | 1,97 | 11,71 | 9,9 | Despensa |
| Nopal, crudo / Nopal (Kaktusblatt), roh | USDA 168571 | Nopales, raw | 16 | 1,32 | 0,09 | 3,33 | 2,2 | Frutas y verduras |
| Nopal, cocido (sin sal) / Nopal (Kaktusblatt), gekocht, ohne Salz | USDA 169388 | Nopales, cooked, without salt | 15 | 1,35 | 0,05 | 3,28 | 2 | Frutas y verduras |
| Espinaca, cruda / Spinat, roh | CIQUAL 20059 | Épinard, cru | 33,3 | 2,68 | 0,39 | 3,06 | 2,6 | Frutas y verduras |
| Espinaca, cocida (hervida, sin sal) / Spinat, gekocht, ohne Salz | USDA 168463 | Spinach, cooked, boiled, drained, without salt | 23 | 2,97 | 0,26 | 3,75 | 2,4 | Frutas y verduras |
| Acelga, cruda / Mangold, roh | USDA 169991 | Chard, swiss, raw | 19 | 1,8 | 0,2 | 3,74 | 1,6 | Frutas y verduras |
| Acelga (hoja y penca), hervida / Mangold, gekocht | CIQUAL 20301 | Bette ou blette, côte et feuille, bouillie/cuite à l'eau | 15,6 | 0,88 | 0,3 | 1,43 | 2,5 | Frutas y verduras |
| Lechuga iceberg (americana), cruda / Eisbergsalat, roh | CIQUAL 20200 | Laitue iceberg, crue | 17,3 | 0,95 | 0,14 | 2,5 | 1,1 | Frutas y verduras |
| Lechuga romana, cruda / Römersalat, roh | CIQUAL 20171 | Laitue romaine, crue | 17,2 | 1,23 | 0,3 | 1,35 | 2,1 | Frutas y verduras |
| Lechuga, cruda / Kopfsalat, roh | CIQUAL 20031 | Laitue, crue | 14,7 | 1,35 | 0,2 | 1,22 | 1,1 | Frutas y verduras |
| Lechuga de hoja verde, cruda / Grüner Blattsalat, roh | USDA 169249 | Lettuce, green leaf, raw | 15 | 1,36 | 0,15 | 2,87 | 1,3 | Frutas y verduras |
| Lechuga de hoja roja, cruda / Roter Blattsalat, roh | USDA 168431 | Lettuce, red leaf, raw | 13 | 1,33 | 0,22 | 2,26 | 0,9 | Frutas y verduras |
| Rúcula (rúgula), cruda / Rucola, roh | CIQUAL 20217 | Roquette, crue | 27,9 | 2,58 | 0,66 | 2,1 | 1,6 | Frutas y verduras |
| Canónigos, crudos / Feldsalat, roh | USDA 169219 | Cornsalad, raw | 21 | 2 | 0,4 | 3,6 | — | Frutas y verduras |
| Escarola, cruda / Endivie (Escariol), roh | CIQUAL 20090 | Scarole, crue | 20,5 | 1,44 | 0,23 | 2 | 2,3 | Frutas y verduras |
| Endibia belga, cruda / Chicorée, roh | USDA 170404 | Chicory, witloof, raw | 17 | 0,9 | 0,1 | 4 | 3,1 | Frutas y verduras |
| Radicchio (achicoria roja), crudo / Radicchio, roh | CIQUAL 20162 | Chicorée rouge, crue | 18,9 | 1,4 | 0,1 | 1,6 | 3 | Frutas y verduras |
| Berro, crudo / Brunnenkresse, roh | CIQUAL 20022 | Cresson de fontaine, cru | 15,5 | 2,3 | 0,1 | 1,11 | 0,5 | Frutas y verduras |
| Mastuerzo (berro de jardín), crudo / Gartenkresse, roh | CIQUAL 20199 | Cresson alénois, cru | 23,8 | 2,6 | 0,7 | 1,22 | 1,1 | Frutas y verduras |
| Germinados de frijol mungo (brotes de soja), crudos / Mungobohnensprossen (Sojasprossen), roh | USDA 169957 | Mung beans, mature seeds, sprouted, raw | 30 | 3,04 | 0,18 | 5,94 | 1,8 | Frutas y verduras |
| Cilantro, fresco / Koriander, frisch | CIQUAL 11094 | Coriandre, fraiche | 22,3 | 2,13 | 0,52 | 0,87 | 2,8 | Frutas y verduras |
| Perejil, fresco / Petersilie, frisch | CIQUAL 11014 | Persil, frais | 42,5 | 2,97 | 0,63 | 4,1 | 4,3 | Frutas y verduras |
| Albahaca, fresca / Basilikum, frisch | CIQUAL 11033 | Basilic, frais | 35,2 | 3,15 | 0,64 | 3,4 | 1,6 | Frutas y verduras |
| Eneldo, fresco / Dill, frisch | CIQUAL 11093 | Aneth, frais | 48,2 | 3,93 | 1,1 | 3,9 | 3,5 | Frutas y verduras |
| Menta (hierbabuena), fresca / Minze, frisch | CIQUAL 11027 | Menthe, fraîche | 57,6 | 3,52 | 0,84 | 5,3 | 7,4 | Frutas y verduras |
| Menta piperita, fresca / Pfefferminze, frisch | USDA 173474 | Peppermint, fresh | 70 | 3,75 | 0,94 | 14,89 | 8 | Frutas y verduras |
| Tomillo, fresco / Thymian, frisch | CIQUAL 11070 | Thym, frais | 107 | 5,56 | 1,68 | 10,5 | 14 | Frutas y verduras |
| Romero, fresco / Rosmarin, frisch | CIQUAL 11068 | Romarin, frais | 121 | 3,31 | 5,86 | 6,6 | 14,1 | Frutas y verduras |
| Champiñones blancos, crudos / Weiße Champignons, roh | CIQUAL 20056 | Champignon de Paris ou champignon de couche, cru | 21 | 2,11 | 0,36 | 1,83 | 1 | Frutas y verduras |
| Champiñones blancos, hervidos / Weiße Champignons, gekocht | CIQUAL 20102 | Champignon de Paris ou champignon de couche, bouilli/cuit à l'eau | 28,7 | 2,17 | 0,47 | 3 | 2,2 | Frutas y verduras |
| Champiñones en lata, escurridos / Champignons aus der Dose, abgetropft | CIQUAL 20079 | Champignon de Paris ou champignon de couche, appertisé, égoutté | 18,3 | 2 | 0,37 | 0,64 | 2,5 | Despensa |
| Champiñones marrones (crimini), crudos / Braune Champignons, roh | USDA 168434 | Mushrooms, brown, italian, or crimini, raw | 22 | 2,5 | 0,1 | 4,3 | 0,6 | Frutas y verduras |
| Portobello, crudo / Portobello (Riesenchampignon), roh | USDA 169255 | Mushrooms, portabella, raw | 22 | 2,11 | 0,35 | 3,87 | 1,3 | Frutas y verduras |
| Shiitake, crudo / Shiitake, roh | USDA 169242 | Mushrooms, shiitake, raw | 34 | 2,24 | 0,49 | 6,79 | 2,5 | Frutas y verduras |
| Setas de ostra (gírgolas), crudas / Austernpilze, roh | CIQUAL 20114 | Champignon, pleurote, crue | 26,8 | 3,31 | 0,41 | 1,5 | 2,3 | Frutas y verduras |
| Rebozuelos, crudos / Pfifferlinge, roh | CIQUAL 20103 | Champignon, chanterelle ou girolle, crue | 24,7 | 1,49 | 0,53 | 1,77 | 3,8 | Frutas y verduras |
| Papa (patata) pelada, cruda / Kartoffel, geschält, roh | CIQUAL 4008 | Pomme de terre, sans peau, crue | 80 | 2,02 | 0,09 | 16,2 | 2,2 | Frutas y verduras |
| Papa (patata), hervida / Kartoffel, gekocht | CIQUAL 4003 | Pomme de terre, bouillie/cuite à l'eau | 81 | 1,8 | 0,34 | 16,8 | 1,8 | Frutas y verduras |
| Papa (patata) hervida con piel, solo pulpa, sin sal / Pellkartoffel, nur Fruchtfleisch, ohne Salz | USDA 170438 | Potatoes, boiled, cooked in skin, flesh, without salt | 87 | 1,87 | 0,1 | 20,13 | 1,8 | Frutas y verduras |
| Papa (patata) asada al horno, con piel, sin sal / Ofenkartoffel mit Schale, ohne Salz | USDA 170093 | Potatoes, baked, flesh and skin, without salt | 93 | 2,5 | 0,13 | 21,15 | 2,2 | Frutas y verduras |
| Batata (boniato, camote), cruda / Süßkartoffel, roh | CIQUAL 4101 | Patate douce, crue | 81,2 | 1,57 | 0,05 | 17,1 | 3 | Frutas y verduras |
| Batata (boniato, camote), cocida / Süßkartoffel, gekocht | CIQUAL 4102 | Patate douce, cuite | 79,1 | 1,69 | 0,15 | 16,3 | 2,9 | Frutas y verduras |
| Batata (boniato, camote), asada al horno, pulpa, sin sal / Süßkartoffel, im Ofen gebacken, Fruchtfleisch, ohne Salz | USDA 168483 | Sweet potato, cooked, baked in skin, flesh, without salt | 90 | 2,01 | 0,15 | 20,71 | 3,3 | Frutas y verduras |
| Yuca (mandioca), cruda / Maniok (Cassava), roh | CIQUAL 54031 | Manioc, racine crue | 157 | 1,36 | 0,28 | 36,3 | 1,8 | Frutas y verduras |
| Ñame, pelado, crudo / Yamswurzel, geschält, roh | CIQUAL 53502 | Igname, pelée, crue | 111 | 1,53 | 0,17 | 23,7 | 4,1 | Frutas y verduras |
| Ñame, pelado, hervido / Yamswurzel, geschält, gekocht | CIQUAL 53503 | Igname, épluchée, bouillie/cuite à l'eau | 109 | 1,49 | 0,14 | 23,6 | 3,9 | Frutas y verduras |
| Ocumo (yautía, malanga), crudo / Tannia (Malanga), roh | USDA 169401 | Yautia (tannier), raw | 98 | 1,46 | 0,4 | 23,63 | 1,5 | Frutas y verduras |
| Ocumo chino (taro), crudo / Taro, roh | CIQUAL 53200 | Taro, tubercule, cru | 105 | 1,5 | 0,2 | 22,4 | 4,1 | Frutas y verduras |
| Ocumo chino (taro), cocido / Taro, gekocht | CIQUAL 53201 | Taro, tubercule, cuit | 131 | 0,52 | 0,11 | 29,5 | 5,1 | Frutas y verduras |
| Cebolla morada, cruda / Rote Zwiebel, roh | CIQUAL 20238 | Oignon rouge, cru | 35 | 1,31 | 0,4 | 5,63 | 2,5 | Frutas y verduras |
| Pepinillos agridulces / Gewürzgurken, süß-sauer | CIQUAL 11097 | Cornichon, aigre-doux | 36 | 1,25 | 0,35 | 5 | 1,5 | Despensa |
| Calabaza Hokkaido (potimarrón), cruda / Hokkaido-Kürbis, roh | CIQUAL 20132 | Potimarron, chair sans peau, cru | 22,1 | 0,95 | 0,28 | 3,1 | 1,7 | Frutas y verduras |
| Calabaza Hokkaido (potimarrón), hervida / Hokkaido-Kürbis, gekocht | CIQUAL 20331 | Potimarron, chair sans peau, bouilli/cuit à l'eau | 38,6 | 1,06 | 0,3 | 6,88 | 1,8 | Frutas y verduras |
| Espárrago blanco, pelado, crudo / Weißer Spargel, geschält, roh | CIQUAL 20282 | Asperge, blanche ou violette, pelée, crue | 21 | 2,2 | 0,12 | 1,62 | 2,1 | Frutas y verduras |
| Espárrago blanco, hervido / Weißer Spargel, gekocht | CIQUAL 20277 | Asperge blanche, bouillie/cuite à l'eau | 17,3 | 1,44 | 0,3 | 1,63 | 1,3 | Frutas y verduras |
| Yuca (mandioca), cocida / Maniok (Cassava), gekocht | CIQUAL 54034 | Manioc, racine cuite | 135 | 0,69 | 0,043 | 32,8 | 0,4 | Frutas y verduras |
