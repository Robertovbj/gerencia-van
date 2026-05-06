import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../models/aluno.dart';

class AlunoRepository {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  Future<List<Aluno>> listarTodos() async {
    final db = await _db;
    final maps = await db.rawQuery('''
      SELECT a.*, e.nome as escola_nome
      FROM alunos a
      LEFT JOIN escolas e ON e.id = a.escola_id
      ORDER BY a.ativo DESC, a.nome ASC
    ''');
    return maps.map(Aluno.fromMap).toList();
  }

  Future<Aluno?> buscarPorId(int id) async {
    final db = await _db;
    final maps = await db.rawQuery('''
      SELECT a.*, e.nome as escola_nome
      FROM alunos a
      LEFT JOIN escolas e ON e.id = a.escola_id
      WHERE a.id = ?
    ''', [id]);
    if (maps.isEmpty) return null;
    return Aluno.fromMap(maps.first);
  }

  Future<int> inserir(Aluno aluno) async {
    final db = await _db;
    final map = aluno.toMap()..remove('id');
    return db.insert('alunos', map);
  }

  Future<int> atualizar(Aluno aluno) async {
    final db = await _db;
    return db.update(
      'alunos',
      aluno.toMap(),
      where: 'id = ?',
      whereArgs: [aluno.id],
    );
  }

  Future<int> excluir(int id) async {
    final db = await _db;
    return db.delete('alunos', where: 'id = ?', whereArgs: [id]);
  }
}
