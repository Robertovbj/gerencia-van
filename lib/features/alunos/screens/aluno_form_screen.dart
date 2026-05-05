import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/aluno.dart';
import '../models/contrato.dart';
import '../providers/aluno_provider.dart';
import '../../escolas/providers/escola_provider.dart';
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
  bool _ativo = true;

  DateTime _dataInicio = DateTime(DateTime.now().year, 1, 1);
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
    _ativo = a?.ativo ?? true;
    _dataInicio = c?.dataInicio ?? DateTime(DateTime.now().year, 1, 1);
    _dataFim = c?.dataFim ?? DateTime(DateTime.now().year, 12, 31);
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _apelidoCtrl.dispose();
    _responsavelCtrl.dispose();
    _valorCtrl.dispose();
    super.dispose();
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
      ativo: _ativo,
    );

    final contrato = Contrato(
      id: widget.contrato?.id,
      alunoId: widget.aluno?.id ?? 0,
      dataInicio: _dataInicio,
      dataFim: _dataFim,
    );

    await context.read<AlunoProvider>().salvar(aluno: aluno, contrato: contrato);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final escolas = context.watch<EscolaProvider>().escolasAtivas;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.aluno == null ? 'Novo Aluno' : 'Editar Aluno'),
        actions: [
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

  Widget _secao(String titulo) => Text(
        titulo,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      );
}
