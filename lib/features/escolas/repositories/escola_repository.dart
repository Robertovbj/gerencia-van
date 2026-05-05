import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../models/escola.dart';

class EscolaRepository {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  Future<List<Escola>> listarTodas() async {
    final db = await _db;
    final maps = await db.query('escolas', orderBy: 'nome ASC');
    return maps.map(Escola.fromMap).toList();
  }

  Future<List<Escola>> listarAtivas() async {
    final db = await _db;
    final maps = await db.query(
      'escolas',
      where: 'ativo = 1',
      orderBy: 'nome ASC',
    );
    return maps.map(Escola.fromMap).toList();
  }

  Future<Escola?> buscarPorId(int id) async {
    final db = await _db;
    final maps = await db.query('escolas', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Escola.fromMap(maps.first);
  }

  Future<int> inserir(Escola escola) async {
    final db = await _db;
    final map = escola.toMap()..remove('id');
    return db.insert('escolas', map);
  }

  Future<int> atualizar(Escola escola) async {
    final db = await _db;
    return db.update(
      'escolas',
      escola.toMap(),
      where: 'id = ?',
      whereArgs: [escola.id],
    );
  }

  Future<bool> possuiAlunos(int escolaId) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as c FROM alunos WHERE escola_id = ?',
      [escolaId],
    );
    return (result.first['c'] as int) > 0;
  }

  Future<int> excluir(int id) async {
    final db = await _db;
    return db.delete('escolas', where: 'id = ?', whereArgs: [id]);
  }
}
