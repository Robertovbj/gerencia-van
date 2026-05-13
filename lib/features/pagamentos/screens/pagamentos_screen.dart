import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pagamento_provider.dart';
import '../widgets/pagamento_list_item.dart';
import '../widgets/pagamento_bottom_sheet.dart';
import '../../escolas/providers/escola_provider.dart';
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
  final _buscaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PagamentoProvider>().carregar();
      context.read<EscolaProvider>().carregar();
    });
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
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
          _buildFiltros(context),
          const Divider(height: 1),
          _buildResumo(context),
          const Divider(height: 1),
          Expanded(child: _buildLista(context)),
        ],
      ),
    );
  }

  Widget _buildFiltros(BuildContext context) {
    final provider = context.watch<PagamentoProvider>();
    final escolas = context.watch<EscolaProvider>().escolas;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          Row(
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
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
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
                    ...escolas.map(
                      (e) => DropdownMenuItem(value: e.id, child: Text(e.nome)),
                    ),
                  ],
                  onChanged: (v) => context.read<PagamentoProvider>().setEscolaFiltro(v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String?>(
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
                  onChanged: (v) => context.read<PagamentoProvider>().setHorarioFiltro(v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
                        context.read<PagamentoProvider>().setBusca('');
                      },
                    )
                  : null,
            ),
            onChanged: (v) => context.read<PagamentoProvider>().setBusca(v),
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
