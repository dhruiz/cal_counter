// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CategoriasTable extends Categorias
    with TableInfo<$CategoriasTable, CategoriaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE COLLATE NOCASE',
  );
  static const VerificationMeta _ordenMeta = const VerificationMeta('orden');
  @override
  late final GeneratedColumn<int> orden = GeneratedColumn<int>(
    'orden',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, nombre, orden];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categorias';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoriaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('orden')) {
      context.handle(
        _ordenMeta,
        orden.isAcceptableOrUnknown(data['orden']!, _ordenMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoriaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoriaRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      orden: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}orden'],
      )!,
    );
  }

  @override
  $CategoriasTable createAlias(String alias) {
    return $CategoriasTable(attachedDatabase, alias);
  }
}

class CategoriaRow extends DataClass implements Insertable<CategoriaRow> {
  final int id;
  final String nombre;
  final int orden;
  const CategoriaRow({
    required this.id,
    required this.nombre,
    required this.orden,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nombre'] = Variable<String>(nombre);
    map['orden'] = Variable<int>(orden);
    return map;
  }

  CategoriasCompanion toCompanion(bool nullToAbsent) {
    return CategoriasCompanion(
      id: Value(id),
      nombre: Value(nombre),
      orden: Value(orden),
    );
  }

  factory CategoriaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoriaRow(
      id: serializer.fromJson<int>(json['id']),
      nombre: serializer.fromJson<String>(json['nombre']),
      orden: serializer.fromJson<int>(json['orden']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nombre': serializer.toJson<String>(nombre),
      'orden': serializer.toJson<int>(orden),
    };
  }

  CategoriaRow copyWith({int? id, String? nombre, int? orden}) => CategoriaRow(
    id: id ?? this.id,
    nombre: nombre ?? this.nombre,
    orden: orden ?? this.orden,
  );
  CategoriaRow copyWithCompanion(CategoriasCompanion data) {
    return CategoriaRow(
      id: data.id.present ? data.id.value : this.id,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      orden: data.orden.present ? data.orden.value : this.orden,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoriaRow(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('orden: $orden')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nombre, orden);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoriaRow &&
          other.id == this.id &&
          other.nombre == this.nombre &&
          other.orden == this.orden);
}

class CategoriasCompanion extends UpdateCompanion<CategoriaRow> {
  final Value<int> id;
  final Value<String> nombre;
  final Value<int> orden;
  const CategoriasCompanion({
    this.id = const Value.absent(),
    this.nombre = const Value.absent(),
    this.orden = const Value.absent(),
  });
  CategoriasCompanion.insert({
    this.id = const Value.absent(),
    required String nombre,
    this.orden = const Value.absent(),
  }) : nombre = Value(nombre);
  static Insertable<CategoriaRow> custom({
    Expression<int>? id,
    Expression<String>? nombre,
    Expression<int>? orden,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nombre != null) 'nombre': nombre,
      if (orden != null) 'orden': orden,
    });
  }

  CategoriasCompanion copyWith({
    Value<int>? id,
    Value<String>? nombre,
    Value<int>? orden,
  }) {
    return CategoriasCompanion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      orden: orden ?? this.orden,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (orden.present) {
      map['orden'] = Variable<int>(orden.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriasCompanion(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('orden: $orden')
          ..write(')'))
        .toString();
  }
}

class $AlimentosTable extends Alimentos
    with TableInfo<$AlimentosTable, AlimentoRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlimentosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL COLLATE NOCASE',
  );
  static const VerificationMeta _marcaMeta = const VerificationMeta('marca');
  @override
  late final GeneratedColumn<String> marca = GeneratedColumn<String>(
    'marca',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\' COLLATE NOCASE',
    defaultValue: const CustomExpression('\'\''),
    clientDefault: () => '',
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    check: () => tipo.isIn(['generico', 'envasado', 'preparado']),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('generico'),
  );
  static const VerificationMeta _unidadMeta = const VerificationMeta('unidad');
  @override
  late final GeneratedColumn<String> unidad = GeneratedColumn<String>(
    'unidad',
    aliasedName,
    false,
    check: () => unidad.isIn(['g', 'ml']),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('g'),
  );
  static const VerificationMeta _categoriaIdMeta = const VerificationMeta(
    'categoriaId',
  );
  @override
  late final GeneratedColumn<int> categoriaId = GeneratedColumn<int>(
    'categoria_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categorias (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _kcalMeta = const VerificationMeta('kcal');
  @override
  late final GeneratedColumn<double> kcal = GeneratedColumn<double>(
    'kcal',
    aliasedName,
    true,
    check: () => ComparableExpr(kcal).isBiggerOrEqualValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _proteinasMeta = const VerificationMeta(
    'proteinas',
  );
  @override
  late final GeneratedColumn<double> proteinas = GeneratedColumn<double>(
    'proteinas',
    aliasedName,
    true,
    check: () => ComparableExpr(proteinas).isBiggerOrEqualValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _grasasMeta = const VerificationMeta('grasas');
  @override
  late final GeneratedColumn<double> grasas = GeneratedColumn<double>(
    'grasas',
    aliasedName,
    true,
    check: () => ComparableExpr(grasas).isBiggerOrEqualValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _grasasSaturadasMeta = const VerificationMeta(
    'grasasSaturadas',
  );
  @override
  late final GeneratedColumn<double> grasasSaturadas = GeneratedColumn<double>(
    'grasas_saturadas',
    aliasedName,
    true,
    check: () => ComparableExpr(grasasSaturadas).isBiggerOrEqualValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _carbohidratosMeta = const VerificationMeta(
    'carbohidratos',
  );
  @override
  late final GeneratedColumn<double> carbohidratos = GeneratedColumn<double>(
    'carbohidratos',
    aliasedName,
    true,
    check: () => ComparableExpr(carbohidratos).isBiggerOrEqualValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _azucaresMeta = const VerificationMeta(
    'azucares',
  );
  @override
  late final GeneratedColumn<double> azucares = GeneratedColumn<double>(
    'azucares',
    aliasedName,
    true,
    check: () => ComparableExpr(azucares).isBiggerOrEqualValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fibraMeta = const VerificationMeta('fibra');
  @override
  late final GeneratedColumn<double> fibra = GeneratedColumn<double>(
    'fibra',
    aliasedName,
    true,
    check: () => ComparableExpr(fibra).isBiggerOrEqualValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _salMeta = const VerificationMeta('sal');
  @override
  late final GeneratedColumn<double> sal = GeneratedColumn<double>(
    'sal',
    aliasedName,
    true,
    check: () => ComparableExpr(sal).isBiggerOrEqualValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nutricionOrigenMeta = const VerificationMeta(
    'nutricionOrigen',
  );
  @override
  late final GeneratedColumn<String> nutricionOrigen = GeneratedColumn<String>(
    'nutricion_origen',
    aliasedName,
    true,
    check: () => nutricionOrigen.isIn([
      'manual',
      'etiqueta_ocr',
      'importado',
      'calculado',
    ]),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notasMeta = const VerificationMeta('notas');
  @override
  late final GeneratedColumn<String> notas = GeneratedColumn<String>(
    'notas',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _usoCountMeta = const VerificationMeta(
    'usoCount',
  );
  @override
  late final GeneratedColumn<int> usoCount = GeneratedColumn<int>(
    'uso_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _ultimoUsoMeta = const VerificationMeta(
    'ultimoUso',
  );
  @override
  late final GeneratedColumn<String> ultimoUso = GeneratedColumn<String>(
    'ultimo_uso',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivadoMeta = const VerificationMeta(
    'archivado',
  );
  @override
  late final GeneratedColumn<bool> archivado = GeneratedColumn<bool>(
    'archivado',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archivado" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _creadoMeta = const VerificationMeta('creado');
  @override
  late final GeneratedColumn<String> creado = GeneratedColumn<String>(
    'creado',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actualizadoMeta = const VerificationMeta(
    'actualizado',
  );
  @override
  late final GeneratedColumn<String> actualizado = GeneratedColumn<String>(
    'actualizado',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    nombre,
    marca,
    tipo,
    unidad,
    categoriaId,
    kcal,
    proteinas,
    grasas,
    grasasSaturadas,
    carbohidratos,
    azucares,
    fibra,
    sal,
    nutricionOrigen,
    notas,
    usoCount,
    ultimoUso,
    archivado,
    creado,
    actualizado,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alimentos';
  @override
  VerificationContext validateIntegrity(
    Insertable<AlimentoRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('marca')) {
      context.handle(
        _marcaMeta,
        marca.isAcceptableOrUnknown(data['marca']!, _marcaMeta),
      );
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    }
    if (data.containsKey('unidad')) {
      context.handle(
        _unidadMeta,
        unidad.isAcceptableOrUnknown(data['unidad']!, _unidadMeta),
      );
    }
    if (data.containsKey('categoria_id')) {
      context.handle(
        _categoriaIdMeta,
        categoriaId.isAcceptableOrUnknown(
          data['categoria_id']!,
          _categoriaIdMeta,
        ),
      );
    }
    if (data.containsKey('kcal')) {
      context.handle(
        _kcalMeta,
        kcal.isAcceptableOrUnknown(data['kcal']!, _kcalMeta),
      );
    }
    if (data.containsKey('proteinas')) {
      context.handle(
        _proteinasMeta,
        proteinas.isAcceptableOrUnknown(data['proteinas']!, _proteinasMeta),
      );
    }
    if (data.containsKey('grasas')) {
      context.handle(
        _grasasMeta,
        grasas.isAcceptableOrUnknown(data['grasas']!, _grasasMeta),
      );
    }
    if (data.containsKey('grasas_saturadas')) {
      context.handle(
        _grasasSaturadasMeta,
        grasasSaturadas.isAcceptableOrUnknown(
          data['grasas_saturadas']!,
          _grasasSaturadasMeta,
        ),
      );
    }
    if (data.containsKey('carbohidratos')) {
      context.handle(
        _carbohidratosMeta,
        carbohidratos.isAcceptableOrUnknown(
          data['carbohidratos']!,
          _carbohidratosMeta,
        ),
      );
    }
    if (data.containsKey('azucares')) {
      context.handle(
        _azucaresMeta,
        azucares.isAcceptableOrUnknown(data['azucares']!, _azucaresMeta),
      );
    }
    if (data.containsKey('fibra')) {
      context.handle(
        _fibraMeta,
        fibra.isAcceptableOrUnknown(data['fibra']!, _fibraMeta),
      );
    }
    if (data.containsKey('sal')) {
      context.handle(
        _salMeta,
        sal.isAcceptableOrUnknown(data['sal']!, _salMeta),
      );
    }
    if (data.containsKey('nutricion_origen')) {
      context.handle(
        _nutricionOrigenMeta,
        nutricionOrigen.isAcceptableOrUnknown(
          data['nutricion_origen']!,
          _nutricionOrigenMeta,
        ),
      );
    }
    if (data.containsKey('notas')) {
      context.handle(
        _notasMeta,
        notas.isAcceptableOrUnknown(data['notas']!, _notasMeta),
      );
    }
    if (data.containsKey('uso_count')) {
      context.handle(
        _usoCountMeta,
        usoCount.isAcceptableOrUnknown(data['uso_count']!, _usoCountMeta),
      );
    }
    if (data.containsKey('ultimo_uso')) {
      context.handle(
        _ultimoUsoMeta,
        ultimoUso.isAcceptableOrUnknown(data['ultimo_uso']!, _ultimoUsoMeta),
      );
    }
    if (data.containsKey('archivado')) {
      context.handle(
        _archivadoMeta,
        archivado.isAcceptableOrUnknown(data['archivado']!, _archivadoMeta),
      );
    }
    if (data.containsKey('creado')) {
      context.handle(
        _creadoMeta,
        creado.isAcceptableOrUnknown(data['creado']!, _creadoMeta),
      );
    } else if (isInserting) {
      context.missing(_creadoMeta);
    }
    if (data.containsKey('actualizado')) {
      context.handle(
        _actualizadoMeta,
        actualizado.isAcceptableOrUnknown(
          data['actualizado']!,
          _actualizadoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_actualizadoMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {nombre, marca},
  ];
  @override
  AlimentoRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AlimentoRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      marca: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}marca'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      unidad: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unidad'],
      )!,
      categoriaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}categoria_id'],
      ),
      kcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kcal'],
      ),
      proteinas: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}proteinas'],
      ),
      grasas: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grasas'],
      ),
      grasasSaturadas: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grasas_saturadas'],
      ),
      carbohidratos: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbohidratos'],
      ),
      azucares: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}azucares'],
      ),
      fibra: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fibra'],
      ),
      sal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sal'],
      ),
      nutricionOrigen: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nutricion_origen'],
      ),
      notas: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notas'],
      ),
      usoCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}uso_count'],
      )!,
      ultimoUso: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ultimo_uso'],
      ),
      archivado: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archivado'],
      )!,
      creado: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}creado'],
      )!,
      actualizado: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actualizado'],
      )!,
    );
  }

  @override
  $AlimentosTable createAlias(String alias) {
    return $AlimentosTable(attachedDatabase, alias);
  }
}

class AlimentoRow extends DataClass implements Insertable<AlimentoRow> {
  final int id;
  final String uuid;
  final String nombre;
  final String marca;
  final String tipo;
  final String unidad;
  final int? categoriaId;
  final double? kcal;
  final double? proteinas;
  final double? grasas;
  final double? grasasSaturadas;
  final double? carbohidratos;
  final double? azucares;
  final double? fibra;
  final double? sal;
  final String? nutricionOrigen;
  final String? notas;
  final int usoCount;
  final String? ultimoUso;
  final bool archivado;
  final String creado;
  final String actualizado;
  const AlimentoRow({
    required this.id,
    required this.uuid,
    required this.nombre,
    required this.marca,
    required this.tipo,
    required this.unidad,
    this.categoriaId,
    this.kcal,
    this.proteinas,
    this.grasas,
    this.grasasSaturadas,
    this.carbohidratos,
    this.azucares,
    this.fibra,
    this.sal,
    this.nutricionOrigen,
    this.notas,
    required this.usoCount,
    this.ultimoUso,
    required this.archivado,
    required this.creado,
    required this.actualizado,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['nombre'] = Variable<String>(nombre);
    map['marca'] = Variable<String>(marca);
    map['tipo'] = Variable<String>(tipo);
    map['unidad'] = Variable<String>(unidad);
    if (!nullToAbsent || categoriaId != null) {
      map['categoria_id'] = Variable<int>(categoriaId);
    }
    if (!nullToAbsent || kcal != null) {
      map['kcal'] = Variable<double>(kcal);
    }
    if (!nullToAbsent || proteinas != null) {
      map['proteinas'] = Variable<double>(proteinas);
    }
    if (!nullToAbsent || grasas != null) {
      map['grasas'] = Variable<double>(grasas);
    }
    if (!nullToAbsent || grasasSaturadas != null) {
      map['grasas_saturadas'] = Variable<double>(grasasSaturadas);
    }
    if (!nullToAbsent || carbohidratos != null) {
      map['carbohidratos'] = Variable<double>(carbohidratos);
    }
    if (!nullToAbsent || azucares != null) {
      map['azucares'] = Variable<double>(azucares);
    }
    if (!nullToAbsent || fibra != null) {
      map['fibra'] = Variable<double>(fibra);
    }
    if (!nullToAbsent || sal != null) {
      map['sal'] = Variable<double>(sal);
    }
    if (!nullToAbsent || nutricionOrigen != null) {
      map['nutricion_origen'] = Variable<String>(nutricionOrigen);
    }
    if (!nullToAbsent || notas != null) {
      map['notas'] = Variable<String>(notas);
    }
    map['uso_count'] = Variable<int>(usoCount);
    if (!nullToAbsent || ultimoUso != null) {
      map['ultimo_uso'] = Variable<String>(ultimoUso);
    }
    map['archivado'] = Variable<bool>(archivado);
    map['creado'] = Variable<String>(creado);
    map['actualizado'] = Variable<String>(actualizado);
    return map;
  }

  AlimentosCompanion toCompanion(bool nullToAbsent) {
    return AlimentosCompanion(
      id: Value(id),
      uuid: Value(uuid),
      nombre: Value(nombre),
      marca: Value(marca),
      tipo: Value(tipo),
      unidad: Value(unidad),
      categoriaId: categoriaId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoriaId),
      kcal: kcal == null && nullToAbsent ? const Value.absent() : Value(kcal),
      proteinas: proteinas == null && nullToAbsent
          ? const Value.absent()
          : Value(proteinas),
      grasas: grasas == null && nullToAbsent
          ? const Value.absent()
          : Value(grasas),
      grasasSaturadas: grasasSaturadas == null && nullToAbsent
          ? const Value.absent()
          : Value(grasasSaturadas),
      carbohidratos: carbohidratos == null && nullToAbsent
          ? const Value.absent()
          : Value(carbohidratos),
      azucares: azucares == null && nullToAbsent
          ? const Value.absent()
          : Value(azucares),
      fibra: fibra == null && nullToAbsent
          ? const Value.absent()
          : Value(fibra),
      sal: sal == null && nullToAbsent ? const Value.absent() : Value(sal),
      nutricionOrigen: nutricionOrigen == null && nullToAbsent
          ? const Value.absent()
          : Value(nutricionOrigen),
      notas: notas == null && nullToAbsent
          ? const Value.absent()
          : Value(notas),
      usoCount: Value(usoCount),
      ultimoUso: ultimoUso == null && nullToAbsent
          ? const Value.absent()
          : Value(ultimoUso),
      archivado: Value(archivado),
      creado: Value(creado),
      actualizado: Value(actualizado),
    );
  }

  factory AlimentoRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AlimentoRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      nombre: serializer.fromJson<String>(json['nombre']),
      marca: serializer.fromJson<String>(json['marca']),
      tipo: serializer.fromJson<String>(json['tipo']),
      unidad: serializer.fromJson<String>(json['unidad']),
      categoriaId: serializer.fromJson<int?>(json['categoriaId']),
      kcal: serializer.fromJson<double?>(json['kcal']),
      proteinas: serializer.fromJson<double?>(json['proteinas']),
      grasas: serializer.fromJson<double?>(json['grasas']),
      grasasSaturadas: serializer.fromJson<double?>(json['grasasSaturadas']),
      carbohidratos: serializer.fromJson<double?>(json['carbohidratos']),
      azucares: serializer.fromJson<double?>(json['azucares']),
      fibra: serializer.fromJson<double?>(json['fibra']),
      sal: serializer.fromJson<double?>(json['sal']),
      nutricionOrigen: serializer.fromJson<String?>(json['nutricionOrigen']),
      notas: serializer.fromJson<String?>(json['notas']),
      usoCount: serializer.fromJson<int>(json['usoCount']),
      ultimoUso: serializer.fromJson<String?>(json['ultimoUso']),
      archivado: serializer.fromJson<bool>(json['archivado']),
      creado: serializer.fromJson<String>(json['creado']),
      actualizado: serializer.fromJson<String>(json['actualizado']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'nombre': serializer.toJson<String>(nombre),
      'marca': serializer.toJson<String>(marca),
      'tipo': serializer.toJson<String>(tipo),
      'unidad': serializer.toJson<String>(unidad),
      'categoriaId': serializer.toJson<int?>(categoriaId),
      'kcal': serializer.toJson<double?>(kcal),
      'proteinas': serializer.toJson<double?>(proteinas),
      'grasas': serializer.toJson<double?>(grasas),
      'grasasSaturadas': serializer.toJson<double?>(grasasSaturadas),
      'carbohidratos': serializer.toJson<double?>(carbohidratos),
      'azucares': serializer.toJson<double?>(azucares),
      'fibra': serializer.toJson<double?>(fibra),
      'sal': serializer.toJson<double?>(sal),
      'nutricionOrigen': serializer.toJson<String?>(nutricionOrigen),
      'notas': serializer.toJson<String?>(notas),
      'usoCount': serializer.toJson<int>(usoCount),
      'ultimoUso': serializer.toJson<String?>(ultimoUso),
      'archivado': serializer.toJson<bool>(archivado),
      'creado': serializer.toJson<String>(creado),
      'actualizado': serializer.toJson<String>(actualizado),
    };
  }

  AlimentoRow copyWith({
    int? id,
    String? uuid,
    String? nombre,
    String? marca,
    String? tipo,
    String? unidad,
    Value<int?> categoriaId = const Value.absent(),
    Value<double?> kcal = const Value.absent(),
    Value<double?> proteinas = const Value.absent(),
    Value<double?> grasas = const Value.absent(),
    Value<double?> grasasSaturadas = const Value.absent(),
    Value<double?> carbohidratos = const Value.absent(),
    Value<double?> azucares = const Value.absent(),
    Value<double?> fibra = const Value.absent(),
    Value<double?> sal = const Value.absent(),
    Value<String?> nutricionOrigen = const Value.absent(),
    Value<String?> notas = const Value.absent(),
    int? usoCount,
    Value<String?> ultimoUso = const Value.absent(),
    bool? archivado,
    String? creado,
    String? actualizado,
  }) => AlimentoRow(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    nombre: nombre ?? this.nombre,
    marca: marca ?? this.marca,
    tipo: tipo ?? this.tipo,
    unidad: unidad ?? this.unidad,
    categoriaId: categoriaId.present ? categoriaId.value : this.categoriaId,
    kcal: kcal.present ? kcal.value : this.kcal,
    proteinas: proteinas.present ? proteinas.value : this.proteinas,
    grasas: grasas.present ? grasas.value : this.grasas,
    grasasSaturadas: grasasSaturadas.present
        ? grasasSaturadas.value
        : this.grasasSaturadas,
    carbohidratos: carbohidratos.present
        ? carbohidratos.value
        : this.carbohidratos,
    azucares: azucares.present ? azucares.value : this.azucares,
    fibra: fibra.present ? fibra.value : this.fibra,
    sal: sal.present ? sal.value : this.sal,
    nutricionOrigen: nutricionOrigen.present
        ? nutricionOrigen.value
        : this.nutricionOrigen,
    notas: notas.present ? notas.value : this.notas,
    usoCount: usoCount ?? this.usoCount,
    ultimoUso: ultimoUso.present ? ultimoUso.value : this.ultimoUso,
    archivado: archivado ?? this.archivado,
    creado: creado ?? this.creado,
    actualizado: actualizado ?? this.actualizado,
  );
  AlimentoRow copyWithCompanion(AlimentosCompanion data) {
    return AlimentoRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      marca: data.marca.present ? data.marca.value : this.marca,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      unidad: data.unidad.present ? data.unidad.value : this.unidad,
      categoriaId: data.categoriaId.present
          ? data.categoriaId.value
          : this.categoriaId,
      kcal: data.kcal.present ? data.kcal.value : this.kcal,
      proteinas: data.proteinas.present ? data.proteinas.value : this.proteinas,
      grasas: data.grasas.present ? data.grasas.value : this.grasas,
      grasasSaturadas: data.grasasSaturadas.present
          ? data.grasasSaturadas.value
          : this.grasasSaturadas,
      carbohidratos: data.carbohidratos.present
          ? data.carbohidratos.value
          : this.carbohidratos,
      azucares: data.azucares.present ? data.azucares.value : this.azucares,
      fibra: data.fibra.present ? data.fibra.value : this.fibra,
      sal: data.sal.present ? data.sal.value : this.sal,
      nutricionOrigen: data.nutricionOrigen.present
          ? data.nutricionOrigen.value
          : this.nutricionOrigen,
      notas: data.notas.present ? data.notas.value : this.notas,
      usoCount: data.usoCount.present ? data.usoCount.value : this.usoCount,
      ultimoUso: data.ultimoUso.present ? data.ultimoUso.value : this.ultimoUso,
      archivado: data.archivado.present ? data.archivado.value : this.archivado,
      creado: data.creado.present ? data.creado.value : this.creado,
      actualizado: data.actualizado.present
          ? data.actualizado.value
          : this.actualizado,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AlimentoRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('nombre: $nombre, ')
          ..write('marca: $marca, ')
          ..write('tipo: $tipo, ')
          ..write('unidad: $unidad, ')
          ..write('categoriaId: $categoriaId, ')
          ..write('kcal: $kcal, ')
          ..write('proteinas: $proteinas, ')
          ..write('grasas: $grasas, ')
          ..write('grasasSaturadas: $grasasSaturadas, ')
          ..write('carbohidratos: $carbohidratos, ')
          ..write('azucares: $azucares, ')
          ..write('fibra: $fibra, ')
          ..write('sal: $sal, ')
          ..write('nutricionOrigen: $nutricionOrigen, ')
          ..write('notas: $notas, ')
          ..write('usoCount: $usoCount, ')
          ..write('ultimoUso: $ultimoUso, ')
          ..write('archivado: $archivado, ')
          ..write('creado: $creado, ')
          ..write('actualizado: $actualizado')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    uuid,
    nombre,
    marca,
    tipo,
    unidad,
    categoriaId,
    kcal,
    proteinas,
    grasas,
    grasasSaturadas,
    carbohidratos,
    azucares,
    fibra,
    sal,
    nutricionOrigen,
    notas,
    usoCount,
    ultimoUso,
    archivado,
    creado,
    actualizado,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlimentoRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.nombre == this.nombre &&
          other.marca == this.marca &&
          other.tipo == this.tipo &&
          other.unidad == this.unidad &&
          other.categoriaId == this.categoriaId &&
          other.kcal == this.kcal &&
          other.proteinas == this.proteinas &&
          other.grasas == this.grasas &&
          other.grasasSaturadas == this.grasasSaturadas &&
          other.carbohidratos == this.carbohidratos &&
          other.azucares == this.azucares &&
          other.fibra == this.fibra &&
          other.sal == this.sal &&
          other.nutricionOrigen == this.nutricionOrigen &&
          other.notas == this.notas &&
          other.usoCount == this.usoCount &&
          other.ultimoUso == this.ultimoUso &&
          other.archivado == this.archivado &&
          other.creado == this.creado &&
          other.actualizado == this.actualizado);
}

class AlimentosCompanion extends UpdateCompanion<AlimentoRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> nombre;
  final Value<String> marca;
  final Value<String> tipo;
  final Value<String> unidad;
  final Value<int?> categoriaId;
  final Value<double?> kcal;
  final Value<double?> proteinas;
  final Value<double?> grasas;
  final Value<double?> grasasSaturadas;
  final Value<double?> carbohidratos;
  final Value<double?> azucares;
  final Value<double?> fibra;
  final Value<double?> sal;
  final Value<String?> nutricionOrigen;
  final Value<String?> notas;
  final Value<int> usoCount;
  final Value<String?> ultimoUso;
  final Value<bool> archivado;
  final Value<String> creado;
  final Value<String> actualizado;
  const AlimentosCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.nombre = const Value.absent(),
    this.marca = const Value.absent(),
    this.tipo = const Value.absent(),
    this.unidad = const Value.absent(),
    this.categoriaId = const Value.absent(),
    this.kcal = const Value.absent(),
    this.proteinas = const Value.absent(),
    this.grasas = const Value.absent(),
    this.grasasSaturadas = const Value.absent(),
    this.carbohidratos = const Value.absent(),
    this.azucares = const Value.absent(),
    this.fibra = const Value.absent(),
    this.sal = const Value.absent(),
    this.nutricionOrigen = const Value.absent(),
    this.notas = const Value.absent(),
    this.usoCount = const Value.absent(),
    this.ultimoUso = const Value.absent(),
    this.archivado = const Value.absent(),
    this.creado = const Value.absent(),
    this.actualizado = const Value.absent(),
  });
  AlimentosCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String nombre,
    this.marca = const Value.absent(),
    this.tipo = const Value.absent(),
    this.unidad = const Value.absent(),
    this.categoriaId = const Value.absent(),
    this.kcal = const Value.absent(),
    this.proteinas = const Value.absent(),
    this.grasas = const Value.absent(),
    this.grasasSaturadas = const Value.absent(),
    this.carbohidratos = const Value.absent(),
    this.azucares = const Value.absent(),
    this.fibra = const Value.absent(),
    this.sal = const Value.absent(),
    this.nutricionOrigen = const Value.absent(),
    this.notas = const Value.absent(),
    this.usoCount = const Value.absent(),
    this.ultimoUso = const Value.absent(),
    this.archivado = const Value.absent(),
    required String creado,
    required String actualizado,
  }) : uuid = Value(uuid),
       nombre = Value(nombre),
       creado = Value(creado),
       actualizado = Value(actualizado);
  static Insertable<AlimentoRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? nombre,
    Expression<String>? marca,
    Expression<String>? tipo,
    Expression<String>? unidad,
    Expression<int>? categoriaId,
    Expression<double>? kcal,
    Expression<double>? proteinas,
    Expression<double>? grasas,
    Expression<double>? grasasSaturadas,
    Expression<double>? carbohidratos,
    Expression<double>? azucares,
    Expression<double>? fibra,
    Expression<double>? sal,
    Expression<String>? nutricionOrigen,
    Expression<String>? notas,
    Expression<int>? usoCount,
    Expression<String>? ultimoUso,
    Expression<bool>? archivado,
    Expression<String>? creado,
    Expression<String>? actualizado,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (nombre != null) 'nombre': nombre,
      if (marca != null) 'marca': marca,
      if (tipo != null) 'tipo': tipo,
      if (unidad != null) 'unidad': unidad,
      if (categoriaId != null) 'categoria_id': categoriaId,
      if (kcal != null) 'kcal': kcal,
      if (proteinas != null) 'proteinas': proteinas,
      if (grasas != null) 'grasas': grasas,
      if (grasasSaturadas != null) 'grasas_saturadas': grasasSaturadas,
      if (carbohidratos != null) 'carbohidratos': carbohidratos,
      if (azucares != null) 'azucares': azucares,
      if (fibra != null) 'fibra': fibra,
      if (sal != null) 'sal': sal,
      if (nutricionOrigen != null) 'nutricion_origen': nutricionOrigen,
      if (notas != null) 'notas': notas,
      if (usoCount != null) 'uso_count': usoCount,
      if (ultimoUso != null) 'ultimo_uso': ultimoUso,
      if (archivado != null) 'archivado': archivado,
      if (creado != null) 'creado': creado,
      if (actualizado != null) 'actualizado': actualizado,
    });
  }

  AlimentosCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String>? nombre,
    Value<String>? marca,
    Value<String>? tipo,
    Value<String>? unidad,
    Value<int?>? categoriaId,
    Value<double?>? kcal,
    Value<double?>? proteinas,
    Value<double?>? grasas,
    Value<double?>? grasasSaturadas,
    Value<double?>? carbohidratos,
    Value<double?>? azucares,
    Value<double?>? fibra,
    Value<double?>? sal,
    Value<String?>? nutricionOrigen,
    Value<String?>? notas,
    Value<int>? usoCount,
    Value<String?>? ultimoUso,
    Value<bool>? archivado,
    Value<String>? creado,
    Value<String>? actualizado,
  }) {
    return AlimentosCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      nombre: nombre ?? this.nombre,
      marca: marca ?? this.marca,
      tipo: tipo ?? this.tipo,
      unidad: unidad ?? this.unidad,
      categoriaId: categoriaId ?? this.categoriaId,
      kcal: kcal ?? this.kcal,
      proteinas: proteinas ?? this.proteinas,
      grasas: grasas ?? this.grasas,
      grasasSaturadas: grasasSaturadas ?? this.grasasSaturadas,
      carbohidratos: carbohidratos ?? this.carbohidratos,
      azucares: azucares ?? this.azucares,
      fibra: fibra ?? this.fibra,
      sal: sal ?? this.sal,
      nutricionOrigen: nutricionOrigen ?? this.nutricionOrigen,
      notas: notas ?? this.notas,
      usoCount: usoCount ?? this.usoCount,
      ultimoUso: ultimoUso ?? this.ultimoUso,
      archivado: archivado ?? this.archivado,
      creado: creado ?? this.creado,
      actualizado: actualizado ?? this.actualizado,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (marca.present) {
      map['marca'] = Variable<String>(marca.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (unidad.present) {
      map['unidad'] = Variable<String>(unidad.value);
    }
    if (categoriaId.present) {
      map['categoria_id'] = Variable<int>(categoriaId.value);
    }
    if (kcal.present) {
      map['kcal'] = Variable<double>(kcal.value);
    }
    if (proteinas.present) {
      map['proteinas'] = Variable<double>(proteinas.value);
    }
    if (grasas.present) {
      map['grasas'] = Variable<double>(grasas.value);
    }
    if (grasasSaturadas.present) {
      map['grasas_saturadas'] = Variable<double>(grasasSaturadas.value);
    }
    if (carbohidratos.present) {
      map['carbohidratos'] = Variable<double>(carbohidratos.value);
    }
    if (azucares.present) {
      map['azucares'] = Variable<double>(azucares.value);
    }
    if (fibra.present) {
      map['fibra'] = Variable<double>(fibra.value);
    }
    if (sal.present) {
      map['sal'] = Variable<double>(sal.value);
    }
    if (nutricionOrigen.present) {
      map['nutricion_origen'] = Variable<String>(nutricionOrigen.value);
    }
    if (notas.present) {
      map['notas'] = Variable<String>(notas.value);
    }
    if (usoCount.present) {
      map['uso_count'] = Variable<int>(usoCount.value);
    }
    if (ultimoUso.present) {
      map['ultimo_uso'] = Variable<String>(ultimoUso.value);
    }
    if (archivado.present) {
      map['archivado'] = Variable<bool>(archivado.value);
    }
    if (creado.present) {
      map['creado'] = Variable<String>(creado.value);
    }
    if (actualizado.present) {
      map['actualizado'] = Variable<String>(actualizado.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlimentosCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('nombre: $nombre, ')
          ..write('marca: $marca, ')
          ..write('tipo: $tipo, ')
          ..write('unidad: $unidad, ')
          ..write('categoriaId: $categoriaId, ')
          ..write('kcal: $kcal, ')
          ..write('proteinas: $proteinas, ')
          ..write('grasas: $grasas, ')
          ..write('grasasSaturadas: $grasasSaturadas, ')
          ..write('carbohidratos: $carbohidratos, ')
          ..write('azucares: $azucares, ')
          ..write('fibra: $fibra, ')
          ..write('sal: $sal, ')
          ..write('nutricionOrigen: $nutricionOrigen, ')
          ..write('notas: $notas, ')
          ..write('usoCount: $usoCount, ')
          ..write('ultimoUso: $ultimoUso, ')
          ..write('archivado: $archivado, ')
          ..write('creado: $creado, ')
          ..write('actualizado: $actualizado')
          ..write(')'))
        .toString();
  }
}

class $PorcionesTable extends Porciones
    with TableInfo<$PorcionesTable, PorcionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PorcionesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _alimentoIdMeta = const VerificationMeta(
    'alimentoId',
  );
  @override
  late final GeneratedColumn<int> alimentoId = GeneratedColumn<int>(
    'alimento_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES alimentos (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL COLLATE NOCASE',
  );
  static const VerificationMeta _gramosMeta = const VerificationMeta('gramos');
  @override
  late final GeneratedColumn<double> gramos = GeneratedColumn<double>(
    'gramos',
    aliasedName,
    false,
    check: () => ComparableExpr(gramos).isBiggerThanValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, alimentoId, nombre, gramos];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'porciones';
  @override
  VerificationContext validateIntegrity(
    Insertable<PorcionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('alimento_id')) {
      context.handle(
        _alimentoIdMeta,
        alimentoId.isAcceptableOrUnknown(data['alimento_id']!, _alimentoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_alimentoIdMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('gramos')) {
      context.handle(
        _gramosMeta,
        gramos.isAcceptableOrUnknown(data['gramos']!, _gramosMeta),
      );
    } else if (isInserting) {
      context.missing(_gramosMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {alimentoId, nombre},
  ];
  @override
  PorcionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PorcionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      alimentoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}alimento_id'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      gramos: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}gramos'],
      )!,
    );
  }

  @override
  $PorcionesTable createAlias(String alias) {
    return $PorcionesTable(attachedDatabase, alias);
  }
}

class PorcionRow extends DataClass implements Insertable<PorcionRow> {
  final int id;
  final int alimentoId;
  final String nombre;
  final double gramos;
  const PorcionRow({
    required this.id,
    required this.alimentoId,
    required this.nombre,
    required this.gramos,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['alimento_id'] = Variable<int>(alimentoId);
    map['nombre'] = Variable<String>(nombre);
    map['gramos'] = Variable<double>(gramos);
    return map;
  }

  PorcionesCompanion toCompanion(bool nullToAbsent) {
    return PorcionesCompanion(
      id: Value(id),
      alimentoId: Value(alimentoId),
      nombre: Value(nombre),
      gramos: Value(gramos),
    );
  }

  factory PorcionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PorcionRow(
      id: serializer.fromJson<int>(json['id']),
      alimentoId: serializer.fromJson<int>(json['alimentoId']),
      nombre: serializer.fromJson<String>(json['nombre']),
      gramos: serializer.fromJson<double>(json['gramos']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'alimentoId': serializer.toJson<int>(alimentoId),
      'nombre': serializer.toJson<String>(nombre),
      'gramos': serializer.toJson<double>(gramos),
    };
  }

  PorcionRow copyWith({
    int? id,
    int? alimentoId,
    String? nombre,
    double? gramos,
  }) => PorcionRow(
    id: id ?? this.id,
    alimentoId: alimentoId ?? this.alimentoId,
    nombre: nombre ?? this.nombre,
    gramos: gramos ?? this.gramos,
  );
  PorcionRow copyWithCompanion(PorcionesCompanion data) {
    return PorcionRow(
      id: data.id.present ? data.id.value : this.id,
      alimentoId: data.alimentoId.present
          ? data.alimentoId.value
          : this.alimentoId,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      gramos: data.gramos.present ? data.gramos.value : this.gramos,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PorcionRow(')
          ..write('id: $id, ')
          ..write('alimentoId: $alimentoId, ')
          ..write('nombre: $nombre, ')
          ..write('gramos: $gramos')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, alimentoId, nombre, gramos);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PorcionRow &&
          other.id == this.id &&
          other.alimentoId == this.alimentoId &&
          other.nombre == this.nombre &&
          other.gramos == this.gramos);
}

class PorcionesCompanion extends UpdateCompanion<PorcionRow> {
  final Value<int> id;
  final Value<int> alimentoId;
  final Value<String> nombre;
  final Value<double> gramos;
  const PorcionesCompanion({
    this.id = const Value.absent(),
    this.alimentoId = const Value.absent(),
    this.nombre = const Value.absent(),
    this.gramos = const Value.absent(),
  });
  PorcionesCompanion.insert({
    this.id = const Value.absent(),
    required int alimentoId,
    required String nombre,
    required double gramos,
  }) : alimentoId = Value(alimentoId),
       nombre = Value(nombre),
       gramos = Value(gramos);
  static Insertable<PorcionRow> custom({
    Expression<int>? id,
    Expression<int>? alimentoId,
    Expression<String>? nombre,
    Expression<double>? gramos,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (alimentoId != null) 'alimento_id': alimentoId,
      if (nombre != null) 'nombre': nombre,
      if (gramos != null) 'gramos': gramos,
    });
  }

  PorcionesCompanion copyWith({
    Value<int>? id,
    Value<int>? alimentoId,
    Value<String>? nombre,
    Value<double>? gramos,
  }) {
    return PorcionesCompanion(
      id: id ?? this.id,
      alimentoId: alimentoId ?? this.alimentoId,
      nombre: nombre ?? this.nombre,
      gramos: gramos ?? this.gramos,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (alimentoId.present) {
      map['alimento_id'] = Variable<int>(alimentoId.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (gramos.present) {
      map['gramos'] = Variable<double>(gramos.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PorcionesCompanion(')
          ..write('id: $id, ')
          ..write('alimentoId: $alimentoId, ')
          ..write('nombre: $nombre, ')
          ..write('gramos: $gramos')
          ..write(')'))
        .toString();
  }
}

class $PresentacionesTable extends Presentaciones
    with TableInfo<$PresentacionesTable, PresentacionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PresentacionesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _alimentoIdMeta = const VerificationMeta(
    'alimentoId',
  );
  @override
  late final GeneratedColumn<int> alimentoId = GeneratedColumn<int>(
    'alimento_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES alimentos (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _codigoBarrasMeta = const VerificationMeta(
    'codigoBarras',
  );
  @override
  late final GeneratedColumn<String> codigoBarras = GeneratedColumn<String>(
    'codigo_barras',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _descripcionMeta = const VerificationMeta(
    'descripcion',
  );
  @override
  late final GeneratedColumn<String> descripcion = GeneratedColumn<String>(
    'descripcion',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _contenidoMeta = const VerificationMeta(
    'contenido',
  );
  @override
  late final GeneratedColumn<double> contenido = GeneratedColumn<double>(
    'contenido',
    aliasedName,
    true,
    check: () => ComparableExpr(contenido).isBiggerThanValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivadoMeta = const VerificationMeta(
    'archivado',
  );
  @override
  late final GeneratedColumn<bool> archivado = GeneratedColumn<bool>(
    'archivado',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archivado" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _creadoMeta = const VerificationMeta('creado');
  @override
  late final GeneratedColumn<String> creado = GeneratedColumn<String>(
    'creado',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actualizadoMeta = const VerificationMeta(
    'actualizado',
  );
  @override
  late final GeneratedColumn<String> actualizado = GeneratedColumn<String>(
    'actualizado',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    alimentoId,
    codigoBarras,
    descripcion,
    contenido,
    archivado,
    creado,
    actualizado,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'presentaciones';
  @override
  VerificationContext validateIntegrity(
    Insertable<PresentacionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('alimento_id')) {
      context.handle(
        _alimentoIdMeta,
        alimentoId.isAcceptableOrUnknown(data['alimento_id']!, _alimentoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_alimentoIdMeta);
    }
    if (data.containsKey('codigo_barras')) {
      context.handle(
        _codigoBarrasMeta,
        codigoBarras.isAcceptableOrUnknown(
          data['codigo_barras']!,
          _codigoBarrasMeta,
        ),
      );
    }
    if (data.containsKey('descripcion')) {
      context.handle(
        _descripcionMeta,
        descripcion.isAcceptableOrUnknown(
          data['descripcion']!,
          _descripcionMeta,
        ),
      );
    }
    if (data.containsKey('contenido')) {
      context.handle(
        _contenidoMeta,
        contenido.isAcceptableOrUnknown(data['contenido']!, _contenidoMeta),
      );
    }
    if (data.containsKey('archivado')) {
      context.handle(
        _archivadoMeta,
        archivado.isAcceptableOrUnknown(data['archivado']!, _archivadoMeta),
      );
    }
    if (data.containsKey('creado')) {
      context.handle(
        _creadoMeta,
        creado.isAcceptableOrUnknown(data['creado']!, _creadoMeta),
      );
    } else if (isInserting) {
      context.missing(_creadoMeta);
    }
    if (data.containsKey('actualizado')) {
      context.handle(
        _actualizadoMeta,
        actualizado.isAcceptableOrUnknown(
          data['actualizado']!,
          _actualizadoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_actualizadoMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PresentacionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PresentacionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      alimentoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}alimento_id'],
      )!,
      codigoBarras: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}codigo_barras'],
      ),
      descripcion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}descripcion'],
      )!,
      contenido: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}contenido'],
      ),
      archivado: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archivado'],
      )!,
      creado: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}creado'],
      )!,
      actualizado: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actualizado'],
      )!,
    );
  }

  @override
  $PresentacionesTable createAlias(String alias) {
    return $PresentacionesTable(attachedDatabase, alias);
  }
}

class PresentacionRow extends DataClass implements Insertable<PresentacionRow> {
  final int id;
  final String uuid;
  final int alimentoId;
  final String? codigoBarras;
  final String descripcion;
  final double? contenido;
  final bool archivado;
  final String creado;
  final String actualizado;
  const PresentacionRow({
    required this.id,
    required this.uuid,
    required this.alimentoId,
    this.codigoBarras,
    required this.descripcion,
    this.contenido,
    required this.archivado,
    required this.creado,
    required this.actualizado,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['alimento_id'] = Variable<int>(alimentoId);
    if (!nullToAbsent || codigoBarras != null) {
      map['codigo_barras'] = Variable<String>(codigoBarras);
    }
    map['descripcion'] = Variable<String>(descripcion);
    if (!nullToAbsent || contenido != null) {
      map['contenido'] = Variable<double>(contenido);
    }
    map['archivado'] = Variable<bool>(archivado);
    map['creado'] = Variable<String>(creado);
    map['actualizado'] = Variable<String>(actualizado);
    return map;
  }

  PresentacionesCompanion toCompanion(bool nullToAbsent) {
    return PresentacionesCompanion(
      id: Value(id),
      uuid: Value(uuid),
      alimentoId: Value(alimentoId),
      codigoBarras: codigoBarras == null && nullToAbsent
          ? const Value.absent()
          : Value(codigoBarras),
      descripcion: Value(descripcion),
      contenido: contenido == null && nullToAbsent
          ? const Value.absent()
          : Value(contenido),
      archivado: Value(archivado),
      creado: Value(creado),
      actualizado: Value(actualizado),
    );
  }

  factory PresentacionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PresentacionRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      alimentoId: serializer.fromJson<int>(json['alimentoId']),
      codigoBarras: serializer.fromJson<String?>(json['codigoBarras']),
      descripcion: serializer.fromJson<String>(json['descripcion']),
      contenido: serializer.fromJson<double?>(json['contenido']),
      archivado: serializer.fromJson<bool>(json['archivado']),
      creado: serializer.fromJson<String>(json['creado']),
      actualizado: serializer.fromJson<String>(json['actualizado']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'alimentoId': serializer.toJson<int>(alimentoId),
      'codigoBarras': serializer.toJson<String?>(codigoBarras),
      'descripcion': serializer.toJson<String>(descripcion),
      'contenido': serializer.toJson<double?>(contenido),
      'archivado': serializer.toJson<bool>(archivado),
      'creado': serializer.toJson<String>(creado),
      'actualizado': serializer.toJson<String>(actualizado),
    };
  }

  PresentacionRow copyWith({
    int? id,
    String? uuid,
    int? alimentoId,
    Value<String?> codigoBarras = const Value.absent(),
    String? descripcion,
    Value<double?> contenido = const Value.absent(),
    bool? archivado,
    String? creado,
    String? actualizado,
  }) => PresentacionRow(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    alimentoId: alimentoId ?? this.alimentoId,
    codigoBarras: codigoBarras.present ? codigoBarras.value : this.codigoBarras,
    descripcion: descripcion ?? this.descripcion,
    contenido: contenido.present ? contenido.value : this.contenido,
    archivado: archivado ?? this.archivado,
    creado: creado ?? this.creado,
    actualizado: actualizado ?? this.actualizado,
  );
  PresentacionRow copyWithCompanion(PresentacionesCompanion data) {
    return PresentacionRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      alimentoId: data.alimentoId.present
          ? data.alimentoId.value
          : this.alimentoId,
      codigoBarras: data.codigoBarras.present
          ? data.codigoBarras.value
          : this.codigoBarras,
      descripcion: data.descripcion.present
          ? data.descripcion.value
          : this.descripcion,
      contenido: data.contenido.present ? data.contenido.value : this.contenido,
      archivado: data.archivado.present ? data.archivado.value : this.archivado,
      creado: data.creado.present ? data.creado.value : this.creado,
      actualizado: data.actualizado.present
          ? data.actualizado.value
          : this.actualizado,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PresentacionRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('alimentoId: $alimentoId, ')
          ..write('codigoBarras: $codigoBarras, ')
          ..write('descripcion: $descripcion, ')
          ..write('contenido: $contenido, ')
          ..write('archivado: $archivado, ')
          ..write('creado: $creado, ')
          ..write('actualizado: $actualizado')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    alimentoId,
    codigoBarras,
    descripcion,
    contenido,
    archivado,
    creado,
    actualizado,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PresentacionRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.alimentoId == this.alimentoId &&
          other.codigoBarras == this.codigoBarras &&
          other.descripcion == this.descripcion &&
          other.contenido == this.contenido &&
          other.archivado == this.archivado &&
          other.creado == this.creado &&
          other.actualizado == this.actualizado);
}

class PresentacionesCompanion extends UpdateCompanion<PresentacionRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<int> alimentoId;
  final Value<String?> codigoBarras;
  final Value<String> descripcion;
  final Value<double?> contenido;
  final Value<bool> archivado;
  final Value<String> creado;
  final Value<String> actualizado;
  const PresentacionesCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.alimentoId = const Value.absent(),
    this.codigoBarras = const Value.absent(),
    this.descripcion = const Value.absent(),
    this.contenido = const Value.absent(),
    this.archivado = const Value.absent(),
    this.creado = const Value.absent(),
    this.actualizado = const Value.absent(),
  });
  PresentacionesCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required int alimentoId,
    this.codigoBarras = const Value.absent(),
    this.descripcion = const Value.absent(),
    this.contenido = const Value.absent(),
    this.archivado = const Value.absent(),
    required String creado,
    required String actualizado,
  }) : uuid = Value(uuid),
       alimentoId = Value(alimentoId),
       creado = Value(creado),
       actualizado = Value(actualizado);
  static Insertable<PresentacionRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<int>? alimentoId,
    Expression<String>? codigoBarras,
    Expression<String>? descripcion,
    Expression<double>? contenido,
    Expression<bool>? archivado,
    Expression<String>? creado,
    Expression<String>? actualizado,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (alimentoId != null) 'alimento_id': alimentoId,
      if (codigoBarras != null) 'codigo_barras': codigoBarras,
      if (descripcion != null) 'descripcion': descripcion,
      if (contenido != null) 'contenido': contenido,
      if (archivado != null) 'archivado': archivado,
      if (creado != null) 'creado': creado,
      if (actualizado != null) 'actualizado': actualizado,
    });
  }

  PresentacionesCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<int>? alimentoId,
    Value<String?>? codigoBarras,
    Value<String>? descripcion,
    Value<double?>? contenido,
    Value<bool>? archivado,
    Value<String>? creado,
    Value<String>? actualizado,
  }) {
    return PresentacionesCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      alimentoId: alimentoId ?? this.alimentoId,
      codigoBarras: codigoBarras ?? this.codigoBarras,
      descripcion: descripcion ?? this.descripcion,
      contenido: contenido ?? this.contenido,
      archivado: archivado ?? this.archivado,
      creado: creado ?? this.creado,
      actualizado: actualizado ?? this.actualizado,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (alimentoId.present) {
      map['alimento_id'] = Variable<int>(alimentoId.value);
    }
    if (codigoBarras.present) {
      map['codigo_barras'] = Variable<String>(codigoBarras.value);
    }
    if (descripcion.present) {
      map['descripcion'] = Variable<String>(descripcion.value);
    }
    if (contenido.present) {
      map['contenido'] = Variable<double>(contenido.value);
    }
    if (archivado.present) {
      map['archivado'] = Variable<bool>(archivado.value);
    }
    if (creado.present) {
      map['creado'] = Variable<String>(creado.value);
    }
    if (actualizado.present) {
      map['actualizado'] = Variable<String>(actualizado.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PresentacionesCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('alimentoId: $alimentoId, ')
          ..write('codigoBarras: $codigoBarras, ')
          ..write('descripcion: $descripcion, ')
          ..write('contenido: $contenido, ')
          ..write('archivado: $archivado, ')
          ..write('creado: $creado, ')
          ..write('actualizado: $actualizado')
          ..write(')'))
        .toString();
  }
}

class $EstablecimientosTable extends Establecimientos
    with TableInfo<$EstablecimientosTable, EstablecimientoRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EstablecimientosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE COLLATE NOCASE',
  );
  static const VerificationMeta _formatoBasculaMeta = const VerificationMeta(
    'formatoBascula',
  );
  @override
  late final GeneratedColumn<String> formatoBascula = GeneratedColumn<String>(
    'formato_bascula',
    aliasedName,
    true,
    check: () => formatoBascula.isIn(['precio', 'peso']),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudClaveMeta = const VerificationMeta(
    'longitudClave',
  );
  @override
  late final GeneratedColumn<int> longitudClave = GeneratedColumn<int>(
    'longitud_clave',
    aliasedName,
    false,
    check: () => longitudClave.isIn([6, 7]),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(7),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nombre,
    formatoBascula,
    longitudClave,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'establecimientos';
  @override
  VerificationContext validateIntegrity(
    Insertable<EstablecimientoRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('formato_bascula')) {
      context.handle(
        _formatoBasculaMeta,
        formatoBascula.isAcceptableOrUnknown(
          data['formato_bascula']!,
          _formatoBasculaMeta,
        ),
      );
    }
    if (data.containsKey('longitud_clave')) {
      context.handle(
        _longitudClaveMeta,
        longitudClave.isAcceptableOrUnknown(
          data['longitud_clave']!,
          _longitudClaveMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EstablecimientoRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EstablecimientoRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      formatoBascula: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}formato_bascula'],
      ),
      longitudClave: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}longitud_clave'],
      )!,
    );
  }

  @override
  $EstablecimientosTable createAlias(String alias) {
    return $EstablecimientosTable(attachedDatabase, alias);
  }
}

class EstablecimientoRow extends DataClass
    implements Insertable<EstablecimientoRow> {
  final int id;
  final String nombre;
  final String? formatoBascula;
  final int longitudClave;
  const EstablecimientoRow({
    required this.id,
    required this.nombre,
    this.formatoBascula,
    required this.longitudClave,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nombre'] = Variable<String>(nombre);
    if (!nullToAbsent || formatoBascula != null) {
      map['formato_bascula'] = Variable<String>(formatoBascula);
    }
    map['longitud_clave'] = Variable<int>(longitudClave);
    return map;
  }

  EstablecimientosCompanion toCompanion(bool nullToAbsent) {
    return EstablecimientosCompanion(
      id: Value(id),
      nombre: Value(nombre),
      formatoBascula: formatoBascula == null && nullToAbsent
          ? const Value.absent()
          : Value(formatoBascula),
      longitudClave: Value(longitudClave),
    );
  }

  factory EstablecimientoRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EstablecimientoRow(
      id: serializer.fromJson<int>(json['id']),
      nombre: serializer.fromJson<String>(json['nombre']),
      formatoBascula: serializer.fromJson<String?>(json['formatoBascula']),
      longitudClave: serializer.fromJson<int>(json['longitudClave']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nombre': serializer.toJson<String>(nombre),
      'formatoBascula': serializer.toJson<String?>(formatoBascula),
      'longitudClave': serializer.toJson<int>(longitudClave),
    };
  }

  EstablecimientoRow copyWith({
    int? id,
    String? nombre,
    Value<String?> formatoBascula = const Value.absent(),
    int? longitudClave,
  }) => EstablecimientoRow(
    id: id ?? this.id,
    nombre: nombre ?? this.nombre,
    formatoBascula: formatoBascula.present
        ? formatoBascula.value
        : this.formatoBascula,
    longitudClave: longitudClave ?? this.longitudClave,
  );
  EstablecimientoRow copyWithCompanion(EstablecimientosCompanion data) {
    return EstablecimientoRow(
      id: data.id.present ? data.id.value : this.id,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      formatoBascula: data.formatoBascula.present
          ? data.formatoBascula.value
          : this.formatoBascula,
      longitudClave: data.longitudClave.present
          ? data.longitudClave.value
          : this.longitudClave,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EstablecimientoRow(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('formatoBascula: $formatoBascula, ')
          ..write('longitudClave: $longitudClave')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nombre, formatoBascula, longitudClave);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EstablecimientoRow &&
          other.id == this.id &&
          other.nombre == this.nombre &&
          other.formatoBascula == this.formatoBascula &&
          other.longitudClave == this.longitudClave);
}

class EstablecimientosCompanion extends UpdateCompanion<EstablecimientoRow> {
  final Value<int> id;
  final Value<String> nombre;
  final Value<String?> formatoBascula;
  final Value<int> longitudClave;
  const EstablecimientosCompanion({
    this.id = const Value.absent(),
    this.nombre = const Value.absent(),
    this.formatoBascula = const Value.absent(),
    this.longitudClave = const Value.absent(),
  });
  EstablecimientosCompanion.insert({
    this.id = const Value.absent(),
    required String nombre,
    this.formatoBascula = const Value.absent(),
    this.longitudClave = const Value.absent(),
  }) : nombre = Value(nombre);
  static Insertable<EstablecimientoRow> custom({
    Expression<int>? id,
    Expression<String>? nombre,
    Expression<String>? formatoBascula,
    Expression<int>? longitudClave,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nombre != null) 'nombre': nombre,
      if (formatoBascula != null) 'formato_bascula': formatoBascula,
      if (longitudClave != null) 'longitud_clave': longitudClave,
    });
  }

  EstablecimientosCompanion copyWith({
    Value<int>? id,
    Value<String>? nombre,
    Value<String?>? formatoBascula,
    Value<int>? longitudClave,
  }) {
    return EstablecimientosCompanion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      formatoBascula: formatoBascula ?? this.formatoBascula,
      longitudClave: longitudClave ?? this.longitudClave,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (formatoBascula.present) {
      map['formato_bascula'] = Variable<String>(formatoBascula.value);
    }
    if (longitudClave.present) {
      map['longitud_clave'] = Variable<int>(longitudClave.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EstablecimientosCompanion(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('formatoBascula: $formatoBascula, ')
          ..write('longitudClave: $longitudClave')
          ..write(')'))
        .toString();
  }
}

class $OrdenPasillosTable extends OrdenPasillos
    with TableInfo<$OrdenPasillosTable, OrdenPasilloRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrdenPasillosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _establecimientoIdMeta = const VerificationMeta(
    'establecimientoId',
  );
  @override
  late final GeneratedColumn<int> establecimientoId = GeneratedColumn<int>(
    'establecimiento_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES establecimientos (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _categoriaIdMeta = const VerificationMeta(
    'categoriaId',
  );
  @override
  late final GeneratedColumn<int> categoriaId = GeneratedColumn<int>(
    'categoria_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categorias (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _ordenMeta = const VerificationMeta('orden');
  @override
  late final GeneratedColumn<int> orden = GeneratedColumn<int>(
    'orden',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [establecimientoId, categoriaId, orden];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'orden_pasillos';
  @override
  VerificationContext validateIntegrity(
    Insertable<OrdenPasilloRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('establecimiento_id')) {
      context.handle(
        _establecimientoIdMeta,
        establecimientoId.isAcceptableOrUnknown(
          data['establecimiento_id']!,
          _establecimientoIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_establecimientoIdMeta);
    }
    if (data.containsKey('categoria_id')) {
      context.handle(
        _categoriaIdMeta,
        categoriaId.isAcceptableOrUnknown(
          data['categoria_id']!,
          _categoriaIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_categoriaIdMeta);
    }
    if (data.containsKey('orden')) {
      context.handle(
        _ordenMeta,
        orden.isAcceptableOrUnknown(data['orden']!, _ordenMeta),
      );
    } else if (isInserting) {
      context.missing(_ordenMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {establecimientoId, categoriaId};
  @override
  OrdenPasilloRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrdenPasilloRow(
      establecimientoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}establecimiento_id'],
      )!,
      categoriaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}categoria_id'],
      )!,
      orden: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}orden'],
      )!,
    );
  }

  @override
  $OrdenPasillosTable createAlias(String alias) {
    return $OrdenPasillosTable(attachedDatabase, alias);
  }
}

class OrdenPasilloRow extends DataClass implements Insertable<OrdenPasilloRow> {
  final int establecimientoId;
  final int categoriaId;
  final int orden;
  const OrdenPasilloRow({
    required this.establecimientoId,
    required this.categoriaId,
    required this.orden,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['establecimiento_id'] = Variable<int>(establecimientoId);
    map['categoria_id'] = Variable<int>(categoriaId);
    map['orden'] = Variable<int>(orden);
    return map;
  }

  OrdenPasillosCompanion toCompanion(bool nullToAbsent) {
    return OrdenPasillosCompanion(
      establecimientoId: Value(establecimientoId),
      categoriaId: Value(categoriaId),
      orden: Value(orden),
    );
  }

  factory OrdenPasilloRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrdenPasilloRow(
      establecimientoId: serializer.fromJson<int>(json['establecimientoId']),
      categoriaId: serializer.fromJson<int>(json['categoriaId']),
      orden: serializer.fromJson<int>(json['orden']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'establecimientoId': serializer.toJson<int>(establecimientoId),
      'categoriaId': serializer.toJson<int>(categoriaId),
      'orden': serializer.toJson<int>(orden),
    };
  }

  OrdenPasilloRow copyWith({
    int? establecimientoId,
    int? categoriaId,
    int? orden,
  }) => OrdenPasilloRow(
    establecimientoId: establecimientoId ?? this.establecimientoId,
    categoriaId: categoriaId ?? this.categoriaId,
    orden: orden ?? this.orden,
  );
  OrdenPasilloRow copyWithCompanion(OrdenPasillosCompanion data) {
    return OrdenPasilloRow(
      establecimientoId: data.establecimientoId.present
          ? data.establecimientoId.value
          : this.establecimientoId,
      categoriaId: data.categoriaId.present
          ? data.categoriaId.value
          : this.categoriaId,
      orden: data.orden.present ? data.orden.value : this.orden,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrdenPasilloRow(')
          ..write('establecimientoId: $establecimientoId, ')
          ..write('categoriaId: $categoriaId, ')
          ..write('orden: $orden')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(establecimientoId, categoriaId, orden);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrdenPasilloRow &&
          other.establecimientoId == this.establecimientoId &&
          other.categoriaId == this.categoriaId &&
          other.orden == this.orden);
}

class OrdenPasillosCompanion extends UpdateCompanion<OrdenPasilloRow> {
  final Value<int> establecimientoId;
  final Value<int> categoriaId;
  final Value<int> orden;
  final Value<int> rowid;
  const OrdenPasillosCompanion({
    this.establecimientoId = const Value.absent(),
    this.categoriaId = const Value.absent(),
    this.orden = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrdenPasillosCompanion.insert({
    required int establecimientoId,
    required int categoriaId,
    required int orden,
    this.rowid = const Value.absent(),
  }) : establecimientoId = Value(establecimientoId),
       categoriaId = Value(categoriaId),
       orden = Value(orden);
  static Insertable<OrdenPasilloRow> custom({
    Expression<int>? establecimientoId,
    Expression<int>? categoriaId,
    Expression<int>? orden,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (establecimientoId != null) 'establecimiento_id': establecimientoId,
      if (categoriaId != null) 'categoria_id': categoriaId,
      if (orden != null) 'orden': orden,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrdenPasillosCompanion copyWith({
    Value<int>? establecimientoId,
    Value<int>? categoriaId,
    Value<int>? orden,
    Value<int>? rowid,
  }) {
    return OrdenPasillosCompanion(
      establecimientoId: establecimientoId ?? this.establecimientoId,
      categoriaId: categoriaId ?? this.categoriaId,
      orden: orden ?? this.orden,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (establecimientoId.present) {
      map['establecimiento_id'] = Variable<int>(establecimientoId.value);
    }
    if (categoriaId.present) {
      map['categoria_id'] = Variable<int>(categoriaId.value);
    }
    if (orden.present) {
      map['orden'] = Variable<int>(orden.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrdenPasillosCompanion(')
          ..write('establecimientoId: $establecimientoId, ')
          ..write('categoriaId: $categoriaId, ')
          ..write('orden: $orden, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CodigosBasculaTable extends CodigosBascula
    with TableInfo<$CodigosBasculaTable, CodigoBasculaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CodigosBasculaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _establecimientoIdMeta = const VerificationMeta(
    'establecimientoId',
  );
  @override
  late final GeneratedColumn<int> establecimientoId = GeneratedColumn<int>(
    'establecimiento_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES establecimientos (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _claveMeta = const VerificationMeta('clave');
  @override
  late final GeneratedColumn<String> clave = GeneratedColumn<String>(
    'clave',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _presentacionIdMeta = const VerificationMeta(
    'presentacionId',
  );
  @override
  late final GeneratedColumn<int> presentacionId = GeneratedColumn<int>(
    'presentacion_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES presentaciones (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    establecimientoId,
    clave,
    presentacionId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'codigos_bascula';
  @override
  VerificationContext validateIntegrity(
    Insertable<CodigoBasculaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('establecimiento_id')) {
      context.handle(
        _establecimientoIdMeta,
        establecimientoId.isAcceptableOrUnknown(
          data['establecimiento_id']!,
          _establecimientoIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_establecimientoIdMeta);
    }
    if (data.containsKey('clave')) {
      context.handle(
        _claveMeta,
        clave.isAcceptableOrUnknown(data['clave']!, _claveMeta),
      );
    } else if (isInserting) {
      context.missing(_claveMeta);
    }
    if (data.containsKey('presentacion_id')) {
      context.handle(
        _presentacionIdMeta,
        presentacionId.isAcceptableOrUnknown(
          data['presentacion_id']!,
          _presentacionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_presentacionIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {establecimientoId, clave},
  ];
  @override
  CodigoBasculaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CodigoBasculaRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      establecimientoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}establecimiento_id'],
      )!,
      clave: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clave'],
      )!,
      presentacionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}presentacion_id'],
      )!,
    );
  }

  @override
  $CodigosBasculaTable createAlias(String alias) {
    return $CodigosBasculaTable(attachedDatabase, alias);
  }
}

class CodigoBasculaRow extends DataClass
    implements Insertable<CodigoBasculaRow> {
  final int id;
  final int establecimientoId;
  final String clave;
  final int presentacionId;
  const CodigoBasculaRow({
    required this.id,
    required this.establecimientoId,
    required this.clave,
    required this.presentacionId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['establecimiento_id'] = Variable<int>(establecimientoId);
    map['clave'] = Variable<String>(clave);
    map['presentacion_id'] = Variable<int>(presentacionId);
    return map;
  }

  CodigosBasculaCompanion toCompanion(bool nullToAbsent) {
    return CodigosBasculaCompanion(
      id: Value(id),
      establecimientoId: Value(establecimientoId),
      clave: Value(clave),
      presentacionId: Value(presentacionId),
    );
  }

  factory CodigoBasculaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CodigoBasculaRow(
      id: serializer.fromJson<int>(json['id']),
      establecimientoId: serializer.fromJson<int>(json['establecimientoId']),
      clave: serializer.fromJson<String>(json['clave']),
      presentacionId: serializer.fromJson<int>(json['presentacionId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'establecimientoId': serializer.toJson<int>(establecimientoId),
      'clave': serializer.toJson<String>(clave),
      'presentacionId': serializer.toJson<int>(presentacionId),
    };
  }

  CodigoBasculaRow copyWith({
    int? id,
    int? establecimientoId,
    String? clave,
    int? presentacionId,
  }) => CodigoBasculaRow(
    id: id ?? this.id,
    establecimientoId: establecimientoId ?? this.establecimientoId,
    clave: clave ?? this.clave,
    presentacionId: presentacionId ?? this.presentacionId,
  );
  CodigoBasculaRow copyWithCompanion(CodigosBasculaCompanion data) {
    return CodigoBasculaRow(
      id: data.id.present ? data.id.value : this.id,
      establecimientoId: data.establecimientoId.present
          ? data.establecimientoId.value
          : this.establecimientoId,
      clave: data.clave.present ? data.clave.value : this.clave,
      presentacionId: data.presentacionId.present
          ? data.presentacionId.value
          : this.presentacionId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CodigoBasculaRow(')
          ..write('id: $id, ')
          ..write('establecimientoId: $establecimientoId, ')
          ..write('clave: $clave, ')
          ..write('presentacionId: $presentacionId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, establecimientoId, clave, presentacionId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CodigoBasculaRow &&
          other.id == this.id &&
          other.establecimientoId == this.establecimientoId &&
          other.clave == this.clave &&
          other.presentacionId == this.presentacionId);
}

class CodigosBasculaCompanion extends UpdateCompanion<CodigoBasculaRow> {
  final Value<int> id;
  final Value<int> establecimientoId;
  final Value<String> clave;
  final Value<int> presentacionId;
  const CodigosBasculaCompanion({
    this.id = const Value.absent(),
    this.establecimientoId = const Value.absent(),
    this.clave = const Value.absent(),
    this.presentacionId = const Value.absent(),
  });
  CodigosBasculaCompanion.insert({
    this.id = const Value.absent(),
    required int establecimientoId,
    required String clave,
    required int presentacionId,
  }) : establecimientoId = Value(establecimientoId),
       clave = Value(clave),
       presentacionId = Value(presentacionId);
  static Insertable<CodigoBasculaRow> custom({
    Expression<int>? id,
    Expression<int>? establecimientoId,
    Expression<String>? clave,
    Expression<int>? presentacionId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (establecimientoId != null) 'establecimiento_id': establecimientoId,
      if (clave != null) 'clave': clave,
      if (presentacionId != null) 'presentacion_id': presentacionId,
    });
  }

  CodigosBasculaCompanion copyWith({
    Value<int>? id,
    Value<int>? establecimientoId,
    Value<String>? clave,
    Value<int>? presentacionId,
  }) {
    return CodigosBasculaCompanion(
      id: id ?? this.id,
      establecimientoId: establecimientoId ?? this.establecimientoId,
      clave: clave ?? this.clave,
      presentacionId: presentacionId ?? this.presentacionId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (establecimientoId.present) {
      map['establecimiento_id'] = Variable<int>(establecimientoId.value);
    }
    if (clave.present) {
      map['clave'] = Variable<String>(clave.value);
    }
    if (presentacionId.present) {
      map['presentacion_id'] = Variable<int>(presentacionId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CodigosBasculaCompanion(')
          ..write('id: $id, ')
          ..write('establecimientoId: $establecimientoId, ')
          ..write('clave: $clave, ')
          ..write('presentacionId: $presentacionId')
          ..write(')'))
        .toString();
  }
}

class $ComprasTable extends Compras with TableInfo<$ComprasTable, CompraRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ComprasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _presentacionIdMeta = const VerificationMeta(
    'presentacionId',
  );
  @override
  late final GeneratedColumn<int> presentacionId = GeneratedColumn<int>(
    'presentacion_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES presentaciones (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _establecimientoIdMeta = const VerificationMeta(
    'establecimientoId',
  );
  @override
  late final GeneratedColumn<int> establecimientoId = GeneratedColumn<int>(
    'establecimiento_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES establecimientos (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _fechaMeta = const VerificationMeta('fecha');
  @override
  late final GeneratedColumn<String> fecha = GeneratedColumn<String>(
    'fecha',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _precioCentMeta = const VerificationMeta(
    'precioCent',
  );
  @override
  late final GeneratedColumn<int> precioCent = GeneratedColumn<int>(
    'precio_cent',
    aliasedName,
    false,
    check: () => ComparableExpr(precioCent).isBiggerThanValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unidadesMeta = const VerificationMeta(
    'unidades',
  );
  @override
  late final GeneratedColumn<int> unidades = GeneratedColumn<int>(
    'unidades',
    aliasedName,
    false,
    check: () => ComparableExpr(unidades).isBiggerOrEqualValue(1),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _pesoGMeta = const VerificationMeta('pesoG');
  @override
  late final GeneratedColumn<double> pesoG = GeneratedColumn<double>(
    'peso_g',
    aliasedName,
    true,
    check: () => ComparableExpr(pesoG).isBiggerThanValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    presentacionId,
    establecimientoId,
    fecha,
    precioCent,
    unidades,
    pesoG,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'compras';
  @override
  VerificationContext validateIntegrity(
    Insertable<CompraRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('presentacion_id')) {
      context.handle(
        _presentacionIdMeta,
        presentacionId.isAcceptableOrUnknown(
          data['presentacion_id']!,
          _presentacionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_presentacionIdMeta);
    }
    if (data.containsKey('establecimiento_id')) {
      context.handle(
        _establecimientoIdMeta,
        establecimientoId.isAcceptableOrUnknown(
          data['establecimiento_id']!,
          _establecimientoIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_establecimientoIdMeta);
    }
    if (data.containsKey('fecha')) {
      context.handle(
        _fechaMeta,
        fecha.isAcceptableOrUnknown(data['fecha']!, _fechaMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaMeta);
    }
    if (data.containsKey('precio_cent')) {
      context.handle(
        _precioCentMeta,
        precioCent.isAcceptableOrUnknown(data['precio_cent']!, _precioCentMeta),
      );
    } else if (isInserting) {
      context.missing(_precioCentMeta);
    }
    if (data.containsKey('unidades')) {
      context.handle(
        _unidadesMeta,
        unidades.isAcceptableOrUnknown(data['unidades']!, _unidadesMeta),
      );
    }
    if (data.containsKey('peso_g')) {
      context.handle(
        _pesoGMeta,
        pesoG.isAcceptableOrUnknown(data['peso_g']!, _pesoGMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CompraRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CompraRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      presentacionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}presentacion_id'],
      )!,
      establecimientoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}establecimiento_id'],
      )!,
      fecha: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fecha'],
      )!,
      precioCent: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}precio_cent'],
      )!,
      unidades: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unidades'],
      )!,
      pesoG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}peso_g'],
      ),
    );
  }

  @override
  $ComprasTable createAlias(String alias) {
    return $ComprasTable(attachedDatabase, alias);
  }
}

class CompraRow extends DataClass implements Insertable<CompraRow> {
  final int id;
  final int presentacionId;
  final int establecimientoId;
  final String fecha;
  final int precioCent;
  final int unidades;
  final double? pesoG;
  const CompraRow({
    required this.id,
    required this.presentacionId,
    required this.establecimientoId,
    required this.fecha,
    required this.precioCent,
    required this.unidades,
    this.pesoG,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['presentacion_id'] = Variable<int>(presentacionId);
    map['establecimiento_id'] = Variable<int>(establecimientoId);
    map['fecha'] = Variable<String>(fecha);
    map['precio_cent'] = Variable<int>(precioCent);
    map['unidades'] = Variable<int>(unidades);
    if (!nullToAbsent || pesoG != null) {
      map['peso_g'] = Variable<double>(pesoG);
    }
    return map;
  }

  ComprasCompanion toCompanion(bool nullToAbsent) {
    return ComprasCompanion(
      id: Value(id),
      presentacionId: Value(presentacionId),
      establecimientoId: Value(establecimientoId),
      fecha: Value(fecha),
      precioCent: Value(precioCent),
      unidades: Value(unidades),
      pesoG: pesoG == null && nullToAbsent
          ? const Value.absent()
          : Value(pesoG),
    );
  }

  factory CompraRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CompraRow(
      id: serializer.fromJson<int>(json['id']),
      presentacionId: serializer.fromJson<int>(json['presentacionId']),
      establecimientoId: serializer.fromJson<int>(json['establecimientoId']),
      fecha: serializer.fromJson<String>(json['fecha']),
      precioCent: serializer.fromJson<int>(json['precioCent']),
      unidades: serializer.fromJson<int>(json['unidades']),
      pesoG: serializer.fromJson<double?>(json['pesoG']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'presentacionId': serializer.toJson<int>(presentacionId),
      'establecimientoId': serializer.toJson<int>(establecimientoId),
      'fecha': serializer.toJson<String>(fecha),
      'precioCent': serializer.toJson<int>(precioCent),
      'unidades': serializer.toJson<int>(unidades),
      'pesoG': serializer.toJson<double?>(pesoG),
    };
  }

  CompraRow copyWith({
    int? id,
    int? presentacionId,
    int? establecimientoId,
    String? fecha,
    int? precioCent,
    int? unidades,
    Value<double?> pesoG = const Value.absent(),
  }) => CompraRow(
    id: id ?? this.id,
    presentacionId: presentacionId ?? this.presentacionId,
    establecimientoId: establecimientoId ?? this.establecimientoId,
    fecha: fecha ?? this.fecha,
    precioCent: precioCent ?? this.precioCent,
    unidades: unidades ?? this.unidades,
    pesoG: pesoG.present ? pesoG.value : this.pesoG,
  );
  CompraRow copyWithCompanion(ComprasCompanion data) {
    return CompraRow(
      id: data.id.present ? data.id.value : this.id,
      presentacionId: data.presentacionId.present
          ? data.presentacionId.value
          : this.presentacionId,
      establecimientoId: data.establecimientoId.present
          ? data.establecimientoId.value
          : this.establecimientoId,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
      precioCent: data.precioCent.present
          ? data.precioCent.value
          : this.precioCent,
      unidades: data.unidades.present ? data.unidades.value : this.unidades,
      pesoG: data.pesoG.present ? data.pesoG.value : this.pesoG,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CompraRow(')
          ..write('id: $id, ')
          ..write('presentacionId: $presentacionId, ')
          ..write('establecimientoId: $establecimientoId, ')
          ..write('fecha: $fecha, ')
          ..write('precioCent: $precioCent, ')
          ..write('unidades: $unidades, ')
          ..write('pesoG: $pesoG')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    presentacionId,
    establecimientoId,
    fecha,
    precioCent,
    unidades,
    pesoG,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompraRow &&
          other.id == this.id &&
          other.presentacionId == this.presentacionId &&
          other.establecimientoId == this.establecimientoId &&
          other.fecha == this.fecha &&
          other.precioCent == this.precioCent &&
          other.unidades == this.unidades &&
          other.pesoG == this.pesoG);
}

class ComprasCompanion extends UpdateCompanion<CompraRow> {
  final Value<int> id;
  final Value<int> presentacionId;
  final Value<int> establecimientoId;
  final Value<String> fecha;
  final Value<int> precioCent;
  final Value<int> unidades;
  final Value<double?> pesoG;
  const ComprasCompanion({
    this.id = const Value.absent(),
    this.presentacionId = const Value.absent(),
    this.establecimientoId = const Value.absent(),
    this.fecha = const Value.absent(),
    this.precioCent = const Value.absent(),
    this.unidades = const Value.absent(),
    this.pesoG = const Value.absent(),
  });
  ComprasCompanion.insert({
    this.id = const Value.absent(),
    required int presentacionId,
    required int establecimientoId,
    required String fecha,
    required int precioCent,
    this.unidades = const Value.absent(),
    this.pesoG = const Value.absent(),
  }) : presentacionId = Value(presentacionId),
       establecimientoId = Value(establecimientoId),
       fecha = Value(fecha),
       precioCent = Value(precioCent);
  static Insertable<CompraRow> custom({
    Expression<int>? id,
    Expression<int>? presentacionId,
    Expression<int>? establecimientoId,
    Expression<String>? fecha,
    Expression<int>? precioCent,
    Expression<int>? unidades,
    Expression<double>? pesoG,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (presentacionId != null) 'presentacion_id': presentacionId,
      if (establecimientoId != null) 'establecimiento_id': establecimientoId,
      if (fecha != null) 'fecha': fecha,
      if (precioCent != null) 'precio_cent': precioCent,
      if (unidades != null) 'unidades': unidades,
      if (pesoG != null) 'peso_g': pesoG,
    });
  }

  ComprasCompanion copyWith({
    Value<int>? id,
    Value<int>? presentacionId,
    Value<int>? establecimientoId,
    Value<String>? fecha,
    Value<int>? precioCent,
    Value<int>? unidades,
    Value<double?>? pesoG,
  }) {
    return ComprasCompanion(
      id: id ?? this.id,
      presentacionId: presentacionId ?? this.presentacionId,
      establecimientoId: establecimientoId ?? this.establecimientoId,
      fecha: fecha ?? this.fecha,
      precioCent: precioCent ?? this.precioCent,
      unidades: unidades ?? this.unidades,
      pesoG: pesoG ?? this.pesoG,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (presentacionId.present) {
      map['presentacion_id'] = Variable<int>(presentacionId.value);
    }
    if (establecimientoId.present) {
      map['establecimiento_id'] = Variable<int>(establecimientoId.value);
    }
    if (fecha.present) {
      map['fecha'] = Variable<String>(fecha.value);
    }
    if (precioCent.present) {
      map['precio_cent'] = Variable<int>(precioCent.value);
    }
    if (unidades.present) {
      map['unidades'] = Variable<int>(unidades.value);
    }
    if (pesoG.present) {
      map['peso_g'] = Variable<double>(pesoG.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ComprasCompanion(')
          ..write('id: $id, ')
          ..write('presentacionId: $presentacionId, ')
          ..write('establecimientoId: $establecimientoId, ')
          ..write('fecha: $fecha, ')
          ..write('precioCent: $precioCent, ')
          ..write('unidades: $unidades, ')
          ..write('pesoG: $pesoG')
          ..write(')'))
        .toString();
  }
}

class $ListasCompraTable extends ListasCompra
    with TableInfo<$ListasCompraTable, ListaCompraRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ListasCompraTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _creadaMeta = const VerificationMeta('creada');
  @override
  late final GeneratedColumn<String> creada = GeneratedColumn<String>(
    'creada',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, nombre, creada];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'listas_compra';
  @override
  VerificationContext validateIntegrity(
    Insertable<ListaCompraRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('creada')) {
      context.handle(
        _creadaMeta,
        creada.isAcceptableOrUnknown(data['creada']!, _creadaMeta),
      );
    } else if (isInserting) {
      context.missing(_creadaMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ListaCompraRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ListaCompraRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      creada: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}creada'],
      )!,
    );
  }

  @override
  $ListasCompraTable createAlias(String alias) {
    return $ListasCompraTable(attachedDatabase, alias);
  }
}

class ListaCompraRow extends DataClass implements Insertable<ListaCompraRow> {
  final int id;
  final String nombre;
  final String creada;
  const ListaCompraRow({
    required this.id,
    required this.nombre,
    required this.creada,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nombre'] = Variable<String>(nombre);
    map['creada'] = Variable<String>(creada);
    return map;
  }

  ListasCompraCompanion toCompanion(bool nullToAbsent) {
    return ListasCompraCompanion(
      id: Value(id),
      nombre: Value(nombre),
      creada: Value(creada),
    );
  }

  factory ListaCompraRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ListaCompraRow(
      id: serializer.fromJson<int>(json['id']),
      nombre: serializer.fromJson<String>(json['nombre']),
      creada: serializer.fromJson<String>(json['creada']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nombre': serializer.toJson<String>(nombre),
      'creada': serializer.toJson<String>(creada),
    };
  }

  ListaCompraRow copyWith({int? id, String? nombre, String? creada}) =>
      ListaCompraRow(
        id: id ?? this.id,
        nombre: nombre ?? this.nombre,
        creada: creada ?? this.creada,
      );
  ListaCompraRow copyWithCompanion(ListasCompraCompanion data) {
    return ListaCompraRow(
      id: data.id.present ? data.id.value : this.id,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      creada: data.creada.present ? data.creada.value : this.creada,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ListaCompraRow(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('creada: $creada')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nombre, creada);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ListaCompraRow &&
          other.id == this.id &&
          other.nombre == this.nombre &&
          other.creada == this.creada);
}

class ListasCompraCompanion extends UpdateCompanion<ListaCompraRow> {
  final Value<int> id;
  final Value<String> nombre;
  final Value<String> creada;
  const ListasCompraCompanion({
    this.id = const Value.absent(),
    this.nombre = const Value.absent(),
    this.creada = const Value.absent(),
  });
  ListasCompraCompanion.insert({
    this.id = const Value.absent(),
    required String nombre,
    required String creada,
  }) : nombre = Value(nombre),
       creada = Value(creada);
  static Insertable<ListaCompraRow> custom({
    Expression<int>? id,
    Expression<String>? nombre,
    Expression<String>? creada,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nombre != null) 'nombre': nombre,
      if (creada != null) 'creada': creada,
    });
  }

  ListasCompraCompanion copyWith({
    Value<int>? id,
    Value<String>? nombre,
    Value<String>? creada,
  }) {
    return ListasCompraCompanion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      creada: creada ?? this.creada,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (creada.present) {
      map['creada'] = Variable<String>(creada.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ListasCompraCompanion(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('creada: $creada')
          ..write(')'))
        .toString();
  }
}

class $ItemsListaTable extends ItemsLista
    with TableInfo<$ItemsListaTable, ItemListaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemsListaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _listaIdMeta = const VerificationMeta(
    'listaId',
  );
  @override
  late final GeneratedColumn<int> listaId = GeneratedColumn<int>(
    'lista_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES listas_compra (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _alimentoIdMeta = const VerificationMeta(
    'alimentoId',
  );
  @override
  late final GeneratedColumn<int> alimentoId = GeneratedColumn<int>(
    'alimento_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES alimentos (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _textoMeta = const VerificationMeta('texto');
  @override
  late final GeneratedColumn<String> texto = GeneratedColumn<String>(
    'texto',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cantidadMeta = const VerificationMeta(
    'cantidad',
  );
  @override
  late final GeneratedColumn<String> cantidad = GeneratedColumn<String>(
    'cantidad',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ordenMeta = const VerificationMeta('orden');
  @override
  late final GeneratedColumn<int> orden = GeneratedColumn<int>(
    'orden',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _compradoMeta = const VerificationMeta(
    'comprado',
  );
  @override
  late final GeneratedColumn<bool> comprado = GeneratedColumn<bool>(
    'comprado',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("comprado" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _compraIdMeta = const VerificationMeta(
    'compraId',
  );
  @override
  late final GeneratedColumn<int> compraId = GeneratedColumn<int>(
    'compra_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'UNIQUE REFERENCES compras (id) ON DELETE SET NULL',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    listaId,
    alimentoId,
    texto,
    cantidad,
    orden,
    comprado,
    compraId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'items_lista';
  @override
  VerificationContext validateIntegrity(
    Insertable<ItemListaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('lista_id')) {
      context.handle(
        _listaIdMeta,
        listaId.isAcceptableOrUnknown(data['lista_id']!, _listaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_listaIdMeta);
    }
    if (data.containsKey('alimento_id')) {
      context.handle(
        _alimentoIdMeta,
        alimentoId.isAcceptableOrUnknown(data['alimento_id']!, _alimentoIdMeta),
      );
    }
    if (data.containsKey('texto')) {
      context.handle(
        _textoMeta,
        texto.isAcceptableOrUnknown(data['texto']!, _textoMeta),
      );
    } else if (isInserting) {
      context.missing(_textoMeta);
    }
    if (data.containsKey('cantidad')) {
      context.handle(
        _cantidadMeta,
        cantidad.isAcceptableOrUnknown(data['cantidad']!, _cantidadMeta),
      );
    }
    if (data.containsKey('orden')) {
      context.handle(
        _ordenMeta,
        orden.isAcceptableOrUnknown(data['orden']!, _ordenMeta),
      );
    } else if (isInserting) {
      context.missing(_ordenMeta);
    }
    if (data.containsKey('comprado')) {
      context.handle(
        _compradoMeta,
        comprado.isAcceptableOrUnknown(data['comprado']!, _compradoMeta),
      );
    }
    if (data.containsKey('compra_id')) {
      context.handle(
        _compraIdMeta,
        compraId.isAcceptableOrUnknown(data['compra_id']!, _compraIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ItemListaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemListaRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      listaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lista_id'],
      )!,
      alimentoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}alimento_id'],
      ),
      texto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}texto'],
      )!,
      cantidad: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cantidad'],
      ),
      orden: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}orden'],
      )!,
      comprado: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}comprado'],
      )!,
      compraId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}compra_id'],
      ),
    );
  }

  @override
  $ItemsListaTable createAlias(String alias) {
    return $ItemsListaTable(attachedDatabase, alias);
  }
}

class ItemListaRow extends DataClass implements Insertable<ItemListaRow> {
  final int id;
  final int listaId;
  final int? alimentoId;
  final String texto;
  final String? cantidad;
  final int orden;
  final bool comprado;
  final int? compraId;
  const ItemListaRow({
    required this.id,
    required this.listaId,
    this.alimentoId,
    required this.texto,
    this.cantidad,
    required this.orden,
    required this.comprado,
    this.compraId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['lista_id'] = Variable<int>(listaId);
    if (!nullToAbsent || alimentoId != null) {
      map['alimento_id'] = Variable<int>(alimentoId);
    }
    map['texto'] = Variable<String>(texto);
    if (!nullToAbsent || cantidad != null) {
      map['cantidad'] = Variable<String>(cantidad);
    }
    map['orden'] = Variable<int>(orden);
    map['comprado'] = Variable<bool>(comprado);
    if (!nullToAbsent || compraId != null) {
      map['compra_id'] = Variable<int>(compraId);
    }
    return map;
  }

  ItemsListaCompanion toCompanion(bool nullToAbsent) {
    return ItemsListaCompanion(
      id: Value(id),
      listaId: Value(listaId),
      alimentoId: alimentoId == null && nullToAbsent
          ? const Value.absent()
          : Value(alimentoId),
      texto: Value(texto),
      cantidad: cantidad == null && nullToAbsent
          ? const Value.absent()
          : Value(cantidad),
      orden: Value(orden),
      comprado: Value(comprado),
      compraId: compraId == null && nullToAbsent
          ? const Value.absent()
          : Value(compraId),
    );
  }

  factory ItemListaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemListaRow(
      id: serializer.fromJson<int>(json['id']),
      listaId: serializer.fromJson<int>(json['listaId']),
      alimentoId: serializer.fromJson<int?>(json['alimentoId']),
      texto: serializer.fromJson<String>(json['texto']),
      cantidad: serializer.fromJson<String?>(json['cantidad']),
      orden: serializer.fromJson<int>(json['orden']),
      comprado: serializer.fromJson<bool>(json['comprado']),
      compraId: serializer.fromJson<int?>(json['compraId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'listaId': serializer.toJson<int>(listaId),
      'alimentoId': serializer.toJson<int?>(alimentoId),
      'texto': serializer.toJson<String>(texto),
      'cantidad': serializer.toJson<String?>(cantidad),
      'orden': serializer.toJson<int>(orden),
      'comprado': serializer.toJson<bool>(comprado),
      'compraId': serializer.toJson<int?>(compraId),
    };
  }

  ItemListaRow copyWith({
    int? id,
    int? listaId,
    Value<int?> alimentoId = const Value.absent(),
    String? texto,
    Value<String?> cantidad = const Value.absent(),
    int? orden,
    bool? comprado,
    Value<int?> compraId = const Value.absent(),
  }) => ItemListaRow(
    id: id ?? this.id,
    listaId: listaId ?? this.listaId,
    alimentoId: alimentoId.present ? alimentoId.value : this.alimentoId,
    texto: texto ?? this.texto,
    cantidad: cantidad.present ? cantidad.value : this.cantidad,
    orden: orden ?? this.orden,
    comprado: comprado ?? this.comprado,
    compraId: compraId.present ? compraId.value : this.compraId,
  );
  ItemListaRow copyWithCompanion(ItemsListaCompanion data) {
    return ItemListaRow(
      id: data.id.present ? data.id.value : this.id,
      listaId: data.listaId.present ? data.listaId.value : this.listaId,
      alimentoId: data.alimentoId.present
          ? data.alimentoId.value
          : this.alimentoId,
      texto: data.texto.present ? data.texto.value : this.texto,
      cantidad: data.cantidad.present ? data.cantidad.value : this.cantidad,
      orden: data.orden.present ? data.orden.value : this.orden,
      comprado: data.comprado.present ? data.comprado.value : this.comprado,
      compraId: data.compraId.present ? data.compraId.value : this.compraId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemListaRow(')
          ..write('id: $id, ')
          ..write('listaId: $listaId, ')
          ..write('alimentoId: $alimentoId, ')
          ..write('texto: $texto, ')
          ..write('cantidad: $cantidad, ')
          ..write('orden: $orden, ')
          ..write('comprado: $comprado, ')
          ..write('compraId: $compraId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    listaId,
    alimentoId,
    texto,
    cantidad,
    orden,
    comprado,
    compraId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemListaRow &&
          other.id == this.id &&
          other.listaId == this.listaId &&
          other.alimentoId == this.alimentoId &&
          other.texto == this.texto &&
          other.cantidad == this.cantidad &&
          other.orden == this.orden &&
          other.comprado == this.comprado &&
          other.compraId == this.compraId);
}

class ItemsListaCompanion extends UpdateCompanion<ItemListaRow> {
  final Value<int> id;
  final Value<int> listaId;
  final Value<int?> alimentoId;
  final Value<String> texto;
  final Value<String?> cantidad;
  final Value<int> orden;
  final Value<bool> comprado;
  final Value<int?> compraId;
  const ItemsListaCompanion({
    this.id = const Value.absent(),
    this.listaId = const Value.absent(),
    this.alimentoId = const Value.absent(),
    this.texto = const Value.absent(),
    this.cantidad = const Value.absent(),
    this.orden = const Value.absent(),
    this.comprado = const Value.absent(),
    this.compraId = const Value.absent(),
  });
  ItemsListaCompanion.insert({
    this.id = const Value.absent(),
    required int listaId,
    this.alimentoId = const Value.absent(),
    required String texto,
    this.cantidad = const Value.absent(),
    required int orden,
    this.comprado = const Value.absent(),
    this.compraId = const Value.absent(),
  }) : listaId = Value(listaId),
       texto = Value(texto),
       orden = Value(orden);
  static Insertable<ItemListaRow> custom({
    Expression<int>? id,
    Expression<int>? listaId,
    Expression<int>? alimentoId,
    Expression<String>? texto,
    Expression<String>? cantidad,
    Expression<int>? orden,
    Expression<bool>? comprado,
    Expression<int>? compraId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (listaId != null) 'lista_id': listaId,
      if (alimentoId != null) 'alimento_id': alimentoId,
      if (texto != null) 'texto': texto,
      if (cantidad != null) 'cantidad': cantidad,
      if (orden != null) 'orden': orden,
      if (comprado != null) 'comprado': comprado,
      if (compraId != null) 'compra_id': compraId,
    });
  }

  ItemsListaCompanion copyWith({
    Value<int>? id,
    Value<int>? listaId,
    Value<int?>? alimentoId,
    Value<String>? texto,
    Value<String?>? cantidad,
    Value<int>? orden,
    Value<bool>? comprado,
    Value<int?>? compraId,
  }) {
    return ItemsListaCompanion(
      id: id ?? this.id,
      listaId: listaId ?? this.listaId,
      alimentoId: alimentoId ?? this.alimentoId,
      texto: texto ?? this.texto,
      cantidad: cantidad ?? this.cantidad,
      orden: orden ?? this.orden,
      comprado: comprado ?? this.comprado,
      compraId: compraId ?? this.compraId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (listaId.present) {
      map['lista_id'] = Variable<int>(listaId.value);
    }
    if (alimentoId.present) {
      map['alimento_id'] = Variable<int>(alimentoId.value);
    }
    if (texto.present) {
      map['texto'] = Variable<String>(texto.value);
    }
    if (cantidad.present) {
      map['cantidad'] = Variable<String>(cantidad.value);
    }
    if (orden.present) {
      map['orden'] = Variable<int>(orden.value);
    }
    if (comprado.present) {
      map['comprado'] = Variable<bool>(comprado.value);
    }
    if (compraId.present) {
      map['compra_id'] = Variable<int>(compraId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemsListaCompanion(')
          ..write('id: $id, ')
          ..write('listaId: $listaId, ')
          ..write('alimentoId: $alimentoId, ')
          ..write('texto: $texto, ')
          ..write('cantidad: $cantidad, ')
          ..write('orden: $orden, ')
          ..write('comprado: $comprado, ')
          ..write('compraId: $compraId')
          ..write(')'))
        .toString();
  }
}

class $RecetasTable extends Recetas with TableInfo<$RecetasTable, RecetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecetasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoriaMeta = const VerificationMeta(
    'categoria',
  );
  @override
  late final GeneratedColumn<String> categoria = GeneratedColumn<String>(
    'categoria',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _porcionesMeta = const VerificationMeta(
    'porciones',
  );
  @override
  late final GeneratedColumn<int> porciones = GeneratedColumn<int>(
    'porciones',
    aliasedName,
    true,
    check: () => ComparableExpr(porciones).isBiggerThanValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tiempoMinMeta = const VerificationMeta(
    'tiempoMin',
  );
  @override
  late final GeneratedColumn<int> tiempoMin = GeneratedColumn<int>(
    'tiempo_min',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _elaboracionMeta = const VerificationMeta(
    'elaboracion',
  );
  @override
  late final GeneratedColumn<String> elaboracion = GeneratedColumn<String>(
    'elaboracion',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _notasMeta = const VerificationMeta('notas');
  @override
  late final GeneratedColumn<String> notas = GeneratedColumn<String>(
    'notas',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _favoritaMeta = const VerificationMeta(
    'favorita',
  );
  @override
  late final GeneratedColumn<bool> favorita = GeneratedColumn<bool>(
    'favorita',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("favorita" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _pesoFinalGMeta = const VerificationMeta(
    'pesoFinalG',
  );
  @override
  late final GeneratedColumn<double> pesoFinalG = GeneratedColumn<double>(
    'peso_final_g',
    aliasedName,
    true,
    check: () => ComparableExpr(pesoFinalG).isBiggerThanValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _alimentoIdMeta = const VerificationMeta(
    'alimentoId',
  );
  @override
  late final GeneratedColumn<int> alimentoId = GeneratedColumn<int>(
    'alimento_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES alimentos (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _creadaMeta = const VerificationMeta('creada');
  @override
  late final GeneratedColumn<String> creada = GeneratedColumn<String>(
    'creada',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actualizadaMeta = const VerificationMeta(
    'actualizada',
  );
  @override
  late final GeneratedColumn<String> actualizada = GeneratedColumn<String>(
    'actualizada',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    nombre,
    categoria,
    porciones,
    tiempoMin,
    elaboracion,
    notas,
    favorita,
    pesoFinalG,
    alimentoId,
    creada,
    actualizada,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recetas';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecetaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('categoria')) {
      context.handle(
        _categoriaMeta,
        categoria.isAcceptableOrUnknown(data['categoria']!, _categoriaMeta),
      );
    }
    if (data.containsKey('porciones')) {
      context.handle(
        _porcionesMeta,
        porciones.isAcceptableOrUnknown(data['porciones']!, _porcionesMeta),
      );
    }
    if (data.containsKey('tiempo_min')) {
      context.handle(
        _tiempoMinMeta,
        tiempoMin.isAcceptableOrUnknown(data['tiempo_min']!, _tiempoMinMeta),
      );
    }
    if (data.containsKey('elaboracion')) {
      context.handle(
        _elaboracionMeta,
        elaboracion.isAcceptableOrUnknown(
          data['elaboracion']!,
          _elaboracionMeta,
        ),
      );
    }
    if (data.containsKey('notas')) {
      context.handle(
        _notasMeta,
        notas.isAcceptableOrUnknown(data['notas']!, _notasMeta),
      );
    }
    if (data.containsKey('favorita')) {
      context.handle(
        _favoritaMeta,
        favorita.isAcceptableOrUnknown(data['favorita']!, _favoritaMeta),
      );
    }
    if (data.containsKey('peso_final_g')) {
      context.handle(
        _pesoFinalGMeta,
        pesoFinalG.isAcceptableOrUnknown(
          data['peso_final_g']!,
          _pesoFinalGMeta,
        ),
      );
    }
    if (data.containsKey('alimento_id')) {
      context.handle(
        _alimentoIdMeta,
        alimentoId.isAcceptableOrUnknown(data['alimento_id']!, _alimentoIdMeta),
      );
    }
    if (data.containsKey('creada')) {
      context.handle(
        _creadaMeta,
        creada.isAcceptableOrUnknown(data['creada']!, _creadaMeta),
      );
    } else if (isInserting) {
      context.missing(_creadaMeta);
    }
    if (data.containsKey('actualizada')) {
      context.handle(
        _actualizadaMeta,
        actualizada.isAcceptableOrUnknown(
          data['actualizada']!,
          _actualizadaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_actualizadaMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecetaRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      categoria: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}categoria'],
      ),
      porciones: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}porciones'],
      ),
      tiempoMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tiempo_min'],
      ),
      elaboracion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}elaboracion'],
      )!,
      notas: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notas'],
      ),
      favorita: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}favorita'],
      )!,
      pesoFinalG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}peso_final_g'],
      ),
      alimentoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}alimento_id'],
      ),
      creada: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}creada'],
      )!,
      actualizada: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actualizada'],
      )!,
    );
  }

  @override
  $RecetasTable createAlias(String alias) {
    return $RecetasTable(attachedDatabase, alias);
  }
}

class RecetaRow extends DataClass implements Insertable<RecetaRow> {
  final int id;
  final String uuid;
  final String nombre;
  final String? categoria;
  final int? porciones;
  final int? tiempoMin;
  final String elaboracion;
  final String? notas;
  final bool favorita;
  final double? pesoFinalG;
  final int? alimentoId;
  final String creada;
  final String actualizada;
  const RecetaRow({
    required this.id,
    required this.uuid,
    required this.nombre,
    this.categoria,
    this.porciones,
    this.tiempoMin,
    required this.elaboracion,
    this.notas,
    required this.favorita,
    this.pesoFinalG,
    this.alimentoId,
    required this.creada,
    required this.actualizada,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['nombre'] = Variable<String>(nombre);
    if (!nullToAbsent || categoria != null) {
      map['categoria'] = Variable<String>(categoria);
    }
    if (!nullToAbsent || porciones != null) {
      map['porciones'] = Variable<int>(porciones);
    }
    if (!nullToAbsent || tiempoMin != null) {
      map['tiempo_min'] = Variable<int>(tiempoMin);
    }
    map['elaboracion'] = Variable<String>(elaboracion);
    if (!nullToAbsent || notas != null) {
      map['notas'] = Variable<String>(notas);
    }
    map['favorita'] = Variable<bool>(favorita);
    if (!nullToAbsent || pesoFinalG != null) {
      map['peso_final_g'] = Variable<double>(pesoFinalG);
    }
    if (!nullToAbsent || alimentoId != null) {
      map['alimento_id'] = Variable<int>(alimentoId);
    }
    map['creada'] = Variable<String>(creada);
    map['actualizada'] = Variable<String>(actualizada);
    return map;
  }

  RecetasCompanion toCompanion(bool nullToAbsent) {
    return RecetasCompanion(
      id: Value(id),
      uuid: Value(uuid),
      nombre: Value(nombre),
      categoria: categoria == null && nullToAbsent
          ? const Value.absent()
          : Value(categoria),
      porciones: porciones == null && nullToAbsent
          ? const Value.absent()
          : Value(porciones),
      tiempoMin: tiempoMin == null && nullToAbsent
          ? const Value.absent()
          : Value(tiempoMin),
      elaboracion: Value(elaboracion),
      notas: notas == null && nullToAbsent
          ? const Value.absent()
          : Value(notas),
      favorita: Value(favorita),
      pesoFinalG: pesoFinalG == null && nullToAbsent
          ? const Value.absent()
          : Value(pesoFinalG),
      alimentoId: alimentoId == null && nullToAbsent
          ? const Value.absent()
          : Value(alimentoId),
      creada: Value(creada),
      actualizada: Value(actualizada),
    );
  }

  factory RecetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecetaRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      nombre: serializer.fromJson<String>(json['nombre']),
      categoria: serializer.fromJson<String?>(json['categoria']),
      porciones: serializer.fromJson<int?>(json['porciones']),
      tiempoMin: serializer.fromJson<int?>(json['tiempoMin']),
      elaboracion: serializer.fromJson<String>(json['elaboracion']),
      notas: serializer.fromJson<String?>(json['notas']),
      favorita: serializer.fromJson<bool>(json['favorita']),
      pesoFinalG: serializer.fromJson<double?>(json['pesoFinalG']),
      alimentoId: serializer.fromJson<int?>(json['alimentoId']),
      creada: serializer.fromJson<String>(json['creada']),
      actualizada: serializer.fromJson<String>(json['actualizada']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'nombre': serializer.toJson<String>(nombre),
      'categoria': serializer.toJson<String?>(categoria),
      'porciones': serializer.toJson<int?>(porciones),
      'tiempoMin': serializer.toJson<int?>(tiempoMin),
      'elaboracion': serializer.toJson<String>(elaboracion),
      'notas': serializer.toJson<String?>(notas),
      'favorita': serializer.toJson<bool>(favorita),
      'pesoFinalG': serializer.toJson<double?>(pesoFinalG),
      'alimentoId': serializer.toJson<int?>(alimentoId),
      'creada': serializer.toJson<String>(creada),
      'actualizada': serializer.toJson<String>(actualizada),
    };
  }

  RecetaRow copyWith({
    int? id,
    String? uuid,
    String? nombre,
    Value<String?> categoria = const Value.absent(),
    Value<int?> porciones = const Value.absent(),
    Value<int?> tiempoMin = const Value.absent(),
    String? elaboracion,
    Value<String?> notas = const Value.absent(),
    bool? favorita,
    Value<double?> pesoFinalG = const Value.absent(),
    Value<int?> alimentoId = const Value.absent(),
    String? creada,
    String? actualizada,
  }) => RecetaRow(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    nombre: nombre ?? this.nombre,
    categoria: categoria.present ? categoria.value : this.categoria,
    porciones: porciones.present ? porciones.value : this.porciones,
    tiempoMin: tiempoMin.present ? tiempoMin.value : this.tiempoMin,
    elaboracion: elaboracion ?? this.elaboracion,
    notas: notas.present ? notas.value : this.notas,
    favorita: favorita ?? this.favorita,
    pesoFinalG: pesoFinalG.present ? pesoFinalG.value : this.pesoFinalG,
    alimentoId: alimentoId.present ? alimentoId.value : this.alimentoId,
    creada: creada ?? this.creada,
    actualizada: actualizada ?? this.actualizada,
  );
  RecetaRow copyWithCompanion(RecetasCompanion data) {
    return RecetaRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      categoria: data.categoria.present ? data.categoria.value : this.categoria,
      porciones: data.porciones.present ? data.porciones.value : this.porciones,
      tiempoMin: data.tiempoMin.present ? data.tiempoMin.value : this.tiempoMin,
      elaboracion: data.elaboracion.present
          ? data.elaboracion.value
          : this.elaboracion,
      notas: data.notas.present ? data.notas.value : this.notas,
      favorita: data.favorita.present ? data.favorita.value : this.favorita,
      pesoFinalG: data.pesoFinalG.present
          ? data.pesoFinalG.value
          : this.pesoFinalG,
      alimentoId: data.alimentoId.present
          ? data.alimentoId.value
          : this.alimentoId,
      creada: data.creada.present ? data.creada.value : this.creada,
      actualizada: data.actualizada.present
          ? data.actualizada.value
          : this.actualizada,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecetaRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('nombre: $nombre, ')
          ..write('categoria: $categoria, ')
          ..write('porciones: $porciones, ')
          ..write('tiempoMin: $tiempoMin, ')
          ..write('elaboracion: $elaboracion, ')
          ..write('notas: $notas, ')
          ..write('favorita: $favorita, ')
          ..write('pesoFinalG: $pesoFinalG, ')
          ..write('alimentoId: $alimentoId, ')
          ..write('creada: $creada, ')
          ..write('actualizada: $actualizada')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    nombre,
    categoria,
    porciones,
    tiempoMin,
    elaboracion,
    notas,
    favorita,
    pesoFinalG,
    alimentoId,
    creada,
    actualizada,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecetaRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.nombre == this.nombre &&
          other.categoria == this.categoria &&
          other.porciones == this.porciones &&
          other.tiempoMin == this.tiempoMin &&
          other.elaboracion == this.elaboracion &&
          other.notas == this.notas &&
          other.favorita == this.favorita &&
          other.pesoFinalG == this.pesoFinalG &&
          other.alimentoId == this.alimentoId &&
          other.creada == this.creada &&
          other.actualizada == this.actualizada);
}

class RecetasCompanion extends UpdateCompanion<RecetaRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> nombre;
  final Value<String?> categoria;
  final Value<int?> porciones;
  final Value<int?> tiempoMin;
  final Value<String> elaboracion;
  final Value<String?> notas;
  final Value<bool> favorita;
  final Value<double?> pesoFinalG;
  final Value<int?> alimentoId;
  final Value<String> creada;
  final Value<String> actualizada;
  const RecetasCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.nombre = const Value.absent(),
    this.categoria = const Value.absent(),
    this.porciones = const Value.absent(),
    this.tiempoMin = const Value.absent(),
    this.elaboracion = const Value.absent(),
    this.notas = const Value.absent(),
    this.favorita = const Value.absent(),
    this.pesoFinalG = const Value.absent(),
    this.alimentoId = const Value.absent(),
    this.creada = const Value.absent(),
    this.actualizada = const Value.absent(),
  });
  RecetasCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String nombre,
    this.categoria = const Value.absent(),
    this.porciones = const Value.absent(),
    this.tiempoMin = const Value.absent(),
    this.elaboracion = const Value.absent(),
    this.notas = const Value.absent(),
    this.favorita = const Value.absent(),
    this.pesoFinalG = const Value.absent(),
    this.alimentoId = const Value.absent(),
    required String creada,
    required String actualizada,
  }) : uuid = Value(uuid),
       nombre = Value(nombre),
       creada = Value(creada),
       actualizada = Value(actualizada);
  static Insertable<RecetaRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? nombre,
    Expression<String>? categoria,
    Expression<int>? porciones,
    Expression<int>? tiempoMin,
    Expression<String>? elaboracion,
    Expression<String>? notas,
    Expression<bool>? favorita,
    Expression<double>? pesoFinalG,
    Expression<int>? alimentoId,
    Expression<String>? creada,
    Expression<String>? actualizada,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (nombre != null) 'nombre': nombre,
      if (categoria != null) 'categoria': categoria,
      if (porciones != null) 'porciones': porciones,
      if (tiempoMin != null) 'tiempo_min': tiempoMin,
      if (elaboracion != null) 'elaboracion': elaboracion,
      if (notas != null) 'notas': notas,
      if (favorita != null) 'favorita': favorita,
      if (pesoFinalG != null) 'peso_final_g': pesoFinalG,
      if (alimentoId != null) 'alimento_id': alimentoId,
      if (creada != null) 'creada': creada,
      if (actualizada != null) 'actualizada': actualizada,
    });
  }

  RecetasCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String>? nombre,
    Value<String?>? categoria,
    Value<int?>? porciones,
    Value<int?>? tiempoMin,
    Value<String>? elaboracion,
    Value<String?>? notas,
    Value<bool>? favorita,
    Value<double?>? pesoFinalG,
    Value<int?>? alimentoId,
    Value<String>? creada,
    Value<String>? actualizada,
  }) {
    return RecetasCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      nombre: nombre ?? this.nombre,
      categoria: categoria ?? this.categoria,
      porciones: porciones ?? this.porciones,
      tiempoMin: tiempoMin ?? this.tiempoMin,
      elaboracion: elaboracion ?? this.elaboracion,
      notas: notas ?? this.notas,
      favorita: favorita ?? this.favorita,
      pesoFinalG: pesoFinalG ?? this.pesoFinalG,
      alimentoId: alimentoId ?? this.alimentoId,
      creada: creada ?? this.creada,
      actualizada: actualizada ?? this.actualizada,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (categoria.present) {
      map['categoria'] = Variable<String>(categoria.value);
    }
    if (porciones.present) {
      map['porciones'] = Variable<int>(porciones.value);
    }
    if (tiempoMin.present) {
      map['tiempo_min'] = Variable<int>(tiempoMin.value);
    }
    if (elaboracion.present) {
      map['elaboracion'] = Variable<String>(elaboracion.value);
    }
    if (notas.present) {
      map['notas'] = Variable<String>(notas.value);
    }
    if (favorita.present) {
      map['favorita'] = Variable<bool>(favorita.value);
    }
    if (pesoFinalG.present) {
      map['peso_final_g'] = Variable<double>(pesoFinalG.value);
    }
    if (alimentoId.present) {
      map['alimento_id'] = Variable<int>(alimentoId.value);
    }
    if (creada.present) {
      map['creada'] = Variable<String>(creada.value);
    }
    if (actualizada.present) {
      map['actualizada'] = Variable<String>(actualizada.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecetasCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('nombre: $nombre, ')
          ..write('categoria: $categoria, ')
          ..write('porciones: $porciones, ')
          ..write('tiempoMin: $tiempoMin, ')
          ..write('elaboracion: $elaboracion, ')
          ..write('notas: $notas, ')
          ..write('favorita: $favorita, ')
          ..write('pesoFinalG: $pesoFinalG, ')
          ..write('alimentoId: $alimentoId, ')
          ..write('creada: $creada, ')
          ..write('actualizada: $actualizada')
          ..write(')'))
        .toString();
  }
}

class $IngredientesRecetaTable extends IngredientesReceta
    with TableInfo<$IngredientesRecetaTable, IngredienteRecetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IngredientesRecetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _recetaIdMeta = const VerificationMeta(
    'recetaId',
  );
  @override
  late final GeneratedColumn<int> recetaId = GeneratedColumn<int>(
    'receta_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES recetas (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _ordenMeta = const VerificationMeta('orden');
  @override
  late final GeneratedColumn<int> orden = GeneratedColumn<int>(
    'orden',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _textoMeta = const VerificationMeta('texto');
  @override
  late final GeneratedColumn<String> texto = GeneratedColumn<String>(
    'texto',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _alimentoIdMeta = const VerificationMeta(
    'alimentoId',
  );
  @override
  late final GeneratedColumn<int> alimentoId = GeneratedColumn<int>(
    'alimento_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES alimentos (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _cantidadMeta = const VerificationMeta(
    'cantidad',
  );
  @override
  late final GeneratedColumn<double> cantidad = GeneratedColumn<double>(
    'cantidad',
    aliasedName,
    true,
    check: () => ComparableExpr(cantidad).isBiggerThanValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unidadMeta = const VerificationMeta('unidad');
  @override
  late final GeneratedColumn<String> unidad = GeneratedColumn<String>(
    'unidad',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _opcionalMeta = const VerificationMeta(
    'opcional',
  );
  @override
  late final GeneratedColumn<bool> opcional = GeneratedColumn<bool>(
    'opcional',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("opcional" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    recetaId,
    orden,
    texto,
    alimentoId,
    cantidad,
    unidad,
    opcional,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ingredientes_receta';
  @override
  VerificationContext validateIntegrity(
    Insertable<IngredienteRecetaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('receta_id')) {
      context.handle(
        _recetaIdMeta,
        recetaId.isAcceptableOrUnknown(data['receta_id']!, _recetaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recetaIdMeta);
    }
    if (data.containsKey('orden')) {
      context.handle(
        _ordenMeta,
        orden.isAcceptableOrUnknown(data['orden']!, _ordenMeta),
      );
    } else if (isInserting) {
      context.missing(_ordenMeta);
    }
    if (data.containsKey('texto')) {
      context.handle(
        _textoMeta,
        texto.isAcceptableOrUnknown(data['texto']!, _textoMeta),
      );
    } else if (isInserting) {
      context.missing(_textoMeta);
    }
    if (data.containsKey('alimento_id')) {
      context.handle(
        _alimentoIdMeta,
        alimentoId.isAcceptableOrUnknown(data['alimento_id']!, _alimentoIdMeta),
      );
    }
    if (data.containsKey('cantidad')) {
      context.handle(
        _cantidadMeta,
        cantidad.isAcceptableOrUnknown(data['cantidad']!, _cantidadMeta),
      );
    }
    if (data.containsKey('unidad')) {
      context.handle(
        _unidadMeta,
        unidad.isAcceptableOrUnknown(data['unidad']!, _unidadMeta),
      );
    }
    if (data.containsKey('opcional')) {
      context.handle(
        _opcionalMeta,
        opcional.isAcceptableOrUnknown(data['opcional']!, _opcionalMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IngredienteRecetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IngredienteRecetaRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      recetaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}receta_id'],
      )!,
      orden: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}orden'],
      )!,
      texto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}texto'],
      )!,
      alimentoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}alimento_id'],
      ),
      cantidad: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cantidad'],
      ),
      unidad: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unidad'],
      ),
      opcional: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}opcional'],
      )!,
    );
  }

  @override
  $IngredientesRecetaTable createAlias(String alias) {
    return $IngredientesRecetaTable(attachedDatabase, alias);
  }
}

class IngredienteRecetaRow extends DataClass
    implements Insertable<IngredienteRecetaRow> {
  final int id;
  final int recetaId;
  final int orden;
  final String texto;
  final int? alimentoId;
  final double? cantidad;
  final String? unidad;
  final bool opcional;
  const IngredienteRecetaRow({
    required this.id,
    required this.recetaId,
    required this.orden,
    required this.texto,
    this.alimentoId,
    this.cantidad,
    this.unidad,
    required this.opcional,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['receta_id'] = Variable<int>(recetaId);
    map['orden'] = Variable<int>(orden);
    map['texto'] = Variable<String>(texto);
    if (!nullToAbsent || alimentoId != null) {
      map['alimento_id'] = Variable<int>(alimentoId);
    }
    if (!nullToAbsent || cantidad != null) {
      map['cantidad'] = Variable<double>(cantidad);
    }
    if (!nullToAbsent || unidad != null) {
      map['unidad'] = Variable<String>(unidad);
    }
    map['opcional'] = Variable<bool>(opcional);
    return map;
  }

  IngredientesRecetaCompanion toCompanion(bool nullToAbsent) {
    return IngredientesRecetaCompanion(
      id: Value(id),
      recetaId: Value(recetaId),
      orden: Value(orden),
      texto: Value(texto),
      alimentoId: alimentoId == null && nullToAbsent
          ? const Value.absent()
          : Value(alimentoId),
      cantidad: cantidad == null && nullToAbsent
          ? const Value.absent()
          : Value(cantidad),
      unidad: unidad == null && nullToAbsent
          ? const Value.absent()
          : Value(unidad),
      opcional: Value(opcional),
    );
  }

  factory IngredienteRecetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IngredienteRecetaRow(
      id: serializer.fromJson<int>(json['id']),
      recetaId: serializer.fromJson<int>(json['recetaId']),
      orden: serializer.fromJson<int>(json['orden']),
      texto: serializer.fromJson<String>(json['texto']),
      alimentoId: serializer.fromJson<int?>(json['alimentoId']),
      cantidad: serializer.fromJson<double?>(json['cantidad']),
      unidad: serializer.fromJson<String?>(json['unidad']),
      opcional: serializer.fromJson<bool>(json['opcional']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'recetaId': serializer.toJson<int>(recetaId),
      'orden': serializer.toJson<int>(orden),
      'texto': serializer.toJson<String>(texto),
      'alimentoId': serializer.toJson<int?>(alimentoId),
      'cantidad': serializer.toJson<double?>(cantidad),
      'unidad': serializer.toJson<String?>(unidad),
      'opcional': serializer.toJson<bool>(opcional),
    };
  }

  IngredienteRecetaRow copyWith({
    int? id,
    int? recetaId,
    int? orden,
    String? texto,
    Value<int?> alimentoId = const Value.absent(),
    Value<double?> cantidad = const Value.absent(),
    Value<String?> unidad = const Value.absent(),
    bool? opcional,
  }) => IngredienteRecetaRow(
    id: id ?? this.id,
    recetaId: recetaId ?? this.recetaId,
    orden: orden ?? this.orden,
    texto: texto ?? this.texto,
    alimentoId: alimentoId.present ? alimentoId.value : this.alimentoId,
    cantidad: cantidad.present ? cantidad.value : this.cantidad,
    unidad: unidad.present ? unidad.value : this.unidad,
    opcional: opcional ?? this.opcional,
  );
  IngredienteRecetaRow copyWithCompanion(IngredientesRecetaCompanion data) {
    return IngredienteRecetaRow(
      id: data.id.present ? data.id.value : this.id,
      recetaId: data.recetaId.present ? data.recetaId.value : this.recetaId,
      orden: data.orden.present ? data.orden.value : this.orden,
      texto: data.texto.present ? data.texto.value : this.texto,
      alimentoId: data.alimentoId.present
          ? data.alimentoId.value
          : this.alimentoId,
      cantidad: data.cantidad.present ? data.cantidad.value : this.cantidad,
      unidad: data.unidad.present ? data.unidad.value : this.unidad,
      opcional: data.opcional.present ? data.opcional.value : this.opcional,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IngredienteRecetaRow(')
          ..write('id: $id, ')
          ..write('recetaId: $recetaId, ')
          ..write('orden: $orden, ')
          ..write('texto: $texto, ')
          ..write('alimentoId: $alimentoId, ')
          ..write('cantidad: $cantidad, ')
          ..write('unidad: $unidad, ')
          ..write('opcional: $opcional')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    recetaId,
    orden,
    texto,
    alimentoId,
    cantidad,
    unidad,
    opcional,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IngredienteRecetaRow &&
          other.id == this.id &&
          other.recetaId == this.recetaId &&
          other.orden == this.orden &&
          other.texto == this.texto &&
          other.alimentoId == this.alimentoId &&
          other.cantidad == this.cantidad &&
          other.unidad == this.unidad &&
          other.opcional == this.opcional);
}

class IngredientesRecetaCompanion
    extends UpdateCompanion<IngredienteRecetaRow> {
  final Value<int> id;
  final Value<int> recetaId;
  final Value<int> orden;
  final Value<String> texto;
  final Value<int?> alimentoId;
  final Value<double?> cantidad;
  final Value<String?> unidad;
  final Value<bool> opcional;
  const IngredientesRecetaCompanion({
    this.id = const Value.absent(),
    this.recetaId = const Value.absent(),
    this.orden = const Value.absent(),
    this.texto = const Value.absent(),
    this.alimentoId = const Value.absent(),
    this.cantidad = const Value.absent(),
    this.unidad = const Value.absent(),
    this.opcional = const Value.absent(),
  });
  IngredientesRecetaCompanion.insert({
    this.id = const Value.absent(),
    required int recetaId,
    required int orden,
    required String texto,
    this.alimentoId = const Value.absent(),
    this.cantidad = const Value.absent(),
    this.unidad = const Value.absent(),
    this.opcional = const Value.absent(),
  }) : recetaId = Value(recetaId),
       orden = Value(orden),
       texto = Value(texto);
  static Insertable<IngredienteRecetaRow> custom({
    Expression<int>? id,
    Expression<int>? recetaId,
    Expression<int>? orden,
    Expression<String>? texto,
    Expression<int>? alimentoId,
    Expression<double>? cantidad,
    Expression<String>? unidad,
    Expression<bool>? opcional,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recetaId != null) 'receta_id': recetaId,
      if (orden != null) 'orden': orden,
      if (texto != null) 'texto': texto,
      if (alimentoId != null) 'alimento_id': alimentoId,
      if (cantidad != null) 'cantidad': cantidad,
      if (unidad != null) 'unidad': unidad,
      if (opcional != null) 'opcional': opcional,
    });
  }

  IngredientesRecetaCompanion copyWith({
    Value<int>? id,
    Value<int>? recetaId,
    Value<int>? orden,
    Value<String>? texto,
    Value<int?>? alimentoId,
    Value<double?>? cantidad,
    Value<String?>? unidad,
    Value<bool>? opcional,
  }) {
    return IngredientesRecetaCompanion(
      id: id ?? this.id,
      recetaId: recetaId ?? this.recetaId,
      orden: orden ?? this.orden,
      texto: texto ?? this.texto,
      alimentoId: alimentoId ?? this.alimentoId,
      cantidad: cantidad ?? this.cantidad,
      unidad: unidad ?? this.unidad,
      opcional: opcional ?? this.opcional,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (recetaId.present) {
      map['receta_id'] = Variable<int>(recetaId.value);
    }
    if (orden.present) {
      map['orden'] = Variable<int>(orden.value);
    }
    if (texto.present) {
      map['texto'] = Variable<String>(texto.value);
    }
    if (alimentoId.present) {
      map['alimento_id'] = Variable<int>(alimentoId.value);
    }
    if (cantidad.present) {
      map['cantidad'] = Variable<double>(cantidad.value);
    }
    if (unidad.present) {
      map['unidad'] = Variable<String>(unidad.value);
    }
    if (opcional.present) {
      map['opcional'] = Variable<bool>(opcional.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IngredientesRecetaCompanion(')
          ..write('id: $id, ')
          ..write('recetaId: $recetaId, ')
          ..write('orden: $orden, ')
          ..write('texto: $texto, ')
          ..write('alimentoId: $alimentoId, ')
          ..write('cantidad: $cantidad, ')
          ..write('unidad: $unidad, ')
          ..write('opcional: $opcional')
          ..write(')'))
        .toString();
  }
}

class $ComidasTable extends Comidas with TableInfo<$ComidasTable, ComidaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ComidasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaMeta = const VerificationMeta('fecha');
  @override
  late final GeneratedColumn<String> fecha = GeneratedColumn<String>(
    'fecha',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, nombre, fecha];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'comidas';
  @override
  VerificationContext validateIntegrity(
    Insertable<ComidaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('fecha')) {
      context.handle(
        _fechaMeta,
        fecha.isAcceptableOrUnknown(data['fecha']!, _fechaMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ComidaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ComidaRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      fecha: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fecha'],
      )!,
    );
  }

  @override
  $ComidasTable createAlias(String alias) {
    return $ComidasTable(attachedDatabase, alias);
  }
}

class ComidaRow extends DataClass implements Insertable<ComidaRow> {
  final int id;
  final String nombre;
  final String fecha;
  const ComidaRow({
    required this.id,
    required this.nombre,
    required this.fecha,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nombre'] = Variable<String>(nombre);
    map['fecha'] = Variable<String>(fecha);
    return map;
  }

  ComidasCompanion toCompanion(bool nullToAbsent) {
    return ComidasCompanion(
      id: Value(id),
      nombre: Value(nombre),
      fecha: Value(fecha),
    );
  }

  factory ComidaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ComidaRow(
      id: serializer.fromJson<int>(json['id']),
      nombre: serializer.fromJson<String>(json['nombre']),
      fecha: serializer.fromJson<String>(json['fecha']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nombre': serializer.toJson<String>(nombre),
      'fecha': serializer.toJson<String>(fecha),
    };
  }

  ComidaRow copyWith({int? id, String? nombre, String? fecha}) => ComidaRow(
    id: id ?? this.id,
    nombre: nombre ?? this.nombre,
    fecha: fecha ?? this.fecha,
  );
  ComidaRow copyWithCompanion(ComidasCompanion data) {
    return ComidaRow(
      id: data.id.present ? data.id.value : this.id,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ComidaRow(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('fecha: $fecha')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nombre, fecha);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ComidaRow &&
          other.id == this.id &&
          other.nombre == this.nombre &&
          other.fecha == this.fecha);
}

class ComidasCompanion extends UpdateCompanion<ComidaRow> {
  final Value<int> id;
  final Value<String> nombre;
  final Value<String> fecha;
  const ComidasCompanion({
    this.id = const Value.absent(),
    this.nombre = const Value.absent(),
    this.fecha = const Value.absent(),
  });
  ComidasCompanion.insert({
    this.id = const Value.absent(),
    required String nombre,
    required String fecha,
  }) : nombre = Value(nombre),
       fecha = Value(fecha);
  static Insertable<ComidaRow> custom({
    Expression<int>? id,
    Expression<String>? nombre,
    Expression<String>? fecha,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nombre != null) 'nombre': nombre,
      if (fecha != null) 'fecha': fecha,
    });
  }

  ComidasCompanion copyWith({
    Value<int>? id,
    Value<String>? nombre,
    Value<String>? fecha,
  }) {
    return ComidasCompanion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      fecha: fecha ?? this.fecha,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (fecha.present) {
      map['fecha'] = Variable<String>(fecha.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ComidasCompanion(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('fecha: $fecha')
          ..write(')'))
        .toString();
  }
}

class $ItemsComidaTable extends ItemsComida
    with TableInfo<$ItemsComidaTable, ItemComidaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemsComidaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _comidaIdMeta = const VerificationMeta(
    'comidaId',
  );
  @override
  late final GeneratedColumn<int> comidaId = GeneratedColumn<int>(
    'comida_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES comidas (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _alimentoIdMeta = const VerificationMeta(
    'alimentoId',
  );
  @override
  late final GeneratedColumn<int> alimentoId = GeneratedColumn<int>(
    'alimento_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES alimentos (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cantidadMeta = const VerificationMeta(
    'cantidad',
  );
  @override
  late final GeneratedColumn<double> cantidad = GeneratedColumn<double>(
    'cantidad',
    aliasedName,
    false,
    check: () => ComparableExpr(cantidad).isBiggerThanValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kcalMeta = const VerificationMeta('kcal');
  @override
  late final GeneratedColumn<double> kcal = GeneratedColumn<double>(
    'kcal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinasMeta = const VerificationMeta(
    'proteinas',
  );
  @override
  late final GeneratedColumn<double> proteinas = GeneratedColumn<double>(
    'proteinas',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _grasasMeta = const VerificationMeta('grasas');
  @override
  late final GeneratedColumn<double> grasas = GeneratedColumn<double>(
    'grasas',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbohidratosMeta = const VerificationMeta(
    'carbohidratos',
  );
  @override
  late final GeneratedColumn<double> carbohidratos = GeneratedColumn<double>(
    'carbohidratos',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    comidaId,
    alimentoId,
    nombre,
    cantidad,
    kcal,
    proteinas,
    grasas,
    carbohidratos,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'items_comida';
  @override
  VerificationContext validateIntegrity(
    Insertable<ItemComidaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('comida_id')) {
      context.handle(
        _comidaIdMeta,
        comidaId.isAcceptableOrUnknown(data['comida_id']!, _comidaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_comidaIdMeta);
    }
    if (data.containsKey('alimento_id')) {
      context.handle(
        _alimentoIdMeta,
        alimentoId.isAcceptableOrUnknown(data['alimento_id']!, _alimentoIdMeta),
      );
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('cantidad')) {
      context.handle(
        _cantidadMeta,
        cantidad.isAcceptableOrUnknown(data['cantidad']!, _cantidadMeta),
      );
    } else if (isInserting) {
      context.missing(_cantidadMeta);
    }
    if (data.containsKey('kcal')) {
      context.handle(
        _kcalMeta,
        kcal.isAcceptableOrUnknown(data['kcal']!, _kcalMeta),
      );
    } else if (isInserting) {
      context.missing(_kcalMeta);
    }
    if (data.containsKey('proteinas')) {
      context.handle(
        _proteinasMeta,
        proteinas.isAcceptableOrUnknown(data['proteinas']!, _proteinasMeta),
      );
    } else if (isInserting) {
      context.missing(_proteinasMeta);
    }
    if (data.containsKey('grasas')) {
      context.handle(
        _grasasMeta,
        grasas.isAcceptableOrUnknown(data['grasas']!, _grasasMeta),
      );
    } else if (isInserting) {
      context.missing(_grasasMeta);
    }
    if (data.containsKey('carbohidratos')) {
      context.handle(
        _carbohidratosMeta,
        carbohidratos.isAcceptableOrUnknown(
          data['carbohidratos']!,
          _carbohidratosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_carbohidratosMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ItemComidaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemComidaRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      comidaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}comida_id'],
      )!,
      alimentoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}alimento_id'],
      ),
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      cantidad: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cantidad'],
      )!,
      kcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kcal'],
      )!,
      proteinas: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}proteinas'],
      )!,
      grasas: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grasas'],
      )!,
      carbohidratos: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbohidratos'],
      )!,
    );
  }

  @override
  $ItemsComidaTable createAlias(String alias) {
    return $ItemsComidaTable(attachedDatabase, alias);
  }
}

class ItemComidaRow extends DataClass implements Insertable<ItemComidaRow> {
  final int id;
  final int comidaId;
  final int? alimentoId;
  final String nombre;
  final double cantidad;
  final double kcal;
  final double proteinas;
  final double grasas;
  final double carbohidratos;
  const ItemComidaRow({
    required this.id,
    required this.comidaId,
    this.alimentoId,
    required this.nombre,
    required this.cantidad,
    required this.kcal,
    required this.proteinas,
    required this.grasas,
    required this.carbohidratos,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['comida_id'] = Variable<int>(comidaId);
    if (!nullToAbsent || alimentoId != null) {
      map['alimento_id'] = Variable<int>(alimentoId);
    }
    map['nombre'] = Variable<String>(nombre);
    map['cantidad'] = Variable<double>(cantidad);
    map['kcal'] = Variable<double>(kcal);
    map['proteinas'] = Variable<double>(proteinas);
    map['grasas'] = Variable<double>(grasas);
    map['carbohidratos'] = Variable<double>(carbohidratos);
    return map;
  }

  ItemsComidaCompanion toCompanion(bool nullToAbsent) {
    return ItemsComidaCompanion(
      id: Value(id),
      comidaId: Value(comidaId),
      alimentoId: alimentoId == null && nullToAbsent
          ? const Value.absent()
          : Value(alimentoId),
      nombre: Value(nombre),
      cantidad: Value(cantidad),
      kcal: Value(kcal),
      proteinas: Value(proteinas),
      grasas: Value(grasas),
      carbohidratos: Value(carbohidratos),
    );
  }

  factory ItemComidaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemComidaRow(
      id: serializer.fromJson<int>(json['id']),
      comidaId: serializer.fromJson<int>(json['comidaId']),
      alimentoId: serializer.fromJson<int?>(json['alimentoId']),
      nombre: serializer.fromJson<String>(json['nombre']),
      cantidad: serializer.fromJson<double>(json['cantidad']),
      kcal: serializer.fromJson<double>(json['kcal']),
      proteinas: serializer.fromJson<double>(json['proteinas']),
      grasas: serializer.fromJson<double>(json['grasas']),
      carbohidratos: serializer.fromJson<double>(json['carbohidratos']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'comidaId': serializer.toJson<int>(comidaId),
      'alimentoId': serializer.toJson<int?>(alimentoId),
      'nombre': serializer.toJson<String>(nombre),
      'cantidad': serializer.toJson<double>(cantidad),
      'kcal': serializer.toJson<double>(kcal),
      'proteinas': serializer.toJson<double>(proteinas),
      'grasas': serializer.toJson<double>(grasas),
      'carbohidratos': serializer.toJson<double>(carbohidratos),
    };
  }

  ItemComidaRow copyWith({
    int? id,
    int? comidaId,
    Value<int?> alimentoId = const Value.absent(),
    String? nombre,
    double? cantidad,
    double? kcal,
    double? proteinas,
    double? grasas,
    double? carbohidratos,
  }) => ItemComidaRow(
    id: id ?? this.id,
    comidaId: comidaId ?? this.comidaId,
    alimentoId: alimentoId.present ? alimentoId.value : this.alimentoId,
    nombre: nombre ?? this.nombre,
    cantidad: cantidad ?? this.cantidad,
    kcal: kcal ?? this.kcal,
    proteinas: proteinas ?? this.proteinas,
    grasas: grasas ?? this.grasas,
    carbohidratos: carbohidratos ?? this.carbohidratos,
  );
  ItemComidaRow copyWithCompanion(ItemsComidaCompanion data) {
    return ItemComidaRow(
      id: data.id.present ? data.id.value : this.id,
      comidaId: data.comidaId.present ? data.comidaId.value : this.comidaId,
      alimentoId: data.alimentoId.present
          ? data.alimentoId.value
          : this.alimentoId,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      cantidad: data.cantidad.present ? data.cantidad.value : this.cantidad,
      kcal: data.kcal.present ? data.kcal.value : this.kcal,
      proteinas: data.proteinas.present ? data.proteinas.value : this.proteinas,
      grasas: data.grasas.present ? data.grasas.value : this.grasas,
      carbohidratos: data.carbohidratos.present
          ? data.carbohidratos.value
          : this.carbohidratos,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemComidaRow(')
          ..write('id: $id, ')
          ..write('comidaId: $comidaId, ')
          ..write('alimentoId: $alimentoId, ')
          ..write('nombre: $nombre, ')
          ..write('cantidad: $cantidad, ')
          ..write('kcal: $kcal, ')
          ..write('proteinas: $proteinas, ')
          ..write('grasas: $grasas, ')
          ..write('carbohidratos: $carbohidratos')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    comidaId,
    alimentoId,
    nombre,
    cantidad,
    kcal,
    proteinas,
    grasas,
    carbohidratos,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemComidaRow &&
          other.id == this.id &&
          other.comidaId == this.comidaId &&
          other.alimentoId == this.alimentoId &&
          other.nombre == this.nombre &&
          other.cantidad == this.cantidad &&
          other.kcal == this.kcal &&
          other.proteinas == this.proteinas &&
          other.grasas == this.grasas &&
          other.carbohidratos == this.carbohidratos);
}

class ItemsComidaCompanion extends UpdateCompanion<ItemComidaRow> {
  final Value<int> id;
  final Value<int> comidaId;
  final Value<int?> alimentoId;
  final Value<String> nombre;
  final Value<double> cantidad;
  final Value<double> kcal;
  final Value<double> proteinas;
  final Value<double> grasas;
  final Value<double> carbohidratos;
  const ItemsComidaCompanion({
    this.id = const Value.absent(),
    this.comidaId = const Value.absent(),
    this.alimentoId = const Value.absent(),
    this.nombre = const Value.absent(),
    this.cantidad = const Value.absent(),
    this.kcal = const Value.absent(),
    this.proteinas = const Value.absent(),
    this.grasas = const Value.absent(),
    this.carbohidratos = const Value.absent(),
  });
  ItemsComidaCompanion.insert({
    this.id = const Value.absent(),
    required int comidaId,
    this.alimentoId = const Value.absent(),
    required String nombre,
    required double cantidad,
    required double kcal,
    required double proteinas,
    required double grasas,
    required double carbohidratos,
  }) : comidaId = Value(comidaId),
       nombre = Value(nombre),
       cantidad = Value(cantidad),
       kcal = Value(kcal),
       proteinas = Value(proteinas),
       grasas = Value(grasas),
       carbohidratos = Value(carbohidratos);
  static Insertable<ItemComidaRow> custom({
    Expression<int>? id,
    Expression<int>? comidaId,
    Expression<int>? alimentoId,
    Expression<String>? nombre,
    Expression<double>? cantidad,
    Expression<double>? kcal,
    Expression<double>? proteinas,
    Expression<double>? grasas,
    Expression<double>? carbohidratos,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (comidaId != null) 'comida_id': comidaId,
      if (alimentoId != null) 'alimento_id': alimentoId,
      if (nombre != null) 'nombre': nombre,
      if (cantidad != null) 'cantidad': cantidad,
      if (kcal != null) 'kcal': kcal,
      if (proteinas != null) 'proteinas': proteinas,
      if (grasas != null) 'grasas': grasas,
      if (carbohidratos != null) 'carbohidratos': carbohidratos,
    });
  }

  ItemsComidaCompanion copyWith({
    Value<int>? id,
    Value<int>? comidaId,
    Value<int?>? alimentoId,
    Value<String>? nombre,
    Value<double>? cantidad,
    Value<double>? kcal,
    Value<double>? proteinas,
    Value<double>? grasas,
    Value<double>? carbohidratos,
  }) {
    return ItemsComidaCompanion(
      id: id ?? this.id,
      comidaId: comidaId ?? this.comidaId,
      alimentoId: alimentoId ?? this.alimentoId,
      nombre: nombre ?? this.nombre,
      cantidad: cantidad ?? this.cantidad,
      kcal: kcal ?? this.kcal,
      proteinas: proteinas ?? this.proteinas,
      grasas: grasas ?? this.grasas,
      carbohidratos: carbohidratos ?? this.carbohidratos,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (comidaId.present) {
      map['comida_id'] = Variable<int>(comidaId.value);
    }
    if (alimentoId.present) {
      map['alimento_id'] = Variable<int>(alimentoId.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (cantidad.present) {
      map['cantidad'] = Variable<double>(cantidad.value);
    }
    if (kcal.present) {
      map['kcal'] = Variable<double>(kcal.value);
    }
    if (proteinas.present) {
      map['proteinas'] = Variable<double>(proteinas.value);
    }
    if (grasas.present) {
      map['grasas'] = Variable<double>(grasas.value);
    }
    if (carbohidratos.present) {
      map['carbohidratos'] = Variable<double>(carbohidratos.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemsComidaCompanion(')
          ..write('id: $id, ')
          ..write('comidaId: $comidaId, ')
          ..write('alimentoId: $alimentoId, ')
          ..write('nombre: $nombre, ')
          ..write('cantidad: $cantidad, ')
          ..write('kcal: $kcal, ')
          ..write('proteinas: $proteinas, ')
          ..write('grasas: $grasas, ')
          ..write('carbohidratos: $carbohidratos')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CategoriasTable categorias = $CategoriasTable(this);
  late final $AlimentosTable alimentos = $AlimentosTable(this);
  late final $PorcionesTable porciones = $PorcionesTable(this);
  late final $PresentacionesTable presentaciones = $PresentacionesTable(this);
  late final $EstablecimientosTable establecimientos = $EstablecimientosTable(
    this,
  );
  late final $OrdenPasillosTable ordenPasillos = $OrdenPasillosTable(this);
  late final $CodigosBasculaTable codigosBascula = $CodigosBasculaTable(this);
  late final $ComprasTable compras = $ComprasTable(this);
  late final $ListasCompraTable listasCompra = $ListasCompraTable(this);
  late final $ItemsListaTable itemsLista = $ItemsListaTable(this);
  late final $RecetasTable recetas = $RecetasTable(this);
  late final $IngredientesRecetaTable ingredientesReceta =
      $IngredientesRecetaTable(this);
  late final $ComidasTable comidas = $ComidasTable(this);
  late final $ItemsComidaTable itemsComida = $ItemsComidaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    categorias,
    alimentos,
    porciones,
    presentaciones,
    establecimientos,
    ordenPasillos,
    codigosBascula,
    compras,
    listasCompra,
    itemsLista,
    recetas,
    ingredientesReceta,
    comidas,
    itemsComida,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'categorias',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('alimentos', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'alimentos',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('porciones', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'alimentos',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('presentaciones', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'establecimientos',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('orden_pasillos', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'categorias',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('orden_pasillos', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'establecimientos',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('codigos_bascula', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'presentaciones',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('codigos_bascula', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'listas_compra',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('items_lista', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'alimentos',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('items_lista', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'compras',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('items_lista', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'alimentos',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('recetas', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'recetas',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('ingredientes_receta', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'alimentos',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('ingredientes_receta', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'comidas',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('items_comida', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'alimentos',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('items_comida', kind: UpdateKind.update)],
    ),
  ]);
}

typedef $$CategoriasTableCreateCompanionBuilder =
    CategoriasCompanion Function({
      Value<int> id,
      required String nombre,
      Value<int> orden,
    });
typedef $$CategoriasTableUpdateCompanionBuilder =
    CategoriasCompanion Function({
      Value<int> id,
      Value<String> nombre,
      Value<int> orden,
    });

final class $$CategoriasTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriasTable, CategoriaRow> {
  $$CategoriasTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AlimentosTable, List<AlimentoRow>>
  _alimentosRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.alimentos,
    aliasName: 'categorias__id__alimentos__categoria_id',
  );

  $$AlimentosTableProcessedTableManager get alimentosRefs {
    final manager = $$AlimentosTableTableManager(
      $_db,
      $_db.alimentos,
    ).filter((f) => f.categoriaId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_alimentosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$OrdenPasillosTable, List<OrdenPasilloRow>>
  _ordenPasillosRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ordenPasillos,
    aliasName: 'categorias__id__orden_pasillos__categoria_id',
  );

  $$OrdenPasillosTableProcessedTableManager get ordenPasillosRefs {
    final manager = $$OrdenPasillosTableTableManager(
      $_db,
      $_db.ordenPasillos,
    ).filter((f) => f.categoriaId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_ordenPasillosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CategoriasTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriasTable> {
  $$CategoriasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orden => $composableBuilder(
    column: $table.orden,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> alimentosRefs(
    Expression<bool> Function($$AlimentosTableFilterComposer f) f,
  ) {
    final $$AlimentosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.alimentos,
      getReferencedColumn: (t) => t.categoriaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlimentosTableFilterComposer(
            $db: $db,
            $table: $db.alimentos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> ordenPasillosRefs(
    Expression<bool> Function($$OrdenPasillosTableFilterComposer f) f,
  ) {
    final $$OrdenPasillosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ordenPasillos,
      getReferencedColumn: (t) => t.categoriaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdenPasillosTableFilterComposer(
            $db: $db,
            $table: $db.ordenPasillos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriasTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriasTable> {
  $$CategoriasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orden => $composableBuilder(
    column: $table.orden,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriasTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriasTable> {
  $$CategoriasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<int> get orden =>
      $composableBuilder(column: $table.orden, builder: (column) => column);

  Expression<T> alimentosRefs<T extends Object>(
    Expression<T> Function($$AlimentosTableAnnotationComposer a) f,
  ) {
    final $$AlimentosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.alimentos,
      getReferencedColumn: (t) => t.categoriaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlimentosTableAnnotationComposer(
            $db: $db,
            $table: $db.alimentos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> ordenPasillosRefs<T extends Object>(
    Expression<T> Function($$OrdenPasillosTableAnnotationComposer a) f,
  ) {
    final $$OrdenPasillosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ordenPasillos,
      getReferencedColumn: (t) => t.categoriaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdenPasillosTableAnnotationComposer(
            $db: $db,
            $table: $db.ordenPasillos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriasTable,
          CategoriaRow,
          $$CategoriasTableFilterComposer,
          $$CategoriasTableOrderingComposer,
          $$CategoriasTableAnnotationComposer,
          $$CategoriasTableCreateCompanionBuilder,
          $$CategoriasTableUpdateCompanionBuilder,
          (CategoriaRow, $$CategoriasTableReferences),
          CategoriaRow,
          PrefetchHooks Function({bool alimentosRefs, bool ordenPasillosRefs})
        > {
  $$CategoriasTableTableManager(_$AppDatabase db, $CategoriasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<int> orden = const Value.absent(),
              }) => CategoriasCompanion(id: id, nombre: nombre, orden: orden),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String nombre,
                Value<int> orden = const Value.absent(),
              }) => CategoriasCompanion.insert(
                id: id,
                nombre: nombre,
                orden: orden,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategoriasTable, CategoriaRow>(table),
                  $$CategoriasTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({alimentosRefs = false, ordenPasillosRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (alimentosRefs) db.alimentos,
                    if (ordenPasillosRefs) db.ordenPasillos,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (alimentosRefs)
                        await $_getPrefetchedDataByColumns<
                          CategoriaRow,
                          $CategoriasTable,
                          AlimentoRow,
                          $AlimentosTable
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriasTableReferences
                              ._alimentosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriasTableReferences(
                                db,
                                table,
                                p0,
                              ).alimentosRefs,
                          currentColumn: 'id',
                          referencedColumn: 'categoria_id',
                          typedResults: items,
                        ),
                      if (ordenPasillosRefs)
                        await $_getPrefetchedDataByColumns<
                          CategoriaRow,
                          $CategoriasTable,
                          OrdenPasilloRow,
                          $OrdenPasillosTable
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriasTableReferences
                              ._ordenPasillosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriasTableReferences(
                                db,
                                table,
                                p0,
                              ).ordenPasillosRefs,
                          currentColumn: 'id',
                          referencedColumn: 'categoria_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CategoriasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriasTable,
      CategoriaRow,
      $$CategoriasTableFilterComposer,
      $$CategoriasTableOrderingComposer,
      $$CategoriasTableAnnotationComposer,
      $$CategoriasTableCreateCompanionBuilder,
      $$CategoriasTableUpdateCompanionBuilder,
      (CategoriaRow, $$CategoriasTableReferences),
      CategoriaRow,
      PrefetchHooks Function({bool alimentosRefs, bool ordenPasillosRefs})
    >;
typedef $$AlimentosTableCreateCompanionBuilder =
    AlimentosCompanion Function({
      Value<int> id,
      required String uuid,
      required String nombre,
      Value<String> marca,
      Value<String> tipo,
      Value<String> unidad,
      Value<int?> categoriaId,
      Value<double?> kcal,
      Value<double?> proteinas,
      Value<double?> grasas,
      Value<double?> grasasSaturadas,
      Value<double?> carbohidratos,
      Value<double?> azucares,
      Value<double?> fibra,
      Value<double?> sal,
      Value<String?> nutricionOrigen,
      Value<String?> notas,
      Value<int> usoCount,
      Value<String?> ultimoUso,
      Value<bool> archivado,
      required String creado,
      required String actualizado,
    });
typedef $$AlimentosTableUpdateCompanionBuilder =
    AlimentosCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<String> nombre,
      Value<String> marca,
      Value<String> tipo,
      Value<String> unidad,
      Value<int?> categoriaId,
      Value<double?> kcal,
      Value<double?> proteinas,
      Value<double?> grasas,
      Value<double?> grasasSaturadas,
      Value<double?> carbohidratos,
      Value<double?> azucares,
      Value<double?> fibra,
      Value<double?> sal,
      Value<String?> nutricionOrigen,
      Value<String?> notas,
      Value<int> usoCount,
      Value<String?> ultimoUso,
      Value<bool> archivado,
      Value<String> creado,
      Value<String> actualizado,
    });

final class $$AlimentosTableReferences
    extends BaseReferences<_$AppDatabase, $AlimentosTable, AlimentoRow> {
  $$AlimentosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriasTable _categoriaIdTable(_$AppDatabase db) =>
      db.categorias.createAlias('alimentos__categoria_id__categorias__id');

  $$CategoriasTableProcessedTableManager? get categoriaId {
    final $_column = $_itemColumn<int>('categoria_id');
    if ($_column == null) return null;
    final manager = $$CategoriasTableTableManager(
      $_db,
      $_db.categorias,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoriaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PorcionesTable, List<PorcionRow>>
  _porcionesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.porciones,
    aliasName: 'alimentos__id__porciones__alimento_id',
  );

  $$PorcionesTableProcessedTableManager get porcionesRefs {
    final manager = $$PorcionesTableTableManager(
      $_db,
      $_db.porciones,
    ).filter((f) => f.alimentoId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_porcionesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PresentacionesTable, List<PresentacionRow>>
  _presentacionesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.presentaciones,
    aliasName: 'alimentos__id__presentaciones__alimento_id',
  );

  $$PresentacionesTableProcessedTableManager get presentacionesRefs {
    final manager = $$PresentacionesTableTableManager(
      $_db,
      $_db.presentaciones,
    ).filter((f) => f.alimentoId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_presentacionesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ItemsListaTable, List<ItemListaRow>>
  _itemsListaRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.itemsLista,
    aliasName: 'alimentos__id__items_lista__alimento_id',
  );

  $$ItemsListaTableProcessedTableManager get itemsListaRefs {
    final manager = $$ItemsListaTableTableManager(
      $_db,
      $_db.itemsLista,
    ).filter((f) => f.alimentoId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_itemsListaRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RecetasTable, List<RecetaRow>> _recetasRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.recetas,
    aliasName: 'alimentos__id__recetas__alimento_id',
  );

  $$RecetasTableProcessedTableManager get recetasRefs {
    final manager = $$RecetasTableTableManager(
      $_db,
      $_db.recetas,
    ).filter((f) => f.alimentoId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_recetasRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $IngredientesRecetaTable,
    List<IngredienteRecetaRow>
  >
  _ingredientesRecetaRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.ingredientesReceta,
        aliasName: 'alimentos__id__ingredientes_receta__alimento_id',
      );

  $$IngredientesRecetaTableProcessedTableManager get ingredientesRecetaRefs {
    final manager = $$IngredientesRecetaTableTableManager(
      $_db,
      $_db.ingredientesReceta,
    ).filter((f) => f.alimentoId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _ingredientesRecetaRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ItemsComidaTable, List<ItemComidaRow>>
  _itemsComidaRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.itemsComida,
    aliasName: 'alimentos__id__items_comida__alimento_id',
  );

  $$ItemsComidaTableProcessedTableManager get itemsComidaRefs {
    final manager = $$ItemsComidaTableTableManager(
      $_db,
      $_db.itemsComida,
    ).filter((f) => f.alimentoId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_itemsComidaRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AlimentosTableFilterComposer
    extends Composer<_$AppDatabase, $AlimentosTable> {
  $$AlimentosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get marca => $composableBuilder(
    column: $table.marca,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unidad => $composableBuilder(
    column: $table.unidad,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kcal => $composableBuilder(
    column: $table.kcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinas => $composableBuilder(
    column: $table.proteinas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grasas => $composableBuilder(
    column: $table.grasas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grasasSaturadas => $composableBuilder(
    column: $table.grasasSaturadas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbohidratos => $composableBuilder(
    column: $table.carbohidratos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get azucares => $composableBuilder(
    column: $table.azucares,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fibra => $composableBuilder(
    column: $table.fibra,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sal => $composableBuilder(
    column: $table.sal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nutricionOrigen => $composableBuilder(
    column: $table.nutricionOrigen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notas => $composableBuilder(
    column: $table.notas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get usoCount => $composableBuilder(
    column: $table.usoCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ultimoUso => $composableBuilder(
    column: $table.ultimoUso,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archivado => $composableBuilder(
    column: $table.archivado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creado => $composableBuilder(
    column: $table.creado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actualizado => $composableBuilder(
    column: $table.actualizado,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriasTableFilterComposer get categoriaId {
    final $$CategoriasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoriaId,
      referencedTable: $db.categorias,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriasTableFilterComposer(
            $db: $db,
            $table: $db.categorias,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> porcionesRefs(
    Expression<bool> Function($$PorcionesTableFilterComposer f) f,
  ) {
    final $$PorcionesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.porciones,
      getReferencedColumn: (t) => t.alimentoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PorcionesTableFilterComposer(
            $db: $db,
            $table: $db.porciones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> presentacionesRefs(
    Expression<bool> Function($$PresentacionesTableFilterComposer f) f,
  ) {
    final $$PresentacionesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.presentaciones,
      getReferencedColumn: (t) => t.alimentoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PresentacionesTableFilterComposer(
            $db: $db,
            $table: $db.presentaciones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> itemsListaRefs(
    Expression<bool> Function($$ItemsListaTableFilterComposer f) f,
  ) {
    final $$ItemsListaTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemsLista,
      getReferencedColumn: (t) => t.alimentoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsListaTableFilterComposer(
            $db: $db,
            $table: $db.itemsLista,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> recetasRefs(
    Expression<bool> Function($$RecetasTableFilterComposer f) f,
  ) {
    final $$RecetasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recetas,
      getReferencedColumn: (t) => t.alimentoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecetasTableFilterComposer(
            $db: $db,
            $table: $db.recetas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> ingredientesRecetaRefs(
    Expression<bool> Function($$IngredientesRecetaTableFilterComposer f) f,
  ) {
    final $$IngredientesRecetaTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ingredientesReceta,
      getReferencedColumn: (t) => t.alimentoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IngredientesRecetaTableFilterComposer(
            $db: $db,
            $table: $db.ingredientesReceta,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> itemsComidaRefs(
    Expression<bool> Function($$ItemsComidaTableFilterComposer f) f,
  ) {
    final $$ItemsComidaTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemsComida,
      getReferencedColumn: (t) => t.alimentoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsComidaTableFilterComposer(
            $db: $db,
            $table: $db.itemsComida,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AlimentosTableOrderingComposer
    extends Composer<_$AppDatabase, $AlimentosTable> {
  $$AlimentosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get marca => $composableBuilder(
    column: $table.marca,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unidad => $composableBuilder(
    column: $table.unidad,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kcal => $composableBuilder(
    column: $table.kcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinas => $composableBuilder(
    column: $table.proteinas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grasas => $composableBuilder(
    column: $table.grasas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grasasSaturadas => $composableBuilder(
    column: $table.grasasSaturadas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbohidratos => $composableBuilder(
    column: $table.carbohidratos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get azucares => $composableBuilder(
    column: $table.azucares,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fibra => $composableBuilder(
    column: $table.fibra,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sal => $composableBuilder(
    column: $table.sal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nutricionOrigen => $composableBuilder(
    column: $table.nutricionOrigen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notas => $composableBuilder(
    column: $table.notas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get usoCount => $composableBuilder(
    column: $table.usoCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ultimoUso => $composableBuilder(
    column: $table.ultimoUso,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archivado => $composableBuilder(
    column: $table.archivado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creado => $composableBuilder(
    column: $table.creado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actualizado => $composableBuilder(
    column: $table.actualizado,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriasTableOrderingComposer get categoriaId {
    final $$CategoriasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoriaId,
      referencedTable: $db.categorias,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriasTableOrderingComposer(
            $db: $db,
            $table: $db.categorias,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AlimentosTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlimentosTable> {
  $$AlimentosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get marca =>
      $composableBuilder(column: $table.marca, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<String> get unidad =>
      $composableBuilder(column: $table.unidad, builder: (column) => column);

  GeneratedColumn<double> get kcal =>
      $composableBuilder(column: $table.kcal, builder: (column) => column);

  GeneratedColumn<double> get proteinas =>
      $composableBuilder(column: $table.proteinas, builder: (column) => column);

  GeneratedColumn<double> get grasas =>
      $composableBuilder(column: $table.grasas, builder: (column) => column);

  GeneratedColumn<double> get grasasSaturadas => $composableBuilder(
    column: $table.grasasSaturadas,
    builder: (column) => column,
  );

  GeneratedColumn<double> get carbohidratos => $composableBuilder(
    column: $table.carbohidratos,
    builder: (column) => column,
  );

  GeneratedColumn<double> get azucares =>
      $composableBuilder(column: $table.azucares, builder: (column) => column);

  GeneratedColumn<double> get fibra =>
      $composableBuilder(column: $table.fibra, builder: (column) => column);

  GeneratedColumn<double> get sal =>
      $composableBuilder(column: $table.sal, builder: (column) => column);

  GeneratedColumn<String> get nutricionOrigen => $composableBuilder(
    column: $table.nutricionOrigen,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notas =>
      $composableBuilder(column: $table.notas, builder: (column) => column);

  GeneratedColumn<int> get usoCount =>
      $composableBuilder(column: $table.usoCount, builder: (column) => column);

  GeneratedColumn<String> get ultimoUso =>
      $composableBuilder(column: $table.ultimoUso, builder: (column) => column);

  GeneratedColumn<bool> get archivado =>
      $composableBuilder(column: $table.archivado, builder: (column) => column);

  GeneratedColumn<String> get creado =>
      $composableBuilder(column: $table.creado, builder: (column) => column);

  GeneratedColumn<String> get actualizado => $composableBuilder(
    column: $table.actualizado,
    builder: (column) => column,
  );

  $$CategoriasTableAnnotationComposer get categoriaId {
    final $$CategoriasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoriaId,
      referencedTable: $db.categorias,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriasTableAnnotationComposer(
            $db: $db,
            $table: $db.categorias,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> porcionesRefs<T extends Object>(
    Expression<T> Function($$PorcionesTableAnnotationComposer a) f,
  ) {
    final $$PorcionesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.porciones,
      getReferencedColumn: (t) => t.alimentoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PorcionesTableAnnotationComposer(
            $db: $db,
            $table: $db.porciones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> presentacionesRefs<T extends Object>(
    Expression<T> Function($$PresentacionesTableAnnotationComposer a) f,
  ) {
    final $$PresentacionesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.presentaciones,
      getReferencedColumn: (t) => t.alimentoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PresentacionesTableAnnotationComposer(
            $db: $db,
            $table: $db.presentaciones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> itemsListaRefs<T extends Object>(
    Expression<T> Function($$ItemsListaTableAnnotationComposer a) f,
  ) {
    final $$ItemsListaTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemsLista,
      getReferencedColumn: (t) => t.alimentoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsListaTableAnnotationComposer(
            $db: $db,
            $table: $db.itemsLista,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> recetasRefs<T extends Object>(
    Expression<T> Function($$RecetasTableAnnotationComposer a) f,
  ) {
    final $$RecetasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recetas,
      getReferencedColumn: (t) => t.alimentoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecetasTableAnnotationComposer(
            $db: $db,
            $table: $db.recetas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> ingredientesRecetaRefs<T extends Object>(
    Expression<T> Function($$IngredientesRecetaTableAnnotationComposer a) f,
  ) {
    final $$IngredientesRecetaTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.ingredientesReceta,
          getReferencedColumn: (t) => t.alimentoId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$IngredientesRecetaTableAnnotationComposer(
                $db: $db,
                $table: $db.ingredientesReceta,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> itemsComidaRefs<T extends Object>(
    Expression<T> Function($$ItemsComidaTableAnnotationComposer a) f,
  ) {
    final $$ItemsComidaTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemsComida,
      getReferencedColumn: (t) => t.alimentoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsComidaTableAnnotationComposer(
            $db: $db,
            $table: $db.itemsComida,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AlimentosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlimentosTable,
          AlimentoRow,
          $$AlimentosTableFilterComposer,
          $$AlimentosTableOrderingComposer,
          $$AlimentosTableAnnotationComposer,
          $$AlimentosTableCreateCompanionBuilder,
          $$AlimentosTableUpdateCompanionBuilder,
          (AlimentoRow, $$AlimentosTableReferences),
          AlimentoRow,
          PrefetchHooks Function({
            bool categoriaId,
            bool porcionesRefs,
            bool presentacionesRefs,
            bool itemsListaRefs,
            bool recetasRefs,
            bool ingredientesRecetaRefs,
            bool itemsComidaRefs,
          })
        > {
  $$AlimentosTableTableManager(_$AppDatabase db, $AlimentosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlimentosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlimentosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlimentosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String> marca = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<String> unidad = const Value.absent(),
                Value<int?> categoriaId = const Value.absent(),
                Value<double?> kcal = const Value.absent(),
                Value<double?> proteinas = const Value.absent(),
                Value<double?> grasas = const Value.absent(),
                Value<double?> grasasSaturadas = const Value.absent(),
                Value<double?> carbohidratos = const Value.absent(),
                Value<double?> azucares = const Value.absent(),
                Value<double?> fibra = const Value.absent(),
                Value<double?> sal = const Value.absent(),
                Value<String?> nutricionOrigen = const Value.absent(),
                Value<String?> notas = const Value.absent(),
                Value<int> usoCount = const Value.absent(),
                Value<String?> ultimoUso = const Value.absent(),
                Value<bool> archivado = const Value.absent(),
                Value<String> creado = const Value.absent(),
                Value<String> actualizado = const Value.absent(),
              }) => AlimentosCompanion(
                id: id,
                uuid: uuid,
                nombre: nombre,
                marca: marca,
                tipo: tipo,
                unidad: unidad,
                categoriaId: categoriaId,
                kcal: kcal,
                proteinas: proteinas,
                grasas: grasas,
                grasasSaturadas: grasasSaturadas,
                carbohidratos: carbohidratos,
                azucares: azucares,
                fibra: fibra,
                sal: sal,
                nutricionOrigen: nutricionOrigen,
                notas: notas,
                usoCount: usoCount,
                ultimoUso: ultimoUso,
                archivado: archivado,
                creado: creado,
                actualizado: actualizado,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required String nombre,
                Value<String> marca = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<String> unidad = const Value.absent(),
                Value<int?> categoriaId = const Value.absent(),
                Value<double?> kcal = const Value.absent(),
                Value<double?> proteinas = const Value.absent(),
                Value<double?> grasas = const Value.absent(),
                Value<double?> grasasSaturadas = const Value.absent(),
                Value<double?> carbohidratos = const Value.absent(),
                Value<double?> azucares = const Value.absent(),
                Value<double?> fibra = const Value.absent(),
                Value<double?> sal = const Value.absent(),
                Value<String?> nutricionOrigen = const Value.absent(),
                Value<String?> notas = const Value.absent(),
                Value<int> usoCount = const Value.absent(),
                Value<String?> ultimoUso = const Value.absent(),
                Value<bool> archivado = const Value.absent(),
                required String creado,
                required String actualizado,
              }) => AlimentosCompanion.insert(
                id: id,
                uuid: uuid,
                nombre: nombre,
                marca: marca,
                tipo: tipo,
                unidad: unidad,
                categoriaId: categoriaId,
                kcal: kcal,
                proteinas: proteinas,
                grasas: grasas,
                grasasSaturadas: grasasSaturadas,
                carbohidratos: carbohidratos,
                azucares: azucares,
                fibra: fibra,
                sal: sal,
                nutricionOrigen: nutricionOrigen,
                notas: notas,
                usoCount: usoCount,
                ultimoUso: ultimoUso,
                archivado: archivado,
                creado: creado,
                actualizado: actualizado,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AlimentosTable, AlimentoRow>(table),
                  $$AlimentosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                categoriaId = false,
                porcionesRefs = false,
                presentacionesRefs = false,
                itemsListaRefs = false,
                recetasRefs = false,
                ingredientesRecetaRefs = false,
                itemsComidaRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (porcionesRefs) db.porciones,
                    if (presentacionesRefs) db.presentaciones,
                    if (itemsListaRefs) db.itemsLista,
                    if (recetasRefs) db.recetas,
                    if (ingredientesRecetaRefs) db.ingredientesReceta,
                    if (itemsComidaRefs) db.itemsComida,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (categoriaId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.categoriaId,
                                    referencedTable: $$AlimentosTableReferences
                                        ._categoriaIdTable(db),
                                    referencedColumn: $$AlimentosTableReferences
                                        ._categoriaIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (porcionesRefs)
                        await $_getPrefetchedDataByColumns<
                          AlimentoRow,
                          $AlimentosTable,
                          PorcionRow,
                          $PorcionesTable
                        >(
                          currentTable: table,
                          referencedTable: $$AlimentosTableReferences
                              ._porcionesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AlimentosTableReferences(
                                db,
                                table,
                                p0,
                              ).porcionesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'alimento_id',
                          typedResults: items,
                        ),
                      if (presentacionesRefs)
                        await $_getPrefetchedDataByColumns<
                          AlimentoRow,
                          $AlimentosTable,
                          PresentacionRow,
                          $PresentacionesTable
                        >(
                          currentTable: table,
                          referencedTable: $$AlimentosTableReferences
                              ._presentacionesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AlimentosTableReferences(
                                db,
                                table,
                                p0,
                              ).presentacionesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'alimento_id',
                          typedResults: items,
                        ),
                      if (itemsListaRefs)
                        await $_getPrefetchedDataByColumns<
                          AlimentoRow,
                          $AlimentosTable,
                          ItemListaRow,
                          $ItemsListaTable
                        >(
                          currentTable: table,
                          referencedTable: $$AlimentosTableReferences
                              ._itemsListaRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AlimentosTableReferences(
                                db,
                                table,
                                p0,
                              ).itemsListaRefs,
                          currentColumn: 'id',
                          referencedColumn: 'alimento_id',
                          typedResults: items,
                        ),
                      if (recetasRefs)
                        await $_getPrefetchedDataByColumns<
                          AlimentoRow,
                          $AlimentosTable,
                          RecetaRow,
                          $RecetasTable
                        >(
                          currentTable: table,
                          referencedTable: $$AlimentosTableReferences
                              ._recetasRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AlimentosTableReferences(
                                db,
                                table,
                                p0,
                              ).recetasRefs,
                          currentColumn: 'id',
                          referencedColumn: 'alimento_id',
                          typedResults: items,
                        ),
                      if (ingredientesRecetaRefs)
                        await $_getPrefetchedDataByColumns<
                          AlimentoRow,
                          $AlimentosTable,
                          IngredienteRecetaRow,
                          $IngredientesRecetaTable
                        >(
                          currentTable: table,
                          referencedTable: $$AlimentosTableReferences
                              ._ingredientesRecetaRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AlimentosTableReferences(
                                db,
                                table,
                                p0,
                              ).ingredientesRecetaRefs,
                          currentColumn: 'id',
                          referencedColumn: 'alimento_id',
                          typedResults: items,
                        ),
                      if (itemsComidaRefs)
                        await $_getPrefetchedDataByColumns<
                          AlimentoRow,
                          $AlimentosTable,
                          ItemComidaRow,
                          $ItemsComidaTable
                        >(
                          currentTable: table,
                          referencedTable: $$AlimentosTableReferences
                              ._itemsComidaRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AlimentosTableReferences(
                                db,
                                table,
                                p0,
                              ).itemsComidaRefs,
                          currentColumn: 'id',
                          referencedColumn: 'alimento_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AlimentosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlimentosTable,
      AlimentoRow,
      $$AlimentosTableFilterComposer,
      $$AlimentosTableOrderingComposer,
      $$AlimentosTableAnnotationComposer,
      $$AlimentosTableCreateCompanionBuilder,
      $$AlimentosTableUpdateCompanionBuilder,
      (AlimentoRow, $$AlimentosTableReferences),
      AlimentoRow,
      PrefetchHooks Function({
        bool categoriaId,
        bool porcionesRefs,
        bool presentacionesRefs,
        bool itemsListaRefs,
        bool recetasRefs,
        bool ingredientesRecetaRefs,
        bool itemsComidaRefs,
      })
    >;
typedef $$PorcionesTableCreateCompanionBuilder =
    PorcionesCompanion Function({
      Value<int> id,
      required int alimentoId,
      required String nombre,
      required double gramos,
    });
typedef $$PorcionesTableUpdateCompanionBuilder =
    PorcionesCompanion Function({
      Value<int> id,
      Value<int> alimentoId,
      Value<String> nombre,
      Value<double> gramos,
    });

final class $$PorcionesTableReferences
    extends BaseReferences<_$AppDatabase, $PorcionesTable, PorcionRow> {
  $$PorcionesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AlimentosTable _alimentoIdTable(_$AppDatabase db) =>
      db.alimentos.createAlias('porciones__alimento_id__alimentos__id');

  $$AlimentosTableProcessedTableManager get alimentoId {
    final $_column = $_itemColumn<int>('alimento_id')!;

    final manager = $$AlimentosTableTableManager(
      $_db,
      $_db.alimentos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_alimentoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PorcionesTableFilterComposer
    extends Composer<_$AppDatabase, $PorcionesTable> {
  $$PorcionesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get gramos => $composableBuilder(
    column: $table.gramos,
    builder: (column) => ColumnFilters(column),
  );

  $$AlimentosTableFilterComposer get alimentoId {
    final $$AlimentosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.alimentoId,
      referencedTable: $db.alimentos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlimentosTableFilterComposer(
            $db: $db,
            $table: $db.alimentos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PorcionesTableOrderingComposer
    extends Composer<_$AppDatabase, $PorcionesTable> {
  $$PorcionesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get gramos => $composableBuilder(
    column: $table.gramos,
    builder: (column) => ColumnOrderings(column),
  );

  $$AlimentosTableOrderingComposer get alimentoId {
    final $$AlimentosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.alimentoId,
      referencedTable: $db.alimentos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlimentosTableOrderingComposer(
            $db: $db,
            $table: $db.alimentos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PorcionesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PorcionesTable> {
  $$PorcionesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<double> get gramos =>
      $composableBuilder(column: $table.gramos, builder: (column) => column);

  $$AlimentosTableAnnotationComposer get alimentoId {
    final $$AlimentosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.alimentoId,
      referencedTable: $db.alimentos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlimentosTableAnnotationComposer(
            $db: $db,
            $table: $db.alimentos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PorcionesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PorcionesTable,
          PorcionRow,
          $$PorcionesTableFilterComposer,
          $$PorcionesTableOrderingComposer,
          $$PorcionesTableAnnotationComposer,
          $$PorcionesTableCreateCompanionBuilder,
          $$PorcionesTableUpdateCompanionBuilder,
          (PorcionRow, $$PorcionesTableReferences),
          PorcionRow,
          PrefetchHooks Function({bool alimentoId})
        > {
  $$PorcionesTableTableManager(_$AppDatabase db, $PorcionesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PorcionesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PorcionesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PorcionesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> alimentoId = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<double> gramos = const Value.absent(),
              }) => PorcionesCompanion(
                id: id,
                alimentoId: alimentoId,
                nombre: nombre,
                gramos: gramos,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int alimentoId,
                required String nombre,
                required double gramos,
              }) => PorcionesCompanion.insert(
                id: id,
                alimentoId: alimentoId,
                nombre: nombre,
                gramos: gramos,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PorcionesTable, PorcionRow>(table),
                  $$PorcionesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({alimentoId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (alimentoId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.alimentoId,
                                referencedTable: $$PorcionesTableReferences
                                    ._alimentoIdTable(db),
                                referencedColumn: $$PorcionesTableReferences
                                    ._alimentoIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PorcionesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PorcionesTable,
      PorcionRow,
      $$PorcionesTableFilterComposer,
      $$PorcionesTableOrderingComposer,
      $$PorcionesTableAnnotationComposer,
      $$PorcionesTableCreateCompanionBuilder,
      $$PorcionesTableUpdateCompanionBuilder,
      (PorcionRow, $$PorcionesTableReferences),
      PorcionRow,
      PrefetchHooks Function({bool alimentoId})
    >;
typedef $$PresentacionesTableCreateCompanionBuilder =
    PresentacionesCompanion Function({
      Value<int> id,
      required String uuid,
      required int alimentoId,
      Value<String?> codigoBarras,
      Value<String> descripcion,
      Value<double?> contenido,
      Value<bool> archivado,
      required String creado,
      required String actualizado,
    });
typedef $$PresentacionesTableUpdateCompanionBuilder =
    PresentacionesCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<int> alimentoId,
      Value<String?> codigoBarras,
      Value<String> descripcion,
      Value<double?> contenido,
      Value<bool> archivado,
      Value<String> creado,
      Value<String> actualizado,
    });

final class $$PresentacionesTableReferences
    extends
        BaseReferences<_$AppDatabase, $PresentacionesTable, PresentacionRow> {
  $$PresentacionesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AlimentosTable _alimentoIdTable(_$AppDatabase db) =>
      db.alimentos.createAlias('presentaciones__alimento_id__alimentos__id');

  $$AlimentosTableProcessedTableManager get alimentoId {
    final $_column = $_itemColumn<int>('alimento_id')!;

    final manager = $$AlimentosTableTableManager(
      $_db,
      $_db.alimentos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_alimentoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$CodigosBasculaTable, List<CodigoBasculaRow>>
  _codigosBasculaRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.codigosBascula,
    aliasName: 'presentaciones__id__codigos_bascula__presentacion_id',
  );

  $$CodigosBasculaTableProcessedTableManager get codigosBasculaRefs {
    final manager = $$CodigosBasculaTableTableManager(
      $_db,
      $_db.codigosBascula,
    ).filter((f) => f.presentacionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_codigosBasculaRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ComprasTable, List<CompraRow>> _comprasRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.compras,
    aliasName: 'presentaciones__id__compras__presentacion_id',
  );

  $$ComprasTableProcessedTableManager get comprasRefs {
    final manager = $$ComprasTableTableManager(
      $_db,
      $_db.compras,
    ).filter((f) => f.presentacionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_comprasRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PresentacionesTableFilterComposer
    extends Composer<_$AppDatabase, $PresentacionesTable> {
  $$PresentacionesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codigoBarras => $composableBuilder(
    column: $table.codigoBarras,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get contenido => $composableBuilder(
    column: $table.contenido,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archivado => $composableBuilder(
    column: $table.archivado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creado => $composableBuilder(
    column: $table.creado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actualizado => $composableBuilder(
    column: $table.actualizado,
    builder: (column) => ColumnFilters(column),
  );

  $$AlimentosTableFilterComposer get alimentoId {
    final $$AlimentosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.alimentoId,
      referencedTable: $db.alimentos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlimentosTableFilterComposer(
            $db: $db,
            $table: $db.alimentos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> codigosBasculaRefs(
    Expression<bool> Function($$CodigosBasculaTableFilterComposer f) f,
  ) {
    final $$CodigosBasculaTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.codigosBascula,
      getReferencedColumn: (t) => t.presentacionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CodigosBasculaTableFilterComposer(
            $db: $db,
            $table: $db.codigosBascula,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> comprasRefs(
    Expression<bool> Function($$ComprasTableFilterComposer f) f,
  ) {
    final $$ComprasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.compras,
      getReferencedColumn: (t) => t.presentacionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ComprasTableFilterComposer(
            $db: $db,
            $table: $db.compras,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PresentacionesTableOrderingComposer
    extends Composer<_$AppDatabase, $PresentacionesTable> {
  $$PresentacionesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codigoBarras => $composableBuilder(
    column: $table.codigoBarras,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get contenido => $composableBuilder(
    column: $table.contenido,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archivado => $composableBuilder(
    column: $table.archivado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creado => $composableBuilder(
    column: $table.creado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actualizado => $composableBuilder(
    column: $table.actualizado,
    builder: (column) => ColumnOrderings(column),
  );

  $$AlimentosTableOrderingComposer get alimentoId {
    final $$AlimentosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.alimentoId,
      referencedTable: $db.alimentos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlimentosTableOrderingComposer(
            $db: $db,
            $table: $db.alimentos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PresentacionesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PresentacionesTable> {
  $$PresentacionesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get codigoBarras => $composableBuilder(
    column: $table.codigoBarras,
    builder: (column) => column,
  );

  GeneratedColumn<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => column,
  );

  GeneratedColumn<double> get contenido =>
      $composableBuilder(column: $table.contenido, builder: (column) => column);

  GeneratedColumn<bool> get archivado =>
      $composableBuilder(column: $table.archivado, builder: (column) => column);

  GeneratedColumn<String> get creado =>
      $composableBuilder(column: $table.creado, builder: (column) => column);

  GeneratedColumn<String> get actualizado => $composableBuilder(
    column: $table.actualizado,
    builder: (column) => column,
  );

  $$AlimentosTableAnnotationComposer get alimentoId {
    final $$AlimentosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.alimentoId,
      referencedTable: $db.alimentos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlimentosTableAnnotationComposer(
            $db: $db,
            $table: $db.alimentos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> codigosBasculaRefs<T extends Object>(
    Expression<T> Function($$CodigosBasculaTableAnnotationComposer a) f,
  ) {
    final $$CodigosBasculaTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.codigosBascula,
      getReferencedColumn: (t) => t.presentacionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CodigosBasculaTableAnnotationComposer(
            $db: $db,
            $table: $db.codigosBascula,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> comprasRefs<T extends Object>(
    Expression<T> Function($$ComprasTableAnnotationComposer a) f,
  ) {
    final $$ComprasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.compras,
      getReferencedColumn: (t) => t.presentacionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ComprasTableAnnotationComposer(
            $db: $db,
            $table: $db.compras,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PresentacionesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PresentacionesTable,
          PresentacionRow,
          $$PresentacionesTableFilterComposer,
          $$PresentacionesTableOrderingComposer,
          $$PresentacionesTableAnnotationComposer,
          $$PresentacionesTableCreateCompanionBuilder,
          $$PresentacionesTableUpdateCompanionBuilder,
          (PresentacionRow, $$PresentacionesTableReferences),
          PresentacionRow,
          PrefetchHooks Function({
            bool alimentoId,
            bool codigosBasculaRefs,
            bool comprasRefs,
          })
        > {
  $$PresentacionesTableTableManager(
    _$AppDatabase db,
    $PresentacionesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PresentacionesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PresentacionesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PresentacionesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> alimentoId = const Value.absent(),
                Value<String?> codigoBarras = const Value.absent(),
                Value<String> descripcion = const Value.absent(),
                Value<double?> contenido = const Value.absent(),
                Value<bool> archivado = const Value.absent(),
                Value<String> creado = const Value.absent(),
                Value<String> actualizado = const Value.absent(),
              }) => PresentacionesCompanion(
                id: id,
                uuid: uuid,
                alimentoId: alimentoId,
                codigoBarras: codigoBarras,
                descripcion: descripcion,
                contenido: contenido,
                archivado: archivado,
                creado: creado,
                actualizado: actualizado,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required int alimentoId,
                Value<String?> codigoBarras = const Value.absent(),
                Value<String> descripcion = const Value.absent(),
                Value<double?> contenido = const Value.absent(),
                Value<bool> archivado = const Value.absent(),
                required String creado,
                required String actualizado,
              }) => PresentacionesCompanion.insert(
                id: id,
                uuid: uuid,
                alimentoId: alimentoId,
                codigoBarras: codigoBarras,
                descripcion: descripcion,
                contenido: contenido,
                archivado: archivado,
                creado: creado,
                actualizado: actualizado,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PresentacionesTable, PresentacionRow>(table),
                  $$PresentacionesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                alimentoId = false,
                codigosBasculaRefs = false,
                comprasRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (codigosBasculaRefs) db.codigosBascula,
                    if (comprasRefs) db.compras,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (alimentoId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.alimentoId,
                                    referencedTable:
                                        $$PresentacionesTableReferences
                                            ._alimentoIdTable(db),
                                    referencedColumn:
                                        $$PresentacionesTableReferences
                                            ._alimentoIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (codigosBasculaRefs)
                        await $_getPrefetchedDataByColumns<
                          PresentacionRow,
                          $PresentacionesTable,
                          CodigoBasculaRow,
                          $CodigosBasculaTable
                        >(
                          currentTable: table,
                          referencedTable: $$PresentacionesTableReferences
                              ._codigosBasculaRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PresentacionesTableReferences(
                                db,
                                table,
                                p0,
                              ).codigosBasculaRefs,
                          currentColumn: 'id',
                          referencedColumn: 'presentacion_id',
                          typedResults: items,
                        ),
                      if (comprasRefs)
                        await $_getPrefetchedDataByColumns<
                          PresentacionRow,
                          $PresentacionesTable,
                          CompraRow,
                          $ComprasTable
                        >(
                          currentTable: table,
                          referencedTable: $$PresentacionesTableReferences
                              ._comprasRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PresentacionesTableReferences(
                                db,
                                table,
                                p0,
                              ).comprasRefs,
                          currentColumn: 'id',
                          referencedColumn: 'presentacion_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PresentacionesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PresentacionesTable,
      PresentacionRow,
      $$PresentacionesTableFilterComposer,
      $$PresentacionesTableOrderingComposer,
      $$PresentacionesTableAnnotationComposer,
      $$PresentacionesTableCreateCompanionBuilder,
      $$PresentacionesTableUpdateCompanionBuilder,
      (PresentacionRow, $$PresentacionesTableReferences),
      PresentacionRow,
      PrefetchHooks Function({
        bool alimentoId,
        bool codigosBasculaRefs,
        bool comprasRefs,
      })
    >;
typedef $$EstablecimientosTableCreateCompanionBuilder =
    EstablecimientosCompanion Function({
      Value<int> id,
      required String nombre,
      Value<String?> formatoBascula,
      Value<int> longitudClave,
    });
typedef $$EstablecimientosTableUpdateCompanionBuilder =
    EstablecimientosCompanion Function({
      Value<int> id,
      Value<String> nombre,
      Value<String?> formatoBascula,
      Value<int> longitudClave,
    });

final class $$EstablecimientosTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $EstablecimientosTable,
          EstablecimientoRow
        > {
  $$EstablecimientosTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$OrdenPasillosTable, List<OrdenPasilloRow>>
  _ordenPasillosRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ordenPasillos,
    aliasName: 'establecimientos__id__orden_pasillos__establecimiento_id',
  );

  $$OrdenPasillosTableProcessedTableManager get ordenPasillosRefs {
    final manager = $$OrdenPasillosTableTableManager(
      $_db,
      $_db.ordenPasillos,
    ).filter((f) => f.establecimientoId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_ordenPasillosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CodigosBasculaTable, List<CodigoBasculaRow>>
  _codigosBasculaRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.codigosBascula,
    aliasName: 'establecimientos__id__codigos_bascula__establecimiento_id',
  );

  $$CodigosBasculaTableProcessedTableManager get codigosBasculaRefs {
    final manager = $$CodigosBasculaTableTableManager(
      $_db,
      $_db.codigosBascula,
    ).filter((f) => f.establecimientoId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_codigosBasculaRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ComprasTable, List<CompraRow>> _comprasRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.compras,
    aliasName: 'establecimientos__id__compras__establecimiento_id',
  );

  $$ComprasTableProcessedTableManager get comprasRefs {
    final manager = $$ComprasTableTableManager(
      $_db,
      $_db.compras,
    ).filter((f) => f.establecimientoId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_comprasRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EstablecimientosTableFilterComposer
    extends Composer<_$AppDatabase, $EstablecimientosTable> {
  $$EstablecimientosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get formatoBascula => $composableBuilder(
    column: $table.formatoBascula,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get longitudClave => $composableBuilder(
    column: $table.longitudClave,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> ordenPasillosRefs(
    Expression<bool> Function($$OrdenPasillosTableFilterComposer f) f,
  ) {
    final $$OrdenPasillosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ordenPasillos,
      getReferencedColumn: (t) => t.establecimientoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdenPasillosTableFilterComposer(
            $db: $db,
            $table: $db.ordenPasillos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> codigosBasculaRefs(
    Expression<bool> Function($$CodigosBasculaTableFilterComposer f) f,
  ) {
    final $$CodigosBasculaTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.codigosBascula,
      getReferencedColumn: (t) => t.establecimientoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CodigosBasculaTableFilterComposer(
            $db: $db,
            $table: $db.codigosBascula,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> comprasRefs(
    Expression<bool> Function($$ComprasTableFilterComposer f) f,
  ) {
    final $$ComprasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.compras,
      getReferencedColumn: (t) => t.establecimientoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ComprasTableFilterComposer(
            $db: $db,
            $table: $db.compras,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EstablecimientosTableOrderingComposer
    extends Composer<_$AppDatabase, $EstablecimientosTable> {
  $$EstablecimientosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get formatoBascula => $composableBuilder(
    column: $table.formatoBascula,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get longitudClave => $composableBuilder(
    column: $table.longitudClave,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EstablecimientosTableAnnotationComposer
    extends Composer<_$AppDatabase, $EstablecimientosTable> {
  $$EstablecimientosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get formatoBascula => $composableBuilder(
    column: $table.formatoBascula,
    builder: (column) => column,
  );

  GeneratedColumn<int> get longitudClave => $composableBuilder(
    column: $table.longitudClave,
    builder: (column) => column,
  );

  Expression<T> ordenPasillosRefs<T extends Object>(
    Expression<T> Function($$OrdenPasillosTableAnnotationComposer a) f,
  ) {
    final $$OrdenPasillosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ordenPasillos,
      getReferencedColumn: (t) => t.establecimientoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdenPasillosTableAnnotationComposer(
            $db: $db,
            $table: $db.ordenPasillos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> codigosBasculaRefs<T extends Object>(
    Expression<T> Function($$CodigosBasculaTableAnnotationComposer a) f,
  ) {
    final $$CodigosBasculaTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.codigosBascula,
      getReferencedColumn: (t) => t.establecimientoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CodigosBasculaTableAnnotationComposer(
            $db: $db,
            $table: $db.codigosBascula,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> comprasRefs<T extends Object>(
    Expression<T> Function($$ComprasTableAnnotationComposer a) f,
  ) {
    final $$ComprasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.compras,
      getReferencedColumn: (t) => t.establecimientoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ComprasTableAnnotationComposer(
            $db: $db,
            $table: $db.compras,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EstablecimientosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EstablecimientosTable,
          EstablecimientoRow,
          $$EstablecimientosTableFilterComposer,
          $$EstablecimientosTableOrderingComposer,
          $$EstablecimientosTableAnnotationComposer,
          $$EstablecimientosTableCreateCompanionBuilder,
          $$EstablecimientosTableUpdateCompanionBuilder,
          (EstablecimientoRow, $$EstablecimientosTableReferences),
          EstablecimientoRow,
          PrefetchHooks Function({
            bool ordenPasillosRefs,
            bool codigosBasculaRefs,
            bool comprasRefs,
          })
        > {
  $$EstablecimientosTableTableManager(
    _$AppDatabase db,
    $EstablecimientosTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EstablecimientosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EstablecimientosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EstablecimientosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String?> formatoBascula = const Value.absent(),
                Value<int> longitudClave = const Value.absent(),
              }) => EstablecimientosCompanion(
                id: id,
                nombre: nombre,
                formatoBascula: formatoBascula,
                longitudClave: longitudClave,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String nombre,
                Value<String?> formatoBascula = const Value.absent(),
                Value<int> longitudClave = const Value.absent(),
              }) => EstablecimientosCompanion.insert(
                id: id,
                nombre: nombre,
                formatoBascula: formatoBascula,
                longitudClave: longitudClave,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EstablecimientosTable, EstablecimientoRow>(
                    table,
                  ),
                  $$EstablecimientosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                ordenPasillosRefs = false,
                codigosBasculaRefs = false,
                comprasRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (ordenPasillosRefs) db.ordenPasillos,
                    if (codigosBasculaRefs) db.codigosBascula,
                    if (comprasRefs) db.compras,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (ordenPasillosRefs)
                        await $_getPrefetchedDataByColumns<
                          EstablecimientoRow,
                          $EstablecimientosTable,
                          OrdenPasilloRow,
                          $OrdenPasillosTable
                        >(
                          currentTable: table,
                          referencedTable: $$EstablecimientosTableReferences
                              ._ordenPasillosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EstablecimientosTableReferences(
                                db,
                                table,
                                p0,
                              ).ordenPasillosRefs,
                          currentColumn: 'id',
                          referencedColumn: 'establecimiento_id',
                          typedResults: items,
                        ),
                      if (codigosBasculaRefs)
                        await $_getPrefetchedDataByColumns<
                          EstablecimientoRow,
                          $EstablecimientosTable,
                          CodigoBasculaRow,
                          $CodigosBasculaTable
                        >(
                          currentTable: table,
                          referencedTable: $$EstablecimientosTableReferences
                              ._codigosBasculaRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EstablecimientosTableReferences(
                                db,
                                table,
                                p0,
                              ).codigosBasculaRefs,
                          currentColumn: 'id',
                          referencedColumn: 'establecimiento_id',
                          typedResults: items,
                        ),
                      if (comprasRefs)
                        await $_getPrefetchedDataByColumns<
                          EstablecimientoRow,
                          $EstablecimientosTable,
                          CompraRow,
                          $ComprasTable
                        >(
                          currentTable: table,
                          referencedTable: $$EstablecimientosTableReferences
                              ._comprasRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EstablecimientosTableReferences(
                                db,
                                table,
                                p0,
                              ).comprasRefs,
                          currentColumn: 'id',
                          referencedColumn: 'establecimiento_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$EstablecimientosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EstablecimientosTable,
      EstablecimientoRow,
      $$EstablecimientosTableFilterComposer,
      $$EstablecimientosTableOrderingComposer,
      $$EstablecimientosTableAnnotationComposer,
      $$EstablecimientosTableCreateCompanionBuilder,
      $$EstablecimientosTableUpdateCompanionBuilder,
      (EstablecimientoRow, $$EstablecimientosTableReferences),
      EstablecimientoRow,
      PrefetchHooks Function({
        bool ordenPasillosRefs,
        bool codigosBasculaRefs,
        bool comprasRefs,
      })
    >;
typedef $$OrdenPasillosTableCreateCompanionBuilder =
    OrdenPasillosCompanion Function({
      required int establecimientoId,
      required int categoriaId,
      required int orden,
      Value<int> rowid,
    });
typedef $$OrdenPasillosTableUpdateCompanionBuilder =
    OrdenPasillosCompanion Function({
      Value<int> establecimientoId,
      Value<int> categoriaId,
      Value<int> orden,
      Value<int> rowid,
    });

final class $$OrdenPasillosTableReferences
    extends
        BaseReferences<_$AppDatabase, $OrdenPasillosTable, OrdenPasilloRow> {
  $$OrdenPasillosTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $EstablecimientosTable _establecimientoIdTable(_$AppDatabase db) => db
      .establecimientos
      .createAlias('orden_pasillos__establecimiento_id__establecimientos__id');

  $$EstablecimientosTableProcessedTableManager get establecimientoId {
    final $_column = $_itemColumn<int>('establecimiento_id')!;

    final manager = $$EstablecimientosTableTableManager(
      $_db,
      $_db.establecimientos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_establecimientoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CategoriasTable _categoriaIdTable(_$AppDatabase db) =>
      db.categorias.createAlias('orden_pasillos__categoria_id__categorias__id');

  $$CategoriasTableProcessedTableManager get categoriaId {
    final $_column = $_itemColumn<int>('categoria_id')!;

    final manager = $$CategoriasTableTableManager(
      $_db,
      $_db.categorias,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoriaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$OrdenPasillosTableFilterComposer
    extends Composer<_$AppDatabase, $OrdenPasillosTable> {
  $$OrdenPasillosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get orden => $composableBuilder(
    column: $table.orden,
    builder: (column) => ColumnFilters(column),
  );

  $$EstablecimientosTableFilterComposer get establecimientoId {
    final $$EstablecimientosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.establecimientoId,
      referencedTable: $db.establecimientos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EstablecimientosTableFilterComposer(
            $db: $db,
            $table: $db.establecimientos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriasTableFilterComposer get categoriaId {
    final $$CategoriasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoriaId,
      referencedTable: $db.categorias,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriasTableFilterComposer(
            $db: $db,
            $table: $db.categorias,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OrdenPasillosTableOrderingComposer
    extends Composer<_$AppDatabase, $OrdenPasillosTable> {
  $$OrdenPasillosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get orden => $composableBuilder(
    column: $table.orden,
    builder: (column) => ColumnOrderings(column),
  );

  $$EstablecimientosTableOrderingComposer get establecimientoId {
    final $$EstablecimientosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.establecimientoId,
      referencedTable: $db.establecimientos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EstablecimientosTableOrderingComposer(
            $db: $db,
            $table: $db.establecimientos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriasTableOrderingComposer get categoriaId {
    final $$CategoriasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoriaId,
      referencedTable: $db.categorias,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriasTableOrderingComposer(
            $db: $db,
            $table: $db.categorias,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OrdenPasillosTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrdenPasillosTable> {
  $$OrdenPasillosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get orden =>
      $composableBuilder(column: $table.orden, builder: (column) => column);

  $$EstablecimientosTableAnnotationComposer get establecimientoId {
    final $$EstablecimientosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.establecimientoId,
      referencedTable: $db.establecimientos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EstablecimientosTableAnnotationComposer(
            $db: $db,
            $table: $db.establecimientos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriasTableAnnotationComposer get categoriaId {
    final $$CategoriasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoriaId,
      referencedTable: $db.categorias,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriasTableAnnotationComposer(
            $db: $db,
            $table: $db.categorias,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OrdenPasillosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OrdenPasillosTable,
          OrdenPasilloRow,
          $$OrdenPasillosTableFilterComposer,
          $$OrdenPasillosTableOrderingComposer,
          $$OrdenPasillosTableAnnotationComposer,
          $$OrdenPasillosTableCreateCompanionBuilder,
          $$OrdenPasillosTableUpdateCompanionBuilder,
          (OrdenPasilloRow, $$OrdenPasillosTableReferences),
          OrdenPasilloRow,
          PrefetchHooks Function({bool establecimientoId, bool categoriaId})
        > {
  $$OrdenPasillosTableTableManager(_$AppDatabase db, $OrdenPasillosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrdenPasillosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrdenPasillosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrdenPasillosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> establecimientoId = const Value.absent(),
                Value<int> categoriaId = const Value.absent(),
                Value<int> orden = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrdenPasillosCompanion(
                establecimientoId: establecimientoId,
                categoriaId: categoriaId,
                orden: orden,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int establecimientoId,
                required int categoriaId,
                required int orden,
                Value<int> rowid = const Value.absent(),
              }) => OrdenPasillosCompanion.insert(
                establecimientoId: establecimientoId,
                categoriaId: categoriaId,
                orden: orden,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OrdenPasillosTable, OrdenPasilloRow>(table),
                  $$OrdenPasillosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({establecimientoId = false, categoriaId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (establecimientoId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.establecimientoId,
                                    referencedTable:
                                        $$OrdenPasillosTableReferences
                                            ._establecimientoIdTable(db),
                                    referencedColumn:
                                        $$OrdenPasillosTableReferences
                                            ._establecimientoIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (categoriaId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.categoriaId,
                                    referencedTable:
                                        $$OrdenPasillosTableReferences
                                            ._categoriaIdTable(db),
                                    referencedColumn:
                                        $$OrdenPasillosTableReferences
                                            ._categoriaIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$OrdenPasillosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OrdenPasillosTable,
      OrdenPasilloRow,
      $$OrdenPasillosTableFilterComposer,
      $$OrdenPasillosTableOrderingComposer,
      $$OrdenPasillosTableAnnotationComposer,
      $$OrdenPasillosTableCreateCompanionBuilder,
      $$OrdenPasillosTableUpdateCompanionBuilder,
      (OrdenPasilloRow, $$OrdenPasillosTableReferences),
      OrdenPasilloRow,
      PrefetchHooks Function({bool establecimientoId, bool categoriaId})
    >;
typedef $$CodigosBasculaTableCreateCompanionBuilder =
    CodigosBasculaCompanion Function({
      Value<int> id,
      required int establecimientoId,
      required String clave,
      required int presentacionId,
    });
typedef $$CodigosBasculaTableUpdateCompanionBuilder =
    CodigosBasculaCompanion Function({
      Value<int> id,
      Value<int> establecimientoId,
      Value<String> clave,
      Value<int> presentacionId,
    });

final class $$CodigosBasculaTableReferences
    extends
        BaseReferences<_$AppDatabase, $CodigosBasculaTable, CodigoBasculaRow> {
  $$CodigosBasculaTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $EstablecimientosTable _establecimientoIdTable(_$AppDatabase db) => db
      .establecimientos
      .createAlias('codigos_bascula__establecimiento_id__establecimientos__id');

  $$EstablecimientosTableProcessedTableManager get establecimientoId {
    final $_column = $_itemColumn<int>('establecimiento_id')!;

    final manager = $$EstablecimientosTableTableManager(
      $_db,
      $_db.establecimientos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_establecimientoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PresentacionesTable _presentacionIdTable(_$AppDatabase db) => db
      .presentaciones
      .createAlias('codigos_bascula__presentacion_id__presentaciones__id');

  $$PresentacionesTableProcessedTableManager get presentacionId {
    final $_column = $_itemColumn<int>('presentacion_id')!;

    final manager = $$PresentacionesTableTableManager(
      $_db,
      $_db.presentaciones,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_presentacionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CodigosBasculaTableFilterComposer
    extends Composer<_$AppDatabase, $CodigosBasculaTable> {
  $$CodigosBasculaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clave => $composableBuilder(
    column: $table.clave,
    builder: (column) => ColumnFilters(column),
  );

  $$EstablecimientosTableFilterComposer get establecimientoId {
    final $$EstablecimientosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.establecimientoId,
      referencedTable: $db.establecimientos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EstablecimientosTableFilterComposer(
            $db: $db,
            $table: $db.establecimientos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PresentacionesTableFilterComposer get presentacionId {
    final $$PresentacionesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.presentacionId,
      referencedTable: $db.presentaciones,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PresentacionesTableFilterComposer(
            $db: $db,
            $table: $db.presentaciones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CodigosBasculaTableOrderingComposer
    extends Composer<_$AppDatabase, $CodigosBasculaTable> {
  $$CodigosBasculaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clave => $composableBuilder(
    column: $table.clave,
    builder: (column) => ColumnOrderings(column),
  );

  $$EstablecimientosTableOrderingComposer get establecimientoId {
    final $$EstablecimientosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.establecimientoId,
      referencedTable: $db.establecimientos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EstablecimientosTableOrderingComposer(
            $db: $db,
            $table: $db.establecimientos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PresentacionesTableOrderingComposer get presentacionId {
    final $$PresentacionesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.presentacionId,
      referencedTable: $db.presentaciones,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PresentacionesTableOrderingComposer(
            $db: $db,
            $table: $db.presentaciones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CodigosBasculaTableAnnotationComposer
    extends Composer<_$AppDatabase, $CodigosBasculaTable> {
  $$CodigosBasculaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clave =>
      $composableBuilder(column: $table.clave, builder: (column) => column);

  $$EstablecimientosTableAnnotationComposer get establecimientoId {
    final $$EstablecimientosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.establecimientoId,
      referencedTable: $db.establecimientos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EstablecimientosTableAnnotationComposer(
            $db: $db,
            $table: $db.establecimientos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PresentacionesTableAnnotationComposer get presentacionId {
    final $$PresentacionesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.presentacionId,
      referencedTable: $db.presentaciones,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PresentacionesTableAnnotationComposer(
            $db: $db,
            $table: $db.presentaciones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CodigosBasculaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CodigosBasculaTable,
          CodigoBasculaRow,
          $$CodigosBasculaTableFilterComposer,
          $$CodigosBasculaTableOrderingComposer,
          $$CodigosBasculaTableAnnotationComposer,
          $$CodigosBasculaTableCreateCompanionBuilder,
          $$CodigosBasculaTableUpdateCompanionBuilder,
          (CodigoBasculaRow, $$CodigosBasculaTableReferences),
          CodigoBasculaRow,
          PrefetchHooks Function({bool establecimientoId, bool presentacionId})
        > {
  $$CodigosBasculaTableTableManager(
    _$AppDatabase db,
    $CodigosBasculaTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CodigosBasculaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CodigosBasculaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CodigosBasculaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> establecimientoId = const Value.absent(),
                Value<String> clave = const Value.absent(),
                Value<int> presentacionId = const Value.absent(),
              }) => CodigosBasculaCompanion(
                id: id,
                establecimientoId: establecimientoId,
                clave: clave,
                presentacionId: presentacionId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int establecimientoId,
                required String clave,
                required int presentacionId,
              }) => CodigosBasculaCompanion.insert(
                id: id,
                establecimientoId: establecimientoId,
                clave: clave,
                presentacionId: presentacionId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CodigosBasculaTable, CodigoBasculaRow>(table),
                  $$CodigosBasculaTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({establecimientoId = false, presentacionId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (establecimientoId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.establecimientoId,
                                    referencedTable:
                                        $$CodigosBasculaTableReferences
                                            ._establecimientoIdTable(db),
                                    referencedColumn:
                                        $$CodigosBasculaTableReferences
                                            ._establecimientoIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (presentacionId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.presentacionId,
                                    referencedTable:
                                        $$CodigosBasculaTableReferences
                                            ._presentacionIdTable(db),
                                    referencedColumn:
                                        $$CodigosBasculaTableReferences
                                            ._presentacionIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$CodigosBasculaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CodigosBasculaTable,
      CodigoBasculaRow,
      $$CodigosBasculaTableFilterComposer,
      $$CodigosBasculaTableOrderingComposer,
      $$CodigosBasculaTableAnnotationComposer,
      $$CodigosBasculaTableCreateCompanionBuilder,
      $$CodigosBasculaTableUpdateCompanionBuilder,
      (CodigoBasculaRow, $$CodigosBasculaTableReferences),
      CodigoBasculaRow,
      PrefetchHooks Function({bool establecimientoId, bool presentacionId})
    >;
typedef $$ComprasTableCreateCompanionBuilder =
    ComprasCompanion Function({
      Value<int> id,
      required int presentacionId,
      required int establecimientoId,
      required String fecha,
      required int precioCent,
      Value<int> unidades,
      Value<double?> pesoG,
    });
typedef $$ComprasTableUpdateCompanionBuilder =
    ComprasCompanion Function({
      Value<int> id,
      Value<int> presentacionId,
      Value<int> establecimientoId,
      Value<String> fecha,
      Value<int> precioCent,
      Value<int> unidades,
      Value<double?> pesoG,
    });

final class $$ComprasTableReferences
    extends BaseReferences<_$AppDatabase, $ComprasTable, CompraRow> {
  $$ComprasTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PresentacionesTable _presentacionIdTable(_$AppDatabase db) => db
      .presentaciones
      .createAlias('compras__presentacion_id__presentaciones__id');

  $$PresentacionesTableProcessedTableManager get presentacionId {
    final $_column = $_itemColumn<int>('presentacion_id')!;

    final manager = $$PresentacionesTableTableManager(
      $_db,
      $_db.presentaciones,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_presentacionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $EstablecimientosTable _establecimientoIdTable(_$AppDatabase db) => db
      .establecimientos
      .createAlias('compras__establecimiento_id__establecimientos__id');

  $$EstablecimientosTableProcessedTableManager get establecimientoId {
    final $_column = $_itemColumn<int>('establecimiento_id')!;

    final manager = $$EstablecimientosTableTableManager(
      $_db,
      $_db.establecimientos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_establecimientoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ItemsListaTable, List<ItemListaRow>>
  _itemsListaRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.itemsLista,
    aliasName: 'compras__id__items_lista__compra_id',
  );

  $$ItemsListaTableProcessedTableManager get itemsListaRefs {
    final manager = $$ItemsListaTableTableManager(
      $_db,
      $_db.itemsLista,
    ).filter((f) => f.compraId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_itemsListaRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ComprasTableFilterComposer
    extends Composer<_$AppDatabase, $ComprasTable> {
  $$ComprasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get precioCent => $composableBuilder(
    column: $table.precioCent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unidades => $composableBuilder(
    column: $table.unidades,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pesoG => $composableBuilder(
    column: $table.pesoG,
    builder: (column) => ColumnFilters(column),
  );

  $$PresentacionesTableFilterComposer get presentacionId {
    final $$PresentacionesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.presentacionId,
      referencedTable: $db.presentaciones,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PresentacionesTableFilterComposer(
            $db: $db,
            $table: $db.presentaciones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EstablecimientosTableFilterComposer get establecimientoId {
    final $$EstablecimientosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.establecimientoId,
      referencedTable: $db.establecimientos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EstablecimientosTableFilterComposer(
            $db: $db,
            $table: $db.establecimientos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> itemsListaRefs(
    Expression<bool> Function($$ItemsListaTableFilterComposer f) f,
  ) {
    final $$ItemsListaTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemsLista,
      getReferencedColumn: (t) => t.compraId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsListaTableFilterComposer(
            $db: $db,
            $table: $db.itemsLista,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ComprasTableOrderingComposer
    extends Composer<_$AppDatabase, $ComprasTable> {
  $$ComprasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get precioCent => $composableBuilder(
    column: $table.precioCent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unidades => $composableBuilder(
    column: $table.unidades,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pesoG => $composableBuilder(
    column: $table.pesoG,
    builder: (column) => ColumnOrderings(column),
  );

  $$PresentacionesTableOrderingComposer get presentacionId {
    final $$PresentacionesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.presentacionId,
      referencedTable: $db.presentaciones,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PresentacionesTableOrderingComposer(
            $db: $db,
            $table: $db.presentaciones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EstablecimientosTableOrderingComposer get establecimientoId {
    final $$EstablecimientosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.establecimientoId,
      referencedTable: $db.establecimientos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EstablecimientosTableOrderingComposer(
            $db: $db,
            $table: $db.establecimientos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ComprasTableAnnotationComposer
    extends Composer<_$AppDatabase, $ComprasTable> {
  $$ComprasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);

  GeneratedColumn<int> get precioCent => $composableBuilder(
    column: $table.precioCent,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unidades =>
      $composableBuilder(column: $table.unidades, builder: (column) => column);

  GeneratedColumn<double> get pesoG =>
      $composableBuilder(column: $table.pesoG, builder: (column) => column);

  $$PresentacionesTableAnnotationComposer get presentacionId {
    final $$PresentacionesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.presentacionId,
      referencedTable: $db.presentaciones,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PresentacionesTableAnnotationComposer(
            $db: $db,
            $table: $db.presentaciones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EstablecimientosTableAnnotationComposer get establecimientoId {
    final $$EstablecimientosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.establecimientoId,
      referencedTable: $db.establecimientos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EstablecimientosTableAnnotationComposer(
            $db: $db,
            $table: $db.establecimientos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> itemsListaRefs<T extends Object>(
    Expression<T> Function($$ItemsListaTableAnnotationComposer a) f,
  ) {
    final $$ItemsListaTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemsLista,
      getReferencedColumn: (t) => t.compraId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsListaTableAnnotationComposer(
            $db: $db,
            $table: $db.itemsLista,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ComprasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ComprasTable,
          CompraRow,
          $$ComprasTableFilterComposer,
          $$ComprasTableOrderingComposer,
          $$ComprasTableAnnotationComposer,
          $$ComprasTableCreateCompanionBuilder,
          $$ComprasTableUpdateCompanionBuilder,
          (CompraRow, $$ComprasTableReferences),
          CompraRow,
          PrefetchHooks Function({
            bool presentacionId,
            bool establecimientoId,
            bool itemsListaRefs,
          })
        > {
  $$ComprasTableTableManager(_$AppDatabase db, $ComprasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ComprasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ComprasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ComprasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> presentacionId = const Value.absent(),
                Value<int> establecimientoId = const Value.absent(),
                Value<String> fecha = const Value.absent(),
                Value<int> precioCent = const Value.absent(),
                Value<int> unidades = const Value.absent(),
                Value<double?> pesoG = const Value.absent(),
              }) => ComprasCompanion(
                id: id,
                presentacionId: presentacionId,
                establecimientoId: establecimientoId,
                fecha: fecha,
                precioCent: precioCent,
                unidades: unidades,
                pesoG: pesoG,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int presentacionId,
                required int establecimientoId,
                required String fecha,
                required int precioCent,
                Value<int> unidades = const Value.absent(),
                Value<double?> pesoG = const Value.absent(),
              }) => ComprasCompanion.insert(
                id: id,
                presentacionId: presentacionId,
                establecimientoId: establecimientoId,
                fecha: fecha,
                precioCent: precioCent,
                unidades: unidades,
                pesoG: pesoG,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ComprasTable, CompraRow>(table),
                  $$ComprasTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                presentacionId = false,
                establecimientoId = false,
                itemsListaRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (itemsListaRefs) db.itemsLista],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (presentacionId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.presentacionId,
                                    referencedTable: $$ComprasTableReferences
                                        ._presentacionIdTable(db),
                                    referencedColumn: $$ComprasTableReferences
                                        ._presentacionIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (establecimientoId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.establecimientoId,
                                    referencedTable: $$ComprasTableReferences
                                        ._establecimientoIdTable(db),
                                    referencedColumn: $$ComprasTableReferences
                                        ._establecimientoIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (itemsListaRefs)
                        await $_getPrefetchedDataByColumns<
                          CompraRow,
                          $ComprasTable,
                          ItemListaRow,
                          $ItemsListaTable
                        >(
                          currentTable: table,
                          referencedTable: $$ComprasTableReferences
                              ._itemsListaRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ComprasTableReferences(
                                db,
                                table,
                                p0,
                              ).itemsListaRefs,
                          currentColumn: 'id',
                          referencedColumn: 'compra_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ComprasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ComprasTable,
      CompraRow,
      $$ComprasTableFilterComposer,
      $$ComprasTableOrderingComposer,
      $$ComprasTableAnnotationComposer,
      $$ComprasTableCreateCompanionBuilder,
      $$ComprasTableUpdateCompanionBuilder,
      (CompraRow, $$ComprasTableReferences),
      CompraRow,
      PrefetchHooks Function({
        bool presentacionId,
        bool establecimientoId,
        bool itemsListaRefs,
      })
    >;
typedef $$ListasCompraTableCreateCompanionBuilder =
    ListasCompraCompanion Function({
      Value<int> id,
      required String nombre,
      required String creada,
    });
typedef $$ListasCompraTableUpdateCompanionBuilder =
    ListasCompraCompanion Function({
      Value<int> id,
      Value<String> nombre,
      Value<String> creada,
    });

final class $$ListasCompraTableReferences
    extends BaseReferences<_$AppDatabase, $ListasCompraTable, ListaCompraRow> {
  $$ListasCompraTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ItemsListaTable, List<ItemListaRow>>
  _itemsListaRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.itemsLista,
    aliasName: 'listas_compra__id__items_lista__lista_id',
  );

  $$ItemsListaTableProcessedTableManager get itemsListaRefs {
    final manager = $$ItemsListaTableTableManager(
      $_db,
      $_db.itemsLista,
    ).filter((f) => f.listaId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_itemsListaRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ListasCompraTableFilterComposer
    extends Composer<_$AppDatabase, $ListasCompraTable> {
  $$ListasCompraTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creada => $composableBuilder(
    column: $table.creada,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> itemsListaRefs(
    Expression<bool> Function($$ItemsListaTableFilterComposer f) f,
  ) {
    final $$ItemsListaTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemsLista,
      getReferencedColumn: (t) => t.listaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsListaTableFilterComposer(
            $db: $db,
            $table: $db.itemsLista,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ListasCompraTableOrderingComposer
    extends Composer<_$AppDatabase, $ListasCompraTable> {
  $$ListasCompraTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creada => $composableBuilder(
    column: $table.creada,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ListasCompraTableAnnotationComposer
    extends Composer<_$AppDatabase, $ListasCompraTable> {
  $$ListasCompraTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get creada =>
      $composableBuilder(column: $table.creada, builder: (column) => column);

  Expression<T> itemsListaRefs<T extends Object>(
    Expression<T> Function($$ItemsListaTableAnnotationComposer a) f,
  ) {
    final $$ItemsListaTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemsLista,
      getReferencedColumn: (t) => t.listaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsListaTableAnnotationComposer(
            $db: $db,
            $table: $db.itemsLista,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ListasCompraTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ListasCompraTable,
          ListaCompraRow,
          $$ListasCompraTableFilterComposer,
          $$ListasCompraTableOrderingComposer,
          $$ListasCompraTableAnnotationComposer,
          $$ListasCompraTableCreateCompanionBuilder,
          $$ListasCompraTableUpdateCompanionBuilder,
          (ListaCompraRow, $$ListasCompraTableReferences),
          ListaCompraRow,
          PrefetchHooks Function({bool itemsListaRefs})
        > {
  $$ListasCompraTableTableManager(_$AppDatabase db, $ListasCompraTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ListasCompraTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ListasCompraTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ListasCompraTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String> creada = const Value.absent(),
              }) =>
                  ListasCompraCompanion(id: id, nombre: nombre, creada: creada),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String nombre,
                required String creada,
              }) => ListasCompraCompanion.insert(
                id: id,
                nombre: nombre,
                creada: creada,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ListasCompraTable, ListaCompraRow>(table),
                  $$ListasCompraTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemsListaRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (itemsListaRefs) db.itemsLista],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (itemsListaRefs)
                    await $_getPrefetchedDataByColumns<
                      ListaCompraRow,
                      $ListasCompraTable,
                      ItemListaRow,
                      $ItemsListaTable
                    >(
                      currentTable: table,
                      referencedTable: $$ListasCompraTableReferences
                          ._itemsListaRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ListasCompraTableReferences(
                            db,
                            table,
                            p0,
                          ).itemsListaRefs,
                      currentColumn: 'id',
                      referencedColumn: 'lista_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ListasCompraTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ListasCompraTable,
      ListaCompraRow,
      $$ListasCompraTableFilterComposer,
      $$ListasCompraTableOrderingComposer,
      $$ListasCompraTableAnnotationComposer,
      $$ListasCompraTableCreateCompanionBuilder,
      $$ListasCompraTableUpdateCompanionBuilder,
      (ListaCompraRow, $$ListasCompraTableReferences),
      ListaCompraRow,
      PrefetchHooks Function({bool itemsListaRefs})
    >;
typedef $$ItemsListaTableCreateCompanionBuilder =
    ItemsListaCompanion Function({
      Value<int> id,
      required int listaId,
      Value<int?> alimentoId,
      required String texto,
      Value<String?> cantidad,
      required int orden,
      Value<bool> comprado,
      Value<int?> compraId,
    });
typedef $$ItemsListaTableUpdateCompanionBuilder =
    ItemsListaCompanion Function({
      Value<int> id,
      Value<int> listaId,
      Value<int?> alimentoId,
      Value<String> texto,
      Value<String?> cantidad,
      Value<int> orden,
      Value<bool> comprado,
      Value<int?> compraId,
    });

final class $$ItemsListaTableReferences
    extends BaseReferences<_$AppDatabase, $ItemsListaTable, ItemListaRow> {
  $$ItemsListaTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ListasCompraTable _listaIdTable(_$AppDatabase db) =>
      db.listasCompra.createAlias('items_lista__lista_id__listas_compra__id');

  $$ListasCompraTableProcessedTableManager get listaId {
    final $_column = $_itemColumn<int>('lista_id')!;

    final manager = $$ListasCompraTableTableManager(
      $_db,
      $_db.listasCompra,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_listaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AlimentosTable _alimentoIdTable(_$AppDatabase db) =>
      db.alimentos.createAlias('items_lista__alimento_id__alimentos__id');

  $$AlimentosTableProcessedTableManager? get alimentoId {
    final $_column = $_itemColumn<int>('alimento_id');
    if ($_column == null) return null;
    final manager = $$AlimentosTableTableManager(
      $_db,
      $_db.alimentos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_alimentoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ComprasTable _compraIdTable(_$AppDatabase db) =>
      db.compras.createAlias('items_lista__compra_id__compras__id');

  $$ComprasTableProcessedTableManager? get compraId {
    final $_column = $_itemColumn<int>('compra_id');
    if ($_column == null) return null;
    final manager = $$ComprasTableTableManager(
      $_db,
      $_db.compras,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_compraIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ItemsListaTableFilterComposer
    extends Composer<_$AppDatabase, $ItemsListaTable> {
  $$ItemsListaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get texto => $composableBuilder(
    column: $table.texto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cantidad => $composableBuilder(
    column: $table.cantidad,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orden => $composableBuilder(
    column: $table.orden,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get comprado => $composableBuilder(
    column: $table.comprado,
    builder: (column) => ColumnFilters(column),
  );

  $$ListasCompraTableFilterComposer get listaId {
    final $$ListasCompraTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listaId,
      referencedTable: $db.listasCompra,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ListasCompraTableFilterComposer(
            $db: $db,
            $table: $db.listasCompra,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AlimentosTableFilterComposer get alimentoId {
    final $$AlimentosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.alimentoId,
      referencedTable: $db.alimentos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlimentosTableFilterComposer(
            $db: $db,
            $table: $db.alimentos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ComprasTableFilterComposer get compraId {
    final $$ComprasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.compraId,
      referencedTable: $db.compras,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ComprasTableFilterComposer(
            $db: $db,
            $table: $db.compras,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemsListaTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemsListaTable> {
  $$ItemsListaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get texto => $composableBuilder(
    column: $table.texto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cantidad => $composableBuilder(
    column: $table.cantidad,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orden => $composableBuilder(
    column: $table.orden,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get comprado => $composableBuilder(
    column: $table.comprado,
    builder: (column) => ColumnOrderings(column),
  );

  $$ListasCompraTableOrderingComposer get listaId {
    final $$ListasCompraTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listaId,
      referencedTable: $db.listasCompra,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ListasCompraTableOrderingComposer(
            $db: $db,
            $table: $db.listasCompra,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AlimentosTableOrderingComposer get alimentoId {
    final $$AlimentosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.alimentoId,
      referencedTable: $db.alimentos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlimentosTableOrderingComposer(
            $db: $db,
            $table: $db.alimentos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ComprasTableOrderingComposer get compraId {
    final $$ComprasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.compraId,
      referencedTable: $db.compras,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ComprasTableOrderingComposer(
            $db: $db,
            $table: $db.compras,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemsListaTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemsListaTable> {
  $$ItemsListaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get texto =>
      $composableBuilder(column: $table.texto, builder: (column) => column);

  GeneratedColumn<String> get cantidad =>
      $composableBuilder(column: $table.cantidad, builder: (column) => column);

  GeneratedColumn<int> get orden =>
      $composableBuilder(column: $table.orden, builder: (column) => column);

  GeneratedColumn<bool> get comprado =>
      $composableBuilder(column: $table.comprado, builder: (column) => column);

  $$ListasCompraTableAnnotationComposer get listaId {
    final $$ListasCompraTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listaId,
      referencedTable: $db.listasCompra,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ListasCompraTableAnnotationComposer(
            $db: $db,
            $table: $db.listasCompra,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AlimentosTableAnnotationComposer get alimentoId {
    final $$AlimentosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.alimentoId,
      referencedTable: $db.alimentos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlimentosTableAnnotationComposer(
            $db: $db,
            $table: $db.alimentos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ComprasTableAnnotationComposer get compraId {
    final $$ComprasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.compraId,
      referencedTable: $db.compras,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ComprasTableAnnotationComposer(
            $db: $db,
            $table: $db.compras,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemsListaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemsListaTable,
          ItemListaRow,
          $$ItemsListaTableFilterComposer,
          $$ItemsListaTableOrderingComposer,
          $$ItemsListaTableAnnotationComposer,
          $$ItemsListaTableCreateCompanionBuilder,
          $$ItemsListaTableUpdateCompanionBuilder,
          (ItemListaRow, $$ItemsListaTableReferences),
          ItemListaRow,
          PrefetchHooks Function({bool listaId, bool alimentoId, bool compraId})
        > {
  $$ItemsListaTableTableManager(_$AppDatabase db, $ItemsListaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemsListaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemsListaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemsListaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> listaId = const Value.absent(),
                Value<int?> alimentoId = const Value.absent(),
                Value<String> texto = const Value.absent(),
                Value<String?> cantidad = const Value.absent(),
                Value<int> orden = const Value.absent(),
                Value<bool> comprado = const Value.absent(),
                Value<int?> compraId = const Value.absent(),
              }) => ItemsListaCompanion(
                id: id,
                listaId: listaId,
                alimentoId: alimentoId,
                texto: texto,
                cantidad: cantidad,
                orden: orden,
                comprado: comprado,
                compraId: compraId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int listaId,
                Value<int?> alimentoId = const Value.absent(),
                required String texto,
                Value<String?> cantidad = const Value.absent(),
                required int orden,
                Value<bool> comprado = const Value.absent(),
                Value<int?> compraId = const Value.absent(),
              }) => ItemsListaCompanion.insert(
                id: id,
                listaId: listaId,
                alimentoId: alimentoId,
                texto: texto,
                cantidad: cantidad,
                orden: orden,
                comprado: comprado,
                compraId: compraId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ItemsListaTable, ItemListaRow>(table),
                  $$ItemsListaTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({listaId = false, alimentoId = false, compraId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (listaId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.listaId,
                                    referencedTable: $$ItemsListaTableReferences
                                        ._listaIdTable(db),
                                    referencedColumn:
                                        $$ItemsListaTableReferences
                                            ._listaIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (alimentoId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.alimentoId,
                                    referencedTable: $$ItemsListaTableReferences
                                        ._alimentoIdTable(db),
                                    referencedColumn:
                                        $$ItemsListaTableReferences
                                            ._alimentoIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (compraId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.compraId,
                                    referencedTable: $$ItemsListaTableReferences
                                        ._compraIdTable(db),
                                    referencedColumn:
                                        $$ItemsListaTableReferences
                                            ._compraIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$ItemsListaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemsListaTable,
      ItemListaRow,
      $$ItemsListaTableFilterComposer,
      $$ItemsListaTableOrderingComposer,
      $$ItemsListaTableAnnotationComposer,
      $$ItemsListaTableCreateCompanionBuilder,
      $$ItemsListaTableUpdateCompanionBuilder,
      (ItemListaRow, $$ItemsListaTableReferences),
      ItemListaRow,
      PrefetchHooks Function({bool listaId, bool alimentoId, bool compraId})
    >;
typedef $$RecetasTableCreateCompanionBuilder =
    RecetasCompanion Function({
      Value<int> id,
      required String uuid,
      required String nombre,
      Value<String?> categoria,
      Value<int?> porciones,
      Value<int?> tiempoMin,
      Value<String> elaboracion,
      Value<String?> notas,
      Value<bool> favorita,
      Value<double?> pesoFinalG,
      Value<int?> alimentoId,
      required String creada,
      required String actualizada,
    });
typedef $$RecetasTableUpdateCompanionBuilder =
    RecetasCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<String> nombre,
      Value<String?> categoria,
      Value<int?> porciones,
      Value<int?> tiempoMin,
      Value<String> elaboracion,
      Value<String?> notas,
      Value<bool> favorita,
      Value<double?> pesoFinalG,
      Value<int?> alimentoId,
      Value<String> creada,
      Value<String> actualizada,
    });

final class $$RecetasTableReferences
    extends BaseReferences<_$AppDatabase, $RecetasTable, RecetaRow> {
  $$RecetasTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AlimentosTable _alimentoIdTable(_$AppDatabase db) =>
      db.alimentos.createAlias('recetas__alimento_id__alimentos__id');

  $$AlimentosTableProcessedTableManager? get alimentoId {
    final $_column = $_itemColumn<int>('alimento_id');
    if ($_column == null) return null;
    final manager = $$AlimentosTableTableManager(
      $_db,
      $_db.alimentos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_alimentoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $IngredientesRecetaTable,
    List<IngredienteRecetaRow>
  >
  _ingredientesRecetaRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.ingredientesReceta,
        aliasName: 'recetas__id__ingredientes_receta__receta_id',
      );

  $$IngredientesRecetaTableProcessedTableManager get ingredientesRecetaRefs {
    final manager = $$IngredientesRecetaTableTableManager(
      $_db,
      $_db.ingredientesReceta,
    ).filter((f) => f.recetaId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _ingredientesRecetaRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RecetasTableFilterComposer
    extends Composer<_$AppDatabase, $RecetasTable> {
  $$RecetasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoria => $composableBuilder(
    column: $table.categoria,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get porciones => $composableBuilder(
    column: $table.porciones,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tiempoMin => $composableBuilder(
    column: $table.tiempoMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get elaboracion => $composableBuilder(
    column: $table.elaboracion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notas => $composableBuilder(
    column: $table.notas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get favorita => $composableBuilder(
    column: $table.favorita,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pesoFinalG => $composableBuilder(
    column: $table.pesoFinalG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creada => $composableBuilder(
    column: $table.creada,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actualizada => $composableBuilder(
    column: $table.actualizada,
    builder: (column) => ColumnFilters(column),
  );

  $$AlimentosTableFilterComposer get alimentoId {
    final $$AlimentosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.alimentoId,
      referencedTable: $db.alimentos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlimentosTableFilterComposer(
            $db: $db,
            $table: $db.alimentos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> ingredientesRecetaRefs(
    Expression<bool> Function($$IngredientesRecetaTableFilterComposer f) f,
  ) {
    final $$IngredientesRecetaTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ingredientesReceta,
      getReferencedColumn: (t) => t.recetaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IngredientesRecetaTableFilterComposer(
            $db: $db,
            $table: $db.ingredientesReceta,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RecetasTableOrderingComposer
    extends Composer<_$AppDatabase, $RecetasTable> {
  $$RecetasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoria => $composableBuilder(
    column: $table.categoria,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get porciones => $composableBuilder(
    column: $table.porciones,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tiempoMin => $composableBuilder(
    column: $table.tiempoMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get elaboracion => $composableBuilder(
    column: $table.elaboracion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notas => $composableBuilder(
    column: $table.notas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get favorita => $composableBuilder(
    column: $table.favorita,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pesoFinalG => $composableBuilder(
    column: $table.pesoFinalG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creada => $composableBuilder(
    column: $table.creada,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actualizada => $composableBuilder(
    column: $table.actualizada,
    builder: (column) => ColumnOrderings(column),
  );

  $$AlimentosTableOrderingComposer get alimentoId {
    final $$AlimentosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.alimentoId,
      referencedTable: $db.alimentos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlimentosTableOrderingComposer(
            $db: $db,
            $table: $db.alimentos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecetasTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecetasTable> {
  $$RecetasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get categoria =>
      $composableBuilder(column: $table.categoria, builder: (column) => column);

  GeneratedColumn<int> get porciones =>
      $composableBuilder(column: $table.porciones, builder: (column) => column);

  GeneratedColumn<int> get tiempoMin =>
      $composableBuilder(column: $table.tiempoMin, builder: (column) => column);

  GeneratedColumn<String> get elaboracion => $composableBuilder(
    column: $table.elaboracion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notas =>
      $composableBuilder(column: $table.notas, builder: (column) => column);

  GeneratedColumn<bool> get favorita =>
      $composableBuilder(column: $table.favorita, builder: (column) => column);

  GeneratedColumn<double> get pesoFinalG => $composableBuilder(
    column: $table.pesoFinalG,
    builder: (column) => column,
  );

  GeneratedColumn<String> get creada =>
      $composableBuilder(column: $table.creada, builder: (column) => column);

  GeneratedColumn<String> get actualizada => $composableBuilder(
    column: $table.actualizada,
    builder: (column) => column,
  );

  $$AlimentosTableAnnotationComposer get alimentoId {
    final $$AlimentosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.alimentoId,
      referencedTable: $db.alimentos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlimentosTableAnnotationComposer(
            $db: $db,
            $table: $db.alimentos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> ingredientesRecetaRefs<T extends Object>(
    Expression<T> Function($$IngredientesRecetaTableAnnotationComposer a) f,
  ) {
    final $$IngredientesRecetaTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.ingredientesReceta,
          getReferencedColumn: (t) => t.recetaId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$IngredientesRecetaTableAnnotationComposer(
                $db: $db,
                $table: $db.ingredientesReceta,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$RecetasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecetasTable,
          RecetaRow,
          $$RecetasTableFilterComposer,
          $$RecetasTableOrderingComposer,
          $$RecetasTableAnnotationComposer,
          $$RecetasTableCreateCompanionBuilder,
          $$RecetasTableUpdateCompanionBuilder,
          (RecetaRow, $$RecetasTableReferences),
          RecetaRow,
          PrefetchHooks Function({bool alimentoId, bool ingredientesRecetaRefs})
        > {
  $$RecetasTableTableManager(_$AppDatabase db, $RecetasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecetasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecetasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecetasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String?> categoria = const Value.absent(),
                Value<int?> porciones = const Value.absent(),
                Value<int?> tiempoMin = const Value.absent(),
                Value<String> elaboracion = const Value.absent(),
                Value<String?> notas = const Value.absent(),
                Value<bool> favorita = const Value.absent(),
                Value<double?> pesoFinalG = const Value.absent(),
                Value<int?> alimentoId = const Value.absent(),
                Value<String> creada = const Value.absent(),
                Value<String> actualizada = const Value.absent(),
              }) => RecetasCompanion(
                id: id,
                uuid: uuid,
                nombre: nombre,
                categoria: categoria,
                porciones: porciones,
                tiempoMin: tiempoMin,
                elaboracion: elaboracion,
                notas: notas,
                favorita: favorita,
                pesoFinalG: pesoFinalG,
                alimentoId: alimentoId,
                creada: creada,
                actualizada: actualizada,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required String nombre,
                Value<String?> categoria = const Value.absent(),
                Value<int?> porciones = const Value.absent(),
                Value<int?> tiempoMin = const Value.absent(),
                Value<String> elaboracion = const Value.absent(),
                Value<String?> notas = const Value.absent(),
                Value<bool> favorita = const Value.absent(),
                Value<double?> pesoFinalG = const Value.absent(),
                Value<int?> alimentoId = const Value.absent(),
                required String creada,
                required String actualizada,
              }) => RecetasCompanion.insert(
                id: id,
                uuid: uuid,
                nombre: nombre,
                categoria: categoria,
                porciones: porciones,
                tiempoMin: tiempoMin,
                elaboracion: elaboracion,
                notas: notas,
                favorita: favorita,
                pesoFinalG: pesoFinalG,
                alimentoId: alimentoId,
                creada: creada,
                actualizada: actualizada,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecetasTable, RecetaRow>(table),
                  $$RecetasTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({alimentoId = false, ingredientesRecetaRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (ingredientesRecetaRefs) db.ingredientesReceta,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (alimentoId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.alimentoId,
                                    referencedTable: $$RecetasTableReferences
                                        ._alimentoIdTable(db),
                                    referencedColumn: $$RecetasTableReferences
                                        ._alimentoIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (ingredientesRecetaRefs)
                        await $_getPrefetchedDataByColumns<
                          RecetaRow,
                          $RecetasTable,
                          IngredienteRecetaRow,
                          $IngredientesRecetaTable
                        >(
                          currentTable: table,
                          referencedTable: $$RecetasTableReferences
                              ._ingredientesRecetaRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RecetasTableReferences(
                                db,
                                table,
                                p0,
                              ).ingredientesRecetaRefs,
                          currentColumn: 'id',
                          referencedColumn: 'receta_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$RecetasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecetasTable,
      RecetaRow,
      $$RecetasTableFilterComposer,
      $$RecetasTableOrderingComposer,
      $$RecetasTableAnnotationComposer,
      $$RecetasTableCreateCompanionBuilder,
      $$RecetasTableUpdateCompanionBuilder,
      (RecetaRow, $$RecetasTableReferences),
      RecetaRow,
      PrefetchHooks Function({bool alimentoId, bool ingredientesRecetaRefs})
    >;
typedef $$IngredientesRecetaTableCreateCompanionBuilder =
    IngredientesRecetaCompanion Function({
      Value<int> id,
      required int recetaId,
      required int orden,
      required String texto,
      Value<int?> alimentoId,
      Value<double?> cantidad,
      Value<String?> unidad,
      Value<bool> opcional,
    });
typedef $$IngredientesRecetaTableUpdateCompanionBuilder =
    IngredientesRecetaCompanion Function({
      Value<int> id,
      Value<int> recetaId,
      Value<int> orden,
      Value<String> texto,
      Value<int?> alimentoId,
      Value<double?> cantidad,
      Value<String?> unidad,
      Value<bool> opcional,
    });

final class $$IngredientesRecetaTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $IngredientesRecetaTable,
          IngredienteRecetaRow
        > {
  $$IngredientesRecetaTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RecetasTable _recetaIdTable(_$AppDatabase db) =>
      db.recetas.createAlias('ingredientes_receta__receta_id__recetas__id');

  $$RecetasTableProcessedTableManager get recetaId {
    final $_column = $_itemColumn<int>('receta_id')!;

    final manager = $$RecetasTableTableManager(
      $_db,
      $_db.recetas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recetaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AlimentosTable _alimentoIdTable(_$AppDatabase db) => db.alimentos
      .createAlias('ingredientes_receta__alimento_id__alimentos__id');

  $$AlimentosTableProcessedTableManager? get alimentoId {
    final $_column = $_itemColumn<int>('alimento_id');
    if ($_column == null) return null;
    final manager = $$AlimentosTableTableManager(
      $_db,
      $_db.alimentos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_alimentoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$IngredientesRecetaTableFilterComposer
    extends Composer<_$AppDatabase, $IngredientesRecetaTable> {
  $$IngredientesRecetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orden => $composableBuilder(
    column: $table.orden,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get texto => $composableBuilder(
    column: $table.texto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cantidad => $composableBuilder(
    column: $table.cantidad,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unidad => $composableBuilder(
    column: $table.unidad,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get opcional => $composableBuilder(
    column: $table.opcional,
    builder: (column) => ColumnFilters(column),
  );

  $$RecetasTableFilterComposer get recetaId {
    final $$RecetasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recetaId,
      referencedTable: $db.recetas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecetasTableFilterComposer(
            $db: $db,
            $table: $db.recetas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AlimentosTableFilterComposer get alimentoId {
    final $$AlimentosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.alimentoId,
      referencedTable: $db.alimentos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlimentosTableFilterComposer(
            $db: $db,
            $table: $db.alimentos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IngredientesRecetaTableOrderingComposer
    extends Composer<_$AppDatabase, $IngredientesRecetaTable> {
  $$IngredientesRecetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orden => $composableBuilder(
    column: $table.orden,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get texto => $composableBuilder(
    column: $table.texto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cantidad => $composableBuilder(
    column: $table.cantidad,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unidad => $composableBuilder(
    column: $table.unidad,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get opcional => $composableBuilder(
    column: $table.opcional,
    builder: (column) => ColumnOrderings(column),
  );

  $$RecetasTableOrderingComposer get recetaId {
    final $$RecetasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recetaId,
      referencedTable: $db.recetas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecetasTableOrderingComposer(
            $db: $db,
            $table: $db.recetas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AlimentosTableOrderingComposer get alimentoId {
    final $$AlimentosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.alimentoId,
      referencedTable: $db.alimentos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlimentosTableOrderingComposer(
            $db: $db,
            $table: $db.alimentos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IngredientesRecetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $IngredientesRecetaTable> {
  $$IngredientesRecetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get orden =>
      $composableBuilder(column: $table.orden, builder: (column) => column);

  GeneratedColumn<String> get texto =>
      $composableBuilder(column: $table.texto, builder: (column) => column);

  GeneratedColumn<double> get cantidad =>
      $composableBuilder(column: $table.cantidad, builder: (column) => column);

  GeneratedColumn<String> get unidad =>
      $composableBuilder(column: $table.unidad, builder: (column) => column);

  GeneratedColumn<bool> get opcional =>
      $composableBuilder(column: $table.opcional, builder: (column) => column);

  $$RecetasTableAnnotationComposer get recetaId {
    final $$RecetasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recetaId,
      referencedTable: $db.recetas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecetasTableAnnotationComposer(
            $db: $db,
            $table: $db.recetas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AlimentosTableAnnotationComposer get alimentoId {
    final $$AlimentosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.alimentoId,
      referencedTable: $db.alimentos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlimentosTableAnnotationComposer(
            $db: $db,
            $table: $db.alimentos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IngredientesRecetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IngredientesRecetaTable,
          IngredienteRecetaRow,
          $$IngredientesRecetaTableFilterComposer,
          $$IngredientesRecetaTableOrderingComposer,
          $$IngredientesRecetaTableAnnotationComposer,
          $$IngredientesRecetaTableCreateCompanionBuilder,
          $$IngredientesRecetaTableUpdateCompanionBuilder,
          (IngredienteRecetaRow, $$IngredientesRecetaTableReferences),
          IngredienteRecetaRow,
          PrefetchHooks Function({bool recetaId, bool alimentoId})
        > {
  $$IngredientesRecetaTableTableManager(
    _$AppDatabase db,
    $IngredientesRecetaTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IngredientesRecetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IngredientesRecetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IngredientesRecetaTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> recetaId = const Value.absent(),
                Value<int> orden = const Value.absent(),
                Value<String> texto = const Value.absent(),
                Value<int?> alimentoId = const Value.absent(),
                Value<double?> cantidad = const Value.absent(),
                Value<String?> unidad = const Value.absent(),
                Value<bool> opcional = const Value.absent(),
              }) => IngredientesRecetaCompanion(
                id: id,
                recetaId: recetaId,
                orden: orden,
                texto: texto,
                alimentoId: alimentoId,
                cantidad: cantidad,
                unidad: unidad,
                opcional: opcional,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int recetaId,
                required int orden,
                required String texto,
                Value<int?> alimentoId = const Value.absent(),
                Value<double?> cantidad = const Value.absent(),
                Value<String?> unidad = const Value.absent(),
                Value<bool> opcional = const Value.absent(),
              }) => IngredientesRecetaCompanion.insert(
                id: id,
                recetaId: recetaId,
                orden: orden,
                texto: texto,
                alimentoId: alimentoId,
                cantidad: cantidad,
                unidad: unidad,
                opcional: opcional,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$IngredientesRecetaTable, IngredienteRecetaRow>(
                    table,
                  ),
                  $$IngredientesRecetaTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({recetaId = false, alimentoId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (recetaId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.recetaId,
                                referencedTable:
                                    $$IngredientesRecetaTableReferences
                                        ._recetaIdTable(db),
                                referencedColumn:
                                    $$IngredientesRecetaTableReferences
                                        ._recetaIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (alimentoId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.alimentoId,
                                referencedTable:
                                    $$IngredientesRecetaTableReferences
                                        ._alimentoIdTable(db),
                                referencedColumn:
                                    $$IngredientesRecetaTableReferences
                                        ._alimentoIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$IngredientesRecetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IngredientesRecetaTable,
      IngredienteRecetaRow,
      $$IngredientesRecetaTableFilterComposer,
      $$IngredientesRecetaTableOrderingComposer,
      $$IngredientesRecetaTableAnnotationComposer,
      $$IngredientesRecetaTableCreateCompanionBuilder,
      $$IngredientesRecetaTableUpdateCompanionBuilder,
      (IngredienteRecetaRow, $$IngredientesRecetaTableReferences),
      IngredienteRecetaRow,
      PrefetchHooks Function({bool recetaId, bool alimentoId})
    >;
typedef $$ComidasTableCreateCompanionBuilder =
    ComidasCompanion Function({
      Value<int> id,
      required String nombre,
      required String fecha,
    });
typedef $$ComidasTableUpdateCompanionBuilder =
    ComidasCompanion Function({
      Value<int> id,
      Value<String> nombre,
      Value<String> fecha,
    });

final class $$ComidasTableReferences
    extends BaseReferences<_$AppDatabase, $ComidasTable, ComidaRow> {
  $$ComidasTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ItemsComidaTable, List<ItemComidaRow>>
  _itemsComidaRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.itemsComida,
    aliasName: 'comidas__id__items_comida__comida_id',
  );

  $$ItemsComidaTableProcessedTableManager get itemsComidaRefs {
    final manager = $$ItemsComidaTableTableManager(
      $_db,
      $_db.itemsComida,
    ).filter((f) => f.comidaId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_itemsComidaRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ComidasTableFilterComposer
    extends Composer<_$AppDatabase, $ComidasTable> {
  $$ComidasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> itemsComidaRefs(
    Expression<bool> Function($$ItemsComidaTableFilterComposer f) f,
  ) {
    final $$ItemsComidaTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemsComida,
      getReferencedColumn: (t) => t.comidaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsComidaTableFilterComposer(
            $db: $db,
            $table: $db.itemsComida,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ComidasTableOrderingComposer
    extends Composer<_$AppDatabase, $ComidasTable> {
  $$ComidasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ComidasTableAnnotationComposer
    extends Composer<_$AppDatabase, $ComidasTable> {
  $$ComidasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);

  Expression<T> itemsComidaRefs<T extends Object>(
    Expression<T> Function($$ItemsComidaTableAnnotationComposer a) f,
  ) {
    final $$ItemsComidaTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemsComida,
      getReferencedColumn: (t) => t.comidaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsComidaTableAnnotationComposer(
            $db: $db,
            $table: $db.itemsComida,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ComidasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ComidasTable,
          ComidaRow,
          $$ComidasTableFilterComposer,
          $$ComidasTableOrderingComposer,
          $$ComidasTableAnnotationComposer,
          $$ComidasTableCreateCompanionBuilder,
          $$ComidasTableUpdateCompanionBuilder,
          (ComidaRow, $$ComidasTableReferences),
          ComidaRow,
          PrefetchHooks Function({bool itemsComidaRefs})
        > {
  $$ComidasTableTableManager(_$AppDatabase db, $ComidasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ComidasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ComidasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ComidasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String> fecha = const Value.absent(),
              }) => ComidasCompanion(id: id, nombre: nombre, fecha: fecha),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String nombre,
                required String fecha,
              }) =>
                  ComidasCompanion.insert(id: id, nombre: nombre, fecha: fecha),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ComidasTable, ComidaRow>(table),
                  $$ComidasTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemsComidaRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (itemsComidaRefs) db.itemsComida],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (itemsComidaRefs)
                    await $_getPrefetchedDataByColumns<
                      ComidaRow,
                      $ComidasTable,
                      ItemComidaRow,
                      $ItemsComidaTable
                    >(
                      currentTable: table,
                      referencedTable: $$ComidasTableReferences
                          ._itemsComidaRefsTable(db),
                      managerFromTypedResult: (p0) => $$ComidasTableReferences(
                        db,
                        table,
                        p0,
                      ).itemsComidaRefs,
                      currentColumn: 'id',
                      referencedColumn: 'comida_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ComidasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ComidasTable,
      ComidaRow,
      $$ComidasTableFilterComposer,
      $$ComidasTableOrderingComposer,
      $$ComidasTableAnnotationComposer,
      $$ComidasTableCreateCompanionBuilder,
      $$ComidasTableUpdateCompanionBuilder,
      (ComidaRow, $$ComidasTableReferences),
      ComidaRow,
      PrefetchHooks Function({bool itemsComidaRefs})
    >;
typedef $$ItemsComidaTableCreateCompanionBuilder =
    ItemsComidaCompanion Function({
      Value<int> id,
      required int comidaId,
      Value<int?> alimentoId,
      required String nombre,
      required double cantidad,
      required double kcal,
      required double proteinas,
      required double grasas,
      required double carbohidratos,
    });
typedef $$ItemsComidaTableUpdateCompanionBuilder =
    ItemsComidaCompanion Function({
      Value<int> id,
      Value<int> comidaId,
      Value<int?> alimentoId,
      Value<String> nombre,
      Value<double> cantidad,
      Value<double> kcal,
      Value<double> proteinas,
      Value<double> grasas,
      Value<double> carbohidratos,
    });

final class $$ItemsComidaTableReferences
    extends BaseReferences<_$AppDatabase, $ItemsComidaTable, ItemComidaRow> {
  $$ItemsComidaTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ComidasTable _comidaIdTable(_$AppDatabase db) =>
      db.comidas.createAlias('items_comida__comida_id__comidas__id');

  $$ComidasTableProcessedTableManager get comidaId {
    final $_column = $_itemColumn<int>('comida_id')!;

    final manager = $$ComidasTableTableManager(
      $_db,
      $_db.comidas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_comidaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AlimentosTable _alimentoIdTable(_$AppDatabase db) =>
      db.alimentos.createAlias('items_comida__alimento_id__alimentos__id');

  $$AlimentosTableProcessedTableManager? get alimentoId {
    final $_column = $_itemColumn<int>('alimento_id');
    if ($_column == null) return null;
    final manager = $$AlimentosTableTableManager(
      $_db,
      $_db.alimentos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_alimentoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ItemsComidaTableFilterComposer
    extends Composer<_$AppDatabase, $ItemsComidaTable> {
  $$ItemsComidaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cantidad => $composableBuilder(
    column: $table.cantidad,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kcal => $composableBuilder(
    column: $table.kcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinas => $composableBuilder(
    column: $table.proteinas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grasas => $composableBuilder(
    column: $table.grasas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbohidratos => $composableBuilder(
    column: $table.carbohidratos,
    builder: (column) => ColumnFilters(column),
  );

  $$ComidasTableFilterComposer get comidaId {
    final $$ComidasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.comidaId,
      referencedTable: $db.comidas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ComidasTableFilterComposer(
            $db: $db,
            $table: $db.comidas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AlimentosTableFilterComposer get alimentoId {
    final $$AlimentosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.alimentoId,
      referencedTable: $db.alimentos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlimentosTableFilterComposer(
            $db: $db,
            $table: $db.alimentos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemsComidaTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemsComidaTable> {
  $$ItemsComidaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cantidad => $composableBuilder(
    column: $table.cantidad,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kcal => $composableBuilder(
    column: $table.kcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinas => $composableBuilder(
    column: $table.proteinas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grasas => $composableBuilder(
    column: $table.grasas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbohidratos => $composableBuilder(
    column: $table.carbohidratos,
    builder: (column) => ColumnOrderings(column),
  );

  $$ComidasTableOrderingComposer get comidaId {
    final $$ComidasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.comidaId,
      referencedTable: $db.comidas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ComidasTableOrderingComposer(
            $db: $db,
            $table: $db.comidas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AlimentosTableOrderingComposer get alimentoId {
    final $$AlimentosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.alimentoId,
      referencedTable: $db.alimentos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlimentosTableOrderingComposer(
            $db: $db,
            $table: $db.alimentos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemsComidaTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemsComidaTable> {
  $$ItemsComidaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<double> get cantidad =>
      $composableBuilder(column: $table.cantidad, builder: (column) => column);

  GeneratedColumn<double> get kcal =>
      $composableBuilder(column: $table.kcal, builder: (column) => column);

  GeneratedColumn<double> get proteinas =>
      $composableBuilder(column: $table.proteinas, builder: (column) => column);

  GeneratedColumn<double> get grasas =>
      $composableBuilder(column: $table.grasas, builder: (column) => column);

  GeneratedColumn<double> get carbohidratos => $composableBuilder(
    column: $table.carbohidratos,
    builder: (column) => column,
  );

  $$ComidasTableAnnotationComposer get comidaId {
    final $$ComidasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.comidaId,
      referencedTable: $db.comidas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ComidasTableAnnotationComposer(
            $db: $db,
            $table: $db.comidas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AlimentosTableAnnotationComposer get alimentoId {
    final $$AlimentosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.alimentoId,
      referencedTable: $db.alimentos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlimentosTableAnnotationComposer(
            $db: $db,
            $table: $db.alimentos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemsComidaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemsComidaTable,
          ItemComidaRow,
          $$ItemsComidaTableFilterComposer,
          $$ItemsComidaTableOrderingComposer,
          $$ItemsComidaTableAnnotationComposer,
          $$ItemsComidaTableCreateCompanionBuilder,
          $$ItemsComidaTableUpdateCompanionBuilder,
          (ItemComidaRow, $$ItemsComidaTableReferences),
          ItemComidaRow,
          PrefetchHooks Function({bool comidaId, bool alimentoId})
        > {
  $$ItemsComidaTableTableManager(_$AppDatabase db, $ItemsComidaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemsComidaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemsComidaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemsComidaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> comidaId = const Value.absent(),
                Value<int?> alimentoId = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<double> cantidad = const Value.absent(),
                Value<double> kcal = const Value.absent(),
                Value<double> proteinas = const Value.absent(),
                Value<double> grasas = const Value.absent(),
                Value<double> carbohidratos = const Value.absent(),
              }) => ItemsComidaCompanion(
                id: id,
                comidaId: comidaId,
                alimentoId: alimentoId,
                nombre: nombre,
                cantidad: cantidad,
                kcal: kcal,
                proteinas: proteinas,
                grasas: grasas,
                carbohidratos: carbohidratos,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int comidaId,
                Value<int?> alimentoId = const Value.absent(),
                required String nombre,
                required double cantidad,
                required double kcal,
                required double proteinas,
                required double grasas,
                required double carbohidratos,
              }) => ItemsComidaCompanion.insert(
                id: id,
                comidaId: comidaId,
                alimentoId: alimentoId,
                nombre: nombre,
                cantidad: cantidad,
                kcal: kcal,
                proteinas: proteinas,
                grasas: grasas,
                carbohidratos: carbohidratos,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ItemsComidaTable, ItemComidaRow>(table),
                  $$ItemsComidaTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({comidaId = false, alimentoId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (comidaId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.comidaId,
                                referencedTable: $$ItemsComidaTableReferences
                                    ._comidaIdTable(db),
                                referencedColumn: $$ItemsComidaTableReferences
                                    ._comidaIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (alimentoId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.alimentoId,
                                referencedTable: $$ItemsComidaTableReferences
                                    ._alimentoIdTable(db),
                                referencedColumn: $$ItemsComidaTableReferences
                                    ._alimentoIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ItemsComidaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemsComidaTable,
      ItemComidaRow,
      $$ItemsComidaTableFilterComposer,
      $$ItemsComidaTableOrderingComposer,
      $$ItemsComidaTableAnnotationComposer,
      $$ItemsComidaTableCreateCompanionBuilder,
      $$ItemsComidaTableUpdateCompanionBuilder,
      (ItemComidaRow, $$ItemsComidaTableReferences),
      ItemComidaRow,
      PrefetchHooks Function({bool comidaId, bool alimentoId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CategoriasTableTableManager get categorias =>
      $$CategoriasTableTableManager(_db, _db.categorias);
  $$AlimentosTableTableManager get alimentos =>
      $$AlimentosTableTableManager(_db, _db.alimentos);
  $$PorcionesTableTableManager get porciones =>
      $$PorcionesTableTableManager(_db, _db.porciones);
  $$PresentacionesTableTableManager get presentaciones =>
      $$PresentacionesTableTableManager(_db, _db.presentaciones);
  $$EstablecimientosTableTableManager get establecimientos =>
      $$EstablecimientosTableTableManager(_db, _db.establecimientos);
  $$OrdenPasillosTableTableManager get ordenPasillos =>
      $$OrdenPasillosTableTableManager(_db, _db.ordenPasillos);
  $$CodigosBasculaTableTableManager get codigosBascula =>
      $$CodigosBasculaTableTableManager(_db, _db.codigosBascula);
  $$ComprasTableTableManager get compras =>
      $$ComprasTableTableManager(_db, _db.compras);
  $$ListasCompraTableTableManager get listasCompra =>
      $$ListasCompraTableTableManager(_db, _db.listasCompra);
  $$ItemsListaTableTableManager get itemsLista =>
      $$ItemsListaTableTableManager(_db, _db.itemsLista);
  $$RecetasTableTableManager get recetas =>
      $$RecetasTableTableManager(_db, _db.recetas);
  $$IngredientesRecetaTableTableManager get ingredientesReceta =>
      $$IngredientesRecetaTableTableManager(_db, _db.ingredientesReceta);
  $$ComidasTableTableManager get comidas =>
      $$ComidasTableTableManager(_db, _db.comidas);
  $$ItemsComidaTableTableManager get itemsComida =>
      $$ItemsComidaTableTableManager(_db, _db.itemsComida);
}
