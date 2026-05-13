import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../models/frequencia_dia.dart';

class FrequenciaDiaRepository {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  Future<List<FrequenciaDia>> listarPorAluno(int alunoId) async {
    final db = await _db;
    final maps = await db.query(
      'frequencia_dias',
      where: 'aluno_id = ?',
      whereArgs: [alunoId],
      orderBy: 'dia ASC',
    );
    return maps.map(FrequenciaDia.fromMap).toList();
  }

  /// Substitui todos os dias de cobrança do aluno pelos fornecidos.
  Future<void> salvarTodos(int alunoId, List<FrequenciaDia> dias) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete(
        'frequencia_dias',
        where: 'aluno_id = ?',
        whereArgs: [alunoId],
      );
      for (final d in dias) {
        await txn.insert('frequencia_dias', {
          'aluno_id': alunoId,
          'dia': d.dia,
          'valor': d.valor,
        });
      }
    });
  }

  Future<void> excluirPorAluno(int alunoId) async {
    final db = await _db;
    await db.delete('frequencia_dias', where: 'aluno_id = ?', whereArgs: [alunoId]);
  }
}
