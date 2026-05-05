import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../models/contrato.dart';

class ContratoRepository {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  Future<List<Contrato>> listarPorAluno(int alunoId) async {
    final db = await _db;
    final maps = await db.query(
      'contratos',
      where: 'aluno_id = ?',
      whereArgs: [alunoId],
      orderBy: 'data_inicio DESC',
    );
    return maps.map(Contrato.fromMap).toList();
  }

  Future<Contrato?> buscarPorId(int id) async {
    final db = await _db;
    final maps = await db.query('contratos', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Contrato.fromMap(maps.first);
  }

  Future<int> inserir(Contrato contrato) async {
    final db = await _db;
    final map = contrato.toMap()..remove('id');
    return db.insert('contratos', map);
  }

  Future<int> atualizar(Contrato contrato) async {
    final db = await _db;
    return db.update(
      'contratos',
      contrato.toMap(),
      where: 'id = ?',
      whereArgs: [contrato.id],
    );
  }
}
