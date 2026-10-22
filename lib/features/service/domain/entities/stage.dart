import 'package:flutter/foundation.dart';

@immutable
class Stage {
  const Stage({required this.id, required this.serviceId, required this.name});

  final String id;
  final String serviceId;
  final String name;

  Stage copyWith({String? id, String? serviceId, String? name}) {
    return Stage(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      name: name ?? this.name,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Stage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          serviceId == other.serviceId;

  @override
  int get hashCode => id.hashCode ^ serviceId.hashCode;
}
