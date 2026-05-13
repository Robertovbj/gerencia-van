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

### Rodando em modo debug

```bash
flutter pub get
flutter run
```

### Configuração do Google Drive (opcional)

A sincronização com o Google Drive requer um projeto no Firebase com autenticação Google habilitada.

1. Acesse o [Firebase Console](https://console.firebase.google.com) e crie um projeto
2. Adicione um app Android com o package name `br.com.gerenciaVan.gerencia_van`
3. Habilite o método de login **Google** em **Authentication → Sign-in method**
4. Em **Configurações do projeto → Geral → seu app Android**, adicione o SHA-1 do keystore (debug ou release — veja abaixo como obter)
5. Baixe o arquivo `google-services.json` e coloque em `android/app/`

> O arquivo `google-services.json` **não está incluso** no repositório pois contém chaves de API. Sem ele, o app funciona normalmente, mas sem a funcionalidade de sincronização com o Drive.

---

## Gerando o APK de release

### 1. Criar o keystore de assinatura (uma vez só)

```bash
keytool -genkey -v -keystore ~/gerencia-van-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias gerencia-van
```

Guarde o arquivo `.jks` e as senhas em local seguro. **Sem eles não é possível atualizar o app depois.**

### 2. Obter o SHA-1 do keystore de release

```bash
keytool -list -v \
  -keystore ~/gerencia-van-release.jks \
  -alias gerencia-van \
  -storepass SUA_SENHA | grep "SHA1:"
```

Registre esse SHA-1 no Firebase Console (passo 4 da seção acima) e baixe o `google-services.json` atualizado. Isso é necessário para o Google Sign-In funcionar no APK de release.

### 3. Configurar a assinatura no projeto

Crie o arquivo `android/key.properties` (já está no `.gitignore`):

```properties
storePassword=SUA_SENHA
keyPassword=SUA_SENHA
keyAlias=gerencia-van
storeFile=/caminho/absoluto/gerencia-van-release.jks
```

### 4. Gerar o APK

```bash
flutter build apk --release
```

O APK ficará em:
```
build/app/outputs/flutter-apk/app-release.apk
```

Basta enviar o arquivo por WhatsApp ou e-mail. No dispositivo de destino, é necessário permitir **"Instalar apps de fontes desconhecidas"** nas configurações de segurança do Android.

## Licença e uso

Projeto de uso livre. Use, modifique e distribua como quiser, mas é necessário dar os devidos créditos ao autor original (Roberto Barbosa) em qualquer uso ou redistribuição, seja em projetos públicos, privados ou comerciais.

## Contribuições

Contribuições são bem-vindas via pull request. Não há roadmap definido nem prazo de resposta garantido, dado o caráter pessoal do projeto.
