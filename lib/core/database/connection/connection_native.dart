import 'package:drift/drift.dart';
import 'package:drift/native.dart';

DatabaseConnection testingDatabaseConnection() =>
    DatabaseConnection(NativeDatabase.memory());
