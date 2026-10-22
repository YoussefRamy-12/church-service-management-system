import 'package:flutter/foundation.dart';

@immutable
class ServiceClass {
  const ServiceClass({
    required this.id,
    required this.stageId,
    required this.name,
  });

  final String id;
  final String stageId;
  final String name;

  ServiceClass copyWith({String? id, String? stageId, String? name}) {
    return ServiceClass(
      id: id ?? this.id,
      stageId: stageId ?? this.stageId,
      name: name ?? this.name,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceClass &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          stageId == other.stageId;

  @override
  int get hashCode => id.hashCode ^ stageId.hashCode;
}
