import 'package:flutter/material.dart';
import '../models/aluno.dart';
import '../models/contrato.dart';
import '../models/frequencia_dia.dart';
import '../repositories/aluno_repository.dart';
import '../repositories/contrato_repository.dart';
import '../repositories/frequencia_dia_repository.dart';
import '../../../core/services/sync_service.dart';
import '../../pagamentos/repositories/pagamento_repository.dart';

class AlunoProvider extends ChangeNotifier {
  final _alunoRepo = AlunoRepository();
  final _contratoRepo = ContratoRepository();
  final _pagamentoRepo = PagamentoRepository();
  final _frequenciaRepo = FrequenciaDiaRepository();

  List<Aluno> _alunos = [];
  List<Aluno> get alunos => _alunos;

  bool _carregando = false;
  bool get carregando => _carregando;

  String? _erro;
  String? get erro => _erro;

  Future<void> carregar() async {
    _carregando = true;
    _erro = null;
    notifyListeners();
    try {
      _alunos = await _alunoRepo.listarTodos();
    } catch (e) {
      _erro = e.toString();
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<void> salvar({
    required Aluno aluno,
    required Contrato contrato,
    List<FrequenciaDia> frequenciaDias = const [],
  }) async {
    int alunoId;
    if (aluno.id == null) {
      alunoId = await _alunoRepo.inserir(aluno);
    } else {
      alunoId = aluno.id!;
      await _alunoRepo.atualizar(aluno);
    }

    // Persiste os dias de cobrança personalizada
    if (aluno.frequenciaTipo == 'personalizada') {
      await _frequenciaRepo.salvarTodos(alunoId, frequenciaDias);
    } else {
      await _frequenciaRepo.excluirPorAluno(alunoId);
    }

    final contratoComAluno = contrato.copyWith(alunoId: alunoId);
    int contratoId;
    if (contrato.id == null) {
      contratoId = await _contratoRepo.inserir(contratoComAluno);
    } else {
      contratoId = contrato.id!;
      await _contratoRepo.atualizar(contratoComAluno);
      // Regenera pagamentos não pagos com a configuração atual
      await _pagamentoRepo.deleteUnpaidByContrato(contratoId);
    }

    await _pagamentoRepo.gerarPagamentosContrato(
      alunoId: alunoId,
      contratoId: contratoId,
      dataInicio: contrato.dataInicio,
      dataFim: contrato.dataFim,
      valorMensalidade: aluno.valorMensalidade,
      frequenciaTipo: aluno.frequenciaTipo,
      frequenciaDias: frequenciaDias,
    );

    await carregar();
    SyncService.instance.scheduleSync();
  }

  Future<List<Contrato>> listarContratos(int alunoId) async {
    return _contratoRepo.listarPorAluno(alunoId);
  }

  Future<void> adicionarContrato({
    required int alunoId,
    required double valorMensalidade,
    required Contrato contrato,
  }) async {
    final aluno = _alunos.firstWhere((a) => a.id == alunoId);
    final frequenciaDias = await _frequenciaRepo.listarPorAluno(alunoId);
    final contratoComAluno = contrato.copyWith(alunoId: alunoId);
    final contratoId = await _contratoRepo.inserir(contratoComAluno);
    await _pagamentoRepo.gerarPagamentosContrato(
      alunoId: alunoId,
      contratoId: contratoId,
      dataInicio: contrato.dataInicio,
      dataFim: contrato.dataFim,
      valorMensalidade: valorMensalidade,
      frequenciaTipo: aluno.frequenciaTipo,
      frequenciaDias: frequenciaDias,
    );
    await carregar();
    SyncService.instance.scheduleSync();
  }

  Future<void> excluirContrato(int contratoId) async {
    await _contratoRepo.excluir(contratoId);
    await carregar();
    SyncService.instance.scheduleSync();
  }

  /// Para cada aluno em [alunoIds], adiciona um contrato de [dataInicio] a [dataFim].
  /// Se o aluno já tiver um contrato cujo fim seja >= dataInicio, o início
  /// desse novo contrato é adiado para o primeiro dia do mês seguinte ao fim
  /// do contrato existente mais recente que conflite.
  Future<void> renovarContratos({
    required List<int> alunoIds,
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    for (final alunoId in alunoIds) {
      final aluno = _alunos.firstWhere((a) => a.id == alunoId);
      final contratos = await _contratoRepo.listarPorAluno(alunoId);

      DateTime inicio = dataInicio;

      // Verifica conflito: contrato existente cujo fim >= dataInicio
      final conflitantes = contratos
          .where((c) => !c.dataFim.isBefore(dataInicio))
          .toList();

      if (conflitantes.isNotEmpty) {
        // Pega o fim mais distante entre os conflitantes
        final fimMaisLonge = conflitantes
            .map((c) => c.dataFim)
            .reduce((a, b) => a.isAfter(b) ? a : b);
        // Início = primeiro dia do mês seguinte ao fim mais longo
        final proximoMes = fimMaisLonge.month == 12
            ? 1
            : fimMaisLonge.month + 1;
        final proximoAno = fimMaisLonge.month == 12
            ? fimMaisLonge.year + 1
            : fimMaisLonge.year;
        inicio = DateTime(proximoAno, proximoMes, 1);
      }

      // Só adiciona se o início ajustado ainda for antes do fim
      if (!inicio.isAfter(dataFim)) {
        final frequenciaDias = await _frequenciaRepo.listarPorAluno(alunoId);
        final contratoId = await _contratoRepo.inserir(
          Contrato(alunoId: alunoId, dataInicio: inicio, dataFim: dataFim),
        );
        await _pagamentoRepo.gerarPagamentosContrato(
          alunoId: alunoId,
          contratoId: contratoId,
          dataInicio: inicio,
          dataFim: dataFim,
          valorMensalidade: aluno.valorMensalidade,
          frequenciaTipo: aluno.frequenciaTipo,
          frequenciaDias: frequenciaDias,
        );
      }
    }
    await carregar();
    SyncService.instance.scheduleSync();
  }
}
