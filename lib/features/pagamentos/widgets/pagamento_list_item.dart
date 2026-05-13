import 'package:flutter/material.dart';
import '../models/pagamento.dart';
import '../../../core/utils/formatters.dart';

class PagamentoListItem extends StatelessWidget {
  final Pagamento pagamento;
  final VoidCallback onMarcarPago;
  final VoidCallback onDesmarcar;

  const PagamentoListItem({
    super.key,
    required this.pagamento,
    required this.onMarcarPago,
    required this.onDesmarcar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pago = pagamento.pago;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: pago ? Colors.green.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pagamento.nomeExibicao,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${pagamento.escolaNome ?? ''} · ${labelHorario(pagamento.horario ?? '')}',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (pagamento.dataVencimento != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          Icon(Icons.event, size: 12,
                              color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Vencimento: ${formatarData(pagamento.dataVencimento!)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Previsto: ${formatarMoeda(pagamento.valorPrevisto)}',
                        style: theme.textTheme.bodySmall,
                      ),
                      if (pago && pagamento.valorPago != null) ...[
                        const Text(' · '),
                        Text(
                          'Pago: ${formatarMoeda(pagamento.valorPago!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (pago && pagamento.dataPagamento != null)
                    Text(
                      'Em ${formatarData(pagamento.dataPagamento!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade700,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              children: [
                Chip(
                  label: Text(pago ? 'Pago' : 'Pendente'),
                  backgroundColor:
                      pago ? Colors.green.shade100 : Colors.red.shade100,
                  labelStyle: TextStyle(
                    color: pago ? Colors.green.shade800 : Colors.red.shade800,
                    fontSize: 12,
                  ),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(height: 4),
                if (!pago)
                  ElevatedButton.icon(
                    onPressed: onMarcarPago,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Pagar'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  )
                else
                  TextButton.icon(
                    onPressed: onDesmarcar,
                    icon: const Icon(Icons.undo, size: 16),
                    label: const Text('Desfazer'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange.shade800,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
