import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/aluno.dart';
import '../models/contrato.dart';
import '../models/frequencia_dia.dart';
import '../providers/aluno_provider.dart';
import '../repositories/frequencia_dia_repository.dart';
import '../../escolas/providers/escola_provider.dart';
import '../../pagamentos/providers/pagamento_provider.dart';
import '../../../core/utils/formatters.dart';

class AlunoFormScreen extends StatefulWidget {
  final Aluno? aluno;
  final Contrato? contrato;

  const AlunoFormScreen({super.key, this.aluno, this.contrato});

  @override
  State<AlunoFormScreen> createState() => _AlunoFormScreenState();
}

class _AlunoFormScreenState extends State<AlunoFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomeCtrl;
  late final TextEditingController _apelidoCtrl;
  late final TextEditingController _responsavelCtrl;
  late final TextEditingController _valorCtrl;

  int? _escolaId;
  String _horario = 'manha';
  int _diaPagamento = 1;
  String _frequenciaTipo = 'mensal';
  final List<_DiaCobranca> _diasCobranca = [];
  bool _ativo = true;

  DateTime _dataInicio = DateTime.now();
  DateTime _dataFim = DateTime(DateTime.now().year, 12, 31);

  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final a = widget.aluno;
    final c = widget.contrato;
    _nomeCtrl = TextEditingController(text: a?.nome ?? '');
    _apelidoCtrl = TextEditingController(text: a?.apelido ?? '');
    _responsavelCtrl = TextEditingController(text: a?.nomeResponsavel ?? '');
    _valorCtrl = TextEditingController(
      text: a != null ? a.valorMensalidade.toStringAsFixed(2).replaceAll('.', ',') : '',
    );
    _escolaId = a?.escolaId;
    _horario = a?.horario ?? 'manha';
    _diaPagamento = a?.diaPagamento ?? 1;
    _frequenciaTipo = a?.frequenciaTipo ?? 'mensal';
    _ativo = a?.ativo ?? true;
    _dataInicio = c?.dataInicio ?? DateTime.now();
    _dataFim = c?.dataFim ?? DateTime(DateTime.now().year, 12, 31);

    if (a?.id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _carregarFrequencia(a!.id!));
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _apelidoCtrl.dispose();
    _responsavelCtrl.dispose();
    _valorCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarFrequencia(int alunoId) async {
    final dias = await FrequenciaDiaRepository().listarPorAluno(alunoId);
    if (!mounted) return;
    setState(() {
      _diasCobranca
        ..clear()
        ..addAll(dias.map((d) => _DiaCobranca(dia: d.dia, valor: d.valor)));
    });
  }

  Future<void> _selecionarData({required bool isInicio}) async {
    final initial = isInicio ? _dataInicio : _dataFim;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2099),
      locale: const Locale('pt', 'BR'),
    );
    if (picked == null) return;
    setState(() {
      if (isInicio) {
        _dataInicio = picked;
      } else {
        _dataFim = picked;
      }
    });
  }

  Future<void> _abrirDialogDia({int? index}) async {
    final editando = index != null;
    // Dias já usados, excluindo o que está sendo editado
    final diasEmUso = _diasCobranca
        .asMap()
        .entries
        .where((e) => e.key != index)
        .map((e) => e.value.dia)
        .toList();

    final result = await showDialog<({int dia, double valor})>(
      context: context,
      builder: (ctx) => _DiaCobrancaDialog(
        diaInicial: editando ? _diasCobranca[index].dia : _primeiroDiaLivre(diasEmUso),
        valorInicial: editando ? _diasCobranca[index].valor : null,
        titulo: editando ? 'Editar dia de cobrança' : 'Adicionar dia de cobrança',
        excluirDias: diasEmUso,
      ),
    );

    if (result == null) return;

    setState(() {
      if (editando) {
        _diasCobranca[index] = _DiaCobranca(dia: result.dia, valor: result.valor);
      } else {
        _diasCobranca.add(_DiaCobranca(dia: result.dia, valor: result.valor));
      }
      _diasCobranca.sort((a, b) => a.dia.compareTo(b.dia));
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_escolaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma escola')),
      );
      return;
    }
    if (_dataFim.isBefore(_dataInicio)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data fim deve ser após data início')),
      );
      return;
    }
    if (_frequenciaTipo == 'personalizada' && _diasCobranca.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Adicione ao menos um dia de cobrança personalizado')),
      );
      return;
    }

    setState(() => _salvando = true);

    final valorStr = _valorCtrl.text.replaceAll('.', '').replaceAll(',', '.');
    final valor = double.tryParse(valorStr) ?? 0;

    final aluno = Aluno(
      id: widget.aluno?.id,
      nome: _nomeCtrl.text.trim(),
      apelido: _apelidoCtrl.text.trim().isEmpty ? null : _apelidoCtrl.text.trim(),
      nomeResponsavel: _responsavelCtrl.text.trim().isEmpty ? null : _responsavelCtrl.text.trim(),
      valorMensalidade: valor,
      escolaId: _escolaId!,
      horario: _horario,
      diaPagamento: _diaPagamento,
      frequenciaTipo: _frequenciaTipo,
      ativo: _ativo,
    );

    final contrato = Contrato(
      id: widget.contrato?.id,
      alunoId: widget.aluno?.id ?? 0,
      dataInicio: _dataInicio,
      dataFim: _dataFim,
    );

    final frequenciaDias = _diasCobranca
        .map((d) => FrequenciaDia(alunoId: aluno.id ?? 0, dia: d.dia, valor: d.valor))
        .toList();

    await context
        .read<AlunoProvider>()
        .salvar(aluno: aluno, contrato: contrato, frequenciaDias: frequenciaDias);
    if (mounted) context.read<PagamentoProvider>().carregar();

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmarExclusao(BuildContext context) async {
    final nome = widget.aluno!.nome;
    final alunoProvider = context.read<AlunoProvider>();
    final pagamentoProvider = context.read<PagamentoProvider>();
    final navigator = Navigator.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Aluno'),
        content: Text(
          'Tem certeza que deseja excluir "$nome"?\n\n'
          'Todos os contratos e pagamentos vinculados a este aluno também serão removidos permanentemente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _salvando = true);
      try {
        await alunoProvider.excluirAluno(widget.aluno!.id!);
        if (mounted) {
          pagamentoProvider.carregar();
          navigator.pop('deleted');
        }
      } finally {
        if (mounted) setState(() => _salvando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final escolas = context.watch<EscolaProvider>().escolasAtivas;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.aluno == null ? 'Novo Aluno' : 'Editar Aluno'),
        actions: [
          if (widget.aluno != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Excluir aluno',
              onPressed: _salvando ? null : () => _confirmarExclusao(context),
            ),
          TextButton(
            onPressed: _salvando ? null : _salvar,
            child: _salvando
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Salvar'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _secao('Dados do Aluno'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nomeCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome completo *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _apelidoCtrl,
              decoration: const InputDecoration(
                labelText: 'Apelido',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _responsavelCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome do responsável',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _valorCtrl,
              decoration: const InputDecoration(
                labelText: 'Valor da mensalidade (R\$) *',
                prefixText: 'R\$ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Obrigatório';
                final val = double.tryParse(v.replaceAll(',', '.'));
                if (val == null || val <= 0) return 'Valor inválido';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _escolaId,
              decoration: const InputDecoration(
                labelText: 'Escola *',
                border: OutlineInputBorder(),
              ),
              items: escolas
                  .map((e) => DropdownMenuItem(value: e.id, child: Text(e.nome)))
                  .toList(),
              onChanged: (v) => setState(() => _escolaId = v),
              validator: (v) => v == null ? 'Selecione uma escola' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _horario,
              decoration: const InputDecoration(
                labelText: 'Horário',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'manha', child: Text('Manhã')),
                DropdownMenuItem(value: 'tarde', child: Text('Tarde')),
                DropdownMenuItem(value: 'noite', child: Text('Noite')),
                DropdownMenuItem(value: 'integral', child: Text('Integral')),
              ],
              onChanged: (v) => setState(() => _horario = v ?? 'manha'),
            ),
            const SizedBox(height: 12),
            if (_frequenciaTipo == 'mensal')
              DropdownButtonFormField<int>(
                initialValue: _diaPagamento,
                decoration: const InputDecoration(
                  labelText: 'Dia do pagamento',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(
                  31,
                  (i) => DropdownMenuItem(value: i + 1, child: Text('Dia ${i + 1}')),
                ),
                onChanged: (v) => setState(() => _diaPagamento = v ?? 1),
              ),
            const SizedBox(height: 12),
            _buildFrequenciaSection(),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Aluno ativo'),
              value: _ativo,
              onChanged: (v) => setState(() => _ativo = v),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(height: 32),
            _secao('Contrato'),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _selecionarData(isInicio: true),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Data de início',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(formatarData(_dataInicio)),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _selecionarData(isInicio: false),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Data de término',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(formatarData(_dataFim)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  int _primeiroDiaLivre(List<int> emUso) {
    for (int d = 1; d <= 31; d++) {
      if (!emUso.contains(d)) return d;
    }
    return 1;
  }

  Widget _buildFrequenciaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _secao('Frequência de cobrança'),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'mensal',
              label: Text('Mensal'),
              icon: Icon(Icons.calendar_month),
            ),
            ButtonSegment(
              value: 'personalizada',
              label: Text('Personalizada'),
              icon: Icon(Icons.tune),
            ),
          ],
          selected: {_frequenciaTipo},
          onSelectionChanged: (s) =>
              setState(() => _frequenciaTipo = s.first),
          showSelectedIcon: false,
        ),
        if (_frequenciaTipo == 'personalizada') ...[
          const SizedBox(height: 12),
          if (_diasCobranca.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Nenhum dia configurado. Adicione ao menos um dia de cobrança.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...List.generate(_diasCobranca.length, (i) {
              final d = _diasCobranca[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('${d.dia}',
                        style: const TextStyle(fontSize: 13)),
                  ),
                  title: Text('Dia ${d.dia}'),
                  subtitle: Text(formatarMoeda(d.valor)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _abrirDialogDia(index: i),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        color: Colors.red,
                        onPressed: () =>
                            setState(() => _diasCobranca.removeAt(i)),
                      ),
                    ],
                  ),
                ),
              );
            }),
          OutlinedButton.icon(
            onPressed: () => _abrirDialogDia(),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar dia de cobrança'),
          ),
        ],
      ],
    );
  }

  Widget _secao(String titulo) => Text(
        titulo,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      );
}

class _DiaCobranca {
  int dia;
  double valor;
  _DiaCobranca({required this.dia, required this.valor});
}

class _DiaCobrancaDialog extends StatefulWidget {
  final int diaInicial;
  final double? valorInicial;
  final String titulo;
  final List<int> excluirDias;

  const _DiaCobrancaDialog({
    required this.diaInicial,
    required this.titulo,
    this.valorInicial,
    this.excluirDias = const [],
  });

  @override
  State<_DiaCobrancaDialog> createState() => _DiaCobrancaDialogState();
}

class _DiaCobrancaDialogState extends State<_DiaCobrancaDialog> {
  late int _dia;
  late final TextEditingController _valorCtrl;

  @override
  void initState() {
    super.initState();
    _dia = widget.diaInicial;
    _valorCtrl = TextEditingController(
      text: widget.valorInicial != null
          ? widget.valorInicial!.toStringAsFixed(2).replaceAll('.', ',')
          : '',
    );
  }

  @override
  void dispose() {
    _valorCtrl.dispose();
    super.dispose();
  }

  void _confirmar() {
    final v = double.tryParse(
        _valorCtrl.text.replaceAll('.', '').replaceAll(',', '.'));
    if (v == null || v <= 0) return;
    Navigator.of(context).pop((dia: _dia, valor: v));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            initialValue: _dia,
            decoration: const InputDecoration(
              labelText: 'Dia do mês',
              border: OutlineInputBorder(),
            ),
            items: List.generate(31, (i) => i + 1)
                .where((d) => !widget.excluirDias.contains(d))
                .map((d) => DropdownMenuItem(value: d, child: Text('Dia $d')))
                .toList(),
            onChanged: (v) => setState(() => _dia = v ?? _dia),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _valorCtrl,
            decoration: const InputDecoration(
              labelText: 'Valor (R\$)',
              prefixText: 'R\$ ',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: widget.valorInicial == null,
            onSubmitted: (_) => _confirmar(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _confirmar,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
