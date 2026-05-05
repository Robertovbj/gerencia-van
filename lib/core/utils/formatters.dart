import 'package:intl/intl.dart';

final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final _mesAno = DateFormat('MMMM yyyy', 'pt_BR');
final _dataCompleta = DateFormat('dd/MM/yyyy', 'pt_BR');
final _mesRef = DateFormat('yyyy-MM');

String formatarMoeda(double valor) => _brl.format(valor);

String formatarData(DateTime data) => _dataCompleta.format(data);

String formatarMesAno(DateTime data) => _mesAno.format(data);

/// 'yyyy-MM' → DateTime
DateTime mesReferenciaParaDateTime(String mesRef) {
  final parts = mesRef.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]));
}

/// DateTime → 'yyyy-MM'
String dateTimeParaMesReferencia(DateTime dt) => _mesRef.format(dt);

String labelHorario(String horario) {
  switch (horario) {
    case 'manha':
      return 'Manhã';
    case 'tarde':
      return 'Tarde';
    case 'noite':
      return 'Noite';
    case 'integral':
      return 'Integral';
    default:
      return horario;
  }
}
