import '../../core/database/database_helper.dart';
import '../../core/database/schema_constants.dart';
import '../../domain/repositories/audit_log_repository.dart';
import '../models/audit_log_model.dart';

class AuditLogRepositoryImpl implements AuditLogRepository {
  final DatabaseHelper _dbHelper;

  AuditLogRepositoryImpl(this._dbHelper);

  @override
  Future<List<AuditLogModel>> getAuditLogs() async {
    final list = await _dbHelper.queryAll(SchemaConstants.storeAuditLogs);
    final logs = list.map((e) => AuditLogModel.fromMap(e)).toList();
    // Sort descending by timestamp
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs;
  }

  @override
  Future<void> logAction(AuditLogModel log) async {
    await _dbHelper.put(SchemaConstants.storeAuditLogs, log.toMap());
  }
}
