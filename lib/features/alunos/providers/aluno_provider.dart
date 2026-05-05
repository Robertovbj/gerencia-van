import 'package:flutter/material.dart';
import '../models/aluno.dart';
import '../models/contrato.dart';
import '../repositories/aluno_repository.dart';
import '../repositories/contrato_repository.dart';
import '../../pagamentos/repositories/pagamento_repository.dart';

class AlunoProvider extends ChangeNotifier {
  final _alunoRepo = AlunoRepository();
  final _contratoRepo = ContratoRepository();
  final _pagamentoRepo = PagamentoRepository();

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
  }) async {
    int alunoId;
    if (aluno.id == null) {
      alunoId = await _alunoRepo.inserir(aluno);
    } else {
      alunoId = aluno.id!;
      await _alunoRepo.atualizar(aluno);
    }

    final contratoComAluno = contrato.copyWith(alunoId: alunoId);
    int contratoId;
    if (contrato.id == null) {
      contratoId = await _contratoRepo.inserir(contratoComAluno);
    } else {
      contratoId = contrato.id!;
      await _contratoRepo.atualizar(contratoComAluno);
    }

    await _pagamentoRepo.gerarPagamentosContrato(
      alunoId: alunoId,
      contratoId: contratoId,
      dataInicio: contrato.dataInicio,
      dataFim: contrato.dataFim,
      valorMensalidade: aluno.valorMensalidade,
    );

    await carregar();
  }

  Future<List<Contrato>> listarContratos(int alunoId) async {
    return _contratoRepo.listarPorAluno(alunoId);
  }

  Future<void> adicionarContrato({
    required int alunoId,
    required double valorMensalidade,
    required Contrato contrato,
  }) async {
    final contratoComAluno = contrato.copyWith(alunoId: alunoId);
    final contratoId = await _contratoRepo.inserir(contratoComAluno);
    await _pagamentoRepo.gerarPagamentosContrato(
      alunoId: alunoId,
      contratoId: contratoId,
      dataInicio: contrato.dataInicio,
      dataFim: contrato.dataFim,
      valorMensalidade: valorMensalidade,
    );
    await carregar();
  }
}
