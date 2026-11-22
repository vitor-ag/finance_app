# App de Finanças Pessoais

Aplicativo pessoal de finanças com armazenamento local e foco inicial em Android via APK. A [especificação do produto](docs/especificacao.md) reúne os requisitos, as regras de negócio, o escopo do MVP e o roadmap.

## Base técnica

O projeto usa Flutter, Dart, Riverpod e Drift sobre SQLite. Cada módulo em `lib/features/` tem camadas de domínio, dados e apresentação. O banco fica em `lib/data/local/` e grava o arquivo `finance_app.sqlite` no diretório de documentos do aplicativo.

O design **Violeta Vibrante** usa Outfit e Inter empacotadas no app. A aparência pode seguir o sistema ou usar tema claro ou escuro. Em janelas estreitas, a navegação fica na base. Em janelas maiores, aparece na lateral.

## Funcionalidades

- **Início** mostra o saldo das contas ativas, o resultado do mês, receitas, despesas, orçamentos, vencimentos e lançamentos recentes. O botão de olho ativa o modo discreto.
- **Lançamentos** reúne receitas, despesas, transferências e compras no cartão. É possível pesquisar, combinar filtros, agendar, duplicar, editar e consultar a lixeira e o histórico de alterações.
- **Planejar** reúne orçamentos mensais por categoria e metas com histórico de aportes e retiradas.
- **Relatórios** compara receitas, despesas e resultado com o período anterior, detalha os gastos por categoria e exporta CSV e PDF.
- **Ajustes** dá acesso a contas, cartões e faturas, categorias, contas a pagar, recorrências, notificações, segurança, aparência e backup.

As movimentações mensais incluem receitas e despesas pagas e compras no cartão pela data da compra. Transferências, pagamentos de fatura e lançamentos pendentes, cancelados ou excluídos ficam fora do resultado. Consultar um mês anterior mantém o saldo atual e a situação dos vencimentos de hoje.

Em **Ajustes → Backup e restauração**, você pode criar um arquivo cifrado, restaurar uma cópia ou escolher uma pasta para backups automáticos. No Android, o backup pelo Google Drive continua opcional. A senha do backup é independente da senha de acesso. [Configuração do Google Drive](docs/backup-google-drive.md)

Em **Ajustes → Notificações**, você pode configurar o horário do lembrete diário, os avisos de vencimento e os alertas de orçamento. O Android pode ajustar o horário de entrega conforme as condições do aparelho.

## Validação

Os testes cobrem regras financeiras, migrações do SQLite, backups, fluxos de interface e navegação adaptativa. A versão 8 do banco adiciona orçamentos, histórico de metas, anexos e os novos campos de apresentação. A restauração aceita também backups do esquema 7.

### Validação em um aparelho Android

O aplicativo oculta a prévia na lista de apps recentes. No Android 12 e anteriores, o mecanismo disponível também bloqueia capturas de tela.

1. Em uma instalação nova, confirme que a criação de senha antecede o dashboard e que senhas diferentes são rejeitadas. Em uma atualização com o mesmo pacote e certificado, confira se as contas e os lançamentos continuam disponíveis.
2. Encerre e reabra o app. Confira que o desbloqueio é obrigatório. Use o prazo de 30 segundos e teste o retorno antes e depois do prazo, inclusive com uma tela financeira ou formulário aberto. Repita com bloqueio imediato.
3. Erre a senha três vezes. Confira a espera de 5 segundos, o aumento após outro erro e a persistência ao reabrir. Reinicie o aparelho e confirme que a senha cadastrada continua válida e o app abre bloqueado.
4. Com uma biometria forte cadastrada, ative-a, cancele um prompt e desbloqueie por senha. Depois desbloqueie por biometria, altere o cadastro biométrico no Android e confirme que o app exige a senha antes de reativá-la. Em aparelho sem biometria cadastrada, confira que a opção fica indisponível.
5. Altere a senha em **Segurança**, confirmando a atual. Reabra o app e valide a nova. Desative a biometria e confira que o atalho desaparece na próxima abertura.

## Comandos de desenvolvimento

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```
