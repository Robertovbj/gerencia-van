import 'package:flutter/material.dart';
import '../../core/services/backup_service.dart';
import 'main_scaffold_key.dart';
import '../../features/escolas/screens/escolas_screen.dart';
import '../../features/alunos/screens/alunos_screen.dart';
import '../../features/pagamentos/screens/pagamentos_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _abaAtual = 0;

  static const _telas = [
    EscolasScreen(),
    AlunosScreen(),
    PagamentosScreen(),
  ];

  Future<void> _exportar() async {
    Navigator.of(context).pop();
    try {
      await BackupService.instance.exportar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao exportar: $e')),
        );
      }
    }
  }

  Future<void> _importar() async {
    Navigator.of(context).pop();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importar dados'),
        content: const Text(
          'Isso substituirá TODOS os dados atuais pelo conteúdo do arquivo. Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Importar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final erro = await BackupService.instance.importar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(erro ?? 'Dados importados com sucesso!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao importar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffoldKey(
      scaffoldKey: _scaffoldKey,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DrawerHeader(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.directions_bus, size: 40),
                    SizedBox(height: 8),
                    Text(
                      'Gerência Van',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text('Exportar dados (JSON)'),
                onTap: _exportar,
              ),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Importar dados (JSON)'),
                onTap: _importar,
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _abaAtual,
        children: _telas,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _abaAtual,
        onDestinationSelected: (i) => setState(() => _abaAtual = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Escolas',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people),
            label: 'Alunos',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: 'Pagamentos',
          ),
        ],
      ),
      ),
    );
  }
}
