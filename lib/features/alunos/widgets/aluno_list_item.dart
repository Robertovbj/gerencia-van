import 'package:flutter/material.dart';
import '../models/aluno.dart';
import '../../../core/utils/formatters.dart';

class AlunoListItem extends StatelessWidget {
  final Aluno aluno;
  final VoidCallback onTap;

  const AlunoListItem({super.key, required this.aluno, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: aluno.ativo ? 1.0 : 0.5,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _corHorario(aluno.horario, context),
            child: Text(
              aluno.nome.isNotEmpty ? aluno.nome[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            aluno.apelido != null && aluno.apelido!.isNotEmpty
                ? '${aluno.nome} (${aluno.apelido})'
                : aluno.nome,
            style: TextStyle(
              decoration: aluno.ativo ? null : TextDecoration.lineThrough,
            ),
          ),
          subtitle: Text(
            '${aluno.escolaNome ?? ''} · ${labelHorario(aluno.horario)} · ${formatarMoeda(aluno.valorMensalidade)}',
          ),
          trailing: aluno.ativo
              ? null
              : Chip(
                  label: const Text('Inativo', style: TextStyle(fontSize: 11)),
                  backgroundColor: Colors.grey.shade200,
                ),
          onTap: onTap,
        ),
      ),
    );
  }

  Color _corHorario(String horario, BuildContext context) {
    switch (horario) {
      case 'manha':
        return Colors.orange;
      case 'tarde':
        return Colors.blue;
      case 'noite':
        return Colors.indigo;
      case 'integral':
        return Colors.teal;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }
}
