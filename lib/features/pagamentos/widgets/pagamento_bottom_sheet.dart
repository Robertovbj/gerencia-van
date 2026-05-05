import 'package:flutter/material.dart';
import '../models/pagamento.dart';
import '../../../core/utils/formatters.dart';

class PagamentoBottomSheet extends StatefulWidget {
  final Pagamento pagamento;
  final Future<void> Function(double valor, DateTime data) onConfirmar;

  const PagamentoBottomSheet({
    super.key,
    required this.pagamento,
    required this.onConfirmar,
  });

  @override
  State<PagamentoBottomSheet> createState() => _PagamentoBottomSheetState();
}

class _PagamentoBottomSheetState extends State<PagamentoBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _valorController;
  late DateTime _dataSelecionada;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _valorController = TextEditingController(
      text: widget.pagamento.valorPrevisto.toStringAsFixed(2).replaceAll('.', ','),
    );
    _dataSelecionada = DateTime.now();
  }

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2099),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) setState(() => _dataSelecionada = picked);
  }

  Future<void> _confirmar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);

    final valorStr = _valorController.text.replaceAll('.', '').replaceAll(',', '.');
    final valor = double.tryParse(valorStr) ?? widget.pagamento.valorPrevisto;

    await widget.onConfirmar(valor, _dataSelecionada);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Registrar Pagamento',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              widget.pagamento.nomeExibicao,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valorController,
              decoration: const InputDecoration(
                labelText: 'Valor pago (R\$)',
                prefixText: 'R\$ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Informe o valor';
                final val = double.tryParse(v.replaceAll(',', '.'));
                if (val == null || val <= 0) return 'Valor inválido';
                return null;
              },
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selecionarData,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Data do pagamento',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(formatarData(_dataSelecionada)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _salvando ? null : _confirmar,
                child: _salvando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Confirmar Pagamento'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
