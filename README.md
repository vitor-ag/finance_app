# App de Finanças Pessoais

Aplicativo pessoal de finanças com armazenamento local e foco inicial em Android via APK. A [especificação do produto](docs/especificacao.md) reúne os requisitos, as regras de negócio, o escopo do MVP e o roadmap.

## Base técnica

O projeto usa Flutter, Dart, Riverpod e Drift sobre SQLite. Cada módulo em `lib/features/` tem camadas de domínio, dados e apresentação. O banco fica em `lib/data/local/` e grava o arquivo `finance_app.sqlite` no diretório de documentos do aplicativo.

A navegação abre em **Início** e inclui **Lançamentos**, o atalho central **Novo**, **Contas** e **Mais**. Metas financeiras, contas a pagar, recorrências e categorias ficam em **Mais**. O tema claro ou escuro segue a preferência do sistema.

## O que já está no código

| Módulo | Implementado no código | O que falta para o escopo previsto |
| --- | --- | --- |
| Contas e carteiras (RF01) | Cadastro com saldo inicial, listagem, total de contas ativas, edição de dados cadastrais e arquivamento. Contas arquivadas continuam identificáveis no histórico. | A conta precisa estar livre de recorrências ativas ou pausadas para ser arquivada. |
| Categorias (RF02) | Cadastro, edição e arquivamento de categorias e subcategorias de receita e despesa. Um nível de subcategorias por categoria principal. | Organizar fontes de renda e despesa em um cadastro próprio, se necessário. |
| Lançamentos (RF03–RF05, RF22) | Entradas, saídas e transferências com data selecionável. Entradas podem ter uma fonte de receita. O histórico permite editar, duplicar, mover para a lixeira e restaurar, com registro das revisões. Alterações de saldo são atômicas. Pagamentos vinculados a contas a pagar ficam protegidos contra alterações no histórico. | Tags e filtros avançados ficam na v1.1. |
| Contas a pagar (RF09) | Cadastro, edição e cancelamento de contas pendentes, indicação de atraso e pagamento com uma única despesa vinculada. Novas séries mensais geram a próxima conta a partir do vencimento e podem ser encerradas preservando as contas já geradas. | Lembretes de vencimento ficam no módulo de notificações. |
| Recorrências (RF10) | Entradas e saídas semanais, mensais ou anuais com data final e limite de ocorrências opcionais. Geração ao salvar, abrir ou retomar o app, com pausa, retomada, cancelamento e proteção contra duplicidade. | Notificações de vencimento ficam no módulo correspondente. |
| Metas financeiras (RF12) | Cadastro e edição com valor-alvo, prazo e conta de referência opcional. A reserva manual permite registrar valores e acompanhar percentual, valor restante e situação da meta. | — |
| Dashboard (RF14) | Saldo atual das contas ativas, entradas, saídas e resultado para o mês selecionado, além de valores e lista de contas vencidas e a vencer. | O patrimônio investido será integrado quando o módulo de investimentos estiver disponível. |
| Tema (RF21) | Temas claro e escuro conforme a configuração do aparelho. | Incluir um seletor manual caso a alternância deva ser feita dentro do app. |

As movimentações mensais incluem entradas e saídas pagas no mês selecionado. Transferências, lançamentos pendentes, cancelados e excluídos ficam fora do resultado. O saldo atual e as contas pendentes refletem a situação de hoje, mesmo ao consultar meses anteriores.

Para fechar o MVP, faltam backup e restauração local e notificações essenciais. Cartões, parcelamento, faturas, investimentos, tags e filtros avançados estão previstos na v1.1. Orçamento, análises, exportação CSV/JSON e PIN/biometria estão previstos na v1.2.

## Validação do estado atual

`flutter test --no-pub` cobre cadastro, arquivamento, edição de transferências, lixeira e revisões, pagamento, séries mensais, limites de recorrência, metas e a migração dos bancos SQLite das versões 1, 2 e 3 para a 4. A versão 4 adiciona a tabela de metas.

A versão 3 usa centavos inteiros para saldos e valores. A migração mantém os vínculos e os saldos gravados, arredondando valores antigos com mais de duas casas para o centavo mais próximo. Empates são arredondados para longe de zero. Contas a pagar já marcadas como recorrentes nas versões antigas permanecem como registros individuais para evitar gerar cobranças retroativas sem uma série cadastrada. O histórico de alterações começa com as ações registradas a partir da versão 3.

## Prioridade para retomar o desenvolvimento

1. **Validar o MVP em uso.** Verificar o APK em Android com instalação nova, atualização e uso offline.
2. **Concluir o MVP.** Avançar para backup e restauração e notificações locais.

## Comandos de desenvolvimento

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```
