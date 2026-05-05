import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/aluno_provider.dart';
import '../widgets/aluno_list_item.dart';
import 'aluno_form_screen.dart';
import 'aluno_detail_screen.dart';
import '../../escolas/providers/escola_provider.dart';

class AlunosScreen extends StatefulWidget {
  const AlunosScreen({super.key});

  @override
  State<AlunosScreen> createState() => _AlunosScreenState();
}

class _AlunosScreenState extends State<AlunosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlunoProvider>().carregar();
      context.read<EscolaProvider>().carregar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alunos')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_alunos',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AlunoFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: Consumer<AlunoProvider>(
        builder: (context, provider, _) {
          if (provider.carregando) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.alunos.isEmpty) {
            return const Center(
              child: Text('Nenhum aluno cadastrado.\nToque em + para adicionar.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: provider.alunos.length,
            itemBuilder: (context, index) {
              final aluno = provider.alunos[index];
              return AlunoListItem(
                aluno: aluno,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AlunoDetailScreen(aluno: aluno),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
