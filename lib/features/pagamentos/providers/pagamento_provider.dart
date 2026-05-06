import 'package:flutter/material.dart';
import '../models/pagamento.dart';
import '../repositories/pagamento_repository.dart';
import '../../../core/services/sync_service.dart';

class PagamentoProvider extends ChangeNotifier {
  final _repo = PagamentoRepository();

  List<Pagamento> _pagamentos = [];
  List<Pagamento> get pagamentos => _pagamentos;

  DateTime _mesSelecionado = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime get mesSelecionado => _mesSelecionado;

  int? _escolaFiltro;
  int? get escolaFiltro => _escolaFiltro;

  String? _horarioFiltro;
  String? get horarioFiltro => _horarioFiltro;

  String _busca = '';
  String get busca => _busca;

  bool _carregando = false;
  bool get carregando => _carregando;

  void setMes(DateTime mes) {
    _mesSelecionado = mes;
    carregar();
  }

  void setEscolaFiltro(int? escolaId) {
    _escolaFiltro = escolaId;
    carregar();
  }

  void setHorarioFiltro(String? horario) {
    _horarioFiltro = horario;
    carregar();
  }

  void setBusca(String valor) {
    _busca = valor;
    carregar();
  }

  String get _mesRef {
    return '${_mesSelecionado.year}-${_mesSelecionado.month.toString().padLeft(2, '0')}';
  }

  Future<void> carregar() async {
    _carregando = true;
    notifyListeners();
    try {
      _pagamentos = await _repo.listarPorMes(
        mesReferencia: _mesRef,
        escolaId: _escolaFiltro,
        horario: (_horarioFiltro != null && _horarioFiltro!.isNotEmpty) ? _horarioFiltro : null,
        buscaNome: _busca.isNotEmpty ? _busca : null,
      );
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<void> marcarComoPago({
    required int pagamentoId,
    required double valorPago,
    required DateTime dataPagamento,
  }) async {
    await _repo.marcarComoPago(
      id: pagamentoId,
      valorPago: valorPago,
      dataPagamento: dataPagamento,
    );
    await carregar();
    SyncService.instance.scheduleSync();
  }

  Future<void> desmarcarPagamento(int pagamentoId) async {
    await _repo.desmarcarPagamento(pagamentoId);
    await carregar();
    SyncService.instance.scheduleSync();
  }

  int get totalPagos => _pagamentos.where((p) => p.pago).length;
  int get totalPendentes => _pagamentos.where((p) => !p.pago).length;
  double get somaPagos => _pagamentos
      .where((p) => p.pago)
      .fold(0.0, (sum, p) => sum + (p.valorPago ?? 0));
  double get somaPendentes => _pagamentos
      .where((p) => !p.pago)
      .fold(0.0, (sum, p) => sum + p.valorPrevisto);
}
