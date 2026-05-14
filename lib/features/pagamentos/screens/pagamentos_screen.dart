import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pagamento_provider.dart';
import '../widgets/pagamento_list_item.dart';
import '../widgets/pagamento_bottom_sheet.dart';
import '../../escolas/providers/escola_provider.dart';
import '../../escolas/models/escola.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/main_scaffold_key.dart';

const _labelOrdenacao = {
  OrdenacaoPagamento.nome: 'Nome',
  OrdenacaoPagamento.dataVencimento: 'Data de vencimento',
  OrdenacaoPagamento.valor: 'Valor',
};

class PagamentosScreen extends StatefulWidget {
  const PagamentosScreen({super.key});

  @override
  State<PagamentosScreen> createState() => _PagamentosScreenState();
}

class _PagamentosScreenState extends State<PagamentosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PagamentoProvider>().carregar();
      context.read<EscolaProvider>().carregar();
    });
  }

  void _navMes(BuildContext context, int delta) {
    final p = context.read<PagamentoProvider>();
    final atual = p.mesSelecionado;
    final novo = DateTime(atual.year, atual.month + delta);
    p.setMes(novo);
  }

  Future<void> _abrirPagamento(BuildContext context, pagamento) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PagamentoBottomSheet(
        pagamento: pagamento,
        onConfirmar: (valor, data) async {
          await context.read<PagamentoProvider>().marcarComoPago(
            pagamentoId: pagamento.id!,
            valorPago: valor,
            dataPagamento: data,
          );
        },
      ),
    );
  }

  Future<void> _desmarcar(BuildContext context, pagamento) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desfazer Pagamento'),
        content: const Text('Deseja desfazer o registro deste pagamento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await context.read<PagamentoProvider>().desmarcarPagamento(pagamento.id!);
    }
  }

  Future<void> _abrirFiltros(BuildContext context) async {
    final escolas = context.read<EscolaProvider>().escolas;
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar filtros',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 230),
      transitionBuilder: (ctx, anim, _, child) => SlideTransition(
        position: Tween(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
        child: child,
      ),
      pageBuilder: (ctx, _, _) => _FiltrosPanel(escolas: escolas),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagamentos'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => MainScaffoldKey.of(context)?.currentState?.openDrawer(),
        ),
        actions: [
          Consumer<PagamentoProvider>(
            builder: (context, provider, _) => IconButton(
              icon: Badge(
                isLabelVisible: provider.temFiltrosAtivos,
                child: const Icon(Icons.tune),
              ),
              tooltip: 'Filtros',
              onPressed: () => _abrirFiltros(context),
            ),
          ),
          Consumer<PagamentoProvider>(
            builder: (context, provider, _) => PopupMenuButton<OrdenacaoPagamento>(
              icon: const Icon(Icons.sort),
              tooltip: 'Ordenar por',
              onSelected: (v) => context.read<PagamentoProvider>().setOrdenacao(v),
              itemBuilder: (_) => OrdenacaoPagamento.values
                  .map(
                    (op) => PopupMenuItem(
                      value: op,
                      child: Row(
                        children: [
                          if (provider.ordenacao == op)
                            const Icon(Icons.check, size: 18)
                          else
                            const SizedBox(width: 18),
                          const SizedBox(width: 8),
                          Text(_labelOrdenacao[op]!),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildNavMes(context),
          const Divider(height: 1),
          _buildResumo(context),
          const Divider(height: 1),
          Expanded(child: _buildLista(context)),
        ],
      ),
    );
  }

  Widget _buildNavMes(BuildContext context) {
    final provider = context.watch<PagamentoProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _navMes(context, -1),
          ),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: provider.mesSelecionado,
                firstDate: DateTime(2020),
                lastDate: DateTime(2099),
                locale: const Locale('pt', 'BR'),
                initialDatePickerMode: DatePickerMode.year,
              );
              if (picked != null && context.mounted) {
                context.read<PagamentoProvider>().setMes(
                  DateTime(picked.year, picked.month),
                );
              }
            },
            child: Text(
              formatarMesAno(provider.mesSelecionado).toUpperCase(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _navMes(context, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildResumo(BuildContext context) {
    final p = context.watch<PagamentoProvider>();
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _resumoItem(context, 'Pagos', '${p.totalPagos}', Colors.green),
          _resumoItem(context, 'Pendentes', '${p.totalPendentes}', Colors.red),
          _resumoItem(context, 'Recebido', formatarMoeda(p.somaPagos), Colors.green),
          _resumoItem(context, 'A receber', formatarMoeda(p.somaPendentes), Colors.orange),
        ],
      ),
    );
  }

  Widget _resumoItem(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildLista(BuildContext context) {
    return Consumer<PagamentoProvider>(
      builder: (context, provider, _) {
        if (provider.carregando) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.pagamentos.isEmpty) {
          return const Center(child: Text('Nenhum pagamento encontrado.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: provider.pagamentos.length,
          itemBuilder: (context, index) {
            final pag = provider.pagamentos[index];
            return PagamentoListItem(
              pagamento: pag,
              onMarcarPago: () => _abrirPagamento(context, pag),
              onDesmarcar: () => _desmarcar(context, pag),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Painel lateral de filtros (desliza da esquerda)
// ─────────────────────────────────────────────────────────────────────────────

class _FiltrosPanel extends StatefulWidget {
  final List<Escola> escolas;

  const _FiltrosPanel({required this.escolas});

  @override
  State<_FiltrosPanel> createState() => _FiltrosPanelState();
}

class _FiltrosPanelState extends State<_FiltrosPanel> {
  late final TextEditingController _buscaCtrl;

  @override
  void initState() {
    super.initState();
    _buscaCtrl = TextEditingController(text: context.read<PagamentoProvider>().busca);
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PagamentoProvider>();
    final width = MediaQuery.of(context).size.width * 0.82;

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        elevation: 8,
        child: SafeArea(
          child: SizedBox(
            width: width,
            height: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
                  child: Row(
                    children: [
                      Text('Filtros', style: Theme.of(context).textTheme.titleLarge),
                      const Spacer(),
                      if (provider.temFiltrosAtivos)
                        TextButton(
                          onPressed: () {
                            provider.setEscolaFiltro(null);
                            provider.setHorarioFiltro(null);
                            provider.setBusca('');
                            provider.setStatusFiltro(null);
                            _buscaCtrl.clear();
                          },
                          child: const Text('Limpar'),
                        ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Busca
                      TextField(
                        controller: _buscaCtrl,
                        decoration: InputDecoration(
                          labelText: 'Buscar aluno',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          isDense: true,
                          suffixIcon: _buscaCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _buscaCtrl.clear();
                                    setState(() {});
                                    provider.setBusca('');
                                  },
                                )
                              : null,
                        ),
                        onChanged: (v) {
                          setState(() {});
                          provider.setBusca(v);
                        },
                      ),
                      const SizedBox(height: 16),
                      // Escola
                      DropdownButtonFormField<int?>(
                        key: ValueKey(provider.escolaFiltro),
                        initialValue: provider.escolaFiltro,
                        decoration: const InputDecoration(
                          labelText: 'Escola',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Todas')),
                          ...widget.escolas.map(
                            (e) => DropdownMenuItem(value: e.id, child: Text(e.nome)),
                          ),
                        ],
                        onChanged: (v) => provider.setEscolaFiltro(v),
                      ),
                      const SizedBox(height: 16),
                      // Horário
                      DropdownButtonFormField<String?>(
                        key: ValueKey(provider.horarioFiltro),
                        initialValue: provider.horarioFiltro,
                        decoration: const InputDecoration(
                          labelText: 'Horário',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Todos')),
                          DropdownMenuItem(value: 'manha', child: Text('Manhã')),
                          DropdownMenuItem(value: 'tarde', child: Text('Tarde')),
                          DropdownMenuItem(value: 'noite', child: Text('Noite')),
                          DropdownMenuItem(value: 'integral', child: Text('Integral')),
                        ],
                        onChanged: (v) => provider.setHorarioFiltro(v),
                      ),
                      const SizedBox(height: 20),
                      // Status
                      Text('Status', style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('Todos'),
                            selected: provider.statusFiltro == null,
                            onSelected: (_) => provider.setStatusFiltro(null),
                          ),
                          FilterChip(
                            label: const Text('Pagos'),
                            selected: provider.statusFiltro == 'pago',
                            onSelected: (_) => provider.setStatusFiltro(
                              provider.statusFiltro == 'pago' ? null : 'pago',
                            ),
                          ),
                          FilterChip(
                            label: const Text('Pendentes'),
                            selected: provider.statusFiltro == 'pendente',
                            onSelected: (_) => provider.setStatusFiltro(
                              provider.statusFiltro == 'pendente' ? null : 'pendente',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

