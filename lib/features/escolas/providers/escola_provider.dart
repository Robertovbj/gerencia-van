import 'package:flutter/material.dart';
import '../models/escola.dart';
import '../repositories/escola_repository.dart';

class EscolaProvider extends ChangeNotifier {
  final _repo = EscolaRepository();

  List<Escola> _escolas = [];
  List<Escola> get escolas => _escolas;

  List<Escola> get escolasAtivas =>
      _escolas.where((e) => e.ativo).toList();

  bool _carregando = false;
  bool get carregando => _carregando;

  String? _erro;
  String? get erro => _erro;

  Future<void> carregar() async {
    _carregando = true;
    _erro = null;
    notifyListeners();
    try {
      _escolas = await _repo.listarTodas();
    } catch (e) {
      _erro = e.toString();
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<void> salvar(Escola escola) async {
    if (escola.id == null) {
      await _repo.inserir(escola);
    } else {
      await _repo.atualizar(escola);
    }
    await carregar();
  }

  Future<bool> excluir(Escola escola) async {
    final temAlunos = await _repo.possuiAlunos(escola.id!);
    if (temAlunos) return false;
    await _repo.excluir(escola.id!);
    await carregar();
    return true;
  }
}
