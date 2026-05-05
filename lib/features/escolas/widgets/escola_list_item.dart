import 'package:flutter/material.dart';
import '../models/escola.dart';

class EscolaListItem extends StatelessWidget {
  final Escola escola;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const EscolaListItem({
    super.key,
    required this.escola,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: escola.ativo
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.school,
          color: escola.ativo
              ? Theme.of(context).colorScheme.onPrimaryContainer
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      title: Text(escola.nome),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Chip(
            label: Text(
              escola.ativo ? 'Ativo' : 'Inativo',
              style: const TextStyle(fontSize: 12),
            ),
            backgroundColor: escola.ativo ? Colors.green.shade100 : Colors.grey.shade200,
            labelStyle: TextStyle(
              color: escola.ativo ? Colors.green.shade800 : Colors.grey.shade700,
            ),
            padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
              color: Theme.of(context).colorScheme.error,
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}
