import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/item_model.dart';
import '../models/person_model.dart';
import '../models/bank_operation_model.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._();
  LocalDatabase._();

  static const int schemaVersion = 3;
  static const String packageVersion = '2';
  static const String syncExt = '.adsync';

  Database? _db;

  final List<ItemModel> items = [];
  final List<PersonModel> customers = [];
  final List<PersonModel> suppliers = [];
  final List<BankOperationModel> bankOperations = [];

  final List<String> syncTables = const [
    'suppliers',
    'customers',
    'items',
    'purchase_invoices',
    'purchase_invoice_items',
    'sales_invoices',
    'sales_invoice_items',
    'payments',
    'financial_payments',
    'financial_withdrawals',
    'capital_adjustments',
    'notes_journal',
    'bank_account_audit',
    'customer_debt_transactions',
    'sales_returns',
    'sales_return_items',
    'purchase_returns',
    'purchase_return_items',
    'stock_count_sessions',
    'stock_count_items',
    'stock_movements',
  ];

  Future<Database> get database async {
    if (_db != null) return _db!;
    await init();
    return _db!;
  }

  Future<void> init() async {
    if (_db != null) return;
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'aldood_mobile.db');
    _db = await openDatabase(
      dbPath,
      version: schemaVersion,
      onCreate: (db, version) async => _createTables(db),
      onUpgrade: (db, oldVersion, newVersion) async => _createTables(db),
    );
    await _createTables(_db!);
    await _ensureDeviceSettings();
    await _seedIfEmpty();
    await loadAll();
  }

  String now() => DateTime.now().toIso8601String().substring(0, 19).replaceAll('T', ' ');

  Future<String> deviceId() async {
    final db = await database;
    final rows = await db.query('settings', where: 'key=?', whereArgs: ['sync_device_id'], limit: 1);
    if (rows.isNotEmpty && '${rows.first['value'] ?? ''}'.isNotEmpty) return '${rows.first['value']}';
    final id = 'mobile-${DateTime.now().millisecondsSinceEpoch}';
    await setSetting('sync_device_id', id);
    return id;
  }

  Future<String> deviceName() async {
    final db = await database;
    final rows = await db.query('settings', where: 'key=?', whereArgs: ['sync_device_name'], limit: 1);
    if (rows.isNotEmpty && '${rows.first['value'] ?? ''}'.isNotEmpty) return '${rows.first['value']}';
    return 'هاتف الدود ماركت';
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String> getSetting(String key, [String fallback = '']) async {
    final db = await database;
    final rows = await db.query('settings', where: 'key=?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return fallback;
    return '${rows.first['value'] ?? fallback}';
  }

  Future<void> _createTables(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_import_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        package_id TEXT NOT NULL UNIQUE,
        source_device TEXT,
        package_kind TEXT,
        imported_rows INTEGER NOT NULL DEFAULT 0,
        skipped_rows INTEGER NOT NULL DEFAULT 0,
        conflicts INTEGER NOT NULL DEFAULT 0,
        details TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_conflicts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        package_id TEXT,
        table_name TEXT,
        row_uuid TEXT,
        local_data TEXT,
        incoming_data TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        sync_uuid TEXT UNIQUE,
        source_device TEXT,
        deleted_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        sync_uuid TEXT UNIQUE,
        source_device TEXT,
        deleted_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        quantity REAL NOT NULL DEFAULT 0,
        supplier_id INTEGER,
        purchase_price REAL NOT NULL DEFAULT 0,
        wholesale_price REAL NOT NULL DEFAULT 0,
        retail_price REAL NOT NULL DEFAULT 0,
        warehouse_location TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        sync_uuid TEXT UNIQUE,
        source_device TEXT,
        deleted_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS purchase_invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_no TEXT NOT NULL UNIQUE,
        supplier_id INTEGER,
        invoice_date TEXT NOT NULL,
        payment_method TEXT,
        payment_status TEXT,
        paid_amount REAL NOT NULL DEFAULT 0,
        notes TEXT,
        total_amount REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        sync_uuid TEXT UNIQUE,
        source_device TEXT,
        deleted_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS purchase_invoice_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        item_id INTEGER NOT NULL,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        line_total REAL NOT NULL,
        notes TEXT,
        created_at TEXT,
        updated_at TEXT,
        sync_uuid TEXT UNIQUE,
        source_device TEXT,
        deleted_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales_invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_no TEXT NOT NULL UNIQUE,
        customer_id INTEGER,
        invoice_date TEXT NOT NULL,
        payment_status TEXT,
        payment_channel TEXT,
        paid_amount REAL NOT NULL DEFAULT 0,
        notes TEXT,
        total_amount REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        sync_uuid TEXT UNIQUE,
        source_device TEXT,
        deleted_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales_invoice_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        item_id INTEGER NOT NULL,
        quantity REAL NOT NULL,
        sale_price REAL NOT NULL,
        purchase_ref_price REAL NOT NULL DEFAULT 0,
        line_total REAL NOT NULL,
        created_at TEXT,
        updated_at TEXT,
        sync_uuid TEXT UNIQUE,
        source_device TEXT,
        deleted_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS stock_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id INTEGER NOT NULL,
        movement_type TEXT NOT NULL,
        reference_type TEXT,
        reference_id INTEGER,
        quantity REAL NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        sync_uuid TEXT UNIQUE,
        source_device TEXT,
        deleted_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_kind TEXT NOT NULL,
        invoice_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_method TEXT,
        notes TEXT,
        created_by TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        sync_uuid TEXT UNIQUE,
        source_device TEXT,
        deleted_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS financial_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        category TEXT NOT NULL DEFAULT 'عام',
        executor TEXT,
        tx_date TEXT NOT NULL,
        notes TEXT,
        created_by TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        sync_uuid TEXT UNIQUE,
        source_device TEXT,
        deleted_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS financial_withdrawals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        category TEXT NOT NULL DEFAULT 'عام',
        executor TEXT,
        tx_date TEXT NOT NULL,
        notes TEXT,
        created_by TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        sync_uuid TEXT UNIQUE,
        source_device TEXT,
        deleted_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS capital_adjustments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        adj_type TEXT NOT NULL,
        amount REAL NOT NULL,
        tx_date TEXT NOT NULL,
        reason TEXT,
        created_by TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        sync_uuid TEXT UNIQUE,
        source_device TEXT,
        deleted_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notes_journal (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'عام',
        content TEXT,
        created_by TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_uuid TEXT UNIQUE,
        source_device TEXT,
        deleted_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bank_account_audit (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        person_name TEXT NOT NULL,
        phone TEXT,
        account_name TEXT,
        operation_type TEXT NOT NULL DEFAULT 'بيع يومي',
        expected_amount REAL NOT NULL DEFAULT 0,
        received_amount REAL NOT NULL DEFAULT 0,
        remaining_amount REAL NOT NULL DEFAULT 0,
        payment_method TEXT,
        tx_date TEXT NOT NULL,
        status TEXT,
        notes TEXT,
        created_by TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_uuid TEXT UNIQUE,
        source_device TEXT,
        deleted_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS customer_debt_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        tx_type TEXT NOT NULL,
        amount REAL NOT NULL,
        tx_date TEXT NOT NULL,
        payment_method TEXT,
        notes TEXT,
        created_by TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        sync_uuid TEXT UNIQUE,
        source_device TEXT,
        deleted_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales_returns (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        return_no TEXT NOT NULL UNIQUE,
        sales_invoice_id INTEGER NOT NULL,
        customer_id INTEGER,
        return_date TEXT NOT NULL,
        reason TEXT,
        total_amount REAL NOT NULL DEFAULT 0,
        created_by TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        sync_uuid TEXT UNIQUE,
        source_device TEXT,
        deleted_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales_return_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        return_id INTEGER NOT NULL,
        sales_invoice_item_id INTEGER NOT NULL,
        item_id INTEGER NOT NULL,
        quantity REAL NOT NULL,
        sale_price REAL NOT NULL,
        line_total REAL NOT NULL,
        created_at TEXT,
        updated_at TEXT,
        sync_uuid TEXT UNIQUE,
        source_device TEXT,
        deleted_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS purchase_returns (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        return_no TEXT NOT NULL UNIQUE,
        purchase_invoice_id INTEGER NOT NULL,
        supplier_id INTEGER,
        return_date TEXT NOT NULL,
        reason TEXT,
        total_amount REAL NOT NULL DEFAULT 0,
        created_by TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        sync_uuid TEXT UNIQUE,
        source_device TEXT,
        deleted_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS purchase_return_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        return_id INTEGER NOT NULL,
        purchase_invoice_item_id INTEGER NOT NULL,
        item_id INTEGER NOT NULL,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        line_total REAL NOT NULL,
        created_at TEXT,
        updated_at TEXT,
        sync_uuid TEXT UNIQUE,
        source_device TEXT,
        deleted_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS stock_count_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_no TEXT NOT NULL UNIQUE,
        count_date TEXT NOT NULL,
        notes TEXT,
        created_by TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        sync_uuid TEXT UNIQUE,
        source_device TEXT,
        deleted_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS stock_count_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        item_id INTEGER NOT NULL,
        system_qty REAL NOT NULL,
        actual_qty REAL NOT NULL,
        diff_qty REAL NOT NULL,
        notes TEXT,
        created_at TEXT,
        updated_at TEXT,
        sync_uuid TEXT UNIQUE,
        source_device TEXT,
        deleted_at TEXT
      )
    ''');
  }

  Future<void> _ensureDeviceSettings() async {
    final id = await getSetting('sync_device_id');
    if (id.isEmpty) await setSetting('sync_device_id', 'mobile-${DateTime.now().millisecondsSinceEpoch}');
    final name = await getSetting('sync_device_name');
    if (name.isEmpty) await setSetting('sync_device_name', 'هاتف الدود ماركت');
    final last = await getSetting('sync_last_export_at');
    if (last.isEmpty) await setSetting('sync_last_export_at', '');
  }

  String _uuid(String table) => 'mobile-${DateTime.now().millisecondsSinceEpoch}-$table-${DateTime.now().microsecond}';

  Future<void> _seedIfEmpty() async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM items')) ?? 0;
    if (count > 0) return;
    final created = now();
    final device = await deviceId();
    await db.insert('items', {
      'name': 'بيبسي 250 مل', 'quantity': 24, 'purchase_price': 2.0, 'wholesale_price': 2.5, 'retail_price': 3.0,
      'warehouse_location': 'المخزن الرئيسي', 'notes': '', 'created_at': created, 'updated_at': created,
      'sync_uuid': _uuid('items'), 'source_device': device,
    });
    await db.insert('items', {
      'name': 'سكر 1 كيلو', 'quantity': 12, 'purchase_price': 4.0, 'wholesale_price': 4.5, 'retail_price': 5.0,
      'warehouse_location': 'رف 1', 'notes': '', 'created_at': created, 'updated_at': created,
      'sync_uuid': _uuid('items'), 'source_device': device,
    });
    await db.insert('customers', {
      'name': 'أحمد', 'phone': '0590000000', 'address': '', 'notes': 'عميل دائم', 'created_at': created, 'updated_at': created,
      'sync_uuid': _uuid('customers'), 'source_device': device,
    });
    await db.insert('suppliers', {
      'name': 'مورد تجريبي', 'phone': '0592222222', 'address': '', 'notes': 'توريد مواد غذائية', 'created_at': created, 'updated_at': created,
      'sync_uuid': _uuid('suppliers'), 'source_device': device,
    });
  }

  Future<void> loadAll() async {
    final db = await database;
    items
      ..clear()
      ..addAll((await db.query('items', where: 'deleted_at IS NULL', orderBy: 'name')).map((r) => ItemModel(
            id: (r['id'] as num).toInt(),
            name: '${r['name'] ?? ''}',
            quantity: (r['quantity'] as num?)?.toDouble() ?? 0,
            purchasePrice: (r['purchase_price'] as num?)?.toDouble() ?? 0,
            wholesalePrice: (r['wholesale_price'] as num?)?.toDouble() ?? 0,
            retailPrice: (r['retail_price'] as num?)?.toDouble() ?? 0,
            storagePlace: '${r['warehouse_location'] ?? ''}',
            supplier: '',
          )));
    customers
      ..clear()
      ..addAll((await db.query('customers', where: 'deleted_at IS NULL', orderBy: 'name')).map((r) => PersonModel(
            id: (r['id'] as num).toInt(),
            name: '${r['name'] ?? ''}',
            phone: '${r['phone'] ?? ''}',
            notes: '${r['notes'] ?? ''}',
          )));
    suppliers
      ..clear()
      ..addAll((await db.query('suppliers', where: 'deleted_at IS NULL', orderBy: 'name')).map((r) => PersonModel(
            id: (r['id'] as num).toInt(),
            name: '${r['name'] ?? ''}',
            phone: '${r['phone'] ?? ''}',
            notes: '${r['notes'] ?? ''}',
          )));
    bankOperations
      ..clear()
      ..addAll((await db.query('bank_account_audit', where: 'deleted_at IS NULL', orderBy: 'tx_date DESC')).map((r) => BankOperationModel(
            id: (r['id'] as num).toInt(),
            name: '${r['person_name'] ?? ''}',
            account: '${r['account_name'] ?? ''}',
            type: '${r['operation_type'] ?? ''}',
            originalAmount: (r['expected_amount'] as num?)?.toDouble() ?? 0,
            transferredAmount: (r['received_amount'] as num?)?.toDouble() ?? 0,
            date: DateTime.tryParse('${r['tx_date'] ?? ''}') ?? DateTime.now(),
            notes: '${r['notes'] ?? ''}',
          )));
  }

  Future<int> addItem({required String name, required double quantity, required double purchasePrice, required double wholesalePrice, required double retailPrice, String location = '', String notes = ''}) async {
    final db = await database;
    final created = now();
    final device = await deviceId();
    final id = await db.insert('items', {
      'name': name,
      'quantity': quantity,
      'purchase_price': purchasePrice,
      'wholesale_price': wholesalePrice,
      'retail_price': retailPrice,
      'warehouse_location': location,
      'notes': notes,
      'created_at': created,
      'updated_at': created,
      'sync_uuid': _uuid('items'),
      'source_device': device,
    });
    await loadAll();
    return id;
  }

  Future<int> addPerson(String table, {required String name, String phone = '', String notes = ''}) async {
    final db = await database;
    final created = now();
    final device = await deviceId();
    final id = await db.insert(table, {
      'name': name,
      'phone': phone,
      'address': '',
      'notes': notes,
      'created_at': created,
      'updated_at': created,
      'sync_uuid': _uuid(table),
      'source_device': device,
    });
    await loadAll();
    return id;
  }

  Future<int> createInvoice({required bool isSales, required List<Map<String, dynamic>> rows, int? partyId, double paidAmount = 0, String paymentMethod = 'كاش', String notes = ''}) async {
    if (rows.isEmpty) throw Exception('لا توجد أصناف في الفاتورة');
    final db = await database;
    final created = now();
    final device = await deviceId();
    final total = rows.fold<double>(0, (s, r) => s + (r['qty'] as double) * (r['price'] as double));
    final status = paidAmount >= total ? 'مدفوع' : (paidAmount > 0 ? 'جزئي' : 'غير مدفوع');
    return db.transaction<int>((txn) async {
      final invoiceNo = '${isSales ? 'M-S' : 'M-P'}-${DateTime.now().millisecondsSinceEpoch}';
      final invoiceId = await txn.insert(isSales ? 'sales_invoices' : 'purchase_invoices', isSales
          ? {
              'invoice_no': invoiceNo,
              'customer_id': partyId,
              'invoice_date': created,
              'payment_status': status,
              'payment_channel': paymentMethod,
              'paid_amount': paidAmount,
              'notes': notes,
              'total_amount': total,
              'created_at': created,
              'updated_at': created,
              'sync_uuid': _uuid('sales_invoices'),
              'source_device': device,
            }
          : {
              'invoice_no': invoiceNo,
              'supplier_id': partyId,
              'invoice_date': created,
              'payment_method': paymentMethod,
              'payment_status': status,
              'paid_amount': paidAmount,
              'notes': notes,
              'total_amount': total,
              'created_at': created,
              'updated_at': created,
              'sync_uuid': _uuid('purchase_invoices'),
              'source_device': device,
            });
      for (final r in rows) {
        final item = r['item'] as ItemModel;
        final qty = r['qty'] as double;
        final price = r['price'] as double;
        final line = qty * price;
        if (isSales) {
          await txn.insert('sales_invoice_items', {
            'invoice_id': invoiceId,
            'item_id': item.id,
            'quantity': qty,
            'sale_price': price,
            'purchase_ref_price': item.purchasePrice,
            'line_total': line,
            'created_at': created,
            'updated_at': created,
            'sync_uuid': _uuid('sales_invoice_items'),
            'source_device': device,
          });
          await txn.rawUpdate('UPDATE items SET quantity=quantity-?, updated_at=? WHERE id=?', [qty, created, item.id]);
          await txn.insert('stock_movements', {
            'item_id': item.id,
            'movement_type': 'خروج',
            'reference_type': 'sales_invoice',
            'reference_id': invoiceId,
            'quantity': qty,
            'notes': invoiceNo,
            'created_at': created,
            'updated_at': created,
            'sync_uuid': _uuid('stock_movements'),
            'source_device': device,
          });
        } else {
          await txn.insert('purchase_invoice_items', {
            'invoice_id': invoiceId,
            'item_id': item.id,
            'quantity': qty,
            'unit_price': price,
            'line_total': line,
            'notes': '',
            'created_at': created,
            'updated_at': created,
            'sync_uuid': _uuid('purchase_invoice_items'),
            'source_device': device,
          });
          await txn.rawUpdate('UPDATE items SET quantity=quantity+?, purchase_price=?, updated_at=? WHERE id=?', [qty, price, created, item.id]);
          await txn.insert('stock_movements', {
            'item_id': item.id,
            'movement_type': 'دخول',
            'reference_type': 'purchase_invoice',
            'reference_id': invoiceId,
            'quantity': qty,
            'notes': invoiceNo,
            'created_at': created,
            'updated_at': created,
            'sync_uuid': _uuid('stock_movements'),
            'source_device': device,
          });
        }
      }
      if (paidAmount > 0) {
        await txn.insert('payments', {
          'invoice_kind': isSales ? 'SALE' : 'PURCHASE',
          'invoice_id': invoiceId,
          'amount': paidAmount,
          'payment_method': paymentMethod,
          'notes': 'دفعة من فاتورة الهاتف',
          'created_by': 'mobile',
          'created_at': created,
          'updated_at': created,
          'sync_uuid': _uuid('payments'),
          'source_device': device,
        });
      }
      return invoiceId;
    }).then((id) async {
      await loadAll();
      return id;
    });
  }

  Future<void> addBankOperation({required String name, required String account, required String type, required double original, required double transferred, String notes = ''}) async {
    final db = await database;
    final created = now();
    final device = await deviceId();
    final remaining = original - transferred;
    final status = remaining <= 0 ? 'مسدد' : (transferred > 0 ? 'جزئي' : 'غير مسدد');
    await db.insert('bank_account_audit', {
      'person_name': name,
      'phone': '',
      'account_name': account,
      'operation_type': type,
      'expected_amount': original,
      'received_amount': transferred,
      'remaining_amount': remaining,
      'payment_method': '',
      'tx_date': created,
      'status': status,
      'notes': notes,
      'created_by': 'mobile',
      'created_at': created,
      'updated_at': created,
      'sync_uuid': _uuid('bank_account_audit'),
      'source_device': device,
    });
    await loadAll();
  }

  Future<Map<String, dynamic>> exportPayload({String kind = 'full'}) async {
    final db = await database;
    final created = now();
    final device = await deviceId();
    final lastExport = await getSetting('sync_last_export_at');
    final tables = <String, dynamic>{};
    for (final table in syncTables) {
      final exists = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name=?", [table]);
      if (exists.isEmpty) continue;
      final colsInfo = await db.rawQuery('PRAGMA table_info($table)');
      final cols = colsInfo.map((e) => '${e['name']}').toList();
      String? tsCol;
      for (final c in ['updated_at', 'created_at', 'tx_date', 'invoice_date', 'return_date', 'count_date']) {
        if (cols.contains(c)) {
          tsCol = c;
          break;
        }
      }
      List<Map<String, dynamic>> rows;
      if (kind == 'pending' && lastExport.isNotEmpty && tsCol != null) {
        rows = await db.query(table, where: "COALESCE($tsCol,'') >= ?", whereArgs: [lastExport], orderBy: 'id');
      } else {
        rows = await db.query(table, orderBy: 'id');
      }
      tables[table] = {'columns': cols, 'rows': rows};
    }
    final payload = {
      'package_version': packageVersion,
      'package_id': '$device-${DateTime.now().microsecondsSinceEpoch}',
      'package_kind': kind,
      'created_at': created,
      'source_device': device,
      'source_device_name': await deviceName(),
      'last_export_at': lastExport,
      'tables': tables,
    };
    await setSetting('sync_last_export_at', created);
    return payload;
  }

  Future<Map<String, int>> importPayload(Map<String, dynamic> payload, {String details = ''}) async {
    final db = await database;
    final packageId = '${payload['package_id'] ?? details}';
    final sourceDevice = '${payload['source_device'] ?? 'unknown'}';
    final kind = '${payload['package_kind'] ?? 'unknown'}';
    final existing = await db.query('sync_import_log', where: 'package_id=?', whereArgs: [packageId], limit: 1);
    if (existing.isNotEmpty) {
      return {'imported': 0, 'skipped': 0, 'conflicts': 0};
    }
    final tables = (payload['tables'] as Map?) ?? {};
    int imported = 0, skipped = 0, conflicts = 0;
    await db.transaction((txn) async {
      for (final table in syncTables) {
        final tableData = tables[table];
        if (tableData is! Map) continue;
        final exists = await txn.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name=?", [table]);
        if (exists.isEmpty) continue;
        final localCols = (await txn.rawQuery('PRAGMA table_info($table)')).map((e) => '${e['name']}').toSet();
        final rows = (tableData['rows'] as List?) ?? [];
        for (final raw in rows) {
          try {
            final row = Map<String, dynamic>.from(raw as Map);
            row['source_device'] = row['source_device'] ?? sourceDevice;
            row['sync_uuid'] = row['sync_uuid'] ?? _uuid(table);
            final uuid = '${row['sync_uuid']}';
            List<Map<String, dynamic>> found = await txn.query(table, where: 'sync_uuid=?', whereArgs: [uuid], limit: 1);
            if (found.isEmpty && row['id'] != null) {
              found = await txn.query(table, where: 'id=?', whereArgs: [row['id']], limit: 1);
            }
            if (found.isEmpty && (table == 'customers' || table == 'suppliers') && '${row['name'] ?? ''}'.isNotEmpty) {
              found = await txn.query(table, where: "name=? AND COALESCE(phone,'')=COALESCE(?, '')", whereArgs: [row['name'], row['phone']], limit: 1);
            }
            if (found.isEmpty && table == 'items' && '${row['name'] ?? ''}'.isNotEmpty) {
              found = await txn.query(table, where: 'name=?', whereArgs: [row['name']], limit: 1);
            }
            final clean = <String, dynamic>{};
            for (final e in row.entries) {
              if (localCols.contains(e.key)) clean[e.key] = e.value;
            }
            if (clean.isEmpty) {
              skipped++;
              continue;
            }
            if (found.isNotEmpty) {
              final id = found.first['id'];
              clean.remove('id');
              if (clean.isEmpty) {
                skipped++;
              } else {
                await txn.update(table, clean, where: 'id=?', whereArgs: [id]);
                imported++;
              }
            } else {
              await txn.insert(table, clean, conflictAlgorithm: ConflictAlgorithm.ignore);
              imported++;
            }
          } catch (e) {
            conflicts++;
            try {
              await txn.insert('sync_conflicts', {
                'package_id': packageId,
                'table_name': table,
                'row_uuid': raw is Map ? '${raw['sync_uuid'] ?? ''}' : '',
                'local_data': '',
                'incoming_data': jsonEncode(raw),
                'status': 'pending',
                'created_at': now(),
              });
            } catch (_) {}
          }
        }
      }
      await txn.insert('sync_import_log', {
        'package_id': packageId,
        'source_device': sourceDevice,
        'package_kind': kind,
        'imported_rows': imported,
        'skipped_rows': skipped,
        'conflicts': conflicts,
        'details': details,
        'created_at': now(),
      });
    });
    await loadAll();
    return {'imported': imported, 'skipped': skipped, 'conflicts': conflicts};
  }

  Future<Map<String, int>> syncStats() async {
    final db = await database;
    int total = 0;
    for (final t in syncTables) {
      final exists = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name=?", [t]);
      if (exists.isEmpty) continue;
      total += Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $t')) ?? 0;
    }
    final imports = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM sync_import_log')) ?? 0;
    final conflicts = Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM sync_conflicts WHERE status='pending'")) ?? 0;
    return {'total': total, 'imports': imports, 'conflicts': conflicts};
  }


  Future<List<Map<String, dynamic>>> debtRows() async {
    final db = await database;
    final result = <Map<String, dynamic>>[];

    final sales = await db.rawQuery('''
      SELECT 'دين عميل من فاتورة' AS kind, s.id AS ref_id, s.invoice_no AS ref_no,
             COALESCE(c.name,'-') AS party, s.invoice_date AS tx_date,
             s.total_amount AS total, s.paid_amount AS paid,
             (s.total_amount - s.paid_amount) AS remaining, s.payment_status AS status,
             COALESCE(s.notes,'') AS notes
      FROM sales_invoices s LEFT JOIN customers c ON s.customer_id=c.id
      WHERE s.deleted_at IS NULL AND s.total_amount > s.paid_amount
      ORDER BY s.id DESC
    ''');
    result.addAll(sales.map((e) => Map<String, dynamic>.from(e)));

    final purchases = await db.rawQuery('''
      SELECT 'دين مورد من فاتورة' AS kind, p.id AS ref_id, p.invoice_no AS ref_no,
             COALESCE(s.name,'-') AS party, p.invoice_date AS tx_date,
             p.total_amount AS total, p.paid_amount AS paid,
             (p.total_amount - p.paid_amount) AS remaining, p.payment_status AS status,
             COALESCE(p.notes,'') AS notes
      FROM purchase_invoices p LEFT JOIN suppliers s ON p.supplier_id=s.id
      WHERE p.deleted_at IS NULL AND p.total_amount > p.paid_amount
      ORDER BY p.id DESC
    ''');
    result.addAll(purchases.map((e) => Map<String, dynamic>.from(e)));

    final manual = await db.rawQuery('''
      SELECT 'دين عميل يدوي' AS kind, c.id AS ref_id, 'MANUAL-' || c.id AS ref_no,
             c.name AS party, MAX(t.tx_date) AS tx_date,
             SUM(CASE WHEN t.tx_type='دين' THEN t.amount ELSE 0 END) AS total,
             SUM(CASE WHEN t.tx_type='تسديد' THEN t.amount ELSE 0 END) AS paid,
             SUM(CASE WHEN t.tx_type='دين' THEN t.amount ELSE -t.amount END) AS remaining,
             CASE WHEN SUM(CASE WHEN t.tx_type='دين' THEN t.amount ELSE -t.amount END) <= 0 THEN 'مدفوع' ELSE 'مفتوح' END AS status,
             'معاملات دين يدوية' AS notes
      FROM customer_debt_transactions t INNER JOIN customers c ON t.customer_id=c.id
      WHERE t.deleted_at IS NULL
      GROUP BY c.id, c.name
      HAVING ABS(remaining) > 0.0001
      ORDER BY tx_date DESC
    ''');
    result.addAll(manual.map((e) => Map<String, dynamic>.from(e)));

    return result;
  }

  Future<int> addCustomerDebt({required int customerId, required double amount, String paymentMethod = 'دين', String notes = ''}) async {
    return _addCustomerDebtTx(customerId: customerId, txType: 'دين', amount: amount, paymentMethod: paymentMethod, notes: notes);
  }

  Future<int> payCustomerDebt({required int customerId, required double amount, String paymentMethod = 'نقدي', String notes = ''}) async {
    return _addCustomerDebtTx(customerId: customerId, txType: 'تسديد', amount: amount, paymentMethod: paymentMethod, notes: notes);
  }

  Future<int> _addCustomerDebtTx({required int customerId, required String txType, required double amount, String paymentMethod = '', String notes = ''}) async {
    if (amount <= 0) throw Exception('المبلغ يجب أن يكون أكبر من صفر');
    final db = await database;
    final created = now();
    final device = await deviceId();
    final id = await db.insert('customer_debt_transactions', {
      'customer_id': customerId,
      'tx_type': txType,
      'amount': amount,
      'tx_date': created,
      'payment_method': paymentMethod,
      'notes': notes,
      'created_by': 'mobile',
      'created_at': created,
      'updated_at': created,
      'sync_uuid': _uuid('customer_debt_transactions'),
      'source_device': device,
    });
    await loadAll();
    return id;
  }

  Future<void> payInvoiceDebt({required bool isSales, required int invoiceId, required double amount, String paymentMethod = 'نقدي', String notes = ''}) async {
    if (amount <= 0) throw Exception('المبلغ يجب أن يكون أكبر من صفر');
    final db = await database;
    final created = now();
    final device = await deviceId();
    final table = isSales ? 'sales_invoices' : 'purchase_invoices';
    final rows = await db.query(table, where: 'id=?', whereArgs: [invoiceId], limit: 1);
    if (rows.isEmpty) throw Exception('لم يتم العثور على الفاتورة');
    final total = (rows.first['total_amount'] as num?)?.toDouble() ?? 0;
    final paid = (rows.first['paid_amount'] as num?)?.toDouble() ?? 0;
    final remaining = total - paid;
    if (amount > remaining + 0.0001) throw Exception('مبلغ التسديد أكبر من المتبقي');
    final newPaid = paid + amount;
    final status = newPaid >= total ? 'مدفوع' : 'جزئي';
    await db.transaction((txn) async {
      await txn.update(table, {
        'paid_amount': newPaid,
        'payment_status': status,
        'updated_at': created,
      }, where: 'id=?', whereArgs: [invoiceId]);
      await txn.insert('payments', {
        'invoice_kind': isSales ? 'SALE' : 'PURCHASE',
        'invoice_id': invoiceId,
        'amount': amount,
        'payment_method': paymentMethod,
        'notes': notes,
        'created_by': 'mobile',
        'created_at': created,
        'updated_at': created,
        'sync_uuid': _uuid('payments'),
        'source_device': device,
      });
    });
    await loadAll();
  }

  Future<int> addFinancialPayment({required double amount, String category = 'عام', String executor = '', String notes = ''}) async {
    return _addFinancial(table: 'financial_payments', amount: amount, category: category, executor: executor, notes: notes);
  }

  Future<int> addFinancialWithdrawal({required double amount, String category = 'عام', String executor = '', String notes = ''}) async {
    return _addFinancial(table: 'financial_withdrawals', amount: amount, category: category, executor: executor, notes: notes);
  }

  Future<int> _addFinancial({required String table, required double amount, String category = 'عام', String executor = '', String notes = ''}) async {
    if (amount <= 0) throw Exception('المبلغ يجب أن يكون أكبر من صفر');
    final db = await database;
    final created = now();
    final device = await deviceId();
    final id = await db.insert(table, {
      'amount': amount,
      'category': category,
      'executor': executor,
      'tx_date': created,
      'notes': notes,
      'created_by': 'mobile',
      'created_at': created,
      'updated_at': created,
      'sync_uuid': _uuid(table),
      'source_device': device,
    });
    await loadAll();
    return id;
  }

  Future<List<Map<String, dynamic>>> financialRows() async {
    final db = await database;
    final payments = await db.rawQuery('''
      SELECT 'مدفوعة مالية' AS kind, amount, category, executor, tx_date, notes
      FROM financial_payments WHERE deleted_at IS NULL
    ''');
    final withdrawals = await db.rawQuery('''
      SELECT 'سحبة مالية' AS kind, amount, category, executor, tx_date, notes
      FROM financial_withdrawals WHERE deleted_at IS NULL
    ''');
    final rows = <Map<String, dynamic>>[];
    rows.addAll(payments.map((e) => Map<String, dynamic>.from(e)));
    rows.addAll(withdrawals.map((e) => Map<String, dynamic>.from(e)));
    rows.sort((a, b) => '${b['tx_date']}'.compareTo('${a['tx_date']}'));
    return rows;
  }

  double get inventoryPurchaseValue => items.fold(0, (sum, i) => sum + i.quantity * i.purchasePrice);
  double get inventoryWholesaleValue => items.fold(0, (sum, i) => sum + i.quantity * i.wholesalePrice);
  double get inventoryRetailValue => items.fold(0, (sum, i) => sum + i.quantity * i.retailPrice);
  double get expectedStockProfit => inventoryWholesaleValue - inventoryPurchaseValue;
}
