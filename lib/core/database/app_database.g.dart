// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CachedProfilesTable extends CachedProfiles
    with TableInfo<$CachedProfilesTable, CachedProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authUserIdMeta = const VerificationMeta(
    'authUserId',
  );
  @override
  late final GeneratedColumn<String> authUserId = GeneratedColumn<String>(
    'auth_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serviceIdMeta = const VerificationMeta(
    'serviceId',
  );
  @override
  late final GeneratedColumn<String> serviceId = GeneratedColumn<String>(
    'service_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _birthDateMeta = const VerificationMeta(
    'birthDate',
  );
  @override
  late final GeneratedColumn<String> birthDate = GeneratedColumn<String>(
    'birth_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _workStudyMeta = const VerificationMeta(
    'workStudy',
  );
  @override
  late final GeneratedColumn<String> workStudy = GeneratedColumn<String>(
    'work_study',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountStatusMeta = const VerificationMeta(
    'accountStatus',
  );
  @override
  late final GeneratedColumn<String> accountStatus = GeneratedColumn<String>(
    'account_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mustChangePasswordMeta =
      const VerificationMeta('mustChangePassword');
  @override
  late final GeneratedColumn<bool> mustChangePassword = GeneratedColumn<bool>(
    'must_change_password',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("must_change_password" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _stageIdMeta = const VerificationMeta(
    'stageId',
  );
  @override
  late final GeneratedColumn<String> stageId = GeneratedColumn<String>(
    'stage_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _classIdMeta = const VerificationMeta(
    'classId',
  );
  @override
  late final GeneratedColumn<String> classId = GeneratedColumn<String>(
    'class_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    authUserId,
    serviceId,
    name,
    role,
    phone,
    birthDate,
    workStudy,
    accountStatus,
    mustChangePassword,
    stageId,
    classId,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('auth_user_id')) {
      context.handle(
        _authUserIdMeta,
        authUserId.isAcceptableOrUnknown(
          data['auth_user_id']!,
          _authUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_authUserIdMeta);
    }
    if (data.containsKey('service_id')) {
      context.handle(
        _serviceIdMeta,
        serviceId.isAcceptableOrUnknown(data['service_id']!, _serviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serviceIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('birth_date')) {
      context.handle(
        _birthDateMeta,
        birthDate.isAcceptableOrUnknown(data['birth_date']!, _birthDateMeta),
      );
    }
    if (data.containsKey('work_study')) {
      context.handle(
        _workStudyMeta,
        workStudy.isAcceptableOrUnknown(data['work_study']!, _workStudyMeta),
      );
    }
    if (data.containsKey('account_status')) {
      context.handle(
        _accountStatusMeta,
        accountStatus.isAcceptableOrUnknown(
          data['account_status']!,
          _accountStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accountStatusMeta);
    }
    if (data.containsKey('must_change_password')) {
      context.handle(
        _mustChangePasswordMeta,
        mustChangePassword.isAcceptableOrUnknown(
          data['must_change_password']!,
          _mustChangePasswordMeta,
        ),
      );
    }
    if (data.containsKey('stage_id')) {
      context.handle(
        _stageIdMeta,
        stageId.isAcceptableOrUnknown(data['stage_id']!, _stageIdMeta),
      );
    }
    if (data.containsKey('class_id')) {
      context.handle(
        _classIdMeta,
        classId.isAcceptableOrUnknown(data['class_id']!, _classIdMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedProfile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      authUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}auth_user_id'],
      )!,
      serviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}service_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      birthDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}birth_date'],
      ),
      workStudy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}work_study'],
      ),
      accountStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_status'],
      )!,
      mustChangePassword: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}must_change_password'],
      )!,
      stageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stage_id'],
      ),
      classId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}class_id'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedProfilesTable createAlias(String alias) {
    return $CachedProfilesTable(attachedDatabase, alias);
  }
}

class CachedProfile extends DataClass implements Insertable<CachedProfile> {
  final String id;
  final String authUserId;
  final String serviceId;
  final String name;
  final String role;
  final String? phone;
  final String? birthDate;
  final String? workStudy;
  final String accountStatus;
  final bool mustChangePassword;
  final String? stageId;
  final String? classId;
  final DateTime cachedAt;
  const CachedProfile({
    required this.id,
    required this.authUserId,
    required this.serviceId,
    required this.name,
    required this.role,
    this.phone,
    this.birthDate,
    this.workStudy,
    required this.accountStatus,
    required this.mustChangePassword,
    this.stageId,
    this.classId,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['auth_user_id'] = Variable<String>(authUserId);
    map['service_id'] = Variable<String>(serviceId);
    map['name'] = Variable<String>(name);
    map['role'] = Variable<String>(role);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || birthDate != null) {
      map['birth_date'] = Variable<String>(birthDate);
    }
    if (!nullToAbsent || workStudy != null) {
      map['work_study'] = Variable<String>(workStudy);
    }
    map['account_status'] = Variable<String>(accountStatus);
    map['must_change_password'] = Variable<bool>(mustChangePassword);
    if (!nullToAbsent || stageId != null) {
      map['stage_id'] = Variable<String>(stageId);
    }
    if (!nullToAbsent || classId != null) {
      map['class_id'] = Variable<String>(classId);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedProfilesCompanion toCompanion(bool nullToAbsent) {
    return CachedProfilesCompanion(
      id: Value(id),
      authUserId: Value(authUserId),
      serviceId: Value(serviceId),
      name: Value(name),
      role: Value(role),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      birthDate: birthDate == null && nullToAbsent
          ? const Value.absent()
          : Value(birthDate),
      workStudy: workStudy == null && nullToAbsent
          ? const Value.absent()
          : Value(workStudy),
      accountStatus: Value(accountStatus),
      mustChangePassword: Value(mustChangePassword),
      stageId: stageId == null && nullToAbsent
          ? const Value.absent()
          : Value(stageId),
      classId: classId == null && nullToAbsent
          ? const Value.absent()
          : Value(classId),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedProfile(
      id: serializer.fromJson<String>(json['id']),
      authUserId: serializer.fromJson<String>(json['authUserId']),
      serviceId: serializer.fromJson<String>(json['serviceId']),
      name: serializer.fromJson<String>(json['name']),
      role: serializer.fromJson<String>(json['role']),
      phone: serializer.fromJson<String?>(json['phone']),
      birthDate: serializer.fromJson<String?>(json['birthDate']),
      workStudy: serializer.fromJson<String?>(json['workStudy']),
      accountStatus: serializer.fromJson<String>(json['accountStatus']),
      mustChangePassword: serializer.fromJson<bool>(json['mustChangePassword']),
      stageId: serializer.fromJson<String?>(json['stageId']),
      classId: serializer.fromJson<String?>(json['classId']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'authUserId': serializer.toJson<String>(authUserId),
      'serviceId': serializer.toJson<String>(serviceId),
      'name': serializer.toJson<String>(name),
      'role': serializer.toJson<String>(role),
      'phone': serializer.toJson<String?>(phone),
      'birthDate': serializer.toJson<String?>(birthDate),
      'workStudy': serializer.toJson<String?>(workStudy),
      'accountStatus': serializer.toJson<String>(accountStatus),
      'mustChangePassword': serializer.toJson<bool>(mustChangePassword),
      'stageId': serializer.toJson<String?>(stageId),
      'classId': serializer.toJson<String?>(classId),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedProfile copyWith({
    String? id,
    String? authUserId,
    String? serviceId,
    String? name,
    String? role,
    Value<String?> phone = const Value.absent(),
    Value<String?> birthDate = const Value.absent(),
    Value<String?> workStudy = const Value.absent(),
    String? accountStatus,
    bool? mustChangePassword,
    Value<String?> stageId = const Value.absent(),
    Value<String?> classId = const Value.absent(),
    DateTime? cachedAt,
  }) => CachedProfile(
    id: id ?? this.id,
    authUserId: authUserId ?? this.authUserId,
    serviceId: serviceId ?? this.serviceId,
    name: name ?? this.name,
    role: role ?? this.role,
    phone: phone.present ? phone.value : this.phone,
    birthDate: birthDate.present ? birthDate.value : this.birthDate,
    workStudy: workStudy.present ? workStudy.value : this.workStudy,
    accountStatus: accountStatus ?? this.accountStatus,
    mustChangePassword: mustChangePassword ?? this.mustChangePassword,
    stageId: stageId.present ? stageId.value : this.stageId,
    classId: classId.present ? classId.value : this.classId,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedProfile copyWithCompanion(CachedProfilesCompanion data) {
    return CachedProfile(
      id: data.id.present ? data.id.value : this.id,
      authUserId: data.authUserId.present
          ? data.authUserId.value
          : this.authUserId,
      serviceId: data.serviceId.present ? data.serviceId.value : this.serviceId,
      name: data.name.present ? data.name.value : this.name,
      role: data.role.present ? data.role.value : this.role,
      phone: data.phone.present ? data.phone.value : this.phone,
      birthDate: data.birthDate.present ? data.birthDate.value : this.birthDate,
      workStudy: data.workStudy.present ? data.workStudy.value : this.workStudy,
      accountStatus: data.accountStatus.present
          ? data.accountStatus.value
          : this.accountStatus,
      mustChangePassword: data.mustChangePassword.present
          ? data.mustChangePassword.value
          : this.mustChangePassword,
      stageId: data.stageId.present ? data.stageId.value : this.stageId,
      classId: data.classId.present ? data.classId.value : this.classId,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedProfile(')
          ..write('id: $id, ')
          ..write('authUserId: $authUserId, ')
          ..write('serviceId: $serviceId, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('phone: $phone, ')
          ..write('birthDate: $birthDate, ')
          ..write('workStudy: $workStudy, ')
          ..write('accountStatus: $accountStatus, ')
          ..write('mustChangePassword: $mustChangePassword, ')
          ..write('stageId: $stageId, ')
          ..write('classId: $classId, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    authUserId,
    serviceId,
    name,
    role,
    phone,
    birthDate,
    workStudy,
    accountStatus,
    mustChangePassword,
    stageId,
    classId,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedProfile &&
          other.id == this.id &&
          other.authUserId == this.authUserId &&
          other.serviceId == this.serviceId &&
          other.name == this.name &&
          other.role == this.role &&
          other.phone == this.phone &&
          other.birthDate == this.birthDate &&
          other.workStudy == this.workStudy &&
          other.accountStatus == this.accountStatus &&
          other.mustChangePassword == this.mustChangePassword &&
          other.stageId == this.stageId &&
          other.classId == this.classId &&
          other.cachedAt == this.cachedAt);
}

class CachedProfilesCompanion extends UpdateCompanion<CachedProfile> {
  final Value<String> id;
  final Value<String> authUserId;
  final Value<String> serviceId;
  final Value<String> name;
  final Value<String> role;
  final Value<String?> phone;
  final Value<String?> birthDate;
  final Value<String?> workStudy;
  final Value<String> accountStatus;
  final Value<bool> mustChangePassword;
  final Value<String?> stageId;
  final Value<String?> classId;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedProfilesCompanion({
    this.id = const Value.absent(),
    this.authUserId = const Value.absent(),
    this.serviceId = const Value.absent(),
    this.name = const Value.absent(),
    this.role = const Value.absent(),
    this.phone = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.workStudy = const Value.absent(),
    this.accountStatus = const Value.absent(),
    this.mustChangePassword = const Value.absent(),
    this.stageId = const Value.absent(),
    this.classId = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedProfilesCompanion.insert({
    required String id,
    required String authUserId,
    required String serviceId,
    required String name,
    required String role,
    this.phone = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.workStudy = const Value.absent(),
    required String accountStatus,
    this.mustChangePassword = const Value.absent(),
    this.stageId = const Value.absent(),
    this.classId = const Value.absent(),
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       authUserId = Value(authUserId),
       serviceId = Value(serviceId),
       name = Value(name),
       role = Value(role),
       accountStatus = Value(accountStatus),
       cachedAt = Value(cachedAt);
  static Insertable<CachedProfile> custom({
    Expression<String>? id,
    Expression<String>? authUserId,
    Expression<String>? serviceId,
    Expression<String>? name,
    Expression<String>? role,
    Expression<String>? phone,
    Expression<String>? birthDate,
    Expression<String>? workStudy,
    Expression<String>? accountStatus,
    Expression<bool>? mustChangePassword,
    Expression<String>? stageId,
    Expression<String>? classId,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (authUserId != null) 'auth_user_id': authUserId,
      if (serviceId != null) 'service_id': serviceId,
      if (name != null) 'name': name,
      if (role != null) 'role': role,
      if (phone != null) 'phone': phone,
      if (birthDate != null) 'birth_date': birthDate,
      if (workStudy != null) 'work_study': workStudy,
      if (accountStatus != null) 'account_status': accountStatus,
      if (mustChangePassword != null)
        'must_change_password': mustChangePassword,
      if (stageId != null) 'stage_id': stageId,
      if (classId != null) 'class_id': classId,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? authUserId,
    Value<String>? serviceId,
    Value<String>? name,
    Value<String>? role,
    Value<String?>? phone,
    Value<String?>? birthDate,
    Value<String?>? workStudy,
    Value<String>? accountStatus,
    Value<bool>? mustChangePassword,
    Value<String?>? stageId,
    Value<String?>? classId,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedProfilesCompanion(
      id: id ?? this.id,
      authUserId: authUserId ?? this.authUserId,
      serviceId: serviceId ?? this.serviceId,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      workStudy: workStudy ?? this.workStudy,
      accountStatus: accountStatus ?? this.accountStatus,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      stageId: stageId ?? this.stageId,
      classId: classId ?? this.classId,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (authUserId.present) {
      map['auth_user_id'] = Variable<String>(authUserId.value);
    }
    if (serviceId.present) {
      map['service_id'] = Variable<String>(serviceId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (birthDate.present) {
      map['birth_date'] = Variable<String>(birthDate.value);
    }
    if (workStudy.present) {
      map['work_study'] = Variable<String>(workStudy.value);
    }
    if (accountStatus.present) {
      map['account_status'] = Variable<String>(accountStatus.value);
    }
    if (mustChangePassword.present) {
      map['must_change_password'] = Variable<bool>(mustChangePassword.value);
    }
    if (stageId.present) {
      map['stage_id'] = Variable<String>(stageId.value);
    }
    if (classId.present) {
      map['class_id'] = Variable<String>(classId.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedProfilesCompanion(')
          ..write('id: $id, ')
          ..write('authUserId: $authUserId, ')
          ..write('serviceId: $serviceId, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('phone: $phone, ')
          ..write('birthDate: $birthDate, ')
          ..write('workStudy: $workStudy, ')
          ..write('accountStatus: $accountStatus, ')
          ..write('mustChangePassword: $mustChangePassword, ')
          ..write('stageId: $stageId, ')
          ..write('classId: $classId, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedServicesTable extends CachedServices
    with TableInfo<$CachedServicesTable, CachedService> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedServicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _churchNameMeta = const VerificationMeta(
    'churchName',
  );
  @override
  late final GeneratedColumn<String> churchName = GeneratedColumn<String>(
    'church_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _meetingStartTimeMeta = const VerificationMeta(
    'meetingStartTime',
  );
  @override
  late final GeneratedColumn<String> meetingStartTime = GeneratedColumn<String>(
    'meeting_start_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    churchName,
    meetingStartTime,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_services';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedService> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('church_name')) {
      context.handle(
        _churchNameMeta,
        churchName.isAcceptableOrUnknown(data['church_name']!, _churchNameMeta),
      );
    } else if (isInserting) {
      context.missing(_churchNameMeta);
    }
    if (data.containsKey('meeting_start_time')) {
      context.handle(
        _meetingStartTimeMeta,
        meetingStartTime.isAcceptableOrUnknown(
          data['meeting_start_time']!,
          _meetingStartTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_meetingStartTimeMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedService map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedService(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      churchName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}church_name'],
      )!,
      meetingStartTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meeting_start_time'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedServicesTable createAlias(String alias) {
    return $CachedServicesTable(attachedDatabase, alias);
  }
}

class CachedService extends DataClass implements Insertable<CachedService> {
  final String id;
  final String name;
  final String churchName;
  final String meetingStartTime;
  final DateTime cachedAt;
  const CachedService({
    required this.id,
    required this.name,
    required this.churchName,
    required this.meetingStartTime,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['church_name'] = Variable<String>(churchName);
    map['meeting_start_time'] = Variable<String>(meetingStartTime);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedServicesCompanion toCompanion(bool nullToAbsent) {
    return CachedServicesCompanion(
      id: Value(id),
      name: Value(name),
      churchName: Value(churchName),
      meetingStartTime: Value(meetingStartTime),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedService.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedService(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      churchName: serializer.fromJson<String>(json['churchName']),
      meetingStartTime: serializer.fromJson<String>(json['meetingStartTime']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'churchName': serializer.toJson<String>(churchName),
      'meetingStartTime': serializer.toJson<String>(meetingStartTime),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedService copyWith({
    String? id,
    String? name,
    String? churchName,
    String? meetingStartTime,
    DateTime? cachedAt,
  }) => CachedService(
    id: id ?? this.id,
    name: name ?? this.name,
    churchName: churchName ?? this.churchName,
    meetingStartTime: meetingStartTime ?? this.meetingStartTime,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedService copyWithCompanion(CachedServicesCompanion data) {
    return CachedService(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      churchName: data.churchName.present
          ? data.churchName.value
          : this.churchName,
      meetingStartTime: data.meetingStartTime.present
          ? data.meetingStartTime.value
          : this.meetingStartTime,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedService(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('churchName: $churchName, ')
          ..write('meetingStartTime: $meetingStartTime, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, churchName, meetingStartTime, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedService &&
          other.id == this.id &&
          other.name == this.name &&
          other.churchName == this.churchName &&
          other.meetingStartTime == this.meetingStartTime &&
          other.cachedAt == this.cachedAt);
}

class CachedServicesCompanion extends UpdateCompanion<CachedService> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> churchName;
  final Value<String> meetingStartTime;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedServicesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.churchName = const Value.absent(),
    this.meetingStartTime = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedServicesCompanion.insert({
    required String id,
    required String name,
    required String churchName,
    required String meetingStartTime,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       churchName = Value(churchName),
       meetingStartTime = Value(meetingStartTime),
       cachedAt = Value(cachedAt);
  static Insertable<CachedService> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? churchName,
    Expression<String>? meetingStartTime,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (churchName != null) 'church_name': churchName,
      if (meetingStartTime != null) 'meeting_start_time': meetingStartTime,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedServicesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? churchName,
    Value<String>? meetingStartTime,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedServicesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      churchName: churchName ?? this.churchName,
      meetingStartTime: meetingStartTime ?? this.meetingStartTime,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (churchName.present) {
      map['church_name'] = Variable<String>(churchName.value);
    }
    if (meetingStartTime.present) {
      map['meeting_start_time'] = Variable<String>(meetingStartTime.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedServicesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('churchName: $churchName, ')
          ..write('meetingStartTime: $meetingStartTime, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedStagesTable extends CachedStages
    with TableInfo<$CachedStagesTable, CachedStage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedStagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serviceIdMeta = const VerificationMeta(
    'serviceId',
  );
  @override
  late final GeneratedColumn<String> serviceId = GeneratedColumn<String>(
    'service_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, serviceId, name, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_stages';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedStage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('service_id')) {
      context.handle(
        _serviceIdMeta,
        serviceId.isAcceptableOrUnknown(data['service_id']!, _serviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serviceIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedStage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedStage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      serviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}service_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedStagesTable createAlias(String alias) {
    return $CachedStagesTable(attachedDatabase, alias);
  }
}

class CachedStage extends DataClass implements Insertable<CachedStage> {
  final String id;
  final String serviceId;
  final String name;
  final DateTime cachedAt;
  const CachedStage({
    required this.id,
    required this.serviceId,
    required this.name,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['service_id'] = Variable<String>(serviceId);
    map['name'] = Variable<String>(name);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedStagesCompanion toCompanion(bool nullToAbsent) {
    return CachedStagesCompanion(
      id: Value(id),
      serviceId: Value(serviceId),
      name: Value(name),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedStage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedStage(
      id: serializer.fromJson<String>(json['id']),
      serviceId: serializer.fromJson<String>(json['serviceId']),
      name: serializer.fromJson<String>(json['name']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'serviceId': serializer.toJson<String>(serviceId),
      'name': serializer.toJson<String>(name),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedStage copyWith({
    String? id,
    String? serviceId,
    String? name,
    DateTime? cachedAt,
  }) => CachedStage(
    id: id ?? this.id,
    serviceId: serviceId ?? this.serviceId,
    name: name ?? this.name,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedStage copyWithCompanion(CachedStagesCompanion data) {
    return CachedStage(
      id: data.id.present ? data.id.value : this.id,
      serviceId: data.serviceId.present ? data.serviceId.value : this.serviceId,
      name: data.name.present ? data.name.value : this.name,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedStage(')
          ..write('id: $id, ')
          ..write('serviceId: $serviceId, ')
          ..write('name: $name, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, serviceId, name, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedStage &&
          other.id == this.id &&
          other.serviceId == this.serviceId &&
          other.name == this.name &&
          other.cachedAt == this.cachedAt);
}

class CachedStagesCompanion extends UpdateCompanion<CachedStage> {
  final Value<String> id;
  final Value<String> serviceId;
  final Value<String> name;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedStagesCompanion({
    this.id = const Value.absent(),
    this.serviceId = const Value.absent(),
    this.name = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedStagesCompanion.insert({
    required String id,
    required String serviceId,
    required String name,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       serviceId = Value(serviceId),
       name = Value(name),
       cachedAt = Value(cachedAt);
  static Insertable<CachedStage> custom({
    Expression<String>? id,
    Expression<String>? serviceId,
    Expression<String>? name,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serviceId != null) 'service_id': serviceId,
      if (name != null) 'name': name,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedStagesCompanion copyWith({
    Value<String>? id,
    Value<String>? serviceId,
    Value<String>? name,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedStagesCompanion(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      name: name ?? this.name,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (serviceId.present) {
      map['service_id'] = Variable<String>(serviceId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedStagesCompanion(')
          ..write('id: $id, ')
          ..write('serviceId: $serviceId, ')
          ..write('name: $name, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedClassesTable extends CachedClasses
    with TableInfo<$CachedClassesTable, CachedClassesData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedClassesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stageIdMeta = const VerificationMeta(
    'stageId',
  );
  @override
  late final GeneratedColumn<String> stageId = GeneratedColumn<String>(
    'stage_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, stageId, name, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_classes';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedClassesData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('stage_id')) {
      context.handle(
        _stageIdMeta,
        stageId.isAcceptableOrUnknown(data['stage_id']!, _stageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_stageIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedClassesData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedClassesData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      stageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stage_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedClassesTable createAlias(String alias) {
    return $CachedClassesTable(attachedDatabase, alias);
  }
}

class CachedClassesData extends DataClass
    implements Insertable<CachedClassesData> {
  final String id;
  final String stageId;
  final String name;
  final DateTime cachedAt;
  const CachedClassesData({
    required this.id,
    required this.stageId,
    required this.name,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['stage_id'] = Variable<String>(stageId);
    map['name'] = Variable<String>(name);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedClassesCompanion toCompanion(bool nullToAbsent) {
    return CachedClassesCompanion(
      id: Value(id),
      stageId: Value(stageId),
      name: Value(name),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedClassesData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedClassesData(
      id: serializer.fromJson<String>(json['id']),
      stageId: serializer.fromJson<String>(json['stageId']),
      name: serializer.fromJson<String>(json['name']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'stageId': serializer.toJson<String>(stageId),
      'name': serializer.toJson<String>(name),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedClassesData copyWith({
    String? id,
    String? stageId,
    String? name,
    DateTime? cachedAt,
  }) => CachedClassesData(
    id: id ?? this.id,
    stageId: stageId ?? this.stageId,
    name: name ?? this.name,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedClassesData copyWithCompanion(CachedClassesCompanion data) {
    return CachedClassesData(
      id: data.id.present ? data.id.value : this.id,
      stageId: data.stageId.present ? data.stageId.value : this.stageId,
      name: data.name.present ? data.name.value : this.name,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedClassesData(')
          ..write('id: $id, ')
          ..write('stageId: $stageId, ')
          ..write('name: $name, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, stageId, name, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedClassesData &&
          other.id == this.id &&
          other.stageId == this.stageId &&
          other.name == this.name &&
          other.cachedAt == this.cachedAt);
}

class CachedClassesCompanion extends UpdateCompanion<CachedClassesData> {
  final Value<String> id;
  final Value<String> stageId;
  final Value<String> name;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedClassesCompanion({
    this.id = const Value.absent(),
    this.stageId = const Value.absent(),
    this.name = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedClassesCompanion.insert({
    required String id,
    required String stageId,
    required String name,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       stageId = Value(stageId),
       name = Value(name),
       cachedAt = Value(cachedAt);
  static Insertable<CachedClassesData> custom({
    Expression<String>? id,
    Expression<String>? stageId,
    Expression<String>? name,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (stageId != null) 'stage_id': stageId,
      if (name != null) 'name': name,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedClassesCompanion copyWith({
    Value<String>? id,
    Value<String>? stageId,
    Value<String>? name,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedClassesCompanion(
      id: id ?? this.id,
      stageId: stageId ?? this.stageId,
      name: name ?? this.name,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (stageId.present) {
      map['stage_id'] = Variable<String>(stageId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedClassesCompanion(')
          ..write('id: $id, ')
          ..write('stageId: $stageId, ')
          ..write('name: $name, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedStudentsTable extends CachedStudents
    with TableInfo<$CachedStudentsTable, CachedStudent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedStudentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serviceIdMeta = const VerificationMeta(
    'serviceId',
  );
  @override
  late final GeneratedColumn<String> serviceId = GeneratedColumn<String>(
    'service_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentClassIdMeta = const VerificationMeta(
    'currentClassId',
  );
  @override
  late final GeneratedColumn<String> currentClassId = GeneratedColumn<String>(
    'current_class_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _proposedClassIdMeta = const VerificationMeta(
    'proposedClassId',
  );
  @override
  late final GeneratedColumn<String> proposedClassId = GeneratedColumn<String>(
    'proposed_class_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _birthDateMeta = const VerificationMeta(
    'birthDate',
  );
  @override
  late final GeneratedColumn<String> birthDate = GeneratedColumn<String>(
    'birth_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _schoolMeta = const VerificationMeta('school');
  @override
  late final GeneratedColumn<String> school = GeneratedColumn<String>(
    'school',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gradeMeta = const VerificationMeta('grade');
  @override
  late final GeneratedColumn<String> grade = GeneratedColumn<String>(
    'grade',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enrollmentAtMeta = const VerificationMeta(
    'enrollmentAt',
  );
  @override
  late final GeneratedColumn<String> enrollmentAt = GeneratedColumn<String>(
    'enrollment_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _approvalStatusMeta = const VerificationMeta(
    'approvalStatus',
  );
  @override
  late final GeneratedColumn<String> approvalStatus = GeneratedColumn<String>(
    'approval_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _photoPathMeta = const VerificationMeta(
    'photoPath',
  );
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serviceId,
    currentClassId,
    proposedClassId,
    name,
    birthDate,
    phone,
    school,
    grade,
    enrollmentAt,
    approvalStatus,
    photoPath,
    notes,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_students';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedStudent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('service_id')) {
      context.handle(
        _serviceIdMeta,
        serviceId.isAcceptableOrUnknown(data['service_id']!, _serviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serviceIdMeta);
    }
    if (data.containsKey('current_class_id')) {
      context.handle(
        _currentClassIdMeta,
        currentClassId.isAcceptableOrUnknown(
          data['current_class_id']!,
          _currentClassIdMeta,
        ),
      );
    }
    if (data.containsKey('proposed_class_id')) {
      context.handle(
        _proposedClassIdMeta,
        proposedClassId.isAcceptableOrUnknown(
          data['proposed_class_id']!,
          _proposedClassIdMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('birth_date')) {
      context.handle(
        _birthDateMeta,
        birthDate.isAcceptableOrUnknown(data['birth_date']!, _birthDateMeta),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('school')) {
      context.handle(
        _schoolMeta,
        school.isAcceptableOrUnknown(data['school']!, _schoolMeta),
      );
    }
    if (data.containsKey('grade')) {
      context.handle(
        _gradeMeta,
        grade.isAcceptableOrUnknown(data['grade']!, _gradeMeta),
      );
    }
    if (data.containsKey('enrollment_at')) {
      context.handle(
        _enrollmentAtMeta,
        enrollmentAt.isAcceptableOrUnknown(
          data['enrollment_at']!,
          _enrollmentAtMeta,
        ),
      );
    }
    if (data.containsKey('approval_status')) {
      context.handle(
        _approvalStatusMeta,
        approvalStatus.isAcceptableOrUnknown(
          data['approval_status']!,
          _approvalStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_approvalStatusMeta);
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedStudent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedStudent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      serviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}service_id'],
      )!,
      currentClassId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_class_id'],
      ),
      proposedClassId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}proposed_class_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      birthDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}birth_date'],
      ),
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      school: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}school'],
      ),
      grade: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grade'],
      ),
      enrollmentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}enrollment_at'],
      ),
      approvalStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}approval_status'],
      )!,
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedStudentsTable createAlias(String alias) {
    return $CachedStudentsTable(attachedDatabase, alias);
  }
}

class CachedStudent extends DataClass implements Insertable<CachedStudent> {
  final String id;
  final String serviceId;
  final String? currentClassId;
  final String? proposedClassId;
  final String name;
  final String? birthDate;
  final String? phone;
  final String? school;
  final String? grade;
  final String? enrollmentAt;
  final String approvalStatus;
  final String? photoPath;
  final String? notes;
  final DateTime cachedAt;
  const CachedStudent({
    required this.id,
    required this.serviceId,
    this.currentClassId,
    this.proposedClassId,
    required this.name,
    this.birthDate,
    this.phone,
    this.school,
    this.grade,
    this.enrollmentAt,
    required this.approvalStatus,
    this.photoPath,
    this.notes,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['service_id'] = Variable<String>(serviceId);
    if (!nullToAbsent || currentClassId != null) {
      map['current_class_id'] = Variable<String>(currentClassId);
    }
    if (!nullToAbsent || proposedClassId != null) {
      map['proposed_class_id'] = Variable<String>(proposedClassId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || birthDate != null) {
      map['birth_date'] = Variable<String>(birthDate);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || school != null) {
      map['school'] = Variable<String>(school);
    }
    if (!nullToAbsent || grade != null) {
      map['grade'] = Variable<String>(grade);
    }
    if (!nullToAbsent || enrollmentAt != null) {
      map['enrollment_at'] = Variable<String>(enrollmentAt);
    }
    map['approval_status'] = Variable<String>(approvalStatus);
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedStudentsCompanion toCompanion(bool nullToAbsent) {
    return CachedStudentsCompanion(
      id: Value(id),
      serviceId: Value(serviceId),
      currentClassId: currentClassId == null && nullToAbsent
          ? const Value.absent()
          : Value(currentClassId),
      proposedClassId: proposedClassId == null && nullToAbsent
          ? const Value.absent()
          : Value(proposedClassId),
      name: Value(name),
      birthDate: birthDate == null && nullToAbsent
          ? const Value.absent()
          : Value(birthDate),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      school: school == null && nullToAbsent
          ? const Value.absent()
          : Value(school),
      grade: grade == null && nullToAbsent
          ? const Value.absent()
          : Value(grade),
      enrollmentAt: enrollmentAt == null && nullToAbsent
          ? const Value.absent()
          : Value(enrollmentAt),
      approvalStatus: Value(approvalStatus),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedStudent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedStudent(
      id: serializer.fromJson<String>(json['id']),
      serviceId: serializer.fromJson<String>(json['serviceId']),
      currentClassId: serializer.fromJson<String?>(json['currentClassId']),
      proposedClassId: serializer.fromJson<String?>(json['proposedClassId']),
      name: serializer.fromJson<String>(json['name']),
      birthDate: serializer.fromJson<String?>(json['birthDate']),
      phone: serializer.fromJson<String?>(json['phone']),
      school: serializer.fromJson<String?>(json['school']),
      grade: serializer.fromJson<String?>(json['grade']),
      enrollmentAt: serializer.fromJson<String?>(json['enrollmentAt']),
      approvalStatus: serializer.fromJson<String>(json['approvalStatus']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      notes: serializer.fromJson<String?>(json['notes']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'serviceId': serializer.toJson<String>(serviceId),
      'currentClassId': serializer.toJson<String?>(currentClassId),
      'proposedClassId': serializer.toJson<String?>(proposedClassId),
      'name': serializer.toJson<String>(name),
      'birthDate': serializer.toJson<String?>(birthDate),
      'phone': serializer.toJson<String?>(phone),
      'school': serializer.toJson<String?>(school),
      'grade': serializer.toJson<String?>(grade),
      'enrollmentAt': serializer.toJson<String?>(enrollmentAt),
      'approvalStatus': serializer.toJson<String>(approvalStatus),
      'photoPath': serializer.toJson<String?>(photoPath),
      'notes': serializer.toJson<String?>(notes),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedStudent copyWith({
    String? id,
    String? serviceId,
    Value<String?> currentClassId = const Value.absent(),
    Value<String?> proposedClassId = const Value.absent(),
    String? name,
    Value<String?> birthDate = const Value.absent(),
    Value<String?> phone = const Value.absent(),
    Value<String?> school = const Value.absent(),
    Value<String?> grade = const Value.absent(),
    Value<String?> enrollmentAt = const Value.absent(),
    String? approvalStatus,
    Value<String?> photoPath = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? cachedAt,
  }) => CachedStudent(
    id: id ?? this.id,
    serviceId: serviceId ?? this.serviceId,
    currentClassId: currentClassId.present
        ? currentClassId.value
        : this.currentClassId,
    proposedClassId: proposedClassId.present
        ? proposedClassId.value
        : this.proposedClassId,
    name: name ?? this.name,
    birthDate: birthDate.present ? birthDate.value : this.birthDate,
    phone: phone.present ? phone.value : this.phone,
    school: school.present ? school.value : this.school,
    grade: grade.present ? grade.value : this.grade,
    enrollmentAt: enrollmentAt.present ? enrollmentAt.value : this.enrollmentAt,
    approvalStatus: approvalStatus ?? this.approvalStatus,
    photoPath: photoPath.present ? photoPath.value : this.photoPath,
    notes: notes.present ? notes.value : this.notes,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedStudent copyWithCompanion(CachedStudentsCompanion data) {
    return CachedStudent(
      id: data.id.present ? data.id.value : this.id,
      serviceId: data.serviceId.present ? data.serviceId.value : this.serviceId,
      currentClassId: data.currentClassId.present
          ? data.currentClassId.value
          : this.currentClassId,
      proposedClassId: data.proposedClassId.present
          ? data.proposedClassId.value
          : this.proposedClassId,
      name: data.name.present ? data.name.value : this.name,
      birthDate: data.birthDate.present ? data.birthDate.value : this.birthDate,
      phone: data.phone.present ? data.phone.value : this.phone,
      school: data.school.present ? data.school.value : this.school,
      grade: data.grade.present ? data.grade.value : this.grade,
      enrollmentAt: data.enrollmentAt.present
          ? data.enrollmentAt.value
          : this.enrollmentAt,
      approvalStatus: data.approvalStatus.present
          ? data.approvalStatus.value
          : this.approvalStatus,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      notes: data.notes.present ? data.notes.value : this.notes,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedStudent(')
          ..write('id: $id, ')
          ..write('serviceId: $serviceId, ')
          ..write('currentClassId: $currentClassId, ')
          ..write('proposedClassId: $proposedClassId, ')
          ..write('name: $name, ')
          ..write('birthDate: $birthDate, ')
          ..write('phone: $phone, ')
          ..write('school: $school, ')
          ..write('grade: $grade, ')
          ..write('enrollmentAt: $enrollmentAt, ')
          ..write('approvalStatus: $approvalStatus, ')
          ..write('photoPath: $photoPath, ')
          ..write('notes: $notes, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serviceId,
    currentClassId,
    proposedClassId,
    name,
    birthDate,
    phone,
    school,
    grade,
    enrollmentAt,
    approvalStatus,
    photoPath,
    notes,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedStudent &&
          other.id == this.id &&
          other.serviceId == this.serviceId &&
          other.currentClassId == this.currentClassId &&
          other.proposedClassId == this.proposedClassId &&
          other.name == this.name &&
          other.birthDate == this.birthDate &&
          other.phone == this.phone &&
          other.school == this.school &&
          other.grade == this.grade &&
          other.enrollmentAt == this.enrollmentAt &&
          other.approvalStatus == this.approvalStatus &&
          other.photoPath == this.photoPath &&
          other.notes == this.notes &&
          other.cachedAt == this.cachedAt);
}

class CachedStudentsCompanion extends UpdateCompanion<CachedStudent> {
  final Value<String> id;
  final Value<String> serviceId;
  final Value<String?> currentClassId;
  final Value<String?> proposedClassId;
  final Value<String> name;
  final Value<String?> birthDate;
  final Value<String?> phone;
  final Value<String?> school;
  final Value<String?> grade;
  final Value<String?> enrollmentAt;
  final Value<String> approvalStatus;
  final Value<String?> photoPath;
  final Value<String?> notes;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedStudentsCompanion({
    this.id = const Value.absent(),
    this.serviceId = const Value.absent(),
    this.currentClassId = const Value.absent(),
    this.proposedClassId = const Value.absent(),
    this.name = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.phone = const Value.absent(),
    this.school = const Value.absent(),
    this.grade = const Value.absent(),
    this.enrollmentAt = const Value.absent(),
    this.approvalStatus = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.notes = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedStudentsCompanion.insert({
    required String id,
    required String serviceId,
    this.currentClassId = const Value.absent(),
    this.proposedClassId = const Value.absent(),
    required String name,
    this.birthDate = const Value.absent(),
    this.phone = const Value.absent(),
    this.school = const Value.absent(),
    this.grade = const Value.absent(),
    this.enrollmentAt = const Value.absent(),
    required String approvalStatus,
    this.photoPath = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       serviceId = Value(serviceId),
       name = Value(name),
       approvalStatus = Value(approvalStatus),
       cachedAt = Value(cachedAt);
  static Insertable<CachedStudent> custom({
    Expression<String>? id,
    Expression<String>? serviceId,
    Expression<String>? currentClassId,
    Expression<String>? proposedClassId,
    Expression<String>? name,
    Expression<String>? birthDate,
    Expression<String>? phone,
    Expression<String>? school,
    Expression<String>? grade,
    Expression<String>? enrollmentAt,
    Expression<String>? approvalStatus,
    Expression<String>? photoPath,
    Expression<String>? notes,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serviceId != null) 'service_id': serviceId,
      if (currentClassId != null) 'current_class_id': currentClassId,
      if (proposedClassId != null) 'proposed_class_id': proposedClassId,
      if (name != null) 'name': name,
      if (birthDate != null) 'birth_date': birthDate,
      if (phone != null) 'phone': phone,
      if (school != null) 'school': school,
      if (grade != null) 'grade': grade,
      if (enrollmentAt != null) 'enrollment_at': enrollmentAt,
      if (approvalStatus != null) 'approval_status': approvalStatus,
      if (photoPath != null) 'photo_path': photoPath,
      if (notes != null) 'notes': notes,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedStudentsCompanion copyWith({
    Value<String>? id,
    Value<String>? serviceId,
    Value<String?>? currentClassId,
    Value<String?>? proposedClassId,
    Value<String>? name,
    Value<String?>? birthDate,
    Value<String?>? phone,
    Value<String?>? school,
    Value<String?>? grade,
    Value<String?>? enrollmentAt,
    Value<String>? approvalStatus,
    Value<String?>? photoPath,
    Value<String?>? notes,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedStudentsCompanion(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      currentClassId: currentClassId ?? this.currentClassId,
      proposedClassId: proposedClassId ?? this.proposedClassId,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      phone: phone ?? this.phone,
      school: school ?? this.school,
      grade: grade ?? this.grade,
      enrollmentAt: enrollmentAt ?? this.enrollmentAt,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      photoPath: photoPath ?? this.photoPath,
      notes: notes ?? this.notes,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (serviceId.present) {
      map['service_id'] = Variable<String>(serviceId.value);
    }
    if (currentClassId.present) {
      map['current_class_id'] = Variable<String>(currentClassId.value);
    }
    if (proposedClassId.present) {
      map['proposed_class_id'] = Variable<String>(proposedClassId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (birthDate.present) {
      map['birth_date'] = Variable<String>(birthDate.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (school.present) {
      map['school'] = Variable<String>(school.value);
    }
    if (grade.present) {
      map['grade'] = Variable<String>(grade.value);
    }
    if (enrollmentAt.present) {
      map['enrollment_at'] = Variable<String>(enrollmentAt.value);
    }
    if (approvalStatus.present) {
      map['approval_status'] = Variable<String>(approvalStatus.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedStudentsCompanion(')
          ..write('id: $id, ')
          ..write('serviceId: $serviceId, ')
          ..write('currentClassId: $currentClassId, ')
          ..write('proposedClassId: $proposedClassId, ')
          ..write('name: $name, ')
          ..write('birthDate: $birthDate, ')
          ..write('phone: $phone, ')
          ..write('school: $school, ')
          ..write('grade: $grade, ')
          ..write('enrollmentAt: $enrollmentAt, ')
          ..write('approvalStatus: $approvalStatus, ')
          ..write('photoPath: $photoPath, ')
          ..write('notes: $notes, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedMeetingsTable extends CachedMeetings
    with TableInfo<$CachedMeetingsTable, CachedMeeting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedMeetingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serviceIdMeta = const VerificationMeta(
    'serviceId',
  );
  @override
  late final GeneratedColumn<String> serviceId = GeneratedColumn<String>(
    'service_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _meetingDateMeta = const VerificationMeta(
    'meetingDate',
  );
  @override
  late final GeneratedColumn<String> meetingDate = GeneratedColumn<String>(
    'meeting_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serviceId,
    meetingDate,
    startTime,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_meetings';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedMeeting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('service_id')) {
      context.handle(
        _serviceIdMeta,
        serviceId.isAcceptableOrUnknown(data['service_id']!, _serviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serviceIdMeta);
    }
    if (data.containsKey('meeting_date')) {
      context.handle(
        _meetingDateMeta,
        meetingDate.isAcceptableOrUnknown(
          data['meeting_date']!,
          _meetingDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_meetingDateMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedMeeting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedMeeting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      serviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}service_id'],
      )!,
      meetingDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meeting_date'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_time'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedMeetingsTable createAlias(String alias) {
    return $CachedMeetingsTable(attachedDatabase, alias);
  }
}

class CachedMeeting extends DataClass implements Insertable<CachedMeeting> {
  final String id;
  final String serviceId;
  final String meetingDate;
  final String startTime;
  final DateTime cachedAt;
  const CachedMeeting({
    required this.id,
    required this.serviceId,
    required this.meetingDate,
    required this.startTime,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['service_id'] = Variable<String>(serviceId);
    map['meeting_date'] = Variable<String>(meetingDate);
    map['start_time'] = Variable<String>(startTime);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedMeetingsCompanion toCompanion(bool nullToAbsent) {
    return CachedMeetingsCompanion(
      id: Value(id),
      serviceId: Value(serviceId),
      meetingDate: Value(meetingDate),
      startTime: Value(startTime),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedMeeting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedMeeting(
      id: serializer.fromJson<String>(json['id']),
      serviceId: serializer.fromJson<String>(json['serviceId']),
      meetingDate: serializer.fromJson<String>(json['meetingDate']),
      startTime: serializer.fromJson<String>(json['startTime']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'serviceId': serializer.toJson<String>(serviceId),
      'meetingDate': serializer.toJson<String>(meetingDate),
      'startTime': serializer.toJson<String>(startTime),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedMeeting copyWith({
    String? id,
    String? serviceId,
    String? meetingDate,
    String? startTime,
    DateTime? cachedAt,
  }) => CachedMeeting(
    id: id ?? this.id,
    serviceId: serviceId ?? this.serviceId,
    meetingDate: meetingDate ?? this.meetingDate,
    startTime: startTime ?? this.startTime,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedMeeting copyWithCompanion(CachedMeetingsCompanion data) {
    return CachedMeeting(
      id: data.id.present ? data.id.value : this.id,
      serviceId: data.serviceId.present ? data.serviceId.value : this.serviceId,
      meetingDate: data.meetingDate.present
          ? data.meetingDate.value
          : this.meetingDate,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedMeeting(')
          ..write('id: $id, ')
          ..write('serviceId: $serviceId, ')
          ..write('meetingDate: $meetingDate, ')
          ..write('startTime: $startTime, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, serviceId, meetingDate, startTime, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedMeeting &&
          other.id == this.id &&
          other.serviceId == this.serviceId &&
          other.meetingDate == this.meetingDate &&
          other.startTime == this.startTime &&
          other.cachedAt == this.cachedAt);
}

class CachedMeetingsCompanion extends UpdateCompanion<CachedMeeting> {
  final Value<String> id;
  final Value<String> serviceId;
  final Value<String> meetingDate;
  final Value<String> startTime;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedMeetingsCompanion({
    this.id = const Value.absent(),
    this.serviceId = const Value.absent(),
    this.meetingDate = const Value.absent(),
    this.startTime = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedMeetingsCompanion.insert({
    required String id,
    required String serviceId,
    required String meetingDate,
    required String startTime,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       serviceId = Value(serviceId),
       meetingDate = Value(meetingDate),
       startTime = Value(startTime),
       cachedAt = Value(cachedAt);
  static Insertable<CachedMeeting> custom({
    Expression<String>? id,
    Expression<String>? serviceId,
    Expression<String>? meetingDate,
    Expression<String>? startTime,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serviceId != null) 'service_id': serviceId,
      if (meetingDate != null) 'meeting_date': meetingDate,
      if (startTime != null) 'start_time': startTime,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedMeetingsCompanion copyWith({
    Value<String>? id,
    Value<String>? serviceId,
    Value<String>? meetingDate,
    Value<String>? startTime,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedMeetingsCompanion(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      meetingDate: meetingDate ?? this.meetingDate,
      startTime: startTime ?? this.startTime,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (serviceId.present) {
      map['service_id'] = Variable<String>(serviceId.value);
    }
    if (meetingDate.present) {
      map['meeting_date'] = Variable<String>(meetingDate.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedMeetingsCompanion(')
          ..write('id: $id, ')
          ..write('serviceId: $serviceId, ')
          ..write('meetingDate: $meetingDate, ')
          ..write('startTime: $startTime, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedAttendanceRecordsTable extends CachedAttendanceRecords
    with TableInfo<$CachedAttendanceRecordsTable, CachedAttendanceRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedAttendanceRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _meetingIdMeta = const VerificationMeta(
    'meetingId',
  );
  @override
  late final GeneratedColumn<String> meetingId = GeneratedColumn<String>(
    'meeting_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _studentIdMeta = const VerificationMeta(
    'studentId',
  );
  @override
  late final GeneratedColumn<String> studentId = GeneratedColumn<String>(
    'student_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _classIdAtAttendanceMeta =
      const VerificationMeta('classIdAtAttendance');
  @override
  late final GeneratedColumn<String> classIdAtAttendance =
      GeneratedColumn<String>(
        'class_id_at_attendance',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _checkedInAtMeta = const VerificationMeta(
    'checkedInAt',
  );
  @override
  late final GeneratedColumn<DateTime> checkedInAt = GeneratedColumn<DateTime>(
    'checked_in_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedByMeta = const VerificationMeta(
    'recordedBy',
  );
  @override
  late final GeneratedColumn<String> recordedBy = GeneratedColumn<String>(
    'recorded_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientOperationIdMeta = const VerificationMeta(
    'clientOperationId',
  );
  @override
  late final GeneratedColumn<String> clientOperationId =
      GeneratedColumn<String>(
        'client_operation_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _syncStateMeta = const VerificationMeta(
    'syncState',
  );
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
    'sync_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    meetingId,
    studentId,
    classIdAtAttendance,
    checkedInAt,
    recordedBy,
    clientOperationId,
    syncState,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_attendance_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedAttendanceRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('meeting_id')) {
      context.handle(
        _meetingIdMeta,
        meetingId.isAcceptableOrUnknown(data['meeting_id']!, _meetingIdMeta),
      );
    } else if (isInserting) {
      context.missing(_meetingIdMeta);
    }
    if (data.containsKey('student_id')) {
      context.handle(
        _studentIdMeta,
        studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_studentIdMeta);
    }
    if (data.containsKey('class_id_at_attendance')) {
      context.handle(
        _classIdAtAttendanceMeta,
        classIdAtAttendance.isAcceptableOrUnknown(
          data['class_id_at_attendance']!,
          _classIdAtAttendanceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_classIdAtAttendanceMeta);
    }
    if (data.containsKey('checked_in_at')) {
      context.handle(
        _checkedInAtMeta,
        checkedInAt.isAcceptableOrUnknown(
          data['checked_in_at']!,
          _checkedInAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_checkedInAtMeta);
    }
    if (data.containsKey('recorded_by')) {
      context.handle(
        _recordedByMeta,
        recordedBy.isAcceptableOrUnknown(data['recorded_by']!, _recordedByMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedByMeta);
    }
    if (data.containsKey('client_operation_id')) {
      context.handle(
        _clientOperationIdMeta,
        clientOperationId.isAcceptableOrUnknown(
          data['client_operation_id']!,
          _clientOperationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientOperationIdMeta);
    }
    if (data.containsKey('sync_state')) {
      context.handle(
        _syncStateMeta,
        syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedAttendanceRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedAttendanceRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      meetingId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meeting_id'],
      )!,
      studentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}student_id'],
      )!,
      classIdAtAttendance: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}class_id_at_attendance'],
      )!,
      checkedInAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}checked_in_at'],
      )!,
      recordedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recorded_by'],
      )!,
      clientOperationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_operation_id'],
      )!,
      syncState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_state'],
      )!,
    );
  }

  @override
  $CachedAttendanceRecordsTable createAlias(String alias) {
    return $CachedAttendanceRecordsTable(attachedDatabase, alias);
  }
}

class CachedAttendanceRecord extends DataClass
    implements Insertable<CachedAttendanceRecord> {
  final String id;
  final String meetingId;
  final String studentId;
  final String classIdAtAttendance;
  final DateTime checkedInAt;
  final String recordedBy;
  final String clientOperationId;
  final String syncState;
  const CachedAttendanceRecord({
    required this.id,
    required this.meetingId,
    required this.studentId,
    required this.classIdAtAttendance,
    required this.checkedInAt,
    required this.recordedBy,
    required this.clientOperationId,
    required this.syncState,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['meeting_id'] = Variable<String>(meetingId);
    map['student_id'] = Variable<String>(studentId);
    map['class_id_at_attendance'] = Variable<String>(classIdAtAttendance);
    map['checked_in_at'] = Variable<DateTime>(checkedInAt);
    map['recorded_by'] = Variable<String>(recordedBy);
    map['client_operation_id'] = Variable<String>(clientOperationId);
    map['sync_state'] = Variable<String>(syncState);
    return map;
  }

  CachedAttendanceRecordsCompanion toCompanion(bool nullToAbsent) {
    return CachedAttendanceRecordsCompanion(
      id: Value(id),
      meetingId: Value(meetingId),
      studentId: Value(studentId),
      classIdAtAttendance: Value(classIdAtAttendance),
      checkedInAt: Value(checkedInAt),
      recordedBy: Value(recordedBy),
      clientOperationId: Value(clientOperationId),
      syncState: Value(syncState),
    );
  }

  factory CachedAttendanceRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedAttendanceRecord(
      id: serializer.fromJson<String>(json['id']),
      meetingId: serializer.fromJson<String>(json['meetingId']),
      studentId: serializer.fromJson<String>(json['studentId']),
      classIdAtAttendance: serializer.fromJson<String>(
        json['classIdAtAttendance'],
      ),
      checkedInAt: serializer.fromJson<DateTime>(json['checkedInAt']),
      recordedBy: serializer.fromJson<String>(json['recordedBy']),
      clientOperationId: serializer.fromJson<String>(json['clientOperationId']),
      syncState: serializer.fromJson<String>(json['syncState']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'meetingId': serializer.toJson<String>(meetingId),
      'studentId': serializer.toJson<String>(studentId),
      'classIdAtAttendance': serializer.toJson<String>(classIdAtAttendance),
      'checkedInAt': serializer.toJson<DateTime>(checkedInAt),
      'recordedBy': serializer.toJson<String>(recordedBy),
      'clientOperationId': serializer.toJson<String>(clientOperationId),
      'syncState': serializer.toJson<String>(syncState),
    };
  }

  CachedAttendanceRecord copyWith({
    String? id,
    String? meetingId,
    String? studentId,
    String? classIdAtAttendance,
    DateTime? checkedInAt,
    String? recordedBy,
    String? clientOperationId,
    String? syncState,
  }) => CachedAttendanceRecord(
    id: id ?? this.id,
    meetingId: meetingId ?? this.meetingId,
    studentId: studentId ?? this.studentId,
    classIdAtAttendance: classIdAtAttendance ?? this.classIdAtAttendance,
    checkedInAt: checkedInAt ?? this.checkedInAt,
    recordedBy: recordedBy ?? this.recordedBy,
    clientOperationId: clientOperationId ?? this.clientOperationId,
    syncState: syncState ?? this.syncState,
  );
  CachedAttendanceRecord copyWithCompanion(
    CachedAttendanceRecordsCompanion data,
  ) {
    return CachedAttendanceRecord(
      id: data.id.present ? data.id.value : this.id,
      meetingId: data.meetingId.present ? data.meetingId.value : this.meetingId,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      classIdAtAttendance: data.classIdAtAttendance.present
          ? data.classIdAtAttendance.value
          : this.classIdAtAttendance,
      checkedInAt: data.checkedInAt.present
          ? data.checkedInAt.value
          : this.checkedInAt,
      recordedBy: data.recordedBy.present
          ? data.recordedBy.value
          : this.recordedBy,
      clientOperationId: data.clientOperationId.present
          ? data.clientOperationId.value
          : this.clientOperationId,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedAttendanceRecord(')
          ..write('id: $id, ')
          ..write('meetingId: $meetingId, ')
          ..write('studentId: $studentId, ')
          ..write('classIdAtAttendance: $classIdAtAttendance, ')
          ..write('checkedInAt: $checkedInAt, ')
          ..write('recordedBy: $recordedBy, ')
          ..write('clientOperationId: $clientOperationId, ')
          ..write('syncState: $syncState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    meetingId,
    studentId,
    classIdAtAttendance,
    checkedInAt,
    recordedBy,
    clientOperationId,
    syncState,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedAttendanceRecord &&
          other.id == this.id &&
          other.meetingId == this.meetingId &&
          other.studentId == this.studentId &&
          other.classIdAtAttendance == this.classIdAtAttendance &&
          other.checkedInAt == this.checkedInAt &&
          other.recordedBy == this.recordedBy &&
          other.clientOperationId == this.clientOperationId &&
          other.syncState == this.syncState);
}

class CachedAttendanceRecordsCompanion
    extends UpdateCompanion<CachedAttendanceRecord> {
  final Value<String> id;
  final Value<String> meetingId;
  final Value<String> studentId;
  final Value<String> classIdAtAttendance;
  final Value<DateTime> checkedInAt;
  final Value<String> recordedBy;
  final Value<String> clientOperationId;
  final Value<String> syncState;
  final Value<int> rowid;
  const CachedAttendanceRecordsCompanion({
    this.id = const Value.absent(),
    this.meetingId = const Value.absent(),
    this.studentId = const Value.absent(),
    this.classIdAtAttendance = const Value.absent(),
    this.checkedInAt = const Value.absent(),
    this.recordedBy = const Value.absent(),
    this.clientOperationId = const Value.absent(),
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedAttendanceRecordsCompanion.insert({
    required String id,
    required String meetingId,
    required String studentId,
    required String classIdAtAttendance,
    required DateTime checkedInAt,
    required String recordedBy,
    required String clientOperationId,
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       meetingId = Value(meetingId),
       studentId = Value(studentId),
       classIdAtAttendance = Value(classIdAtAttendance),
       checkedInAt = Value(checkedInAt),
       recordedBy = Value(recordedBy),
       clientOperationId = Value(clientOperationId);
  static Insertable<CachedAttendanceRecord> custom({
    Expression<String>? id,
    Expression<String>? meetingId,
    Expression<String>? studentId,
    Expression<String>? classIdAtAttendance,
    Expression<DateTime>? checkedInAt,
    Expression<String>? recordedBy,
    Expression<String>? clientOperationId,
    Expression<String>? syncState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (meetingId != null) 'meeting_id': meetingId,
      if (studentId != null) 'student_id': studentId,
      if (classIdAtAttendance != null)
        'class_id_at_attendance': classIdAtAttendance,
      if (checkedInAt != null) 'checked_in_at': checkedInAt,
      if (recordedBy != null) 'recorded_by': recordedBy,
      if (clientOperationId != null) 'client_operation_id': clientOperationId,
      if (syncState != null) 'sync_state': syncState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedAttendanceRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? meetingId,
    Value<String>? studentId,
    Value<String>? classIdAtAttendance,
    Value<DateTime>? checkedInAt,
    Value<String>? recordedBy,
    Value<String>? clientOperationId,
    Value<String>? syncState,
    Value<int>? rowid,
  }) {
    return CachedAttendanceRecordsCompanion(
      id: id ?? this.id,
      meetingId: meetingId ?? this.meetingId,
      studentId: studentId ?? this.studentId,
      classIdAtAttendance: classIdAtAttendance ?? this.classIdAtAttendance,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      recordedBy: recordedBy ?? this.recordedBy,
      clientOperationId: clientOperationId ?? this.clientOperationId,
      syncState: syncState ?? this.syncState,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (meetingId.present) {
      map['meeting_id'] = Variable<String>(meetingId.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<String>(studentId.value);
    }
    if (classIdAtAttendance.present) {
      map['class_id_at_attendance'] = Variable<String>(
        classIdAtAttendance.value,
      );
    }
    if (checkedInAt.present) {
      map['checked_in_at'] = Variable<DateTime>(checkedInAt.value);
    }
    if (recordedBy.present) {
      map['recorded_by'] = Variable<String>(recordedBy.value);
    }
    if (clientOperationId.present) {
      map['client_operation_id'] = Variable<String>(clientOperationId.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedAttendanceRecordsCompanion(')
          ..write('id: $id, ')
          ..write('meetingId: $meetingId, ')
          ..write('studentId: $studentId, ')
          ..write('classIdAtAttendance: $classIdAtAttendance, ')
          ..write('checkedInAt: $checkedInAt, ')
          ..write('recordedBy: $recordedBy, ')
          ..write('clientOperationId: $clientOperationId, ')
          ..write('syncState: $syncState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedFollowUpRecordsTable extends CachedFollowUpRecords
    with TableInfo<$CachedFollowUpRecordsTable, CachedFollowUpRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedFollowUpRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _studentIdMeta = const VerificationMeta(
    'studentId',
  );
  @override
  late final GeneratedColumn<String> studentId = GeneratedColumn<String>(
    'student_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _followUpDateMeta = const VerificationMeta(
    'followUpDate',
  );
  @override
  late final GeneratedColumn<String> followUpDate = GeneratedColumn<String>(
    'follow_up_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contactStatusMeta = const VerificationMeta(
    'contactStatus',
  );
  @override
  late final GeneratedColumn<String> contactStatus = GeneratedColumn<String>(
    'contact_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contactMethodMeta = const VerificationMeta(
    'contactMethod',
  );
  @override
  late final GeneratedColumn<String> contactMethod = GeneratedColumn<String>(
    'contact_method',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _absenceReasonMeta = const VerificationMeta(
    'absenceReason',
  );
  @override
  late final GeneratedColumn<String> absenceReason = GeneratedColumn<String>(
    'absence_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _studentResponseMeta = const VerificationMeta(
    'studentResponse',
  );
  @override
  late final GeneratedColumn<String> studentResponse = GeneratedColumn<String>(
    'student_response',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parentResponseMeta = const VerificationMeta(
    'parentResponse',
  );
  @override
  late final GeneratedColumn<String> parentResponse = GeneratedColumn<String>(
    'parent_response',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actionRequiredMeta = const VerificationMeta(
    'actionRequired',
  );
  @override
  late final GeneratedColumn<String> actionRequired = GeneratedColumn<String>(
    'action_required',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _anotherFollowUpNeededMeta =
      const VerificationMeta('anotherFollowUpNeeded');
  @override
  late final GeneratedColumn<bool> anotherFollowUpNeeded =
      GeneratedColumn<bool>(
        'another_follow_up_needed',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("another_follow_up_needed" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _nextFollowUpDateMeta = const VerificationMeta(
    'nextFollowUpDate',
  );
  @override
  late final GeneratedColumn<String> nextFollowUpDate = GeneratedColumn<String>(
    'next_follow_up_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientOperationIdMeta = const VerificationMeta(
    'clientOperationId',
  );
  @override
  late final GeneratedColumn<String> clientOperationId =
      GeneratedColumn<String>(
        'client_operation_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    studentId,
    createdBy,
    followUpDate,
    contactStatus,
    contactMethod,
    absenceReason,
    studentResponse,
    parentResponse,
    actionRequired,
    notes,
    anotherFollowUpNeeded,
    nextFollowUpDate,
    clientOperationId,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_follow_up_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedFollowUpRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('student_id')) {
      context.handle(
        _studentIdMeta,
        studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_studentIdMeta);
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    } else if (isInserting) {
      context.missing(_createdByMeta);
    }
    if (data.containsKey('follow_up_date')) {
      context.handle(
        _followUpDateMeta,
        followUpDate.isAcceptableOrUnknown(
          data['follow_up_date']!,
          _followUpDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_followUpDateMeta);
    }
    if (data.containsKey('contact_status')) {
      context.handle(
        _contactStatusMeta,
        contactStatus.isAcceptableOrUnknown(
          data['contact_status']!,
          _contactStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contactStatusMeta);
    }
    if (data.containsKey('contact_method')) {
      context.handle(
        _contactMethodMeta,
        contactMethod.isAcceptableOrUnknown(
          data['contact_method']!,
          _contactMethodMeta,
        ),
      );
    }
    if (data.containsKey('absence_reason')) {
      context.handle(
        _absenceReasonMeta,
        absenceReason.isAcceptableOrUnknown(
          data['absence_reason']!,
          _absenceReasonMeta,
        ),
      );
    }
    if (data.containsKey('student_response')) {
      context.handle(
        _studentResponseMeta,
        studentResponse.isAcceptableOrUnknown(
          data['student_response']!,
          _studentResponseMeta,
        ),
      );
    }
    if (data.containsKey('parent_response')) {
      context.handle(
        _parentResponseMeta,
        parentResponse.isAcceptableOrUnknown(
          data['parent_response']!,
          _parentResponseMeta,
        ),
      );
    }
    if (data.containsKey('action_required')) {
      context.handle(
        _actionRequiredMeta,
        actionRequired.isAcceptableOrUnknown(
          data['action_required']!,
          _actionRequiredMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('another_follow_up_needed')) {
      context.handle(
        _anotherFollowUpNeededMeta,
        anotherFollowUpNeeded.isAcceptableOrUnknown(
          data['another_follow_up_needed']!,
          _anotherFollowUpNeededMeta,
        ),
      );
    }
    if (data.containsKey('next_follow_up_date')) {
      context.handle(
        _nextFollowUpDateMeta,
        nextFollowUpDate.isAcceptableOrUnknown(
          data['next_follow_up_date']!,
          _nextFollowUpDateMeta,
        ),
      );
    }
    if (data.containsKey('client_operation_id')) {
      context.handle(
        _clientOperationIdMeta,
        clientOperationId.isAcceptableOrUnknown(
          data['client_operation_id']!,
          _clientOperationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientOperationIdMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedFollowUpRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedFollowUpRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      studentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}student_id'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      )!,
      followUpDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}follow_up_date'],
      )!,
      contactStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_status'],
      )!,
      contactMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_method'],
      ),
      absenceReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}absence_reason'],
      ),
      studentResponse: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}student_response'],
      ),
      parentResponse: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_response'],
      ),
      actionRequired: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action_required'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      anotherFollowUpNeeded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}another_follow_up_needed'],
      )!,
      nextFollowUpDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}next_follow_up_date'],
      ),
      clientOperationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_operation_id'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedFollowUpRecordsTable createAlias(String alias) {
    return $CachedFollowUpRecordsTable(attachedDatabase, alias);
  }
}

class CachedFollowUpRecord extends DataClass
    implements Insertable<CachedFollowUpRecord> {
  final String id;
  final String studentId;
  final String createdBy;
  final String followUpDate;
  final String contactStatus;
  final String? contactMethod;
  final String? absenceReason;
  final String? studentResponse;
  final String? parentResponse;
  final String? actionRequired;
  final String? notes;
  final bool anotherFollowUpNeeded;
  final String? nextFollowUpDate;
  final String clientOperationId;
  final DateTime cachedAt;
  const CachedFollowUpRecord({
    required this.id,
    required this.studentId,
    required this.createdBy,
    required this.followUpDate,
    required this.contactStatus,
    this.contactMethod,
    this.absenceReason,
    this.studentResponse,
    this.parentResponse,
    this.actionRequired,
    this.notes,
    required this.anotherFollowUpNeeded,
    this.nextFollowUpDate,
    required this.clientOperationId,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['student_id'] = Variable<String>(studentId);
    map['created_by'] = Variable<String>(createdBy);
    map['follow_up_date'] = Variable<String>(followUpDate);
    map['contact_status'] = Variable<String>(contactStatus);
    if (!nullToAbsent || contactMethod != null) {
      map['contact_method'] = Variable<String>(contactMethod);
    }
    if (!nullToAbsent || absenceReason != null) {
      map['absence_reason'] = Variable<String>(absenceReason);
    }
    if (!nullToAbsent || studentResponse != null) {
      map['student_response'] = Variable<String>(studentResponse);
    }
    if (!nullToAbsent || parentResponse != null) {
      map['parent_response'] = Variable<String>(parentResponse);
    }
    if (!nullToAbsent || actionRequired != null) {
      map['action_required'] = Variable<String>(actionRequired);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['another_follow_up_needed'] = Variable<bool>(anotherFollowUpNeeded);
    if (!nullToAbsent || nextFollowUpDate != null) {
      map['next_follow_up_date'] = Variable<String>(nextFollowUpDate);
    }
    map['client_operation_id'] = Variable<String>(clientOperationId);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedFollowUpRecordsCompanion toCompanion(bool nullToAbsent) {
    return CachedFollowUpRecordsCompanion(
      id: Value(id),
      studentId: Value(studentId),
      createdBy: Value(createdBy),
      followUpDate: Value(followUpDate),
      contactStatus: Value(contactStatus),
      contactMethod: contactMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(contactMethod),
      absenceReason: absenceReason == null && nullToAbsent
          ? const Value.absent()
          : Value(absenceReason),
      studentResponse: studentResponse == null && nullToAbsent
          ? const Value.absent()
          : Value(studentResponse),
      parentResponse: parentResponse == null && nullToAbsent
          ? const Value.absent()
          : Value(parentResponse),
      actionRequired: actionRequired == null && nullToAbsent
          ? const Value.absent()
          : Value(actionRequired),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      anotherFollowUpNeeded: Value(anotherFollowUpNeeded),
      nextFollowUpDate: nextFollowUpDate == null && nullToAbsent
          ? const Value.absent()
          : Value(nextFollowUpDate),
      clientOperationId: Value(clientOperationId),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedFollowUpRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedFollowUpRecord(
      id: serializer.fromJson<String>(json['id']),
      studentId: serializer.fromJson<String>(json['studentId']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      followUpDate: serializer.fromJson<String>(json['followUpDate']),
      contactStatus: serializer.fromJson<String>(json['contactStatus']),
      contactMethod: serializer.fromJson<String?>(json['contactMethod']),
      absenceReason: serializer.fromJson<String?>(json['absenceReason']),
      studentResponse: serializer.fromJson<String?>(json['studentResponse']),
      parentResponse: serializer.fromJson<String?>(json['parentResponse']),
      actionRequired: serializer.fromJson<String?>(json['actionRequired']),
      notes: serializer.fromJson<String?>(json['notes']),
      anotherFollowUpNeeded: serializer.fromJson<bool>(
        json['anotherFollowUpNeeded'],
      ),
      nextFollowUpDate: serializer.fromJson<String?>(json['nextFollowUpDate']),
      clientOperationId: serializer.fromJson<String>(json['clientOperationId']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'studentId': serializer.toJson<String>(studentId),
      'createdBy': serializer.toJson<String>(createdBy),
      'followUpDate': serializer.toJson<String>(followUpDate),
      'contactStatus': serializer.toJson<String>(contactStatus),
      'contactMethod': serializer.toJson<String?>(contactMethod),
      'absenceReason': serializer.toJson<String?>(absenceReason),
      'studentResponse': serializer.toJson<String?>(studentResponse),
      'parentResponse': serializer.toJson<String?>(parentResponse),
      'actionRequired': serializer.toJson<String?>(actionRequired),
      'notes': serializer.toJson<String?>(notes),
      'anotherFollowUpNeeded': serializer.toJson<bool>(anotherFollowUpNeeded),
      'nextFollowUpDate': serializer.toJson<String?>(nextFollowUpDate),
      'clientOperationId': serializer.toJson<String>(clientOperationId),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedFollowUpRecord copyWith({
    String? id,
    String? studentId,
    String? createdBy,
    String? followUpDate,
    String? contactStatus,
    Value<String?> contactMethod = const Value.absent(),
    Value<String?> absenceReason = const Value.absent(),
    Value<String?> studentResponse = const Value.absent(),
    Value<String?> parentResponse = const Value.absent(),
    Value<String?> actionRequired = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    bool? anotherFollowUpNeeded,
    Value<String?> nextFollowUpDate = const Value.absent(),
    String? clientOperationId,
    DateTime? cachedAt,
  }) => CachedFollowUpRecord(
    id: id ?? this.id,
    studentId: studentId ?? this.studentId,
    createdBy: createdBy ?? this.createdBy,
    followUpDate: followUpDate ?? this.followUpDate,
    contactStatus: contactStatus ?? this.contactStatus,
    contactMethod: contactMethod.present
        ? contactMethod.value
        : this.contactMethod,
    absenceReason: absenceReason.present
        ? absenceReason.value
        : this.absenceReason,
    studentResponse: studentResponse.present
        ? studentResponse.value
        : this.studentResponse,
    parentResponse: parentResponse.present
        ? parentResponse.value
        : this.parentResponse,
    actionRequired: actionRequired.present
        ? actionRequired.value
        : this.actionRequired,
    notes: notes.present ? notes.value : this.notes,
    anotherFollowUpNeeded: anotherFollowUpNeeded ?? this.anotherFollowUpNeeded,
    nextFollowUpDate: nextFollowUpDate.present
        ? nextFollowUpDate.value
        : this.nextFollowUpDate,
    clientOperationId: clientOperationId ?? this.clientOperationId,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedFollowUpRecord copyWithCompanion(CachedFollowUpRecordsCompanion data) {
    return CachedFollowUpRecord(
      id: data.id.present ? data.id.value : this.id,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      followUpDate: data.followUpDate.present
          ? data.followUpDate.value
          : this.followUpDate,
      contactStatus: data.contactStatus.present
          ? data.contactStatus.value
          : this.contactStatus,
      contactMethod: data.contactMethod.present
          ? data.contactMethod.value
          : this.contactMethod,
      absenceReason: data.absenceReason.present
          ? data.absenceReason.value
          : this.absenceReason,
      studentResponse: data.studentResponse.present
          ? data.studentResponse.value
          : this.studentResponse,
      parentResponse: data.parentResponse.present
          ? data.parentResponse.value
          : this.parentResponse,
      actionRequired: data.actionRequired.present
          ? data.actionRequired.value
          : this.actionRequired,
      notes: data.notes.present ? data.notes.value : this.notes,
      anotherFollowUpNeeded: data.anotherFollowUpNeeded.present
          ? data.anotherFollowUpNeeded.value
          : this.anotherFollowUpNeeded,
      nextFollowUpDate: data.nextFollowUpDate.present
          ? data.nextFollowUpDate.value
          : this.nextFollowUpDate,
      clientOperationId: data.clientOperationId.present
          ? data.clientOperationId.value
          : this.clientOperationId,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedFollowUpRecord(')
          ..write('id: $id, ')
          ..write('studentId: $studentId, ')
          ..write('createdBy: $createdBy, ')
          ..write('followUpDate: $followUpDate, ')
          ..write('contactStatus: $contactStatus, ')
          ..write('contactMethod: $contactMethod, ')
          ..write('absenceReason: $absenceReason, ')
          ..write('studentResponse: $studentResponse, ')
          ..write('parentResponse: $parentResponse, ')
          ..write('actionRequired: $actionRequired, ')
          ..write('notes: $notes, ')
          ..write('anotherFollowUpNeeded: $anotherFollowUpNeeded, ')
          ..write('nextFollowUpDate: $nextFollowUpDate, ')
          ..write('clientOperationId: $clientOperationId, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    studentId,
    createdBy,
    followUpDate,
    contactStatus,
    contactMethod,
    absenceReason,
    studentResponse,
    parentResponse,
    actionRequired,
    notes,
    anotherFollowUpNeeded,
    nextFollowUpDate,
    clientOperationId,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedFollowUpRecord &&
          other.id == this.id &&
          other.studentId == this.studentId &&
          other.createdBy == this.createdBy &&
          other.followUpDate == this.followUpDate &&
          other.contactStatus == this.contactStatus &&
          other.contactMethod == this.contactMethod &&
          other.absenceReason == this.absenceReason &&
          other.studentResponse == this.studentResponse &&
          other.parentResponse == this.parentResponse &&
          other.actionRequired == this.actionRequired &&
          other.notes == this.notes &&
          other.anotherFollowUpNeeded == this.anotherFollowUpNeeded &&
          other.nextFollowUpDate == this.nextFollowUpDate &&
          other.clientOperationId == this.clientOperationId &&
          other.cachedAt == this.cachedAt);
}

class CachedFollowUpRecordsCompanion
    extends UpdateCompanion<CachedFollowUpRecord> {
  final Value<String> id;
  final Value<String> studentId;
  final Value<String> createdBy;
  final Value<String> followUpDate;
  final Value<String> contactStatus;
  final Value<String?> contactMethod;
  final Value<String?> absenceReason;
  final Value<String?> studentResponse;
  final Value<String?> parentResponse;
  final Value<String?> actionRequired;
  final Value<String?> notes;
  final Value<bool> anotherFollowUpNeeded;
  final Value<String?> nextFollowUpDate;
  final Value<String> clientOperationId;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedFollowUpRecordsCompanion({
    this.id = const Value.absent(),
    this.studentId = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.followUpDate = const Value.absent(),
    this.contactStatus = const Value.absent(),
    this.contactMethod = const Value.absent(),
    this.absenceReason = const Value.absent(),
    this.studentResponse = const Value.absent(),
    this.parentResponse = const Value.absent(),
    this.actionRequired = const Value.absent(),
    this.notes = const Value.absent(),
    this.anotherFollowUpNeeded = const Value.absent(),
    this.nextFollowUpDate = const Value.absent(),
    this.clientOperationId = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedFollowUpRecordsCompanion.insert({
    required String id,
    required String studentId,
    required String createdBy,
    required String followUpDate,
    required String contactStatus,
    this.contactMethod = const Value.absent(),
    this.absenceReason = const Value.absent(),
    this.studentResponse = const Value.absent(),
    this.parentResponse = const Value.absent(),
    this.actionRequired = const Value.absent(),
    this.notes = const Value.absent(),
    this.anotherFollowUpNeeded = const Value.absent(),
    this.nextFollowUpDate = const Value.absent(),
    required String clientOperationId,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       studentId = Value(studentId),
       createdBy = Value(createdBy),
       followUpDate = Value(followUpDate),
       contactStatus = Value(contactStatus),
       clientOperationId = Value(clientOperationId),
       cachedAt = Value(cachedAt);
  static Insertable<CachedFollowUpRecord> custom({
    Expression<String>? id,
    Expression<String>? studentId,
    Expression<String>? createdBy,
    Expression<String>? followUpDate,
    Expression<String>? contactStatus,
    Expression<String>? contactMethod,
    Expression<String>? absenceReason,
    Expression<String>? studentResponse,
    Expression<String>? parentResponse,
    Expression<String>? actionRequired,
    Expression<String>? notes,
    Expression<bool>? anotherFollowUpNeeded,
    Expression<String>? nextFollowUpDate,
    Expression<String>? clientOperationId,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (studentId != null) 'student_id': studentId,
      if (createdBy != null) 'created_by': createdBy,
      if (followUpDate != null) 'follow_up_date': followUpDate,
      if (contactStatus != null) 'contact_status': contactStatus,
      if (contactMethod != null) 'contact_method': contactMethod,
      if (absenceReason != null) 'absence_reason': absenceReason,
      if (studentResponse != null) 'student_response': studentResponse,
      if (parentResponse != null) 'parent_response': parentResponse,
      if (actionRequired != null) 'action_required': actionRequired,
      if (notes != null) 'notes': notes,
      if (anotherFollowUpNeeded != null)
        'another_follow_up_needed': anotherFollowUpNeeded,
      if (nextFollowUpDate != null) 'next_follow_up_date': nextFollowUpDate,
      if (clientOperationId != null) 'client_operation_id': clientOperationId,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedFollowUpRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? studentId,
    Value<String>? createdBy,
    Value<String>? followUpDate,
    Value<String>? contactStatus,
    Value<String?>? contactMethod,
    Value<String?>? absenceReason,
    Value<String?>? studentResponse,
    Value<String?>? parentResponse,
    Value<String?>? actionRequired,
    Value<String?>? notes,
    Value<bool>? anotherFollowUpNeeded,
    Value<String?>? nextFollowUpDate,
    Value<String>? clientOperationId,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedFollowUpRecordsCompanion(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      createdBy: createdBy ?? this.createdBy,
      followUpDate: followUpDate ?? this.followUpDate,
      contactStatus: contactStatus ?? this.contactStatus,
      contactMethod: contactMethod ?? this.contactMethod,
      absenceReason: absenceReason ?? this.absenceReason,
      studentResponse: studentResponse ?? this.studentResponse,
      parentResponse: parentResponse ?? this.parentResponse,
      actionRequired: actionRequired ?? this.actionRequired,
      notes: notes ?? this.notes,
      anotherFollowUpNeeded:
          anotherFollowUpNeeded ?? this.anotherFollowUpNeeded,
      nextFollowUpDate: nextFollowUpDate ?? this.nextFollowUpDate,
      clientOperationId: clientOperationId ?? this.clientOperationId,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<String>(studentId.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (followUpDate.present) {
      map['follow_up_date'] = Variable<String>(followUpDate.value);
    }
    if (contactStatus.present) {
      map['contact_status'] = Variable<String>(contactStatus.value);
    }
    if (contactMethod.present) {
      map['contact_method'] = Variable<String>(contactMethod.value);
    }
    if (absenceReason.present) {
      map['absence_reason'] = Variable<String>(absenceReason.value);
    }
    if (studentResponse.present) {
      map['student_response'] = Variable<String>(studentResponse.value);
    }
    if (parentResponse.present) {
      map['parent_response'] = Variable<String>(parentResponse.value);
    }
    if (actionRequired.present) {
      map['action_required'] = Variable<String>(actionRequired.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (anotherFollowUpNeeded.present) {
      map['another_follow_up_needed'] = Variable<bool>(
        anotherFollowUpNeeded.value,
      );
    }
    if (nextFollowUpDate.present) {
      map['next_follow_up_date'] = Variable<String>(nextFollowUpDate.value);
    }
    if (clientOperationId.present) {
      map['client_operation_id'] = Variable<String>(clientOperationId.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedFollowUpRecordsCompanion(')
          ..write('id: $id, ')
          ..write('studentId: $studentId, ')
          ..write('createdBy: $createdBy, ')
          ..write('followUpDate: $followUpDate, ')
          ..write('contactStatus: $contactStatus, ')
          ..write('contactMethod: $contactMethod, ')
          ..write('absenceReason: $absenceReason, ')
          ..write('studentResponse: $studentResponse, ')
          ..write('parentResponse: $parentResponse, ')
          ..write('actionRequired: $actionRequired, ')
          ..write('notes: $notes, ')
          ..write('anotherFollowUpNeeded: $anotherFollowUpNeeded, ')
          ..write('nextFollowUpDate: $nextFollowUpDate, ')
          ..write('clientOperationId: $clientOperationId, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedReportingPeriodsTable extends CachedReportingPeriods
    with TableInfo<$CachedReportingPeriodsTable, CachedReportingPeriod> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedReportingPeriodsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serviceIdMeta = const VerificationMeta(
    'serviceId',
  );
  @override
  late final GeneratedColumn<String> serviceId = GeneratedColumn<String>(
    'service_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
    'end_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serviceId,
    name,
    type,
    startDate,
    endDate,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_reporting_periods';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedReportingPeriod> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('service_id')) {
      context.handle(
        _serviceIdMeta,
        serviceId.isAcceptableOrUnknown(data['service_id']!, _serviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serviceIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedReportingPeriod map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedReportingPeriod(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      serviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}service_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedReportingPeriodsTable createAlias(String alias) {
    return $CachedReportingPeriodsTable(attachedDatabase, alias);
  }
}

class CachedReportingPeriod extends DataClass
    implements Insertable<CachedReportingPeriod> {
  final String id;
  final String serviceId;
  final String name;
  final String type;
  final String startDate;
  final String endDate;
  final DateTime cachedAt;
  const CachedReportingPeriod({
    required this.id,
    required this.serviceId,
    required this.name,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['service_id'] = Variable<String>(serviceId);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['start_date'] = Variable<String>(startDate);
    map['end_date'] = Variable<String>(endDate);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedReportingPeriodsCompanion toCompanion(bool nullToAbsent) {
    return CachedReportingPeriodsCompanion(
      id: Value(id),
      serviceId: Value(serviceId),
      name: Value(name),
      type: Value(type),
      startDate: Value(startDate),
      endDate: Value(endDate),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedReportingPeriod.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedReportingPeriod(
      id: serializer.fromJson<String>(json['id']),
      serviceId: serializer.fromJson<String>(json['serviceId']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      startDate: serializer.fromJson<String>(json['startDate']),
      endDate: serializer.fromJson<String>(json['endDate']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'serviceId': serializer.toJson<String>(serviceId),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'startDate': serializer.toJson<String>(startDate),
      'endDate': serializer.toJson<String>(endDate),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedReportingPeriod copyWith({
    String? id,
    String? serviceId,
    String? name,
    String? type,
    String? startDate,
    String? endDate,
    DateTime? cachedAt,
  }) => CachedReportingPeriod(
    id: id ?? this.id,
    serviceId: serviceId ?? this.serviceId,
    name: name ?? this.name,
    type: type ?? this.type,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedReportingPeriod copyWithCompanion(
    CachedReportingPeriodsCompanion data,
  ) {
    return CachedReportingPeriod(
      id: data.id.present ? data.id.value : this.id,
      serviceId: data.serviceId.present ? data.serviceId.value : this.serviceId,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedReportingPeriod(')
          ..write('id: $id, ')
          ..write('serviceId: $serviceId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, serviceId, name, type, startDate, endDate, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedReportingPeriod &&
          other.id == this.id &&
          other.serviceId == this.serviceId &&
          other.name == this.name &&
          other.type == this.type &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.cachedAt == this.cachedAt);
}

class CachedReportingPeriodsCompanion
    extends UpdateCompanion<CachedReportingPeriod> {
  final Value<String> id;
  final Value<String> serviceId;
  final Value<String> name;
  final Value<String> type;
  final Value<String> startDate;
  final Value<String> endDate;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedReportingPeriodsCompanion({
    this.id = const Value.absent(),
    this.serviceId = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedReportingPeriodsCompanion.insert({
    required String id,
    required String serviceId,
    required String name,
    required String type,
    required String startDate,
    required String endDate,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       serviceId = Value(serviceId),
       name = Value(name),
       type = Value(type),
       startDate = Value(startDate),
       endDate = Value(endDate),
       cachedAt = Value(cachedAt);
  static Insertable<CachedReportingPeriod> custom({
    Expression<String>? id,
    Expression<String>? serviceId,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serviceId != null) 'service_id': serviceId,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedReportingPeriodsCompanion copyWith({
    Value<String>? id,
    Value<String>? serviceId,
    Value<String>? name,
    Value<String>? type,
    Value<String>? startDate,
    Value<String>? endDate,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedReportingPeriodsCompanion(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      name: name ?? this.name,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (serviceId.present) {
      map['service_id'] = Variable<String>(serviceId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedReportingPeriodsCompanion(')
          ..write('id: $id, ')
          ..write('serviceId: $serviceId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueEntriesTable extends SyncQueueEntries
    with TableInfo<$SyncQueueEntriesTable, SyncQueueEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _operationIdMeta = const VerificationMeta(
    'operationId',
  );
  @override
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
    'operation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationTypeMeta = const VerificationMeta(
    'operationType',
  );
  @override
  late final GeneratedColumn<String> operationType = GeneratedColumn<String>(
    'operation_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    operationId,
    entityType,
    operationType,
    payloadJson,
    createdAt,
    lastAttemptAt,
    attempts,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('operation_id')) {
      context.handle(
        _operationIdMeta,
        operationId.isAcceptableOrUnknown(
          data['operation_id']!,
          _operationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('operation_type')) {
      context.handle(
        _operationTypeMeta,
        operationType.isAcceptableOrUnknown(
          data['operation_type']!,
          _operationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationTypeMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {operationId};
  @override
  SyncQueueEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueEntry(
      operationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      operationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_type'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $SyncQueueEntriesTable createAlias(String alias) {
    return $SyncQueueEntriesTable(attachedDatabase, alias);
  }
}

class SyncQueueEntry extends DataClass implements Insertable<SyncQueueEntry> {
  final String operationId;
  final String entityType;
  final String operationType;
  final String payloadJson;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
  final int attempts;
  final String status;
  const SyncQueueEntry({
    required this.operationId,
    required this.entityType,
    required this.operationType,
    required this.payloadJson,
    required this.createdAt,
    this.lastAttemptAt,
    required this.attempts,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['operation_id'] = Variable<String>(operationId);
    map['entity_type'] = Variable<String>(entityType);
    map['operation_type'] = Variable<String>(operationType);
    map['payload_json'] = Variable<String>(payloadJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    map['attempts'] = Variable<int>(attempts);
    map['status'] = Variable<String>(status);
    return map;
  }

  SyncQueueEntriesCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueEntriesCompanion(
      operationId: Value(operationId),
      entityType: Value(entityType),
      operationType: Value(operationType),
      payloadJson: Value(payloadJson),
      createdAt: Value(createdAt),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      attempts: Value(attempts),
      status: Value(status),
    );
  }

  factory SyncQueueEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueEntry(
      operationId: serializer.fromJson<String>(json['operationId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      operationType: serializer.fromJson<String>(json['operationType']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'operationId': serializer.toJson<String>(operationId),
      'entityType': serializer.toJson<String>(entityType),
      'operationType': serializer.toJson<String>(operationType),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'attempts': serializer.toJson<int>(attempts),
      'status': serializer.toJson<String>(status),
    };
  }

  SyncQueueEntry copyWith({
    String? operationId,
    String? entityType,
    String? operationType,
    String? payloadJson,
    DateTime? createdAt,
    Value<DateTime?> lastAttemptAt = const Value.absent(),
    int? attempts,
    String? status,
  }) => SyncQueueEntry(
    operationId: operationId ?? this.operationId,
    entityType: entityType ?? this.entityType,
    operationType: operationType ?? this.operationType,
    payloadJson: payloadJson ?? this.payloadJson,
    createdAt: createdAt ?? this.createdAt,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    attempts: attempts ?? this.attempts,
    status: status ?? this.status,
  );
  SyncQueueEntry copyWithCompanion(SyncQueueEntriesCompanion data) {
    return SyncQueueEntry(
      operationId: data.operationId.present
          ? data.operationId.value
          : this.operationId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      operationType: data.operationType.present
          ? data.operationType.value
          : this.operationType,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueEntry(')
          ..write('operationId: $operationId, ')
          ..write('entityType: $entityType, ')
          ..write('operationType: $operationType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('attempts: $attempts, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    operationId,
    entityType,
    operationType,
    payloadJson,
    createdAt,
    lastAttemptAt,
    attempts,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueEntry &&
          other.operationId == this.operationId &&
          other.entityType == this.entityType &&
          other.operationType == this.operationType &&
          other.payloadJson == this.payloadJson &&
          other.createdAt == this.createdAt &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.attempts == this.attempts &&
          other.status == this.status);
}

class SyncQueueEntriesCompanion extends UpdateCompanion<SyncQueueEntry> {
  final Value<String> operationId;
  final Value<String> entityType;
  final Value<String> operationType;
  final Value<String> payloadJson;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastAttemptAt;
  final Value<int> attempts;
  final Value<String> status;
  final Value<int> rowid;
  const SyncQueueEntriesCompanion({
    this.operationId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.operationType = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncQueueEntriesCompanion.insert({
    required String operationId,
    required String entityType,
    required String operationType,
    required String payloadJson,
    required DateTime createdAt,
    this.lastAttemptAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : operationId = Value(operationId),
       entityType = Value(entityType),
       operationType = Value(operationType),
       payloadJson = Value(payloadJson),
       createdAt = Value(createdAt);
  static Insertable<SyncQueueEntry> custom({
    Expression<String>? operationId,
    Expression<String>? entityType,
    Expression<String>? operationType,
    Expression<String>? payloadJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastAttemptAt,
    Expression<int>? attempts,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (operationId != null) 'operation_id': operationId,
      if (entityType != null) 'entity_type': entityType,
      if (operationType != null) 'operation_type': operationType,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (createdAt != null) 'created_at': createdAt,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (attempts != null) 'attempts': attempts,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncQueueEntriesCompanion copyWith({
    Value<String>? operationId,
    Value<String>? entityType,
    Value<String>? operationType,
    Value<String>? payloadJson,
    Value<DateTime>? createdAt,
    Value<DateTime?>? lastAttemptAt,
    Value<int>? attempts,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return SyncQueueEntriesCompanion(
      operationId: operationId ?? this.operationId,
      entityType: entityType ?? this.entityType,
      operationType: operationType ?? this.operationType,
      payloadJson: payloadJson ?? this.payloadJson,
      createdAt: createdAt ?? this.createdAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      attempts: attempts ?? this.attempts,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (operationType.present) {
      map['operation_type'] = Variable<String>(operationType.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueEntriesCompanion(')
          ..write('operationId: $operationId, ')
          ..write('entityType: $entityType, ')
          ..write('operationType: $operationType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('attempts: $attempts, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedProfilesTable cachedProfiles = $CachedProfilesTable(this);
  late final $CachedServicesTable cachedServices = $CachedServicesTable(this);
  late final $CachedStagesTable cachedStages = $CachedStagesTable(this);
  late final $CachedClassesTable cachedClasses = $CachedClassesTable(this);
  late final $CachedStudentsTable cachedStudents = $CachedStudentsTable(this);
  late final $CachedMeetingsTable cachedMeetings = $CachedMeetingsTable(this);
  late final $CachedAttendanceRecordsTable cachedAttendanceRecords =
      $CachedAttendanceRecordsTable(this);
  late final $CachedFollowUpRecordsTable cachedFollowUpRecords =
      $CachedFollowUpRecordsTable(this);
  late final $CachedReportingPeriodsTable cachedReportingPeriods =
      $CachedReportingPeriodsTable(this);
  late final $SyncQueueEntriesTable syncQueueEntries = $SyncQueueEntriesTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedProfiles,
    cachedServices,
    cachedStages,
    cachedClasses,
    cachedStudents,
    cachedMeetings,
    cachedAttendanceRecords,
    cachedFollowUpRecords,
    cachedReportingPeriods,
    syncQueueEntries,
  ];
}

typedef $$CachedProfilesTableCreateCompanionBuilder =
    CachedProfilesCompanion Function({
      required String id,
      required String authUserId,
      required String serviceId,
      required String name,
      required String role,
      Value<String?> phone,
      Value<String?> birthDate,
      Value<String?> workStudy,
      required String accountStatus,
      Value<bool> mustChangePassword,
      Value<String?> stageId,
      Value<String?> classId,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$CachedProfilesTableUpdateCompanionBuilder =
    CachedProfilesCompanion Function({
      Value<String> id,
      Value<String> authUserId,
      Value<String> serviceId,
      Value<String> name,
      Value<String> role,
      Value<String?> phone,
      Value<String?> birthDate,
      Value<String?> workStudy,
      Value<String> accountStatus,
      Value<bool> mustChangePassword,
      Value<String?> stageId,
      Value<String?> classId,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CachedProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedProfilesTable> {
  $$CachedProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authUserId => $composableBuilder(
    column: $table.authUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serviceId => $composableBuilder(
    column: $table.serviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get birthDate => $composableBuilder(
    column: $table.birthDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workStudy => $composableBuilder(
    column: $table.workStudy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountStatus => $composableBuilder(
    column: $table.accountStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get mustChangePassword => $composableBuilder(
    column: $table.mustChangePassword,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stageId => $composableBuilder(
    column: $table.stageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get classId => $composableBuilder(
    column: $table.classId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedProfilesTable> {
  $$CachedProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authUserId => $composableBuilder(
    column: $table.authUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serviceId => $composableBuilder(
    column: $table.serviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get birthDate => $composableBuilder(
    column: $table.birthDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workStudy => $composableBuilder(
    column: $table.workStudy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountStatus => $composableBuilder(
    column: $table.accountStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get mustChangePassword => $composableBuilder(
    column: $table.mustChangePassword,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stageId => $composableBuilder(
    column: $table.stageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get classId => $composableBuilder(
    column: $table.classId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedProfilesTable> {
  $$CachedProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get authUserId => $composableBuilder(
    column: $table.authUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serviceId =>
      $composableBuilder(column: $table.serviceId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get birthDate =>
      $composableBuilder(column: $table.birthDate, builder: (column) => column);

  GeneratedColumn<String> get workStudy =>
      $composableBuilder(column: $table.workStudy, builder: (column) => column);

  GeneratedColumn<String> get accountStatus => $composableBuilder(
    column: $table.accountStatus,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get mustChangePassword => $composableBuilder(
    column: $table.mustChangePassword,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stageId =>
      $composableBuilder(column: $table.stageId, builder: (column) => column);

  GeneratedColumn<String> get classId =>
      $composableBuilder(column: $table.classId, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedProfilesTable,
          CachedProfile,
          $$CachedProfilesTableFilterComposer,
          $$CachedProfilesTableOrderingComposer,
          $$CachedProfilesTableAnnotationComposer,
          $$CachedProfilesTableCreateCompanionBuilder,
          $$CachedProfilesTableUpdateCompanionBuilder,
          (
            CachedProfile,
            BaseReferences<_$AppDatabase, $CachedProfilesTable, CachedProfile>,
          ),
          CachedProfile,
          PrefetchHooks Function()
        > {
  $$CachedProfilesTableTableManager(
    _$AppDatabase db,
    $CachedProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> authUserId = const Value.absent(),
                Value<String> serviceId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> birthDate = const Value.absent(),
                Value<String?> workStudy = const Value.absent(),
                Value<String> accountStatus = const Value.absent(),
                Value<bool> mustChangePassword = const Value.absent(),
                Value<String?> stageId = const Value.absent(),
                Value<String?> classId = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedProfilesCompanion(
                id: id,
                authUserId: authUserId,
                serviceId: serviceId,
                name: name,
                role: role,
                phone: phone,
                birthDate: birthDate,
                workStudy: workStudy,
                accountStatus: accountStatus,
                mustChangePassword: mustChangePassword,
                stageId: stageId,
                classId: classId,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String authUserId,
                required String serviceId,
                required String name,
                required String role,
                Value<String?> phone = const Value.absent(),
                Value<String?> birthDate = const Value.absent(),
                Value<String?> workStudy = const Value.absent(),
                required String accountStatus,
                Value<bool> mustChangePassword = const Value.absent(),
                Value<String?> stageId = const Value.absent(),
                Value<String?> classId = const Value.absent(),
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedProfilesCompanion.insert(
                id: id,
                authUserId: authUserId,
                serviceId: serviceId,
                name: name,
                role: role,
                phone: phone,
                birthDate: birthDate,
                workStudy: workStudy,
                accountStatus: accountStatus,
                mustChangePassword: mustChangePassword,
                stageId: stageId,
                classId: classId,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedProfilesTable, CachedProfile>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedProfilesTable,
                    CachedProfile
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedProfilesTable,
      CachedProfile,
      $$CachedProfilesTableFilterComposer,
      $$CachedProfilesTableOrderingComposer,
      $$CachedProfilesTableAnnotationComposer,
      $$CachedProfilesTableCreateCompanionBuilder,
      $$CachedProfilesTableUpdateCompanionBuilder,
      (
        CachedProfile,
        BaseReferences<_$AppDatabase, $CachedProfilesTable, CachedProfile>,
      ),
      CachedProfile,
      PrefetchHooks Function()
    >;
typedef $$CachedServicesTableCreateCompanionBuilder =
    CachedServicesCompanion Function({
      required String id,
      required String name,
      required String churchName,
      required String meetingStartTime,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$CachedServicesTableUpdateCompanionBuilder =
    CachedServicesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> churchName,
      Value<String> meetingStartTime,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CachedServicesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedServicesTable> {
  $$CachedServicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get churchName => $composableBuilder(
    column: $table.churchName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meetingStartTime => $composableBuilder(
    column: $table.meetingStartTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedServicesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedServicesTable> {
  $$CachedServicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get churchName => $composableBuilder(
    column: $table.churchName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meetingStartTime => $composableBuilder(
    column: $table.meetingStartTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedServicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedServicesTable> {
  $$CachedServicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get churchName => $composableBuilder(
    column: $table.churchName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get meetingStartTime => $composableBuilder(
    column: $table.meetingStartTime,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedServicesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedServicesTable,
          CachedService,
          $$CachedServicesTableFilterComposer,
          $$CachedServicesTableOrderingComposer,
          $$CachedServicesTableAnnotationComposer,
          $$CachedServicesTableCreateCompanionBuilder,
          $$CachedServicesTableUpdateCompanionBuilder,
          (
            CachedService,
            BaseReferences<_$AppDatabase, $CachedServicesTable, CachedService>,
          ),
          CachedService,
          PrefetchHooks Function()
        > {
  $$CachedServicesTableTableManager(
    _$AppDatabase db,
    $CachedServicesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedServicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedServicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedServicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> churchName = const Value.absent(),
                Value<String> meetingStartTime = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedServicesCompanion(
                id: id,
                name: name,
                churchName: churchName,
                meetingStartTime: meetingStartTime,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String churchName,
                required String meetingStartTime,
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedServicesCompanion.insert(
                id: id,
                name: name,
                churchName: churchName,
                meetingStartTime: meetingStartTime,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedServicesTable, CachedService>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedServicesTable,
                    CachedService
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedServicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedServicesTable,
      CachedService,
      $$CachedServicesTableFilterComposer,
      $$CachedServicesTableOrderingComposer,
      $$CachedServicesTableAnnotationComposer,
      $$CachedServicesTableCreateCompanionBuilder,
      $$CachedServicesTableUpdateCompanionBuilder,
      (
        CachedService,
        BaseReferences<_$AppDatabase, $CachedServicesTable, CachedService>,
      ),
      CachedService,
      PrefetchHooks Function()
    >;
typedef $$CachedStagesTableCreateCompanionBuilder =
    CachedStagesCompanion Function({
      required String id,
      required String serviceId,
      required String name,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$CachedStagesTableUpdateCompanionBuilder =
    CachedStagesCompanion Function({
      Value<String> id,
      Value<String> serviceId,
      Value<String> name,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CachedStagesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedStagesTable> {
  $$CachedStagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serviceId => $composableBuilder(
    column: $table.serviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedStagesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedStagesTable> {
  $$CachedStagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serviceId => $composableBuilder(
    column: $table.serviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedStagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedStagesTable> {
  $$CachedStagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serviceId =>
      $composableBuilder(column: $table.serviceId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedStagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedStagesTable,
          CachedStage,
          $$CachedStagesTableFilterComposer,
          $$CachedStagesTableOrderingComposer,
          $$CachedStagesTableAnnotationComposer,
          $$CachedStagesTableCreateCompanionBuilder,
          $$CachedStagesTableUpdateCompanionBuilder,
          (
            CachedStage,
            BaseReferences<_$AppDatabase, $CachedStagesTable, CachedStage>,
          ),
          CachedStage,
          PrefetchHooks Function()
        > {
  $$CachedStagesTableTableManager(_$AppDatabase db, $CachedStagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedStagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedStagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedStagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> serviceId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedStagesCompanion(
                id: id,
                serviceId: serviceId,
                name: name,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String serviceId,
                required String name,
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedStagesCompanion.insert(
                id: id,
                serviceId: serviceId,
                name: name,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedStagesTable, CachedStage>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedStagesTable,
                    CachedStage
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedStagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedStagesTable,
      CachedStage,
      $$CachedStagesTableFilterComposer,
      $$CachedStagesTableOrderingComposer,
      $$CachedStagesTableAnnotationComposer,
      $$CachedStagesTableCreateCompanionBuilder,
      $$CachedStagesTableUpdateCompanionBuilder,
      (
        CachedStage,
        BaseReferences<_$AppDatabase, $CachedStagesTable, CachedStage>,
      ),
      CachedStage,
      PrefetchHooks Function()
    >;
typedef $$CachedClassesTableCreateCompanionBuilder =
    CachedClassesCompanion Function({
      required String id,
      required String stageId,
      required String name,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$CachedClassesTableUpdateCompanionBuilder =
    CachedClassesCompanion Function({
      Value<String> id,
      Value<String> stageId,
      Value<String> name,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CachedClassesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedClassesTable> {
  $$CachedClassesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stageId => $composableBuilder(
    column: $table.stageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedClassesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedClassesTable> {
  $$CachedClassesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stageId => $composableBuilder(
    column: $table.stageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedClassesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedClassesTable> {
  $$CachedClassesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get stageId =>
      $composableBuilder(column: $table.stageId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedClassesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedClassesTable,
          CachedClassesData,
          $$CachedClassesTableFilterComposer,
          $$CachedClassesTableOrderingComposer,
          $$CachedClassesTableAnnotationComposer,
          $$CachedClassesTableCreateCompanionBuilder,
          $$CachedClassesTableUpdateCompanionBuilder,
          (
            CachedClassesData,
            BaseReferences<
              _$AppDatabase,
              $CachedClassesTable,
              CachedClassesData
            >,
          ),
          CachedClassesData,
          PrefetchHooks Function()
        > {
  $$CachedClassesTableTableManager(_$AppDatabase db, $CachedClassesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedClassesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedClassesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedClassesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> stageId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedClassesCompanion(
                id: id,
                stageId: stageId,
                name: name,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String stageId,
                required String name,
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedClassesCompanion.insert(
                id: id,
                stageId: stageId,
                name: name,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedClassesTable, CachedClassesData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedClassesTable,
                    CachedClassesData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedClassesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedClassesTable,
      CachedClassesData,
      $$CachedClassesTableFilterComposer,
      $$CachedClassesTableOrderingComposer,
      $$CachedClassesTableAnnotationComposer,
      $$CachedClassesTableCreateCompanionBuilder,
      $$CachedClassesTableUpdateCompanionBuilder,
      (
        CachedClassesData,
        BaseReferences<_$AppDatabase, $CachedClassesTable, CachedClassesData>,
      ),
      CachedClassesData,
      PrefetchHooks Function()
    >;
typedef $$CachedStudentsTableCreateCompanionBuilder =
    CachedStudentsCompanion Function({
      required String id,
      required String serviceId,
      Value<String?> currentClassId,
      Value<String?> proposedClassId,
      required String name,
      Value<String?> birthDate,
      Value<String?> phone,
      Value<String?> school,
      Value<String?> grade,
      Value<String?> enrollmentAt,
      required String approvalStatus,
      Value<String?> photoPath,
      Value<String?> notes,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$CachedStudentsTableUpdateCompanionBuilder =
    CachedStudentsCompanion Function({
      Value<String> id,
      Value<String> serviceId,
      Value<String?> currentClassId,
      Value<String?> proposedClassId,
      Value<String> name,
      Value<String?> birthDate,
      Value<String?> phone,
      Value<String?> school,
      Value<String?> grade,
      Value<String?> enrollmentAt,
      Value<String> approvalStatus,
      Value<String?> photoPath,
      Value<String?> notes,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CachedStudentsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedStudentsTable> {
  $$CachedStudentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serviceId => $composableBuilder(
    column: $table.serviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currentClassId => $composableBuilder(
    column: $table.currentClassId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get proposedClassId => $composableBuilder(
    column: $table.proposedClassId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get birthDate => $composableBuilder(
    column: $table.birthDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get school => $composableBuilder(
    column: $table.school,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get enrollmentAt => $composableBuilder(
    column: $table.enrollmentAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get approvalStatus => $composableBuilder(
    column: $table.approvalStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedStudentsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedStudentsTable> {
  $$CachedStudentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serviceId => $composableBuilder(
    column: $table.serviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentClassId => $composableBuilder(
    column: $table.currentClassId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get proposedClassId => $composableBuilder(
    column: $table.proposedClassId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get birthDate => $composableBuilder(
    column: $table.birthDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get school => $composableBuilder(
    column: $table.school,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get enrollmentAt => $composableBuilder(
    column: $table.enrollmentAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get approvalStatus => $composableBuilder(
    column: $table.approvalStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedStudentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedStudentsTable> {
  $$CachedStudentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serviceId =>
      $composableBuilder(column: $table.serviceId, builder: (column) => column);

  GeneratedColumn<String> get currentClassId => $composableBuilder(
    column: $table.currentClassId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get proposedClassId => $composableBuilder(
    column: $table.proposedClassId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get birthDate =>
      $composableBuilder(column: $table.birthDate, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get school =>
      $composableBuilder(column: $table.school, builder: (column) => column);

  GeneratedColumn<String> get grade =>
      $composableBuilder(column: $table.grade, builder: (column) => column);

  GeneratedColumn<String> get enrollmentAt => $composableBuilder(
    column: $table.enrollmentAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get approvalStatus => $composableBuilder(
    column: $table.approvalStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedStudentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedStudentsTable,
          CachedStudent,
          $$CachedStudentsTableFilterComposer,
          $$CachedStudentsTableOrderingComposer,
          $$CachedStudentsTableAnnotationComposer,
          $$CachedStudentsTableCreateCompanionBuilder,
          $$CachedStudentsTableUpdateCompanionBuilder,
          (
            CachedStudent,
            BaseReferences<_$AppDatabase, $CachedStudentsTable, CachedStudent>,
          ),
          CachedStudent,
          PrefetchHooks Function()
        > {
  $$CachedStudentsTableTableManager(
    _$AppDatabase db,
    $CachedStudentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedStudentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedStudentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedStudentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> serviceId = const Value.absent(),
                Value<String?> currentClassId = const Value.absent(),
                Value<String?> proposedClassId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> birthDate = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> school = const Value.absent(),
                Value<String?> grade = const Value.absent(),
                Value<String?> enrollmentAt = const Value.absent(),
                Value<String> approvalStatus = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedStudentsCompanion(
                id: id,
                serviceId: serviceId,
                currentClassId: currentClassId,
                proposedClassId: proposedClassId,
                name: name,
                birthDate: birthDate,
                phone: phone,
                school: school,
                grade: grade,
                enrollmentAt: enrollmentAt,
                approvalStatus: approvalStatus,
                photoPath: photoPath,
                notes: notes,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String serviceId,
                Value<String?> currentClassId = const Value.absent(),
                Value<String?> proposedClassId = const Value.absent(),
                required String name,
                Value<String?> birthDate = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> school = const Value.absent(),
                Value<String?> grade = const Value.absent(),
                Value<String?> enrollmentAt = const Value.absent(),
                required String approvalStatus,
                Value<String?> photoPath = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedStudentsCompanion.insert(
                id: id,
                serviceId: serviceId,
                currentClassId: currentClassId,
                proposedClassId: proposedClassId,
                name: name,
                birthDate: birthDate,
                phone: phone,
                school: school,
                grade: grade,
                enrollmentAt: enrollmentAt,
                approvalStatus: approvalStatus,
                photoPath: photoPath,
                notes: notes,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedStudentsTable, CachedStudent>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedStudentsTable,
                    CachedStudent
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedStudentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedStudentsTable,
      CachedStudent,
      $$CachedStudentsTableFilterComposer,
      $$CachedStudentsTableOrderingComposer,
      $$CachedStudentsTableAnnotationComposer,
      $$CachedStudentsTableCreateCompanionBuilder,
      $$CachedStudentsTableUpdateCompanionBuilder,
      (
        CachedStudent,
        BaseReferences<_$AppDatabase, $CachedStudentsTable, CachedStudent>,
      ),
      CachedStudent,
      PrefetchHooks Function()
    >;
typedef $$CachedMeetingsTableCreateCompanionBuilder =
    CachedMeetingsCompanion Function({
      required String id,
      required String serviceId,
      required String meetingDate,
      required String startTime,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$CachedMeetingsTableUpdateCompanionBuilder =
    CachedMeetingsCompanion Function({
      Value<String> id,
      Value<String> serviceId,
      Value<String> meetingDate,
      Value<String> startTime,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CachedMeetingsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedMeetingsTable> {
  $$CachedMeetingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serviceId => $composableBuilder(
    column: $table.serviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meetingDate => $composableBuilder(
    column: $table.meetingDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedMeetingsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedMeetingsTable> {
  $$CachedMeetingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serviceId => $composableBuilder(
    column: $table.serviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meetingDate => $composableBuilder(
    column: $table.meetingDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedMeetingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedMeetingsTable> {
  $$CachedMeetingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serviceId =>
      $composableBuilder(column: $table.serviceId, builder: (column) => column);

  GeneratedColumn<String> get meetingDate => $composableBuilder(
    column: $table.meetingDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedMeetingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedMeetingsTable,
          CachedMeeting,
          $$CachedMeetingsTableFilterComposer,
          $$CachedMeetingsTableOrderingComposer,
          $$CachedMeetingsTableAnnotationComposer,
          $$CachedMeetingsTableCreateCompanionBuilder,
          $$CachedMeetingsTableUpdateCompanionBuilder,
          (
            CachedMeeting,
            BaseReferences<_$AppDatabase, $CachedMeetingsTable, CachedMeeting>,
          ),
          CachedMeeting,
          PrefetchHooks Function()
        > {
  $$CachedMeetingsTableTableManager(
    _$AppDatabase db,
    $CachedMeetingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedMeetingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedMeetingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedMeetingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> serviceId = const Value.absent(),
                Value<String> meetingDate = const Value.absent(),
                Value<String> startTime = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedMeetingsCompanion(
                id: id,
                serviceId: serviceId,
                meetingDate: meetingDate,
                startTime: startTime,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String serviceId,
                required String meetingDate,
                required String startTime,
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedMeetingsCompanion.insert(
                id: id,
                serviceId: serviceId,
                meetingDate: meetingDate,
                startTime: startTime,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedMeetingsTable, CachedMeeting>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedMeetingsTable,
                    CachedMeeting
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedMeetingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedMeetingsTable,
      CachedMeeting,
      $$CachedMeetingsTableFilterComposer,
      $$CachedMeetingsTableOrderingComposer,
      $$CachedMeetingsTableAnnotationComposer,
      $$CachedMeetingsTableCreateCompanionBuilder,
      $$CachedMeetingsTableUpdateCompanionBuilder,
      (
        CachedMeeting,
        BaseReferences<_$AppDatabase, $CachedMeetingsTable, CachedMeeting>,
      ),
      CachedMeeting,
      PrefetchHooks Function()
    >;
typedef $$CachedAttendanceRecordsTableCreateCompanionBuilder =
    CachedAttendanceRecordsCompanion Function({
      required String id,
      required String meetingId,
      required String studentId,
      required String classIdAtAttendance,
      required DateTime checkedInAt,
      required String recordedBy,
      required String clientOperationId,
      Value<String> syncState,
      Value<int> rowid,
    });
typedef $$CachedAttendanceRecordsTableUpdateCompanionBuilder =
    CachedAttendanceRecordsCompanion Function({
      Value<String> id,
      Value<String> meetingId,
      Value<String> studentId,
      Value<String> classIdAtAttendance,
      Value<DateTime> checkedInAt,
      Value<String> recordedBy,
      Value<String> clientOperationId,
      Value<String> syncState,
      Value<int> rowid,
    });

class $$CachedAttendanceRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedAttendanceRecordsTable> {
  $$CachedAttendanceRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meetingId => $composableBuilder(
    column: $table.meetingId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get studentId => $composableBuilder(
    column: $table.studentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get classIdAtAttendance => $composableBuilder(
    column: $table.classIdAtAttendance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get checkedInAt => $composableBuilder(
    column: $table.checkedInAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordedBy => $composableBuilder(
    column: $table.recordedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientOperationId => $composableBuilder(
    column: $table.clientOperationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedAttendanceRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedAttendanceRecordsTable> {
  $$CachedAttendanceRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meetingId => $composableBuilder(
    column: $table.meetingId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get studentId => $composableBuilder(
    column: $table.studentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get classIdAtAttendance => $composableBuilder(
    column: $table.classIdAtAttendance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get checkedInAt => $composableBuilder(
    column: $table.checkedInAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordedBy => $composableBuilder(
    column: $table.recordedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientOperationId => $composableBuilder(
    column: $table.clientOperationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedAttendanceRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedAttendanceRecordsTable> {
  $$CachedAttendanceRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get meetingId =>
      $composableBuilder(column: $table.meetingId, builder: (column) => column);

  GeneratedColumn<String> get studentId =>
      $composableBuilder(column: $table.studentId, builder: (column) => column);

  GeneratedColumn<String> get classIdAtAttendance => $composableBuilder(
    column: $table.classIdAtAttendance,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get checkedInAt => $composableBuilder(
    column: $table.checkedInAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recordedBy => $composableBuilder(
    column: $table.recordedBy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clientOperationId => $composableBuilder(
    column: $table.clientOperationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);
}

class $$CachedAttendanceRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedAttendanceRecordsTable,
          CachedAttendanceRecord,
          $$CachedAttendanceRecordsTableFilterComposer,
          $$CachedAttendanceRecordsTableOrderingComposer,
          $$CachedAttendanceRecordsTableAnnotationComposer,
          $$CachedAttendanceRecordsTableCreateCompanionBuilder,
          $$CachedAttendanceRecordsTableUpdateCompanionBuilder,
          (
            CachedAttendanceRecord,
            BaseReferences<
              _$AppDatabase,
              $CachedAttendanceRecordsTable,
              CachedAttendanceRecord
            >,
          ),
          CachedAttendanceRecord,
          PrefetchHooks Function()
        > {
  $$CachedAttendanceRecordsTableTableManager(
    _$AppDatabase db,
    $CachedAttendanceRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedAttendanceRecordsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CachedAttendanceRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedAttendanceRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> meetingId = const Value.absent(),
                Value<String> studentId = const Value.absent(),
                Value<String> classIdAtAttendance = const Value.absent(),
                Value<DateTime> checkedInAt = const Value.absent(),
                Value<String> recordedBy = const Value.absent(),
                Value<String> clientOperationId = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedAttendanceRecordsCompanion(
                id: id,
                meetingId: meetingId,
                studentId: studentId,
                classIdAtAttendance: classIdAtAttendance,
                checkedInAt: checkedInAt,
                recordedBy: recordedBy,
                clientOperationId: clientOperationId,
                syncState: syncState,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String meetingId,
                required String studentId,
                required String classIdAtAttendance,
                required DateTime checkedInAt,
                required String recordedBy,
                required String clientOperationId,
                Value<String> syncState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedAttendanceRecordsCompanion.insert(
                id: id,
                meetingId: meetingId,
                studentId: studentId,
                classIdAtAttendance: classIdAtAttendance,
                checkedInAt: checkedInAt,
                recordedBy: recordedBy,
                clientOperationId: clientOperationId,
                syncState: syncState,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $CachedAttendanceRecordsTable,
                    CachedAttendanceRecord
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedAttendanceRecordsTable,
                    CachedAttendanceRecord
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedAttendanceRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedAttendanceRecordsTable,
      CachedAttendanceRecord,
      $$CachedAttendanceRecordsTableFilterComposer,
      $$CachedAttendanceRecordsTableOrderingComposer,
      $$CachedAttendanceRecordsTableAnnotationComposer,
      $$CachedAttendanceRecordsTableCreateCompanionBuilder,
      $$CachedAttendanceRecordsTableUpdateCompanionBuilder,
      (
        CachedAttendanceRecord,
        BaseReferences<
          _$AppDatabase,
          $CachedAttendanceRecordsTable,
          CachedAttendanceRecord
        >,
      ),
      CachedAttendanceRecord,
      PrefetchHooks Function()
    >;
typedef $$CachedFollowUpRecordsTableCreateCompanionBuilder =
    CachedFollowUpRecordsCompanion Function({
      required String id,
      required String studentId,
      required String createdBy,
      required String followUpDate,
      required String contactStatus,
      Value<String?> contactMethod,
      Value<String?> absenceReason,
      Value<String?> studentResponse,
      Value<String?> parentResponse,
      Value<String?> actionRequired,
      Value<String?> notes,
      Value<bool> anotherFollowUpNeeded,
      Value<String?> nextFollowUpDate,
      required String clientOperationId,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$CachedFollowUpRecordsTableUpdateCompanionBuilder =
    CachedFollowUpRecordsCompanion Function({
      Value<String> id,
      Value<String> studentId,
      Value<String> createdBy,
      Value<String> followUpDate,
      Value<String> contactStatus,
      Value<String?> contactMethod,
      Value<String?> absenceReason,
      Value<String?> studentResponse,
      Value<String?> parentResponse,
      Value<String?> actionRequired,
      Value<String?> notes,
      Value<bool> anotherFollowUpNeeded,
      Value<String?> nextFollowUpDate,
      Value<String> clientOperationId,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CachedFollowUpRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedFollowUpRecordsTable> {
  $$CachedFollowUpRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get studentId => $composableBuilder(
    column: $table.studentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get followUpDate => $composableBuilder(
    column: $table.followUpDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contactStatus => $composableBuilder(
    column: $table.contactStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contactMethod => $composableBuilder(
    column: $table.contactMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get absenceReason => $composableBuilder(
    column: $table.absenceReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get studentResponse => $composableBuilder(
    column: $table.studentResponse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentResponse => $composableBuilder(
    column: $table.parentResponse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actionRequired => $composableBuilder(
    column: $table.actionRequired,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get anotherFollowUpNeeded => $composableBuilder(
    column: $table.anotherFollowUpNeeded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nextFollowUpDate => $composableBuilder(
    column: $table.nextFollowUpDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientOperationId => $composableBuilder(
    column: $table.clientOperationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedFollowUpRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedFollowUpRecordsTable> {
  $$CachedFollowUpRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get studentId => $composableBuilder(
    column: $table.studentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get followUpDate => $composableBuilder(
    column: $table.followUpDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contactStatus => $composableBuilder(
    column: $table.contactStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contactMethod => $composableBuilder(
    column: $table.contactMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get absenceReason => $composableBuilder(
    column: $table.absenceReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get studentResponse => $composableBuilder(
    column: $table.studentResponse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentResponse => $composableBuilder(
    column: $table.parentResponse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actionRequired => $composableBuilder(
    column: $table.actionRequired,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get anotherFollowUpNeeded => $composableBuilder(
    column: $table.anotherFollowUpNeeded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nextFollowUpDate => $composableBuilder(
    column: $table.nextFollowUpDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientOperationId => $composableBuilder(
    column: $table.clientOperationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedFollowUpRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedFollowUpRecordsTable> {
  $$CachedFollowUpRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get studentId =>
      $composableBuilder(column: $table.studentId, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get followUpDate => $composableBuilder(
    column: $table.followUpDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contactStatus => $composableBuilder(
    column: $table.contactStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contactMethod => $composableBuilder(
    column: $table.contactMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get absenceReason => $composableBuilder(
    column: $table.absenceReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get studentResponse => $composableBuilder(
    column: $table.studentResponse,
    builder: (column) => column,
  );

  GeneratedColumn<String> get parentResponse => $composableBuilder(
    column: $table.parentResponse,
    builder: (column) => column,
  );

  GeneratedColumn<String> get actionRequired => $composableBuilder(
    column: $table.actionRequired,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get anotherFollowUpNeeded => $composableBuilder(
    column: $table.anotherFollowUpNeeded,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nextFollowUpDate => $composableBuilder(
    column: $table.nextFollowUpDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clientOperationId => $composableBuilder(
    column: $table.clientOperationId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedFollowUpRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedFollowUpRecordsTable,
          CachedFollowUpRecord,
          $$CachedFollowUpRecordsTableFilterComposer,
          $$CachedFollowUpRecordsTableOrderingComposer,
          $$CachedFollowUpRecordsTableAnnotationComposer,
          $$CachedFollowUpRecordsTableCreateCompanionBuilder,
          $$CachedFollowUpRecordsTableUpdateCompanionBuilder,
          (
            CachedFollowUpRecord,
            BaseReferences<
              _$AppDatabase,
              $CachedFollowUpRecordsTable,
              CachedFollowUpRecord
            >,
          ),
          CachedFollowUpRecord,
          PrefetchHooks Function()
        > {
  $$CachedFollowUpRecordsTableTableManager(
    _$AppDatabase db,
    $CachedFollowUpRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedFollowUpRecordsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CachedFollowUpRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedFollowUpRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> studentId = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<String> followUpDate = const Value.absent(),
                Value<String> contactStatus = const Value.absent(),
                Value<String?> contactMethod = const Value.absent(),
                Value<String?> absenceReason = const Value.absent(),
                Value<String?> studentResponse = const Value.absent(),
                Value<String?> parentResponse = const Value.absent(),
                Value<String?> actionRequired = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> anotherFollowUpNeeded = const Value.absent(),
                Value<String?> nextFollowUpDate = const Value.absent(),
                Value<String> clientOperationId = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedFollowUpRecordsCompanion(
                id: id,
                studentId: studentId,
                createdBy: createdBy,
                followUpDate: followUpDate,
                contactStatus: contactStatus,
                contactMethod: contactMethod,
                absenceReason: absenceReason,
                studentResponse: studentResponse,
                parentResponse: parentResponse,
                actionRequired: actionRequired,
                notes: notes,
                anotherFollowUpNeeded: anotherFollowUpNeeded,
                nextFollowUpDate: nextFollowUpDate,
                clientOperationId: clientOperationId,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String studentId,
                required String createdBy,
                required String followUpDate,
                required String contactStatus,
                Value<String?> contactMethod = const Value.absent(),
                Value<String?> absenceReason = const Value.absent(),
                Value<String?> studentResponse = const Value.absent(),
                Value<String?> parentResponse = const Value.absent(),
                Value<String?> actionRequired = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> anotherFollowUpNeeded = const Value.absent(),
                Value<String?> nextFollowUpDate = const Value.absent(),
                required String clientOperationId,
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedFollowUpRecordsCompanion.insert(
                id: id,
                studentId: studentId,
                createdBy: createdBy,
                followUpDate: followUpDate,
                contactStatus: contactStatus,
                contactMethod: contactMethod,
                absenceReason: absenceReason,
                studentResponse: studentResponse,
                parentResponse: parentResponse,
                actionRequired: actionRequired,
                notes: notes,
                anotherFollowUpNeeded: anotherFollowUpNeeded,
                nextFollowUpDate: nextFollowUpDate,
                clientOperationId: clientOperationId,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $CachedFollowUpRecordsTable,
                    CachedFollowUpRecord
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedFollowUpRecordsTable,
                    CachedFollowUpRecord
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedFollowUpRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedFollowUpRecordsTable,
      CachedFollowUpRecord,
      $$CachedFollowUpRecordsTableFilterComposer,
      $$CachedFollowUpRecordsTableOrderingComposer,
      $$CachedFollowUpRecordsTableAnnotationComposer,
      $$CachedFollowUpRecordsTableCreateCompanionBuilder,
      $$CachedFollowUpRecordsTableUpdateCompanionBuilder,
      (
        CachedFollowUpRecord,
        BaseReferences<
          _$AppDatabase,
          $CachedFollowUpRecordsTable,
          CachedFollowUpRecord
        >,
      ),
      CachedFollowUpRecord,
      PrefetchHooks Function()
    >;
typedef $$CachedReportingPeriodsTableCreateCompanionBuilder =
    CachedReportingPeriodsCompanion Function({
      required String id,
      required String serviceId,
      required String name,
      required String type,
      required String startDate,
      required String endDate,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$CachedReportingPeriodsTableUpdateCompanionBuilder =
    CachedReportingPeriodsCompanion Function({
      Value<String> id,
      Value<String> serviceId,
      Value<String> name,
      Value<String> type,
      Value<String> startDate,
      Value<String> endDate,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CachedReportingPeriodsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedReportingPeriodsTable> {
  $$CachedReportingPeriodsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serviceId => $composableBuilder(
    column: $table.serviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedReportingPeriodsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedReportingPeriodsTable> {
  $$CachedReportingPeriodsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serviceId => $composableBuilder(
    column: $table.serviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedReportingPeriodsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedReportingPeriodsTable> {
  $$CachedReportingPeriodsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serviceId =>
      $composableBuilder(column: $table.serviceId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedReportingPeriodsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedReportingPeriodsTable,
          CachedReportingPeriod,
          $$CachedReportingPeriodsTableFilterComposer,
          $$CachedReportingPeriodsTableOrderingComposer,
          $$CachedReportingPeriodsTableAnnotationComposer,
          $$CachedReportingPeriodsTableCreateCompanionBuilder,
          $$CachedReportingPeriodsTableUpdateCompanionBuilder,
          (
            CachedReportingPeriod,
            BaseReferences<
              _$AppDatabase,
              $CachedReportingPeriodsTable,
              CachedReportingPeriod
            >,
          ),
          CachedReportingPeriod,
          PrefetchHooks Function()
        > {
  $$CachedReportingPeriodsTableTableManager(
    _$AppDatabase db,
    $CachedReportingPeriodsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedReportingPeriodsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CachedReportingPeriodsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedReportingPeriodsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> serviceId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<String> endDate = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedReportingPeriodsCompanion(
                id: id,
                serviceId: serviceId,
                name: name,
                type: type,
                startDate: startDate,
                endDate: endDate,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String serviceId,
                required String name,
                required String type,
                required String startDate,
                required String endDate,
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedReportingPeriodsCompanion.insert(
                id: id,
                serviceId: serviceId,
                name: name,
                type: type,
                startDate: startDate,
                endDate: endDate,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $CachedReportingPeriodsTable,
                    CachedReportingPeriod
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedReportingPeriodsTable,
                    CachedReportingPeriod
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedReportingPeriodsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedReportingPeriodsTable,
      CachedReportingPeriod,
      $$CachedReportingPeriodsTableFilterComposer,
      $$CachedReportingPeriodsTableOrderingComposer,
      $$CachedReportingPeriodsTableAnnotationComposer,
      $$CachedReportingPeriodsTableCreateCompanionBuilder,
      $$CachedReportingPeriodsTableUpdateCompanionBuilder,
      (
        CachedReportingPeriod,
        BaseReferences<
          _$AppDatabase,
          $CachedReportingPeriodsTable,
          CachedReportingPeriod
        >,
      ),
      CachedReportingPeriod,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueEntriesTableCreateCompanionBuilder =
    SyncQueueEntriesCompanion Function({
      required String operationId,
      required String entityType,
      required String operationType,
      required String payloadJson,
      required DateTime createdAt,
      Value<DateTime?> lastAttemptAt,
      Value<int> attempts,
      Value<String> status,
      Value<int> rowid,
    });
typedef $$SyncQueueEntriesTableUpdateCompanionBuilder =
    SyncQueueEntriesCompanion Function({
      Value<String> operationId,
      Value<String> entityType,
      Value<String> operationType,
      Value<String> payloadJson,
      Value<DateTime> createdAt,
      Value<DateTime?> lastAttemptAt,
      Value<int> attempts,
      Value<String> status,
      Value<int> rowid,
    });

class $$SyncQueueEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueEntriesTable> {
  $$SyncQueueEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueEntriesTable> {
  $$SyncQueueEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueEntriesTable> {
  $$SyncQueueEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$SyncQueueEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueEntriesTable,
          SyncQueueEntry,
          $$SyncQueueEntriesTableFilterComposer,
          $$SyncQueueEntriesTableOrderingComposer,
          $$SyncQueueEntriesTableAnnotationComposer,
          $$SyncQueueEntriesTableCreateCompanionBuilder,
          $$SyncQueueEntriesTableUpdateCompanionBuilder,
          (
            SyncQueueEntry,
            BaseReferences<
              _$AppDatabase,
              $SyncQueueEntriesTable,
              SyncQueueEntry
            >,
          ),
          SyncQueueEntry,
          PrefetchHooks Function()
        > {
  $$SyncQueueEntriesTableTableManager(
    _$AppDatabase db,
    $SyncQueueEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> operationId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> operationType = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueEntriesCompanion(
                operationId: operationId,
                entityType: entityType,
                operationType: operationType,
                payloadJson: payloadJson,
                createdAt: createdAt,
                lastAttemptAt: lastAttemptAt,
                attempts: attempts,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String operationId,
                required String entityType,
                required String operationType,
                required String payloadJson,
                required DateTime createdAt,
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueEntriesCompanion.insert(
                operationId: operationId,
                entityType: entityType,
                operationType: operationType,
                payloadJson: payloadJson,
                createdAt: createdAt,
                lastAttemptAt: lastAttemptAt,
                attempts: attempts,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncQueueEntriesTable, SyncQueueEntry>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncQueueEntriesTable,
                    SyncQueueEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueEntriesTable,
      SyncQueueEntry,
      $$SyncQueueEntriesTableFilterComposer,
      $$SyncQueueEntriesTableOrderingComposer,
      $$SyncQueueEntriesTableAnnotationComposer,
      $$SyncQueueEntriesTableCreateCompanionBuilder,
      $$SyncQueueEntriesTableUpdateCompanionBuilder,
      (
        SyncQueueEntry,
        BaseReferences<_$AppDatabase, $SyncQueueEntriesTable, SyncQueueEntry>,
      ),
      SyncQueueEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedProfilesTableTableManager get cachedProfiles =>
      $$CachedProfilesTableTableManager(_db, _db.cachedProfiles);
  $$CachedServicesTableTableManager get cachedServices =>
      $$CachedServicesTableTableManager(_db, _db.cachedServices);
  $$CachedStagesTableTableManager get cachedStages =>
      $$CachedStagesTableTableManager(_db, _db.cachedStages);
  $$CachedClassesTableTableManager get cachedClasses =>
      $$CachedClassesTableTableManager(_db, _db.cachedClasses);
  $$CachedStudentsTableTableManager get cachedStudents =>
      $$CachedStudentsTableTableManager(_db, _db.cachedStudents);
  $$CachedMeetingsTableTableManager get cachedMeetings =>
      $$CachedMeetingsTableTableManager(_db, _db.cachedMeetings);
  $$CachedAttendanceRecordsTableTableManager get cachedAttendanceRecords =>
      $$CachedAttendanceRecordsTableTableManager(
        _db,
        _db.cachedAttendanceRecords,
      );
  $$CachedFollowUpRecordsTableTableManager get cachedFollowUpRecords =>
      $$CachedFollowUpRecordsTableTableManager(_db, _db.cachedFollowUpRecords);
  $$CachedReportingPeriodsTableTableManager get cachedReportingPeriods =>
      $$CachedReportingPeriodsTableTableManager(
        _db,
        _db.cachedReportingPeriods,
      );
  $$SyncQueueEntriesTableTableManager get syncQueueEntries =>
      $$SyncQueueEntriesTableTableManager(_db, _db.syncQueueEntries);
}
