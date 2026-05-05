# Flutter App: Gerenciador de Van Escolar

## Objetivo
Gere um aplicativo Flutter completo para um dono de van escolar gerenciar seus alunos e pagamentos mensais. Use SQLite como banco de dados local (pacote `sqflite`).

---

## Arquitetura e Stack
- **Flutter** (null safety)
- **SQLite** via `sqflite` + `path`
- **Gerenciamento de estado**: Provider ou Riverpod
- **Navegação**: GoRouter ou Navigator 2.0
- **Estrutura de pastas**: feature-first (`lib/features/escolas`, `lib/features/alunos`, `lib/features/pagamentos`)
- UI com Material Design 3

---

## Banco de Dados

### Tabela `escolas`
| Campo  | Tipo    | Observações         |
|--------|---------|---------------------|
| id     | INTEGER | PK, autoincrement   |
| nome   | TEXT    | NOT NULL            |
| ativo  | INTEGER | 0 = inativo, 1 = ativo |

### Tabela `alunos`
| Campo               | Tipo    | Observações                        |
|---------------------|---------|------------------------------------|
| id                  | INTEGER | PK, autoincrement                  |
| nome                | TEXT    | NOT NULL                           |
| apelido             | TEXT    | nullable                           |
| nome_responsavel    | TEXT    | nullable                           |
| valor_mensalidade   | REAL    | NOT NULL                           |
| escola_id           | INTEGER | FK → escolas.id, NOT NULL          |
| horario             | TEXT    | 'manha', 'tarde', 'noite', 'integral' |
| dia_pagamento       | INTEGER | Dia do mês (1–31)                  |
| ativo               | INTEGER | 0 = inativo, 1 = ativo             |

### Tabela `contratos`
| Campo        | Tipo    | Observações                  |
|--------------|---------|------------------------------|
| id           | INTEGER | PK, autoincrement            |
| aluno_id     | INTEGER | FK → alunos.id, NOT NULL     |
| data_inicio  | TEXT    | ISO 8601 (YYYY-MM-DD)        |
| data_fim     | TEXT    | ISO 8601 (YYYY-MM-DD)        |

### Tabela `pagamentos`
| Campo            | Tipo    | Observações                              |
|------------------|---------|------------------------------------------|
| id               | INTEGER | PK, autoincrement                        |
| aluno_id         | INTEGER | FK → alunos.id, NOT NULL                 |
| contrato_id      | INTEGER | FK → contratos.id, NOT NULL              |
| mes_referencia   | TEXT    | Formato 'YYYY-MM'                        |
| valor_previsto   | REAL    | Copiado de alunos.valor_mensalidade      |
| valor_pago       | REAL    | nullable (preenchido ao marcar como pago)|
| pago             | INTEGER | 0 = não pago, 1 = pago                   |
| data_pagamento   | TEXT    | nullable, ISO 8601                       |

---

## Regra de Negócio: Geração Automática de Pagamentos
Ao **salvar um novo aluno** (junto com seu contrato), o app deve **gerar automaticamente** um registro na tabela `pagamentos` para cada mês entre `contrato.data_inicio` e `contrato.data_fim`, com:
- `mes_referencia` = 'YYYY-MM' de cada mês no intervalo
- `valor_previsto` = `aluno.valor_mensalidade`
- `pago` = 0

A mesma lógica deve ser aplicada ao **cadastrar um novo contrato** para um aluno existente.

---

## Telas

### 1. Tela Principal (Bottom Navigation Bar com 3 abas)
- Escolas
- Alunos
- Pagamentos

---

### 2. Aba: Escolas
- Lista de escolas com nome e badge de status (Ativo/Inativo)
- Botão FAB para adicionar nova escola
- Tap na escola abre diálogo ou tela para editar nome e status
- Não permite excluir escola que possui alunos vinculados

---

### 3. Aba: Alunos
- Lista de alunos com nome, apelido (se houver), escola e horário
- Alunos inativos aparecem com visual diferenciado (opacidade reduzida)
- Botão FAB para adicionar novo aluno
- Formulário de cadastro/edição com todos os campos:
  - Nome completo (obrigatório)
  - Apelido (opcional)
  - Nome do responsável (opcional)
  - Valor da mensalidade (obrigatório, teclado numérico)
  - Escola (dropdown com escolas ativas)
  - Horário (dropdown: Manhã / Tarde / Noite / Integral)
  - Dia do pagamento previsto (1–31)
  - Status ativo/inativo (toggle)
  - Seção de contrato: data de início e data fim (DatePicker)
- Ao salvar, gerar os pagamentos futuros automaticamente
- Tela de detalhe do aluno mostra histórico de contratos

---

### 4. Aba: Pagamentos
#### Filtros (no topo da tela)
- Seletor de **mês/ano** (navegação anterior/próximo)
- Filtro por **escola** (dropdown, opção "Todas")
- Filtro por **horário** (dropdown, opção "Todos")
- Campo de **busca por nome** do aluno

#### Lista de Pagamentos
- Ordenação: **não pagos primeiro**, pagos ao final
- Cada item exibe:
  - Nome do aluno (e apelido entre parênteses, se houver)
  - Escola e horário
  - Valor previsto
  - Status: chip "Pago" (verde) ou "Pendente" (vermelho/laranja)
  - Se pago: valor pago e data do pagamento
- **Marcar como pago**: ao tocar no botão/ícone de pago, abre um bottom sheet ou diálogo com:
  - Valor pago (pré-preenchido com valor previsto, editável)
  - Data do pagamento (pré-preenchida com hoje, editável via DatePicker)
  - Botão confirmar
- **Desmarcar pagamento**: botão disponível nos itens já pagos (para desfazer cliques acidentais), com confirmação simples

---

## Requisitos Técnicos
- Validação de formulários com `Form` + `TextFormField`
- Formatação de valores monetários em BRL (R$)
- Tratamento de `dia_pagamento` para meses com menos dias (ex: dia 31 em fevereiro → usar último dia do mês)
- Suporte a múltiplos contratos por aluno (anos letivos diferentes)
- O app deve funcionar **offline** completamente (apenas SQLite, sem backend)

---

## Entregáveis Esperados
1. Projeto Flutter completo e funcional
2. Arquivo `pubspec.yaml` com todas as dependências
3. Script de criação do banco (`database_helper.dart`) com `onCreate` e migrações via `onUpgrade`
4. Separação clara entre camadas: `models/`, `repositories/`, `providers/` (ou controllers), `screens/`, `widgets/`
5. Código em **português** para variáveis de domínio e em **inglês** para estrutura técnica
