import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/sync/sync_queue_repository.dart';
import '../data/local_follow_up_repository.dart';
import '../data/offline_first_follow_up_repository.dart';

final localFollowUpRepositoryProvider=Provider((ref)=>LocalFollowUpRepository(ref.watch(appDatabaseProvider)));
final followUpRepositoryProvider=Provider((ref)=>OfflineFirstFollowUpRepository(local:ref.watch(localFollowUpRepositoryProvider),queue:SyncQueueRepository(ref.watch(appDatabaseProvider))));
