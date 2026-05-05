import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'gerencia_van.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE escolas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        ativo INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE alunos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        apelido TEXT,
        nome_responsavel TEXT,
        valor_mensalidade REAL NOT NULL,
        escola_id INTEGER NOT NULL,
        horario TEXT NOT NULL DEFAULT 'manha',
        dia_pagamento INTEGER NOT NULL DEFAULT 1,
        ativo INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (escola_id) REFERENCES escolas(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE contratos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        aluno_id INTEGER NOT NULL,
        data_inicio TEXT NOT NULL,
        data_fim TEXT NOT NULL,
        FOREIGN KEY (aluno_id) REFERENCES alunos(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE pagamentos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        aluno_id INTEGER NOT NULL,
        contrato_id INTEGER NOT NULL,
        mes_referencia TEXT NOT NULL,
        valor_previsto REAL NOT NULL,
        valor_pago REAL,
        pago INTEGER NOT NULL DEFAULT 0,
        data_pagamento TEXT,
        FOREIGN KEY (aluno_id) REFERENCES alunos(id),
        FOREIGN KEY (contrato_id) REFERENCES contratos(id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // future migrations
  }
}
