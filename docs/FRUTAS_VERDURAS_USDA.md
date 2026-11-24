# Frutas, verduras y hortalizas (USDA SR28)

> Archivo generado por `tool/semilla/generar_frutas_verduras.py`. No editar a mano.

`assets/semilla/frutas_verduras_usda.json` contiene **222 alimentos** en formato `cal_counter/repertorio` v1. Se carga junto al catálogo base en la bienvenida y se puede añadir en cualquier momento desde *Datos y respaldos → Catálogos incluidos → Añadir frutas y verduras* (o importando el archivo). Importarlo de nuevo no duplica nada: cada alimento tiene un uuid v5 fijo derivado de su número NDB (`uuid5(NAMESPACE_URL, "cal_counter/usda-sr28/<NDB>")`).

## Fuente

U.S. Department of Agriculture, Agricultural Research Service, Nutrient Data Laboratory. *USDA National Nutrient Database for Standard Reference, Release 28* (septiembre de 2015, revisado en mayo de 2016). Dominio público.

- **Ningún valor se ha escrito a mano ni estimado.** El script lee cada nutriente y cada peso de porción de los archivos oficiales por su número NDB. Si la fuente no publica un dato, el campo queda **vacío** (nunca 0) y la nota del alimento lo dice («Sin dato en la fuente: …»).
- Los servidores de USDA no eran accesibles desde el entorno en que se generó, así que el script usa dos redistribuciones independientes de los archivos de SR28 (PyPI `django-usda-nutrition` 0.2.0 con los ASCII completos y npm `fda-nutrient-database` 1.0.2 con ABBREV), con sha256 fijado, y exige que coincidan: los 67.454 valores de los 8 nutrientes usados son idénticos en ambas copias para los 8.789 alimentos de SR28.
- **Cómo contrastar un valor**: buscar el número NDB (o la descripción en inglés) en [FoodData Central](https://fdc.nal.usda.gov/) (tipo de datos *SR Legacy*, que es la edición final de SR, de 2018). Cada alimento lleva en su nota el NDB y la descripción original.

## Criterios

- **Valores por 100 g de parte comestible**, unidad `g`.
- **Carbohidratos totales por diferencia: incluyen la fibra** (criterio de USDA). Las etiquetas de la UE declaran los carbohidratos *sin* la fibra, así que estos valores son mayores que los de una etiqueta europea del mismo alimento en la cantidad de fibra. No se ha restado la fibra para no publicar un número que no está en la fuente.
- **Sal = sodio × 2,5** (Reglamento (UE) 1169/2011, anexo I). Es la única conversión aplicada; si la fuente no da sodio, la sal queda vacía.
- Energía: kcal publicadas por USDA. Grasas saturadas, azúcares totales y fibra dietética total, tal cual.
- **Porciones**: medidas caseras de USDA (`WEIGHT.txt`), solo las de unidades (pieza, diente, tallo, hoja, mazorca, cucharada…). Los gramos son de la parte comestible; las pulgadas se han pasado a centímetros (1" = 2,54 cm) en el nombre. El script comprueba que cada porción elegida tiene exactamente la descripción esperada en la fuente.
- **Nombre en español y en alemán** en el mismo campo («Manzana con piel, cruda / Apfel mit Schale, roh»), para buscar en cualquiera de los dos idiomas. La búsqueda ignora tildes y diéresis, y trata «ß» como «ss» («Weißkohl» = «Weisskohl»).
- Categorías: *Frutas y verduras* (frescos) y *Despensa* (conservas, frutas secas y deshidratados).

## No incluidos por no estar en la fuente

SR28 no tiene datos de estos alimentos (o solo en forma de néctar, almíbar o mezcla), así que no se incluyen: ají dulce, tomate de árbol, curuba, granadilla dulce, arracacha (apio criollo), mapuey, mamón, merey (fruto), pitahaya, borojó, mangostino fresco, espárrago blanco como entrada propia y calabaza Hokkaido. Se pueden añadir a mano con los datos de una etiqueta o de otra tabla oficial.

## Lista

| Alimento | NDB | Descripción USDA | kcal | Prot. | Grasas | Carb. | Fibra | Categoría |
|---|---|---|---:|---:|---:|---:|---:|---|
| Manzana con piel, cruda / Apfel mit Schale, roh | 09003 | Apples, raw, with skin | 52 | 0,26 | 0,17 | 13,81 | 2,4 | Frutas y verduras |
| Manzana sin piel, cruda / Apfel ohne Schale, roh | 09004 | Apples, raw, without skin | 48 | 0,27 | 0,13 | 12,76 | 1,3 | Frutas y verduras |
| Pera, cruda / Birne, roh | 09252 | Pears, raw | 57 | 0,36 | 0,14 | 15,23 | 3,1 | Frutas y verduras |
| Cambur (banano, banana), crudo / Banane, roh | 09040 | Bananas, raw | 89 | 1,09 | 0,33 | 22,84 | 2,6 | Frutas y verduras |
| Naranja, cruda / Orange (Apfelsine), roh | 09200 | Oranges, raw, all commercial varieties | 47 | 0,94 | 0,12 | 11,75 | 2,4 | Frutas y verduras |
| Jugo de naranja natural (recién exprimido) / Orangensaft, frisch gepresst | 09206 | Orange juice, raw | 45 | 0,7 | 0,2 | 10,4 | 0,2 | Frutas y verduras |
| Mandarina, cruda / Mandarine, roh | 09218 | Tangerines, (mandarin oranges), raw | 53 | 0,81 | 0,31 | 13,34 | 1,8 | Frutas y verduras |
| Clementina, cruda / Clementine, roh | 09433 | Clementines, raw | 47 | 0,85 | 0,15 | 12,02 | 1,7 | Frutas y verduras |
| Toronja (pomelo), cruda / Grapefruit, roh | 09111 | Grapefruit, raw, pink and red and white, all areas | 32 | 0,63 | 0,1 | 8,08 | 1,1 | Frutas y verduras |
| Limón amarillo, sin cáscara, crudo / Zitrone, ohne Schale, roh | 09150 | Lemons, raw, without peel | 29 | 1,1 | 0,3 | 9,32 | 2,8 | Frutas y verduras |
| Jugo de limón amarillo, natural / Zitronensaft, frisch gepresst | 09152 | Lemon juice, raw | 22 | 0,35 | 0,24 | 6,9 | 0,3 | Frutas y verduras |
| Lima ácida (limón verde), cruda / Limette, roh | 09159 | Limes, raw | 30 | 0,7 | 0,2 | 10,54 | 2,8 | Frutas y verduras |
| Jugo de lima ácida (limón verde), natural / Limettensaft, frisch gepresst | 09160 | Lime juice, raw | 25 | 0,42 | 0,07 | 8,42 | 0,4 | Frutas y verduras |
| Uvas rojas o verdes (tipo europeo), crudas / Weintrauben, rot oder grün, roh | 09132 | Grapes, red or green (European type, such as Thompson seedless), raw | 69 | 0,72 | 0,16 | 18,1 | 0,9 | Frutas y verduras |
| Fresas (frutillas), crudas / Erdbeeren, roh | 09316 | Strawberries, raw | 32 | 0,67 | 0,3 | 7,68 | 2 | Frutas y verduras |
| Arándanos, crudos / Heidelbeeren (Blaubeeren), roh | 09050 | Blueberries, raw | 57 | 0,74 | 0,33 | 14,49 | 2,4 | Frutas y verduras |
| Frambuesas, crudas / Himbeeren, roh | 09302 | Raspberries, raw | 52 | 1,2 | 0,65 | 11,94 | 6,5 | Frutas y verduras |
| Moras (zarzamoras), crudas / Brombeeren, roh | 09042 | Blackberries, raw | 43 | 1,39 | 0,49 | 9,61 | 5,3 | Frutas y verduras |
| Grosellas rojas y blancas, crudas / Rote und weiße Johannisbeeren, roh | 09084 | Currants, red and white, raw | 56 | 1,4 | 0,2 | 13,8 | 4,3 | Frutas y verduras |
| Grosellas negras (casis), crudas / Schwarze Johannisbeeren, roh | 09083 | Currants, european black, raw | 63 | 1,4 | 0,41 | 15,38 | — | Frutas y verduras |
| Grosellas espinosas (uva espina), crudas / Stachelbeeren, roh | 09107 | Gooseberries, raw | 44 | 0,88 | 0,58 | 10,18 | 4,3 | Frutas y verduras |
| Cerezas dulces, crudas / Süßkirschen, roh | 09070 | Cherries, sweet, raw | 63 | 1,06 | 0,2 | 16,01 | 2,1 | Frutas y verduras |
| Guindas (cerezas ácidas), crudas / Sauerkirschen, roh | 09063 | Cherries, sour, red, raw | 50 | 1 | 0,3 | 12,18 | 1,6 | Frutas y verduras |
| Ciruelas, crudas / Pflaumen, roh | 09279 | Plums, raw | 46 | 0,7 | 0,28 | 11,42 | 1,4 | Frutas y verduras |
| Albaricoques (damascos), crudos / Aprikosen, roh | 09021 | Apricots, raw | 48 | 1,4 | 0,39 | 11,12 | 2 | Frutas y verduras |
| Durazno amarillo (melocotón), crudo / Gelber Pfirsich, roh | 09236 | Peaches, yellow, raw | 39 | 0,91 | 0,25 | 9,54 | 1,5 | Frutas y verduras |
| Nectarina, cruda / Nektarine, roh | 09191 | Nectarines, raw | 44 | 1,06 | 0,32 | 10,55 | 1,7 | Frutas y verduras |
| Higos, crudos / Feigen, roh | 09089 | Figs, raw | 74 | 0,75 | 0,3 | 19,18 | 2,9 | Frutas y verduras |
| Granada, cruda / Granatapfel, roh | 09286 | Pomegranates, raw | 83 | 1,67 | 1,17 | 18,7 | 4 | Frutas y verduras |
| Caqui (kaki, persimón), crudo / Kaki (Persimone), roh | 09263 | Persimmons, japanese, raw | 70 | 0,58 | 0,19 | 18,59 | 3,6 | Frutas y verduras |
| Membrillo, crudo / Quitte, roh | 09296 | Quinces, raw | 57 | 0,4 | 0,1 | 15,3 | 1,9 | Frutas y verduras |
| Kiwi verde, crudo / Grüne Kiwi, roh | 09148 | Kiwifruit, green, raw | 61 | 1,14 | 0,52 | 14,66 | 3 | Frutas y verduras |
| Ruibarbo, crudo / Rhabarber, roh | 09307 | Rhubarb, raw | 21 | 0,9 | 0,2 | 4,54 | 1,8 | Frutas y verduras |
| Patilla (sandía), cruda / Wassermelone, roh | 09326 | Watermelon, raw | 30 | 0,61 | 0,15 | 7,55 | 0,4 | Frutas y verduras |
| Melón cantalupo, crudo / Cantaloupe-Melone, roh | 09181 | Melons, cantaloupe, raw | 34 | 0,84 | 0,19 | 8,16 | 0,9 | Frutas y verduras |
| Melón verde (honeydew), crudo / Honigmelone, roh | 09184 | Melons, honeydew, raw | 36 | 0,54 | 0,14 | 9,09 | 0,8 | Frutas y verduras |
| Piña (ananá), cruda / Ananas, roh | 09266 | Pineapple, raw, all varieties | 50 | 0,54 | 0,12 | 13,12 | 1,4 | Frutas y verduras |
| Mango, crudo / Mango, roh | 09176 | Mangos, raw | 60 | 0,82 | 0,38 | 14,98 | 1,6 | Frutas y verduras |
| Lechoza (papaya), cruda / Papaya, roh | 09226 | Papayas, raw | 43 | 0,47 | 0,26 | 10,82 | 1,7 | Frutas y verduras |
| Aguacate (palta), crudo, promedio de variedades comerciales / Avocado, roh, Durchschnitt der Handelssorten | 09037 | Avocados, raw, all commercial varieties | 160 | 2 | 14,66 | 8,53 | 6,7 | Frutas y verduras |
| Aguacate de California (palta), crudo / Avocado aus Kalifornien, roh | 09038 | Avocados, raw, California | 167 | 1,96 | 15,41 | 8,64 | 6,8 | Frutas y verduras |
| Aguacate de Florida (palta), crudo / Avocado aus Florida, roh | 09039 | Avocados, raw, Florida | 120 | 2,23 | 10,06 | 7,82 | 5,6 | Frutas y verduras |
| Coco, pulpa cruda / Kokosnuss, Fruchtfleisch, roh | 12104 | Nuts, coconut meat, raw | 354 | 3,33 | 33,49 | 15,23 | 9 | Frutas y verduras |
| Agua de coco / Kokoswasser | 12119 | Nuts, coconut water (liquid from coconuts) | 19 | 0,72 | 0,2 | 3,71 | 1,1 | Frutas y verduras |
| Guayaba, cruda / Guave, roh | 09139 | Guavas, common, raw | 68 | 2,55 | 0,95 | 14,32 | 5,4 | Frutas y verduras |
| Guanábana, cruda / Stachelannone (Guanábana), roh | 09315 | Soursop, raw | 66 | 1 | 0,3 | 16,84 | 3,3 | Frutas y verduras |
| Chirimoya, cruda / Cherimoya, roh | 09062 | Cherimoya, raw | 75 | 1,57 | 0,68 | 17,71 | 3 | Frutas y verduras |
| Anón (saramuyo), crudo / Zimtapfel, roh | 09321 | Sugar-apples, (sweetsop), raw | 94 | 2,06 | 0,29 | 23,64 | 4,4 | Frutas y verduras |
| Maracuyá morado (gulupa, parchita morada), crudo / Violette Passionsfrucht, roh | 09231 | Passion-fruit, (granadilla), purple, raw | 97 | 2,2 | 0,7 | 23,38 | 10,4 | Frutas y verduras |
| Jugo de maracuyá amarillo (parchita), natural / Saft der gelben Maracuja, frisch | 09233 | Passion-fruit juice, yellow, raw | 60 | 0,67 | 0,18 | 14,45 | 0,2 | Frutas y verduras |
| Mamey, crudo / Mammiapfel (Mamey), roh | 09175 | Mammy-apple, (mamey), raw | 51 | 0,5 | 0,5 | 12,5 | 3 | Frutas y verduras |
| Zapote (mamey colorado), crudo / Mamey-Sapote, roh | 09314 | Sapote, mamey, raw | 124 | 1,45 | 0,46 | 32,1 | 5,4 | Frutas y verduras |
| Níspero (sapodilla, zapote chico), crudo / Sapotille (Breiapfel), roh | 09313 | Sapodilla, raw | 83 | 0,44 | 1,1 | 19,96 | 5,3 | Frutas y verduras |
| Níspero del Japón (níspero de España), crudo / Japanische Wollmispel (Loquat), roh | 09174 | Loquats, raw | 47 | 0,43 | 0,2 | 12,14 | 1,7 | Frutas y verduras |
| Tamarindo, crudo / Tamarinde, roh | 09322 | Tamarinds, raw | 239 | 2,8 | 0,6 | 62,5 | 5,1 | Frutas y verduras |
| Uchuva (aguaymanto, physalis), cruda / Physalis (Kapstachelbeere), roh | 09138 | Groundcherries, (cape-gooseberries or poha), raw | 53 | 1,9 | 0,7 | 11,2 | — | Frutas y verduras |
| Lulo (naranjilla), pulpa congelada sin azúcar / Lulo (Naranjilla), Fruchtmark, tiefgekühlt, ungesüßt | 09450 | Naranjilla (lulo) pulp, frozen, unsweetened | 25 | 0,44 | 0,22 | 5,9 | 1,1 | Frutas y verduras |
| Carambola (fruta estrella), cruda / Karambole (Sternfrucht), roh | 09060 | Carambola, (starfruit), raw | 31 | 1,04 | 0,33 | 6,73 | 2,8 | Frutas y verduras |
| Semeruco (acerola), crudo / Acerola, roh | 09001 | Acerola, (west indian cherry), raw | 32 | 0,4 | 0,3 | 7,69 | 1,1 | Frutas y verduras |
| Pomarrosa, cruda / Rosenapfel, roh | 09312 | Rose-apples, raw | 25 | 0,6 | 0,3 | 5,7 | — | Frutas y verduras |
| Feijoa, cruda / Feijoa (Ananasguave), roh | 09334 | Feijoa, raw | 61 | 0,71 | 0,42 | 15,21 | 6,4 | Frutas y verduras |
| Nance (chaparro manteco), congelado sin azúcar / Nance, tiefgekühlt, ungesüßt | 09449 | Nance, frozen, unsweetened | 73 | 0,66 | 1,16 | 16,97 | 7,5 | Frutas y verduras |
| Tuna (higo chumbo), cruda / Kaktusfeige, roh | 09287 | Prickly pears, raw | 41 | 0,73 | 0,51 | 9,57 | 3,6 | Frutas y verduras |
| Plátano macho (plátano para cocinar), crudo / Kochbanane, roh | 09277 | Plantains, raw | 122 | 1,3 | 0,37 | 31,89 | 2,3 | Frutas y verduras |
| Plátano macho, cocido / Kochbanane, gekocht | 09278 | Plantains, cooked | 116 | 0,79 | 0,18 | 31,15 | 2,3 | Frutas y verduras |
| Tostones o patacones (plátano verde frito) / Frittierte grüne Kochbanane (Tostones) | 09446 | Plantains, green, fried | 309 | 1,5 | 11,81 | 49,17 | 3,5 | Frutas y verduras |
| Plátano maduro frito (tajadas), de restaurante latino / Frittierte reife Kochbanane (Latino-Restaurant) | 09447 | Plantains, yellow, fried, Latino restaurant | 236 | 1,42 | 7,51 | 40,77 | 3,2 | Frutas y verduras |
| Uvas pasas sin semillas / Rosinen, kernlos | 09298 | Raisins, seedless | 299 | 3,07 | 0,46 | 79,18 | 3,7 | Despensa |
| Ciruelas pasas (secas) / Trockenpflaumen | 09291 | Plums, dried (prunes), uncooked | 240 | 2,18 | 0,38 | 63,88 | 7,1 | Despensa |
| Orejones de albaricoque (secos) / Getrocknete Aprikosen | 09032 | Apricots, dried, sulfured, uncooked | 241 | 3,39 | 0,51 | 62,64 | 7,3 | Despensa |
| Higos secos / Getrocknete Feigen | 09094 | Figs, dried, uncooked | 249 | 3,3 | 0,93 | 63,87 | 9,8 | Despensa |
| Dátiles Deglet Noor / Datteln, Deglet Noor | 09087 | Dates, deglet noor | 282 | 2,45 | 0,39 | 75,03 | 8 | Despensa |
| Dátiles Medjool / Datteln, Medjool | 09421 | Dates, medjool | 277 | 1,81 | 0,15 | 74,97 | 6,7 | Despensa |
| Arándanos rojos deshidratados, endulzados / Cranberries, getrocknet, gesüßt | 09079 | Cranberries, dried, sweetened | 308 | 0,17 | 1,09 | 82,8 | 5,3 | Despensa |
| Mango deshidratado, endulzado / Mango, getrocknet, gesüßt | 09178 | Mango, dried, sweetened | 319 | 2,45 | 1,18 | 78,58 | 2,4 | Despensa |
| Aceitunas negras maduras, en lata / Schwarze Oliven, reif, aus der Dose | 09193 | Olives, ripe, canned (small-extra large) | 115 | 0,84 | 10,68 | 6,26 | 3,2 | Despensa |
| Aceitunas verdes, encurtidas, en conserva / Grüne Oliven, eingelegt | 09195 | Olives, pickled, canned or bottled, green | 145 | 1,03 | 15,32 | 3,84 | 3,3 | Despensa |
| Alcaparras, en conserva / Kapern, eingelegt | 02054 | Capers, canned | 23 | 2,36 | 0,86 | 4,89 | 3,2 | Despensa |
| Tomate rojo maduro, crudo / Tomate, rot, reif, roh | 11529 | Tomatoes, red, ripe, raw, year round average | 18 | 0,88 | 0,2 | 3,89 | 1,2 | Frutas y verduras |
| Tomate en lata, en su jugo / Tomaten aus der Dose, in Tomatensaft | 11531 | Tomatoes, red, ripe, canned, packed in tomato juice | 16 | 0,79 | 0,25 | 3,47 | 1,9 | Despensa |
| Tomate triturado, en lata / Tomaten, zerkleinert, aus der Dose | 11693 | Tomatoes, crushed, canned | 32 | 1,64 | 0,28 | 7,29 | 1,9 | Despensa |
| Pasta de tomate (concentrado), sin sal añadida / Tomatenmark, ohne Salzzusatz | 11546 | Tomato products, canned, paste, without salt added | 82 | 4,32 | 0,47 | 18,91 | 4,1 | Despensa |
| Puré de tomate en lata, sin sal añadida / Tomatenpüree aus der Dose, ohne Salzzusatz | 11547 | Tomato products, canned, puree, without salt added | 38 | 1,65 | 0,21 | 8,98 | 1,9 | Despensa |
| Tomates secos (deshidratados) / Getrocknete Tomaten | 11955 | Tomatoes, sun-dried | 258 | 14,11 | 2,97 | 55,76 | 12,3 | Despensa |
| Tomates secos en aceite, escurridos / Getrocknete Tomaten in Öl, abgetropft | 11956 | Tomatoes, sun-dried, packed in oil, drained | 213 | 5,06 | 14,08 | 23,33 | 5,8 | Despensa |
| Cebolla, cruda / Zwiebel, roh | 11282 | Onions, raw | 40 | 1,1 | 0,1 | 9,34 | 1,7 | Frutas y verduras |
| Cebolla, cocida (hervida, sin sal) / Zwiebel, gekocht, ohne Salz | 11283 | Onions, cooked, boiled, drained, without salt | 44 | 1,36 | 0,19 | 10,15 | 1,4 | Frutas y verduras |
| Chalota, cruda / Schalotte, roh | 11677 | Shallots, raw | 72 | 2,5 | 0,1 | 16,8 | 3,2 | Frutas y verduras |
| Cebollín (cebolla larga, cebolleta), crudo / Frühlingszwiebel, roh | 11291 | Onions, spring or scallions (includes tops and bulb), raw | 32 | 1,83 | 0,19 | 7,34 | 2,6 | Frutas y verduras |
| Cebollino (ciboulette), crudo / Schnittlauch, roh | 11156 | Chives, raw | 30 | 3,27 | 0,73 | 4,35 | 2,5 | Frutas y verduras |
| Ajoporro (puerro), crudo / Lauch (Porree), roh | 11246 | Leeks, (bulb and lower leaf-portion), raw | 61 | 1,5 | 0,3 | 14,15 | 1,8 | Frutas y verduras |
| Ajoporro (puerro), cocido (hervido, sin sal) / Lauch (Porree), gekocht, ohne Salz | 11247 | Leeks, (bulb and lower leaf-portion), cooked, boiled, drained, without salt | 31 | 0,81 | 0,2 | 7,62 | 1 | Frutas y verduras |
| Ajo, crudo / Knoblauch, roh | 11215 | Garlic, raw | 149 | 6,36 | 0,5 | 33,06 | 2,1 | Frutas y verduras |
| Jengibre, raíz cruda / Ingwer, roh | 11216 | Ginger root, raw | 80 | 1,82 | 0,75 | 17,77 | 2 | Frutas y verduras |
| Pepino con piel, crudo / Gurke mit Schale, roh | 11205 | Cucumber, with peel, raw | 15 | 0,65 | 0,11 | 3,63 | 0,5 | Frutas y verduras |
| Pepino pelado, crudo / Gurke, geschält, roh | 11206 | Cucumber, peeled, raw | 12 | 0,59 | 0,16 | 2,16 | 0,7 | Frutas y verduras |
| Pepinillos encurtidos al eneldo / Dillgurken, eingelegt | 11937 | Pickles, cucumber, dill or kosher dill | 12 | 0,5 | 0,3 | 2,41 | 1 | Despensa |
| Calabacín (zucchini), crudo / Zucchini, roh | 11477 | Squash, summer, zucchini, includes skin, raw | 17 | 1,21 | 0,32 | 3,11 | 1 | Frutas y verduras |
| Calabacín (zucchini), cocido (hervido, sin sal) / Zucchini, gekocht, ohne Salz | 11478 | Squash, summer, zucchini, includes skin, cooked, boiled, drained, without salt | 15 | 1,14 | 0,36 | 2,69 | 1 | Frutas y verduras |
| Berenjena, cruda / Aubergine, roh | 11209 | Eggplant, raw | 25 | 0,98 | 0,18 | 5,88 | 3 | Frutas y verduras |
| Berenjena, cocida (hervida, sin sal) / Aubergine, gekocht, ohne Salz | 11210 | Eggplant, cooked, boiled, drained, without salt | 35 | 0,83 | 0,23 | 8,73 | 2,5 | Frutas y verduras |
| Pimentón verde (pimiento verde), crudo / Grüne Paprika, roh | 11333 | Peppers, sweet, green, raw | 20 | 0,86 | 0,17 | 4,64 | 1,7 | Frutas y verduras |
| Pimentón rojo (pimiento rojo), crudo / Rote Paprika, roh | 11821 | Peppers, sweet, red, raw | 31 | 0,99 | 0,3 | 6,03 | 2,1 | Frutas y verduras |
| Pimentón amarillo (pimiento amarillo), crudo / Gelbe Paprika, roh | 11951 | Peppers, sweet, yellow, raw | 27 | 1 | 0,21 | 6,32 | 0,9 | Frutas y verduras |
| Ají picante verde (chile verde), crudo / Grüne Chili, roh | 11670 | Peppers, hot chili, green, raw | 40 | 2 | 0,2 | 9,46 | 1,5 | Frutas y verduras |
| Ají picante rojo (chile rojo), crudo / Rote Chili, roh | 11819 | Peppers, hot chili, red, raw | 40 | 1,87 | 0,44 | 8,81 | 1,5 | Frutas y verduras |
| Jalapeño, crudo / Jalapeño, roh | 11979 | Peppers, jalapeno, raw | 29 | 0,91 | 0,37 | 6,5 | 2,8 | Frutas y verduras |
| Quimbombó (okra), crudo / Okra, roh | 11278 | Okra, raw | 33 | 1,93 | 0,19 | 7,45 | 3,2 | Frutas y verduras |
| Quimbombó (okra), cocido (hervido, sin sal) / Okra, gekocht, ohne Salz | 11279 | Okra, cooked, boiled, drained, without salt | 22 | 1,87 | 0,21 | 4,51 | 2,5 | Frutas y verduras |
| Auyama (ahuyama, calabaza), cruda / Kürbis, roh | 11422 | Pumpkin, raw | 26 | 1 | 0,1 | 6,5 | 0,5 | Frutas y verduras |
| Auyama (ahuyama, calabaza), cocida (hervida, sin sal) / Kürbis, gekocht, ohne Salz | 11423 | Pumpkin, cooked, boiled, drained, without salt | 20 | 0,72 | 0,07 | 4,9 | 1,1 | Frutas y verduras |
| Calabaza butternut, cruda / Butternutkürbis, roh | 11485 | Squash, winter, butternut, raw | 45 | 1 | 0,1 | 11,69 | 2 | Frutas y verduras |
| Calabaza butternut, horneada (sin sal) / Butternutkürbis, gebacken, ohne Salz | 11486 | Squash, winter, butternut, cooked, baked, without salt | 40 | 0,9 | 0,09 | 10,49 | 3,2 | Frutas y verduras |
| Chayota (chayote, guatila, cidra), cruda / Chayote, roh | 11149 | Chayote, fruit, raw | 19 | 0,82 | 0,13 | 4,51 | 1,7 | Frutas y verduras |
| Chayota (chayote), cocida (hervida, sin sal) / Chayote, gekocht, ohne Salz | 11150 | Chayote, fruit, cooked, boiled, drained, without salt | 24 | 0,62 | 0,48 | 5,09 | 2,8 | Frutas y verduras |
| Vainitas (judías verdes, habichuelas), crudas / Grüne Bohnen, roh | 11052 | Beans, snap, green, raw | 31 | 1,83 | 0,22 | 6,97 | 2,7 | Frutas y verduras |
| Vainitas (judías verdes), cocidas (hervidas, sin sal) / Grüne Bohnen, gekocht, ohne Salz | 11053 | Beans, snap, green, cooked, boiled, drained, without salt | 35 | 1,89 | 0,28 | 7,88 | 3,2 | Frutas y verduras |
| Arvejas (guisantes), crudas / Grüne Erbsen, roh | 11304 | Peas, green, raw | 81 | 5,42 | 0,4 | 14,45 | 5,7 | Frutas y verduras |
| Arvejas (guisantes), cocidas (hervidas, sin sal) / Grüne Erbsen, gekocht, ohne Salz | 11305 | Peas, green, cooked, boiled, drained, without salt | 84 | 5,36 | 0,22 | 15,63 | 5,5 | Frutas y verduras |
| Arvejas chinas (tirabeques), crudas / Zuckerschoten, roh | 11300 | Peas, edible-podded, raw | 42 | 2,8 | 0,2 | 7,55 | 2,6 | Frutas y verduras |
| Habas tiernas, crudas / Dicke Bohnen, frisch, roh | 11088 | Broadbeans, immature seeds, raw | 72 | 5,6 | 0,6 | 11,7 | 4,2 | Frutas y verduras |
| Habas tiernas, cocidas (hervidas, sin sal) / Dicke Bohnen, frisch, gekocht, ohne Salz | 11089 | Broadbeans, immature seeds, cooked, boiled, drained, without salt | 62 | 4,8 | 0,5 | 10,1 | 3,6 | Frutas y verduras |
| Quinchoncho tierno (guandú), crudo / Straucherbsen (Taubenerbsen), frisch, roh | 11344 | Pigeonpeas, immature seeds, raw | 136 | 7,2 | 1,64 | 23,88 | 5,1 | Frutas y verduras |
| Quinchoncho tierno (guandú), cocido (hervido, sin sal) / Straucherbsen (Taubenerbsen), frisch, gekocht, ohne Salz | 11345 | Pigeonpeas, immature seeds, cooked, boiled, drained, without salt | 111 | 5,96 | 1,36 | 19,49 | 4,2 | Frutas y verduras |
| Frijol tierno (caupí, ojo negro), crudo / Augenbohnen, frisch, roh | 11191 | Cowpeas (blackeyes), immature seeds, raw | 90 | 2,95 | 0,35 | 18,83 | 5 | Frutas y verduras |
| Frijol tierno (caupí, ojo negro), cocido (hervido, sin sal) / Augenbohnen, frisch, gekocht, ohne Salz | 11192 | Cowpeas (blackeyes), immature seeds, cooked, boiled, drained, without salt | 97 | 3,17 | 0,38 | 20,32 | 5 | Frutas y verduras |
| Jojoto amarillo (maíz tierno, mazorca), crudo / Gelber Zuckermais, roh | 11167 | Corn, sweet, yellow, raw | 86 | 3,27 | 1,35 | 18,7 | 2 | Frutas y verduras |
| Jojoto amarillo (maíz tierno), cocido (hervido, sin sal) / Gelber Zuckermais, gekocht, ohne Salz | 11168 | Corn, sweet, yellow, cooked, boiled, drained, without salt | 96 | 3,41 | 1,5 | 20,98 | 2,4 | Frutas y verduras |
| Jojoto blanco (maíz tierno, mazorca), crudo / Weißer Zuckermais, roh | 11900 | Corn, sweet, white, raw | 86 | 3,22 | 1,18 | 19,02 | 2,7 | Frutas y verduras |
| Jojoto blanco (maíz tierno), cocido (hervido, sin sal) / Weißer Zuckermais, gekocht, ohne Salz | 11901 | Corn, sweet, white, cooked, boiled, drained, without salt | 97 | 3,34 | 1,41 | 21,71 | 2,7 | Frutas y verduras |
| Maíz dulce en lata, escurrido / Zuckermais aus der Dose, abgetropft | 11172 | Corn, sweet, yellow, canned, whole kernel, drained solids | 67 | 2,29 | 1,22 | 14,34 | 2 | Despensa |
| Brócoli, crudo / Brokkoli, roh | 11090 | Broccoli, raw | 34 | 2,82 | 0,37 | 6,64 | 2,6 | Frutas y verduras |
| Brócoli, cocido (hervido, sin sal) / Brokkoli, gekocht, ohne Salz | 11091 | Broccoli, cooked, boiled, drained, without salt | 35 | 2,38 | 0,41 | 7,18 | 3,3 | Frutas y verduras |
| Coliflor, cruda / Blumenkohl, roh | 11135 | Cauliflower, raw | 25 | 1,92 | 0,28 | 4,97 | 2 | Frutas y verduras |
| Coliflor, cocida (hervida, sin sal) / Blumenkohl, gekocht, ohne Salz | 11136 | Cauliflower, cooked, boiled, drained, without salt | 23 | 1,84 | 0,45 | 4,11 | 2,3 | Frutas y verduras |
| Repollitos de Bruselas, crudos / Rosenkohl, roh | 11098 | Brussels sprouts, raw | 43 | 3,38 | 0,3 | 8,95 | 3,8 | Frutas y verduras |
| Repollitos de Bruselas, cocidos (hervidos, sin sal) / Rosenkohl, gekocht, ohne Salz | 11099 | Brussels sprouts, cooked, boiled, drained, without salt | 36 | 2,55 | 0,5 | 7,1 | 2,6 | Frutas y verduras |
| Repollo blanco (col), crudo / Weißkohl, roh | 11109 | Cabbage, raw | 25 | 1,28 | 0,1 | 5,8 | 2,5 | Frutas y verduras |
| Repollo blanco (col), cocido (hervido, sin sal) / Weißkohl, gekocht, ohne Salz | 11110 | Cabbage, cooked, boiled, drained, without salt | 23 | 1,27 | 0,06 | 5,51 | 1,9 | Frutas y verduras |
| Repollo morado (lombarda), crudo / Rotkohl, roh | 11112 | Cabbage, red, raw | 31 | 1,43 | 0,16 | 7,37 | 2,1 | Frutas y verduras |
| Repollo morado (lombarda), cocido (hervido, sin sal) / Rotkohl, gekocht, ohne Salz | 11113 | Cabbage, red, cooked, boiled, drained, without salt | 29 | 1,51 | 0,09 | 6,94 | 2,6 | Frutas y verduras |
| Col de Milán (repollo crespo), cruda / Wirsing, roh | 11114 | Cabbage, savoy, raw | 27 | 2 | 0,1 | 6,1 | 3,1 | Frutas y verduras |
| Col de Milán, cocida (hervida, sin sal) / Wirsing, gekocht, ohne Salz | 11115 | Cabbage, savoy, cooked, boiled, drained, without salt | 24 | 1,8 | 0,09 | 5,41 | 2,8 | Frutas y verduras |
| Col rizada (kale), cruda / Grünkohl, roh | 11233 | Kale, raw | 49 | 4,28 | 0,93 | 8,75 | 3,6 | Frutas y verduras |
| Col rizada (kale), cocida (hervida, sin sal) / Grünkohl, gekocht, ohne Salz | 11234 | Kale, cooked, boiled, drained, without salt | 28 | 1,9 | 0,4 | 5,63 | 2 | Frutas y verduras |
| Col china (repollo chino), cruda / Chinakohl, roh | 11119 | Cabbage, chinese (pe-tsai), raw | 16 | 1,2 | 0,2 | 3,23 | 1,2 | Frutas y verduras |
| Pak choi (bok choy), crudo / Pak Choi, roh | 11116 | Cabbage, chinese (pak-choi), raw | 13 | 1,5 | 0,2 | 2,18 | 1 | Frutas y verduras |
| Colinabo, crudo / Kohlrabi, roh | 11241 | Kohlrabi, raw | 27 | 1,7 | 0,1 | 6,2 | 3,6 | Frutas y verduras |
| Colinabo, cocido (hervido, sin sal) / Kohlrabi, gekocht, ohne Salz | 11242 | Kohlrabi, cooked, boiled, drained, without salt | 29 | 1,8 | 0,11 | 6,69 | 1,1 | Frutas y verduras |
| Chucrut, en conserva / Sauerkraut, aus der Dose | 11439 | Sauerkraut, canned, solids and liquids | 19 | 0,91 | 0,14 | 4,28 | 2,9 | Despensa |
| Zanahoria, cruda / Karotte (Möhre), roh | 11124 | Carrots, raw | 41 | 0,93 | 0,24 | 9,58 | 2,8 | Frutas y verduras |
| Zanahoria, cocida (hervida, sin sal) / Karotte (Möhre), gekocht, ohne Salz | 11125 | Carrots, cooked, boiled, drained, without salt | 35 | 0,76 | 0,18 | 8,22 | 3 | Frutas y verduras |
| Remolacha (betabel), cruda / Rote Bete, roh | 11080 | Beets, raw | 43 | 1,61 | 0,17 | 9,56 | 2,8 | Frutas y verduras |
| Remolacha (betabel), cocida (hervida) / Rote Bete, gekocht | 11081 | Beets, cooked, boiled, drained | 44 | 1,68 | 0,18 | 9,96 | 2 | Frutas y verduras |
| Nabo sueco (rutabaga), crudo / Steckrübe, roh | 11435 | Rutabagas, raw | 37 | 1,08 | 0,16 | 8,62 | 2,3 | Frutas y verduras |
| Nabo sueco (rutabaga), cocido (hervido, sin sal) / Steckrübe, gekocht, ohne Salz | 11436 | Rutabagas, cooked, boiled, drained, without salt | 30 | 0,93 | 0,18 | 6,84 | 1,8 | Frutas y verduras |
| Nabo, crudo / Weiße Rübe (Speiserübe), roh | 11564 | Turnips, raw | 28 | 0,9 | 0,1 | 6,43 | 1,8 | Frutas y verduras |
| Nabo, cocido (hervido, sin sal) / Weiße Rübe (Speiserübe), gekocht, ohne Salz | 11565 | Turnips, cooked, boiled, drained, without salt | 22 | 0,71 | 0,08 | 5,06 | 2 | Frutas y verduras |
| Chirivía (pastinaca), cruda / Pastinake, roh | 11298 | Parsnips, raw | 75 | 1,2 | 0,3 | 17,99 | 4,9 | Frutas y verduras |
| Chirivía (pastinaca), cocida (hervida, sin sal) / Pastinake, gekocht, ohne Salz | 11299 | Parsnips, cooked, boiled, drained, without salt | 71 | 1,32 | 0,3 | 17,01 | 3,6 | Frutas y verduras |
| Apionabo, crudo / Knollensellerie, roh | 11141 | Celeriac, raw | 42 | 1,5 | 0,3 | 9,2 | 1,8 | Frutas y verduras |
| Apionabo, cocido (hervido, sin sal) / Knollensellerie, gekocht, ohne Salz | 11142 | Celeriac, cooked, boiled, drained, without salt | 27 | 0,96 | 0,19 | 5,9 | 1,2 | Frutas y verduras |
| Apio España (apio de tallo), crudo / Staudensellerie, roh | 11143 | Celery, raw | 16 | 0,69 | 0,17 | 2,97 | 1,6 | Frutas y verduras |
| Rábano (rabanito), crudo / Radieschen, roh | 11429 | Radishes, raw | 16 | 0,68 | 0,1 | 3,4 | 1,6 | Frutas y verduras |
| Rábano blanco (daikon), crudo / Rettich (Daikon), roh | 11430 | Radishes, oriental, raw | 18 | 0,6 | 0,1 | 4,1 | 1,6 | Frutas y verduras |
| Tupinambo, crudo / Topinambur, roh | 11226 | Jerusalem-artichokes, raw | 73 | 2 | 0,01 | 17,44 | 1,6 | Frutas y verduras |
| Hinojo (bulbo), crudo / Fenchel (Knolle), roh | 11957 | Fennel, bulb, raw | 31 | 1,24 | 0,2 | 7,3 | 3,1 | Frutas y verduras |
| Alcachofa, cruda / Artischocke, roh | 11007 | Artichokes, (globe or french), raw | 47 | 3,27 | 0,15 | 10,51 | 5,4 | Frutas y verduras |
| Alcachofa, cocida (hervida, sin sal) / Artischocke, gekocht, ohne Salz | 11008 | Artichokes, (globe or french), cooked, boiled, drained, without salt | 53 | 2,89 | 0,34 | 11,95 | 5,7 | Frutas y verduras |
| Espárragos, crudos / Spargel, roh | 11011 | Asparagus, raw | 20 | 2,2 | 0,12 | 3,88 | 2,1 | Frutas y verduras |
| Espárragos, cocidos (hervidos) / Spargel, gekocht | 11012 | Asparagus, cooked, boiled, drained | 22 | 2,4 | 0,22 | 4,11 | 2 | Frutas y verduras |
| Espárragos en lata, escurridos / Spargel aus der Dose, abgetropft | 11015 | Asparagus, canned, drained solids | 19 | 2,14 | 0,65 | 2,46 | 1,6 | Despensa |
| Palmito en lata / Palmherzen aus der Dose | 11961 | Hearts of palm, canned | 28 | 2,52 | 0,62 | 4,62 | 2,4 | Despensa |
| Hojas de parra en conserva / Weinblätter, eingelegt | 11975 | Grape leaves, canned | 69 | 4,27 | 1,97 | 11,71 | 9,9 | Despensa |
| Nopal, crudo / Nopal (Kaktusblatt), roh | 11963 | Nopales, raw | 16 | 1,32 | 0,09 | 3,33 | 2,2 | Frutas y verduras |
| Nopal, cocido (sin sal) / Nopal (Kaktusblatt), gekocht, ohne Salz | 11964 | Nopales, cooked, without salt | 15 | 1,35 | 0,05 | 3,28 | 2 | Frutas y verduras |
| Espinaca, cruda / Spinat, roh | 11457 | Spinach, raw | 23 | 2,86 | 0,39 | 3,63 | 2,2 | Frutas y verduras |
| Espinaca, cocida (hervida, sin sal) / Spinat, gekocht, ohne Salz | 11458 | Spinach, cooked, boiled, drained, without salt | 23 | 2,97 | 0,26 | 3,75 | 2,4 | Frutas y verduras |
| Acelga, cruda / Mangold, roh | 11147 | Chard, swiss, raw | 19 | 1,8 | 0,2 | 3,74 | 1,6 | Frutas y verduras |
| Acelga, cocida (hervida, sin sal) / Mangold, gekocht, ohne Salz | 11148 | Chard, swiss, cooked, boiled, drained, without salt | 20 | 1,88 | 0,08 | 4,13 | 2,1 | Frutas y verduras |
| Lechuga iceberg (americana), cruda / Eisbergsalat, roh | 11252 | Lettuce, iceberg (includes crisphead types), raw | 14 | 0,9 | 0,14 | 2,97 | 1,2 | Frutas y verduras |
| Lechuga romana, cruda / Römersalat, roh | 11251 | Lettuce, cos or romaine, raw | 17 | 1,23 | 0,3 | 3,29 | 2,1 | Frutas y verduras |
| Lechuga mantecosa, cruda / Kopfsalat, roh | 11250 | Lettuce, butterhead (includes boston and bibb types), raw | 13 | 1,35 | 0,22 | 2,23 | 1,1 | Frutas y verduras |
| Lechuga de hoja verde, cruda / Grüner Blattsalat, roh | 11253 | Lettuce, green leaf, raw | 15 | 1,36 | 0,15 | 2,87 | 1,3 | Frutas y verduras |
| Lechuga de hoja roja, cruda / Roter Blattsalat, roh | 11257 | Lettuce, red leaf, raw | 16 | 1,33 | 0,22 | 2,26 | 0,9 | Frutas y verduras |
| Rúcula (rúgula), cruda / Rucola, roh | 11959 | Arugula, raw | 25 | 2,58 | 0,66 | 3,65 | 1,6 | Frutas y verduras |
| Canónigos, crudos / Feldsalat, roh | 11190 | Cornsalad, raw | 21 | 2 | 0,4 | 3,6 | — | Frutas y verduras |
| Escarola, cruda / Endivie, roh | 11213 | Endive, raw | 17 | 1,25 | 0,2 | 3,35 | 3,1 | Frutas y verduras |
| Endibia belga, cruda / Chicorée, roh | 11151 | Chicory, witloof, raw | 17 | 0,9 | 0,1 | 4 | 3,1 | Frutas y verduras |
| Radicchio (achicoria roja), crudo / Radicchio, roh | 11952 | Radicchio, raw | 23 | 1,43 | 0,25 | 4,48 | 0,9 | Frutas y verduras |
| Berro, crudo / Brunnenkresse, roh | 11591 | Watercress, raw | 11 | 2,3 | 0,1 | 1,29 | 0,5 | Frutas y verduras |
| Mastuerzo (berro de jardín), crudo / Gartenkresse, roh | 11203 | Cress, garden, raw | 32 | 2,6 | 0,7 | 5,5 | 1,1 | Frutas y verduras |
| Germinados de frijol mungo (brotes de soja), crudos / Mungobohnensprossen (Sojasprossen), roh | 11043 | Mung beans, mature seeds, sprouted, raw | 30 | 3,04 | 0,18 | 5,94 | 1,8 | Frutas y verduras |
| Cilantro (hojas), crudo / Koriander (Blätter), frisch | 11165 | Coriander (cilantro) leaves, raw | 23 | 2,13 | 0,52 | 3,67 | 2,8 | Frutas y verduras |
| Perejil, fresco / Petersilie, frisch | 11297 | Parsley, fresh | 36 | 2,97 | 0,79 | 6,33 | 3,3 | Frutas y verduras |
| Albahaca, fresca / Basilikum, frisch | 02044 | Basil, fresh | 23 | 3,15 | 0,64 | 2,65 | 1,6 | Frutas y verduras |
| Eneldo, fresco / Dill, frisch | 02045 | Dill weed, fresh | 43 | 3,46 | 1,12 | 7,02 | 2,1 | Frutas y verduras |
| Hierbabuena, fresca / Grüne Minze, frisch | 02065 | Spearmint, fresh | 44 | 3,29 | 0,73 | 8,41 | 6,8 | Frutas y verduras |
| Menta piperita, fresca / Pfefferminze, frisch | 02064 | Peppermint, fresh | 70 | 3,75 | 0,94 | 14,89 | 8 | Frutas y verduras |
| Tomillo, fresco / Thymian, frisch | 02049 | Thyme, fresh | 101 | 5,56 | 1,68 | 24,45 | 14 | Frutas y verduras |
| Romero, fresco / Rosmarin, frisch | 02063 | Rosemary, fresh | 131 | 3,31 | 5,86 | 20,7 | 14,1 | Frutas y verduras |
| Champiñones blancos, crudos / Weiße Champignons, roh | 11260 | Mushrooms, white, raw | 22 | 3,09 | 0,34 | 3,26 | 1 | Frutas y verduras |
| Champiñones blancos, cocidos (hervidos, sin sal) / Weiße Champignons, gekocht, ohne Salz | 11261 | Mushrooms, white, cooked, boiled, drained, without salt | 28 | 2,17 | 0,47 | 5,29 | 2,2 | Frutas y verduras |
| Champiñones en lata, escurridos / Champignons aus der Dose, abgetropft | 11264 | Mushrooms, canned, drained solids | 25 | 1,87 | 0,29 | 5,09 | 2,4 | Despensa |
| Champiñones marrones (crimini), crudos / Braune Champignons, roh | 11266 | Mushrooms, brown, italian, or crimini, raw | 22 | 2,5 | 0,1 | 4,3 | 0,6 | Frutas y verduras |
| Portobello, crudo / Portobello (Riesenchampignon), roh | 11265 | Mushrooms, portabella, raw | 22 | 2,11 | 0,35 | 3,87 | 1,3 | Frutas y verduras |
| Shiitake, crudo / Shiitake, roh | 11238 | Mushrooms, shiitake, raw | 34 | 2,24 | 0,49 | 6,79 | 2,5 | Frutas y verduras |
| Setas de ostra (gírgolas), crudas / Austernpilze, roh | 11987 | Mushrooms, oyster, raw | 33 | 3,31 | 0,41 | 6,09 | 2,3 | Frutas y verduras |
| Rebozuelos, crudos / Pfifferlinge, roh | 11239 | Mushrooms, Chanterelle, raw | 38 | 1,49 | 0,53 | 6,86 | 3,8 | Frutas y verduras |
| Papa (patata) con piel, cruda / Kartoffel mit Schale, roh | 11352 | Potatoes, flesh and skin, raw | 77 | 2,05 | 0,09 | 17,49 | 2,1 | Frutas y verduras |
| Papa (patata) pelada, hervida sin sal / Kartoffel, geschält, gekocht, ohne Salz | 11367 | Potatoes, boiled, cooked without skin, flesh, without salt | 86 | 1,71 | 0,1 | 20,01 | 1,8 | Frutas y verduras |
| Papa (patata) hervida con piel, solo pulpa, sin sal / Pellkartoffel, nur Fruchtfleisch, ohne Salz | 11365 | Potatoes, boiled, cooked in skin, flesh, without salt | 87 | 1,87 | 0,1 | 20,13 | 1,8 | Frutas y verduras |
| Papa (patata) asada al horno, con piel, sin sal / Ofenkartoffel mit Schale, ohne Salz | 11674 | Potatoes, baked, flesh and skin, without salt | 93 | 2,5 | 0,13 | 21,15 | 2,2 | Frutas y verduras |
| Batata (boniato, camote), cruda / Süßkartoffel, roh | 11507 | Sweet potato, raw, unprepared | 86 | 1,57 | 0,05 | 20,12 | 3 | Frutas y verduras |
| Batata (boniato, camote), hervida sin piel / Süßkartoffel, gekocht, ohne Schale | 11510 | Sweet potato, cooked, boiled, without skin | 76 | 1,37 | 0,14 | 17,72 | 2,5 | Frutas y verduras |
| Batata (boniato, camote), asada al horno, pulpa, sin sal / Süßkartoffel, im Ofen gebacken, Fruchtfleisch, ohne Salz | 11508 | Sweet potato, cooked, baked in skin, flesh, without salt | 90 | 2,01 | 0,15 | 20,71 | 3,3 | Frutas y verduras |
| Yuca (mandioca), cruda / Maniok (Cassava), roh | 11134 | Cassava, raw | 160 | 1,36 | 0,28 | 38,06 | 1,8 | Frutas y verduras |
| Ñame, crudo / Yamswurzel, roh | 11601 | Yam, raw | 118 | 1,53 | 0,17 | 27,88 | 4,1 | Frutas y verduras |
| Ñame, cocido (hervido u horneado, sin sal) / Yamswurzel, gekocht oder gebacken, ohne Salz | 11602 | Yam, cooked, boiled, drained, or baked, without salt | 116 | 1,49 | 0,14 | 27,48 | 3,9 | Frutas y verduras |
| Ocumo (yautía, malanga), crudo / Tannia (Malanga), roh | 11991 | Yautia (tannier), raw | 98 | 1,46 | 0,4 | 23,63 | 1,5 | Frutas y verduras |
| Ocumo chino (taro), crudo / Taro, roh | 11518 | Taro, raw | 112 | 1,5 | 0,2 | 26,46 | 4,1 | Frutas y verduras |
| Ocumo chino (taro), cocido (sin sal) / Taro, gekocht, ohne Salz | 11519 | Taro, cooked, without salt | 142 | 0,52 | 0,11 | 34,6 | 5,1 | Frutas y verduras |
