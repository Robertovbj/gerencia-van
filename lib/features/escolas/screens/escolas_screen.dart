import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/escola.dart';
import '../providers/escola_provider.dart';
import '../widgets/escola_list_item.dart';

class EscolasScreen extends StatefulWidget {
  const EscolasScreen({super.key});

  @override
  State<EscolasScreen> createState() => _EscolasScreenState();
}

class _EscolasScreenState extends State<EscolasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EscolaProvider>().carregar();
    });
  }

  Future<void> _abrirFormulario(BuildContext context, {Escola? escola}) async {
    final nomeController = TextEditingController(text: escola?.nome ?? '');
    bool ativo = escola?.ativo ?? true;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text(escola == null ? 'Nova Escola' : 'Editar Escola'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da escola',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Escola ativa'),
                  value: ativo,
                  onChanged: (v) => setStateDialog(() => ativo = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final nova = (escola ?? const Escola(nome: '')).copyWith(
                  nome: nomeController.text.trim(),
                  ativo: ativo,
                );
                await context.read<EscolaProvider>().salvar(nova);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _excluir(BuildContext context, Escola escola) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Escola'),
        content: Text('Deseja excluir "${escola.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!context.mounted) return;

    final sucesso = await context.read<EscolaProvider>().excluir(escola);
    if (!context.mounted) return;

    if (!sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não é possível excluir: escola possui alunos vinculados.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escolas')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(context),
        child: const Icon(Icons.add),
      ),
      body: Consumer<EscolaProvider>(
        builder: (context, provider, _) {
          if (provider.carregando) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.escolas.isEmpty) {
            return const Center(
              child: Text('Nenhuma escola cadastrada.\nToque em + para adicionar.'),
            );
          }
          return ListView.builder(
            itemCount: provider.escolas.length,
            itemBuilder: (context, index) {
              final escola = provider.escolas[index];
              return EscolaListItem(
                escola: escola,
                onTap: () => _abrirFormulario(context, escola: escola),
                onDelete: () => _excluir(context, escola),
              );
            },
          );
        },
      ),
    );
  }
}
