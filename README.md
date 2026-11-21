# App de Finanças Pessoais

Aplicativo pessoal de finanças com armazenamento local e foco inicial em Android via APK. A [especificação do produto](docs/especificacao.md) reúne os requisitos, as regras de negócio, o escopo do MVP e o roadmap.

## Base técnica

O projeto usa Flutter, Dart, Riverpod e Drift sobre SQLite. Cada módulo em `lib/features/` tem camadas de domínio, dados e apresentação. O banco fica em `lib/data/local/` e grava o arquivo `finance_app.sqlite` no diretório de documentos do aplicativo.

A navegação atual abre em **Contas** e inclui **Lançamentos**, **A Pagar**, **Recorrências** e **Categorias**. O tema claro ou escuro segue a preferência do sistema.

## O que já está no código

| Módulo | Implementado no código | O que falta para o escopo previsto |
| --- | --- | --- |
| Contas e carteiras (RF01) | Cadastro com saldo inicial, listagem, total de contas ativas, edição de dados cadastrais e arquivamento. Contas arquivadas continuam identificáveis no histórico. | A conta precisa estar livre de recorrências ativas ou pausadas para ser arquivada. |
| Categorias (RF02) | Cadastro, edição e arquivamento de categorias e subcategorias de receita e despesa. Um nível de subcategorias por categoria principal. | Fontes de renda e despesa ainda precisam de definição no fluxo de lançamento. |
| Lançamentos (RF03–RF05, RF22) | Entradas, saídas e transferências com data selecionável. O histórico permite editar, duplicar, mover para a lixeira e restaurar. Alterações de saldo são atômicas. Pagamentos vinculados a contas a pagar ficam protegidos contra alterações no histórico. | Fonte de renda, log de revisões e busca avançada. Tags e filtros avançados ficam na v1.1. |
| Contas a pagar (RF09) | Tela de cadastro e listagem, indicação de atraso e pagamento com uma única despesa vinculada. O repositório permite cancelar contas pendentes. | Expor edição e cancelamento na interface. O tipo “recorrente” é cadastrado na conta a pagar, enquanto a geração automática opera pelo módulo de recorrências de lançamentos. |
| Recorrências (RF10) | Cadastro de entradas e saídas semanais, mensais ou anuais, geração de ocorrências devidas ao abrir o app e após salvar, e ações de pausa, retomada e cancelamento. A geração protege contra duplicidade em chamadas concorrentes do app. | Expor data final e limite de ocorrências no formulário. |
| Tema (RF21) | Temas claro e escuro conforme a configuração do aparelho. | Incluir um seletor manual caso a alternância deva ser feita dentro do app. |

Para fechar o MVP, também faltam o dashboard básico, metas, backup e restauração local e notificações essenciais. A navegação proposta na especificação prevê uma tela **Início** e um atalho central para novo lançamento. Cartões, parcelamento, faturas, investimentos, tags e filtros avançados estão previstos na v1.1. Orçamento, análises, exportação CSV/JSON e PIN/biometria estão previstos na v1.2.

## Validação do estado atual

`flutter test --no-pub` cobre cadastro, arquivamento, edição de transferências, lixeira, pagamento, recorrências e a migração de um arquivo SQLite da versão 1 para a 2. A migração adiciona as tabelas de contas a pagar e recorrências e preserva contas, categorias, lançamentos e saldos existentes.

## Prioridade para retomar o desenvolvimento

1. **Garantir precisão monetária.** O código grava valores como `REAL`. Definir o armazenamento e os cálculos em centavos com uma migração que preserve os dados existentes.
2. **Concluir o MVP.** Avançar para dashboard, metas, backup e restauração e notificações locais. Validar o APK em Android com instalação nova, atualização e uso offline.

## Comandos de desenvolvimento

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```
