# Gerência Van

Aplicativo mobile para gerenciamento de van escolar, desenvolvido em Flutter.

## Sobre o projeto

Este é um projeto **pessoal**, criado para uso próprio no controle de alunos, escolas, contratos e pagamentos de transporte escolar. **Não há garantia de manutenção contínua**, mas o código está disponível livremente para uso e contribuições são bem-vindas.

## Funcionalidades

- Cadastro de escolas e alunos
- Controle de contratos por período
- Registro e acompanhamento de pagamentos mensais
- Renovação de contratos em lote
- Backup manual em JSON (exportar/importar)
- Sincronização automática com Google Drive

## Tecnologias

- [Flutter](https://flutter.dev/) 3.x / Dart 3.x
- SQLite via [`sqflite`](https://pub.dev/packages/sqflite) (banco local)
- [`provider`](https://pub.dev/packages/provider) (gerenciamento de estado)
- [`google_sign_in`](https://pub.dev/packages/google_sign_in) + [`googleapis`](https://pub.dev/packages/googleapis) (Google Drive)
- [`file_picker`](https://pub.dev/packages/file_picker) + [`share_plus`](https://pub.dev/packages/share_plus) (backup manual)

## Como executar

### Pré-requisitos

- Flutter SDK instalado
- Dispositivo Android ou emulador

### Configuração do Google Drive (opcional)

A sincronização com o Google Drive requer um projeto no Firebase com autenticação Google habilitada.

1. Acesse o [Firebase Console](https://console.firebase.google.com) e crie um projeto
2. Adicione um app Android com o package name `br.com.gerenciaVan.gerencia_van`
3. Habilite o método de login **Google** em **Authentication → Sign-in method**
4. Baixe o arquivo `google-services.json` e coloque em `android/app/`

> O arquivo `google-services.json` **não está incluso** no repositório pois contém chaves de API. Sem ele, o app funciona normalmente, mas sem a funcionalidade de sincronização com o Drive.

### Rodando o app

```bash
flutter pub get
flutter run
```

## Licença e uso

Projeto de uso livre. Use, modifique e distribua como quiser, mas é necessário dar os devidos créditos ao autor original (Roberto Barbosa) em qualquer uso ou redistribuição, seja em projetos públicos, privados ou comerciais.

## Contribuições

Contribuições são bem-vindas via pull request. Não há roadmap definido nem prazo de resposta garantido, dado o caráter pessoal do projeto.
