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

  /// Se o contrato tiver pagamentos já realizados, encurta o contrato até
  /// o último mês com pagamento pago e remove os pagamentos não pagos restantes.
  /// Se não houver nenhum pagamento pago, exclui o contrato inteiramente.
  Future<void> excluir(int contratoId) async {
    final db = await _db;
    await db.transaction((txn) async {
      // Busca o último mês com pagamento pago
      final pagos = await txn.query(
        'pagamentos',
        columns: ['mes_referencia'],
        where: 'contrato_id = ? AND pago = 1',
        whereArgs: [contratoId],
        orderBy: 'mes_referencia DESC',
        limit: 1,
      );

      if (pagos.isNotEmpty) {
        // Tem pagamentos pagos: encurta data_fim para o último dia do último mês pago
        final ultimoMes = pagos.first['mes_referencia'] as String;
        final parts = ultimoMes.split('-');
        final ano = int.parse(parts[0]);
        final mes = int.parse(parts[1]);
        final ultimoDia = DateTime(ano, mes + 1, 0); // dia 0 do mês seguinte = último dia do mês atual
        final novaDataFim =
            '${ultimoDia.year}-${ultimoDia.month.toString().padLeft(2, '0')}-${ultimoDia.day.toString().padLeft(2, '0')}';

        await txn.update(
          'contratos',
          {'data_fim': novaDataFim},
          where: 'id = ?',
          whereArgs: [contratoId],
        );
        // Remove apenas os pagamentos não pagos
        await txn.delete(
          'pagamentos',
          where: 'contrato_id = ? AND pago = 0',
          whereArgs: [contratoId],
        );
      } else {
        // Sem nenhum pagamento pago: exclui tudo
        await txn.delete(
          'pagamentos',
          where: 'contrato_id = ?',
          whereArgs: [contratoId],
        );
        await txn.delete(
          'contratos',
          where: 'id = ?',
          whereArgs: [contratoId],
        );
      }
    });
  }
}
