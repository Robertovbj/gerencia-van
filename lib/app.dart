import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'features/escolas/providers/escola_provider.dart';
import 'features/alunos/providers/aluno_provider.dart';
import 'features/pagamentos/providers/pagamento_provider.dart';
import 'shared/widgets/main_scaffold.dart';

class GerenciaVanApp extends StatelessWidget {
  const GerenciaVanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EscolaProvider()),
        ChangeNotifierProvider(create: (_) => AlunoProvider()),
        ChangeNotifierProvider(create: (_) => PagamentoProvider()),
      ],
      child: MaterialApp(
        title: 'Gerência Van',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1565C0),
            brightness: Brightness.light,
          ),
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('pt', 'BR'),
        ],
        locale: const Locale('pt', 'BR'),
        home: const MainScaffold(),
      ),
    );
  }
}
