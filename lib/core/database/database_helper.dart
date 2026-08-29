import 'package:flutter/foundation.dart';
import 'package:idb_shim/idb.dart';
import 'package:idb_shim/idb_browser.dart';
import 'package:idb_shim/idb_client_memory.dart';
import 'schema_constants.dart';

class DatabaseHelper {
  late Database _db;
  bool _isInitialized = false;

  Database get db {
    if (!_isInitialized) {
      throw Exception('Database has not been initialized. Call open() first.');
    }
    return _db;
  }

  Future<void> open() async {
    if (_isInitialized) return;

    // Use browser IndexedDB on Web, and in-memory mock for other platforms/testing
    final idbFactory = kIsWeb ? idbFactoryBrowser : newIdbFactoryMemory();

    _db = await idbFactory.open(
      SchemaConstants.dbName,
      version: SchemaConstants.dbVersion,
      onUpgradeNeeded: (VersionChangeEvent event) {
        final db = event.database;

        // 1. Shifts Store
        if (!db.objectStoreNames.contains(SchemaConstants.storeShifts)) {
          final store = db.createObjectStore(
            SchemaConstants.storeShifts,
            keyPath: 'id',
            autoIncrement: true,
          );
          store.createIndex(
            SchemaConstants.indexName,
            'name',
            unique: true,
          );
        }

        // 2. Employees Store
        if (!db.objectStoreNames.contains(SchemaConstants.storeEmployees)) {
          final store = db.createObjectStore(
            SchemaConstants.storeEmployees,
            keyPath: 'id',
            autoIncrement: true,
          );
          store.createIndex(
            SchemaConstants.indexEmployeeCode,
            'employeeCode',
            unique: true,
          );
          store.createIndex(
            SchemaConstants.indexShiftId,
            'shiftId',
            unique: false,
          );
        }

        // 3. Attendance Store
        if (!db.objectStoreNames.contains(SchemaConstants.storeAttendance)) {
          final store = db.createObjectStore(
            SchemaConstants.storeAttendance,
            keyPath: 'id',
            autoIncrement: true,
          );
          store.createIndex(
            SchemaConstants.indexEmployeeId,
            'employeeId',
            unique: false,
          );
          store.createIndex(
            SchemaConstants.indexDate,
            'date',
            unique: false,
          );
          // Compound index for employeeId and date to guarantee uniqueness per day
          store.createIndex(
            SchemaConstants.indexEmployeeIdDate,
            ['employeeId', 'date'],
            unique: true,
          );
        }

        // 4. Settings Store
        if (!db.objectStoreNames.contains(SchemaConstants.storeSettings)) {
          db.createObjectStore(
            SchemaConstants.storeSettings,
            keyPath: 'key',
          );
        }

        // 5. Leave Types Store
        if (!db.objectStoreNames.contains(SchemaConstants.storeLeaveTypes)) {
          final store = db.createObjectStore(
            SchemaConstants.storeLeaveTypes,
            keyPath: 'id',
            autoIncrement: true,
          );
          store.createIndex(
            SchemaConstants.indexName,
            'name',
            unique: true,
          );
        }

        // 6. Leave Requests Store
        if (!db.objectStoreNames.contains(SchemaConstants.storeLeaveRequests)) {
          final store = db.createObjectStore(
            SchemaConstants.storeLeaveRequests,
            keyPath: 'id',
            autoIncrement: true,
          );
          store.createIndex(
            SchemaConstants.indexEmployeeId,
            'employeeId',
            unique: false,
          );
          store.createIndex(
            SchemaConstants.indexStatus,
            'status',
            unique: false,
          );
          store.createIndex(
            SchemaConstants.indexStartDate,
            'startDate',
            unique: false,
          );
          store.createIndex(
            SchemaConstants.indexEndDate,
            'endDate',
            unique: false,
          );
          store.createIndex(
            SchemaConstants.indexEmployeeIdStatus,
            ['employeeId', 'status'],
            unique: false,
          );
        }

        // 7. Leave Balances Store
        if (!db.objectStoreNames.contains(SchemaConstants.storeLeaveBalances)) {
          final store = db.createObjectStore(
            SchemaConstants.storeLeaveBalances,
            keyPath: 'id',
            autoIncrement: true,
          );
          store.createIndex(
            SchemaConstants.indexEmployeeId,
            'employeeId',
            unique: false,
          );
          store.createIndex(
            SchemaConstants.indexEmployeeTypeYear,
            ['employeeId', 'leaveTypeId', 'leaveYear'],
            unique: true,
          );
        }

        // 8. Official Holidays Store
        if (!db.objectStoreNames.contains(SchemaConstants.storeOfficialHolidays)) {
          final store = db.createObjectStore(
            SchemaConstants.storeOfficialHolidays,
            keyPath: 'id',
            autoIncrement: true,
          );
          store.createIndex(
            SchemaConstants.indexDate,
            'date',
            unique: true,
          );
        }

        // 9. Audit Logs Store
        if (!db.objectStoreNames.contains(SchemaConstants.storeAuditLogs)) {
          db.createObjectStore(
            SchemaConstants.storeAuditLogs,
            keyPath: 'id',
            autoIncrement: true,
          );
        }
      },
    );

    _isInitialized = true;
  }

  // Insert or update record (if key exists)
  Future<dynamic> put(String storeName, Map<String, dynamic> data) async {
    final txn = _db.transaction(storeName, idbModeReadWrite);
    final store = txn.objectStore(storeName);
    final key = await store.put(data);
    await txn.completed;
    return key;
  }

  // Delete a record
  Future<void> delete(String storeName, dynamic key) async {
    final txn = _db.transaction(storeName, idbModeReadWrite);
    final store = txn.objectStore(storeName);
    await store.delete(key);
    await txn.completed;
  }

  // Clear all records in a store
  Future<void> clearStore(String storeName) async {
    final txn = _db.transaction(storeName, idbModeReadWrite);
    final store = txn.objectStore(storeName);
    await store.clear();
    await txn.completed;
  }

  // Query a record by primary key
  Future<Map<String, dynamic>?> queryById(String storeName, dynamic key) async {
    final txn = _db.transaction(storeName, idbModeReadOnly);
    final store = txn.objectStore(storeName);
    final result = await store.getObject(key);
    await txn.completed;
    if (result == null) return null;
    return Map<String, dynamic>.from(result as Map);
  }

  // Query all records in a store
  Future<List<Map<String, dynamic>>> queryAll(String storeName) async {
    final txn = _db.transaction(storeName, idbModeReadOnly);
    final store = txn.objectStore(storeName);
    final list = await store.getAll();
    await txn.completed;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // Query a record by an index value
  Future<Map<String, dynamic>?> queryByIndex(
    String storeName,
    String indexName,
    dynamic key,
  ) async {
    final txn = _db.transaction(storeName, idbModeReadOnly);
    final store = txn.objectStore(storeName);
    final index = store.index(indexName);
    final result = await index.get(key);
    await txn.completed;
    if (result == null) return null;
    return Map<String, dynamic>.from(result as Map);
  }

  // Query all records matching an index value
  Future<List<Map<String, dynamic>>> queryAllByIndex(
    String storeName,
    String indexName,
    dynamic key,
  ) async {
    final txn = _db.transaction(storeName, idbModeReadOnly);
    final store = txn.objectStore(storeName);
    final index = store.index(indexName);
    final list = await index.getAll(key);
    await txn.completed;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
