# App de Finanças Pessoais

Aplicativo pessoal de finanças com armazenamento local e foco inicial em Android via APK. A [especificação do produto](docs/especificacao.md) reúne os requisitos, as regras de negócio, o escopo do MVP e o roadmap.

## Base técnica

O projeto usa Flutter, Dart, Riverpod e Drift sobre SQLite. Cada módulo em `lib/features/` tem camadas de domínio, dados e apresentação. O banco fica em `lib/data/local/` e grava o arquivo `finance_app.sqlite` no diretório de documentos do aplicativo.

A navegação atual abre em **Contas** e inclui **Lançamentos**, **A Pagar**, **Recorrências** e **Categorias**. O tema claro ou escuro segue a preferência do sistema.

## O que já está no código

| Módulo | Implementado no código | O que falta para o escopo previsto |
| --- | --- | --- |
| Contas e carteiras (RF01) | Cadastro com saldo inicial, listagem e total. O repositório oferece edição e arquivamento. | Expor edição e arquivamento na interface e impedir alterações de saldo que não passem por um lançamento. |
| Categorias (RF02) | Cadastro e listagem por receita ou despesa. O modelo aceita categoria-pai, e o repositório oferece edição e arquivamento. | Expor subcategorias, edição e arquivamento na interface. |
| Lançamentos (RF03–RF05, RF22) | Cadastro de entradas, saídas e transferências, histórico básico e atualização atômica de saldos. A exclusão lógica existe no repositório e estorna o efeito no saldo. | Permitir escolher a data no cadastro e completar fonte de renda, edição, duplicação, exclusão pela interface e recuperação na lixeira. Tags ficam na v1.1. |
| Contas a pagar (RF09) | Tela de cadastro e listagem, indicação de atraso e pagamento com uma única despesa vinculada. O repositório permite cancelar contas pendentes. | Expor edição e cancelamento na interface. O tipo “recorrente” é cadastrado na conta a pagar, enquanto a geração automática opera pelo módulo de recorrências de lançamentos. |
| Recorrências (RF10) | Cadastro de entradas e saídas semanais, mensais ou anuais, geração de ocorrências devidas ao abrir o app e após salvar, e ações de pausa, retomada e cancelamento. A geração protege contra duplicidade em chamadas concorrentes do app. | Expor data final e limite de ocorrências no formulário. |
| Tema (RF21) | Temas claro e escuro conforme a configuração do aparelho. | Incluir um seletor manual caso a alternância deva ser feita dentro do app. |

Para fechar o MVP, também faltam o dashboard básico, metas, backup e restauração local e notificações essenciais. A navegação proposta na especificação prevê uma tela **Início** e um atalho central para novo lançamento. Cartões, parcelamento, faturas, investimentos, tags e filtros avançados estão previstos na v1.1. Orçamento, análises, exportação CSV/JSON e PIN/biometria estão previstos na v1.2.

## Validação do estado atual

`flutter test --no-pub` cobre os fluxos de cadastro, pagamento, recorrências e a migração de um arquivo SQLite da versão 1 para a 2. A migração adiciona as tabelas de contas a pagar e recorrências e preserva contas, categorias, lançamentos e saldos existentes.

## Prioridade para retomar o desenvolvimento

1. **Concluir os fluxos financeiros básicos.** Completar contas, categorias e histórico de lançamentos. O código grava valores monetários como `REAL` e o repositório de contas ainda permite atualizar o saldo diretamente. Resolver precisão e rastreabilidade antes de usar dados reais.
2. **Concluir o MVP.** Avançar para dashboard, metas, backup e restauração e notificações locais. Validar o APK em Android com instalação nova, atualização e uso offline.

## Comandos de desenvolvimento

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```
