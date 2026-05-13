import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';

class BackupService {
  static final BackupService instance = BackupService._();
  BackupService._();

  /// Lê todas as tabelas e retorna o mapa de backup.
  /// [asOf] é o timestamp que será gravado em 'exportadoEm';
  /// se omitido, usa DateTime.now().
  Future<Map<String, dynamic>> buildBackupData({DateTime? asOf}) async {
    final db = await DatabaseHelper.instance.database;
    final escolas = await db.query('escolas');
    final alunos = await db.query('alunos');
    final contratos = await db.query('contratos');
    final pagamentos = await db.query('pagamentos');
    final frequenciaDias = await db.query('frequencia_dias');

    return {
      'versao': 2,
      'exportadoEm': (asOf ?? DateTime.now()).toIso8601String(),
      'escolas': escolas,
      'alunos': alunos,
      'contratos': contratos,
      'pagamentos': pagamentos,
      'frequencia_dias': frequenciaDias,
    };
  }

  /// Aplica os dados do mapa ao banco.
  /// Retorna null em caso de sucesso ou uma mensagem de erro.
  Future<String?> importarDados(Map<String, dynamic> data) async {
    final versao = data['versao'] as int? ?? 1;
    if (versao < 1 || versao > 2) return 'Versão de backup incompatível.';

    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      await txn.delete('frequencia_dias');
      await txn.delete('pagamentos');
      await txn.delete('contratos');
      await txn.delete('alunos');
      await txn.delete('escolas');

      for (final row in (data['escolas'] as List)) {
        await txn.insert('escolas', Map<String, dynamic>.from(row as Map));
      }
      for (final row in (data['alunos'] as List)) {
        await txn.insert('alunos', Map<String, dynamic>.from(row as Map));
      }
      for (final row in (data['contratos'] as List)) {
        await txn.insert('contratos', Map<String, dynamic>.from(row as Map));
      }
      for (final row in (data['pagamentos'] as List)) {
        await txn.insert('pagamentos', Map<String, dynamic>.from(row as Map));
      }
      // Versão 2+: frequência de dias personalizada
      if (versao >= 2 && data['frequencia_dias'] != null) {
        for (final row in (data['frequencia_dias'] as List)) {
          await txn.insert('frequencia_dias', Map<String, dynamic>.from(row as Map));
        }
      }
    });

    return null;
  }

  /// Exporta todas as tabelas em um único JSON e abre o seletor de compartilhamento.
  Future<void> exportar() async {
    final data = await buildBackupData();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/gerencia_van_backup.json');
    await file.writeAsString(jsonEncode(data));

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Backup Gerência Van',
    );
  }

  /// Abre o seletor de arquivos, lê o JSON e reimporta os dados.
  /// Retorna null em caso de sucesso ou uma mensagem de erro.
  Future<String?> importar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) return null;

    final file = File(result.files.single.path!);
    final content = await file.readAsString();

    late Map<String, dynamic> data;
    try {
      data = jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return 'Arquivo JSON inválido.';
    }

    return importarDados(data);
  }
}
