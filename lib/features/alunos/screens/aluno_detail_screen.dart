import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/aluno.dart';
import '../models/contrato.dart';
import '../providers/aluno_provider.dart';
import 'aluno_form_screen.dart';
import '../../../core/utils/formatters.dart';

class AlunoDetailScreen extends StatefulWidget {
  final Aluno aluno;

  const AlunoDetailScreen({super.key, required this.aluno});

  @override
  State<AlunoDetailScreen> createState() => _AlunoDetailScreenState();
}

class _AlunoDetailScreenState extends State<AlunoDetailScreen> {
  List<Contrato> _contratos = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarContratos();
  }

  Future<void> _carregarContratos() async {
    final contratos = await context.read<AlunoProvider>().listarContratos(widget.aluno.id!);
    if (mounted) setState(() { _contratos = contratos; _carregando = false; });
  }

  Future<void> _adicionarContrato() async {
    DateTime inicio = DateTime(DateTime.now().year, 1, 1);
    DateTime fim = DateTime(DateTime.now().year, 12, 31);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Novo Contrato'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () async {
                  final p = await showDatePicker(
                    context: ctx,
                    initialDate: inicio,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2099),
                    locale: const Locale('pt', 'BR'),
                  );
                  if (p != null) setS(() => inicio = p);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data início',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(formatarData(inicio)),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final p = await showDatePicker(
                    context: ctx,
                    initialDate: fim,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2099),
                    locale: const Locale('pt', 'BR'),
                  );
                  if (p != null) setS(() => fim = p);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data fim',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(formatarData(fim)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                await context.read<AlunoProvider>().adicionarContrato(
                  alunoId: widget.aluno.id!,
                  valorMensalidade: widget.aluno.valorMensalidade,
                  contrato: Contrato(alunoId: widget.aluno.id!, dataInicio: inicio, dataFim: fim),
                );
                if (ctx.mounted) Navigator.of(ctx).pop();
                await _carregarContratos();
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aluno = widget.aluno;
    return Scaffold(
      appBar: AppBar(
        title: Text(aluno.nome),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final contrato = _contratos.isNotEmpty ? _contratos.first : null;
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => AlunoFormScreen(aluno: aluno, contrato: contrato),
              ));
              await _carregarContratos();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _infoCard(context, aluno),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Contratos', style: Theme.of(context).textTheme.titleMedium),
              TextButton.icon(
                onPressed: _adicionarContrato,
                icon: const Icon(Icons.add),
                label: const Text('Novo'),
              ),
            ],
          ),
          if (_carregando)
            const Center(child: CircularProgressIndicator())
          else if (_contratos.isEmpty)
            const Text('Nenhum contrato.')
          else
            ..._contratos.map((c) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.description),
                    title: Text('${formatarData(c.dataInicio)} → ${formatarData(c.dataFim)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Excluir contrato',
                      onPressed: () async {
                        final confirmar = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Excluir contrato'),
                            content: const Text(
                              'Se houver pagamentos já realizados, o contrato será encurtado '
                              'até o último mês pago e os demais pagamentos serão removidos.\n\n'
                              'Se não houver nenhum pagamento realizado, o contrato será excluído completamente.\n\n'
                              'Deseja continuar?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancelar'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(ctx).colorScheme.error,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Excluir'),
                              ),
                            ],
                          ),
                        );
                        if (confirmar == true) {
                          await context.read<AlunoProvider>().excluirContrato(c.id!);
                          await _carregarContratos();
                        }
                      },
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _infoCard(BuildContext context, Aluno aluno) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (aluno.apelido != null && aluno.apelido!.isNotEmpty)
              _info('Apelido', aluno.apelido!),
            if (aluno.nomeResponsavel != null && aluno.nomeResponsavel!.isNotEmpty)
              _info('Responsável', aluno.nomeResponsavel!),
            _info('Escola', aluno.escolaNome ?? '—'),
            _info('Horário', labelHorario(aluno.horario)),
            _info('Mensalidade', formatarMoeda(aluno.valorMensalidade)),
            _info('Dia pagamento', 'Dia ${aluno.diaPagamento}'),
            _info('Status', aluno.ativo ? 'Ativo' : 'Inativo'),
          ],
        ),
      ),
    );
  }

  Widget _info(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );
}
