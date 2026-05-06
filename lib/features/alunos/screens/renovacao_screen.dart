import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/aluno.dart';
import '../providers/aluno_provider.dart';
import '../../pagamentos/providers/pagamento_provider.dart';
import '../../../core/utils/formatters.dart';

class RenovacaoScreen extends StatefulWidget {
  const RenovacaoScreen({super.key});

  @override
  State<RenovacaoScreen> createState() => _RenovacaoScreenState();
}

class _RenovacaoScreenState extends State<RenovacaoScreen> {
  final Set<int> _selecionados = {};
  DateTime _dataInicio = DateTime(DateTime.now().year + 1, 1, 1);
  DateTime _dataFim = DateTime(DateTime.now().year + 1, 12, 31);
  bool _salvando = false;

  List<Aluno> get _alunosAtivos =>
      context.read<AlunoProvider>().alunos.where((a) => a.ativo).toList();

  bool get _todosMarcados =>
      _alunosAtivos.isNotEmpty &&
      _alunosAtivos.every((a) => _selecionados.contains(a.id));

  void _toggleTodos(bool? value) {
    setState(() {
      if (value == true) {
        _selecionados.addAll(_alunosAtivos.map((a) => a.id!));
      } else {
        _selecionados.clear();
      }
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

  Future<void> _renovar() async {
    if (_selecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione ao menos um aluno.')),
      );
      return;
    }
    if (_dataFim.isBefore(_dataInicio)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data fim deve ser após data início.')),
      );
      return;
    }

    setState(() => _salvando = true);
    try {
      await context.read<AlunoProvider>().renovarContratos(
        alunoIds: _selecionados.toList(),
        dataInicio: _dataInicio,
        dataFim: _dataFim,
      );
      if (mounted) context.read<PagamentoProvider>().carregar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contratos renovados com sucesso!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao renovar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final alunos = _alunosAtivos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Renovar Contratos'),
        actions: [
          TextButton(
            onPressed: _salvando ? null : _renovar,
            child: _salvando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Renovar'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Seleção de período
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Período do novo contrato',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selecionarData(isInicio: true),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Data início',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                            isDense: true,
                          ),
                          child: Text(formatarData(_dataInicio)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selecionarData(isInicio: false),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Data fim',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                            isDense: true,
                          ),
                          child: Text(formatarData(_dataFim)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Cabeçalho com "marcar todos"
          CheckboxListTile(
            value: _todosMarcados,
            tristate: false,
            onChanged: alunos.isEmpty ? null : _toggleTodos,
            title: Text(
              'Selecionar todos (${_selecionados.length}/${alunos.length})',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const Divider(height: 1),
          // Lista de alunos
          Expanded(
            child: alunos.isEmpty
                ? const Center(child: Text('Nenhum aluno ativo.'))
                : ListView.builder(
                    itemCount: alunos.length,
                    itemBuilder: (context, index) {
                      final aluno = alunos[index];
                      final marcado = _selecionados.contains(aluno.id);
                      return CheckboxListTile(
                        value: marcado,
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selecionados.add(aluno.id!);
                            } else {
                              _selecionados.remove(aluno.id);
                            }
                          });
                        },
                        title: Text(aluno.nome),
                        subtitle: Text(
                          '${aluno.escolaNome ?? '—'} · ${labelHorario(aluno.horario)}',
                        ),
                        secondary: Text(
                          formatarMoeda(aluno.valorMensalidade),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
