import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/sync_service.dart';
import 'main_scaffold_key.dart';
import '../../features/escolas/screens/escolas_screen.dart';
import '../../features/escolas/providers/escola_provider.dart';
import '../../features/alunos/screens/alunos_screen.dart';
import '../../features/alunos/screens/renovacao_screen.dart';
import '../../features/alunos/providers/aluno_provider.dart';
import '../../features/pagamentos/screens/pagamentos_screen.dart';
import '../../features/pagamentos/providers/pagamento_provider.dart';
import '../../features/sincronia/screens/sincronia_screen.dart';

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

  @override
  void initState() {
    super.initState();
    SyncService.instance.onDataImported = () {
      if (!mounted) return;
      context.read<EscolaProvider>().carregar();
      context.read<AlunoProvider>().carregar();
      context.read<PagamentoProvider>().carregar();
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SyncService.instance.init();
    });
  }

  @override
  void dispose() {
    SyncService.instance.onDataImported = null;
    super.dispose();
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
                leading: const Icon(Icons.autorenew),
                title: const Text('Renovar contratos'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RenovacaoScreen()),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.cloud_sync),
                title: const Text('Importação e sincronia'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SincroniaScreen()),
                  );
                },
              ),
              const Spacer(),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text(
                  'Desenvolvido por Roberto Barbosa',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
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
