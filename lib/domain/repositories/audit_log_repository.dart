import '../../data/models/audit_log_model.dart';

abstract class AuditLogRepository {
  Future<List<AuditLogModel>> getAuditLogs();
  Future<void> logAction(AuditLogModel log);
}
