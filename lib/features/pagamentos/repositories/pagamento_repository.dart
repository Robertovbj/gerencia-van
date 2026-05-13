import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../models/pagamento.dart';
import '../../alunos/models/frequencia_dia.dart';

class PagamentoRepository {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  Future<List<Pagamento>> listarPorMes({
    required String mesReferencia,
    int? escolaId,
    String? horario,
    String? buscaNome,
  }) async {
    final db = await _db;
    final conditions = ['p.mes_referencia = ?'];
    final args = <dynamic>[mesReferencia];

    if (escolaId != null) {
      conditions.add('a.escola_id = ?');
      args.add(escolaId);
    }
    if (horario != null && horario.isNotEmpty) {
      conditions.add('a.horario = ?');
      args.add(horario);
    }
    if (buscaNome != null && buscaNome.isNotEmpty) {
      conditions.add("(a.nome LIKE ? OR a.apelido LIKE ?)");
      args.add('%$buscaNome%');
      args.add('%$buscaNome%');
    }

    final where = conditions.join(' AND ');
    final maps = await db.rawQuery('''
      SELECT p.*,
             a.nome as aluno_nome,
             a.apelido as aluno_apelido,
             a.horario as horario,
             a.dia_pagamento as dia_pagamento,
             e.nome as escola_nome
      FROM pagamentos p
      JOIN alunos a ON a.id = p.aluno_id
      JOIN escolas e ON e.id = a.escola_id
      WHERE $where
      ORDER BY p.pago ASC, a.nome ASC
    ''', args);

    return maps.map(Pagamento.fromMap).toList();
  }

  Future<List<Pagamento>> listarPorAluno(int alunoId) async {
    final db = await _db;
    final maps = await db.rawQuery('''
      SELECT p.*,
             a.nome as aluno_nome,
             a.apelido as aluno_apelido,
             a.horario as horario,
             e.nome as escola_nome
      FROM pagamentos p
      JOIN alunos a ON a.id = p.aluno_id
      JOIN escolas e ON e.id = a.escola_id
      WHERE p.aluno_id = ?
      ORDER BY p.mes_referencia DESC
    ''', [alunoId]);
    return maps.map(Pagamento.fromMap).toList();
  }

  Future<void> gerarPagamentosContrato({
    required int alunoId,
    required int contratoId,
    required DateTime dataInicio,
    required DateTime dataFim,
    required double valorMensalidade,
    String frequenciaTipo = 'mensal',
    List<FrequenciaDia> frequenciaDias = const [],
  }) async {
    final db = await _db;
    final batch = db.batch();

    DateTime current = DateTime(dataInicio.year, dataInicio.month);
    final fim = DateTime(dataFim.year, dataFim.month);

    while (!current.isAfter(fim)) {
      final mesRef =
          '${current.year}-${current.month.toString().padLeft(2, '0')}';

      if (frequenciaTipo == 'personalizada' && frequenciaDias.isNotEmpty) {
        for (final fd in frequenciaDias) {
          // Clamp ao último dia do mês
          final ultimoDia = DateTime(current.year, current.month + 1, 0).day;
          final diaReal = fd.dia > ultimoDia ? ultimoDia : fd.dia;
          final dataVenc =
              '$mesRef-${diaReal.toString().padLeft(2, '0')}';

          final existing = await db.query(
            'pagamentos',
            where:
                'aluno_id = ? AND contrato_id = ? AND mes_referencia = ? AND data_vencimento = ?',
            whereArgs: [alunoId, contratoId, mesRef, dataVenc],
          );

          if (existing.isEmpty) {
            batch.insert('pagamentos', {
              'aluno_id': alunoId,
              'contrato_id': contratoId,
              'mes_referencia': mesRef,
              'data_vencimento': dataVenc,
              'valor_previsto': fd.valor,
              'pago': 0,
            });
          }
        }
      } else {
        // Frequência mensal padrão
        final existing = await db.query(
          'pagamentos',
          where:
              'aluno_id = ? AND contrato_id = ? AND mes_referencia = ? AND data_vencimento IS NULL',
          whereArgs: [alunoId, contratoId, mesRef],
        );

        if (existing.isEmpty) {
          batch.insert('pagamentos', {
            'aluno_id': alunoId,
            'contrato_id': contratoId,
            'mes_referencia': mesRef,
            'data_vencimento': null,
            'valor_previsto': valorMensalidade,
            'pago': 0,
          });
        }
      }

      final nextMonth = current.month == 12 ? 1 : current.month + 1;
      final nextYear = current.month == 12 ? current.year + 1 : current.year;
      current = DateTime(nextYear, nextMonth);
    }

    await batch.commit(noResult: true);
  }

  /// Remove todos os pagamentos não pagos do contrato (usado ao regenerar
  /// após edição de aluno).
  Future<void> deleteUnpaidByContrato(int contratoId) async {
    final db = await _db;
    await db.delete(
      'pagamentos',
      where: 'contrato_id = ? AND pago = 0',
      whereArgs: [contratoId],
    );
  }

  Future<int> marcarComoPago({
    required int id,
    required double valorPago,
    required DateTime dataPagamento,
  }) async {
    final db = await _db;
    return db.update(
      'pagamentos',
      {
        'pago': 1,
        'valor_pago': valorPago,
        'data_pagamento': dataPagamento.toIso8601String().substring(0, 10),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> desmarcarPagamento(int id) async {
    final db = await _db;
    return db.update(
      'pagamentos',
      {'pago': 0, 'valor_pago': null, 'data_pagamento': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
