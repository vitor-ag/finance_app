# Especificação — App de Controle e Gestão de Finanças Pessoais

**Plataforma inicial:** Android (APK direto) | **Princípio:** Local-first · Privacy-first · Offline-first

---

## 1. Visão Geral do Produto

Um aplicativo mobile de finanças pessoais que dá ao usuário uma visão completa e confiável da própria vida financeira — receitas, despesas, contas, cartões, investimentos, metas e orçamento — **sem depender de nenhum servidor, backend ou nuvem** para funcionar. Todo o processamento e armazenamento acontece no dispositivo. A internet, se um dia for usada, servirá apenas para recursos opcionais (backup em nuvem, por exemplo), nunca para o núcleo do app.

O diferencial central não é "mais um app de finanças", mas sim: **privacidade real** (nenhum dado financeiro sai do celular), **funcionamento 100% offline** e uma experiência de registro de lançamentos extremamente rápida.

### Público-alvo

- Pessoas físicas que quorem controlar finanças pessoais sem abrir mão de privacidade.
- Usuários desconfiados de apps bancários/financeiros que exigem conta em nuvem.
- Perfil inicial: você mesmo como usuário-piloto (dogfooding), o que ajuda a validar UX rapidamente.

---

## 2. Escopo

**Dentro do escopo (MVP + evoluções previstas):** contas/carteiras, categorias, lançamentos de entrada/saída, transferências, cartões de crédito com parcelamento, contas a pagar (fixas/recorrentes/eventuais), metas, orçamento, investimentos (registro manual), dashboard, notificações locais, backup/restore local, segurança (senha local e biometria), dark/light mode.

**Fora do escopo inicial (futuro/opcional):** sincronização em nuvem, múltiplos usuários/contas compartilhadas, integração com Open Finance/bancos, OCR de comprovantes, leitura de notificações bancárias, IA/ML para previsões, versão iOS.

---

## 3. Lista Completa de Módulos

1. Contas/Carteiras
2. Categorias e Subcategorias (+ Fontes de renda/despesa)
3. Lançamentos (Entradas, Saídas, Transferências)
4. Cartões de Crédito e Faturas
5. Contas a Pagar (fixas, recorrentes, eventuais)
6. Recorrências
7. Investimentos
8. Metas Financeiras
9. Orçamento/Planejamento (mensal e anual)
10. Dashboard
11. Análise Financeira / Insights
12. Busca e Filtros
13. Tags
14. Notificações Locais
15. Backup e Restauração
16. Segurança (senha local, biometria e bloqueio automático)
17. Configurações

---

## 4. Requisitos Funcionais (principais)

| ID | Requisito |
| --- | --- |
| RF01 | Cadastrar, editar, arquivar e listar contas/carteiras com saldo inicial e atual |
| RF02 | Cadastrar categorias/subcategorias próprias para entradas e saídas |
| RF03 | Registrar lançamento de entrada com valor, categoria, fonte, conta, data, observação |
| RF04 | Registrar lançamento de saída com valor, categoria, conta, data, observação, tags |
| RF05 | Realizar transferência entre contas sem impactar entrada/saída |
| RF06 | Cadastrar cartão de crédito (limite, fechamento, vencimento) |
| RF07 | Registrar compra no cartão à vista ou parcelada, gerando parcelas futuras automaticamente |
| RF08 | Consolidar fatura do cartão por período de fechamento e permitir pagamento sem duplicar despesa |
| RF09 | Cadastrar contas a pagar fixas, recorrentes e eventuais, com status (pendente/paga/atrasada/cancelada) |
| RF10 | Gerar lançamentos recorrentes automaticamente conforme periodicidade definida |
| RF11 | Registrar investimentos, aportes, resgates e rendimentos, separando patrimônio investido de saldo disponível |
| RF12 | Criar metas financeiras com valor-alvo, prazo e acompanhamento de progresso |
| RF13 | Criar orçamento mensal/anual por categoria e comparar planejado x realizado |
| RF14 | Exibir dashboard com saldo, entradas, saídas, resultado do mês, investimentos e pendências |
| RF15 | Gerar análises descritivas (maior categoria de gasto, variações, médias) sem recomendação de investimento |
| RF16 | Buscar e filtrar lançamentos por período, categoria, conta, cartão, valor, status, tag |
| RF17 | Criar e associar tags a lançamentos |
| RF18 | Emitir notificações locais de vencimento, fechamento de fatura e estouro de orçamento |
| RF19 | Exportar e importar backup local (arquivo), com exportação adicional em CSV/JSON |
| RF20 | Exigir senha local ou biometria no Android, com bloqueio automático configurável |
| RF21 | Alternar entre tema claro e escuro |
| RF22 | Editar, excluir (lógico) e duplicar lançamentos, com histórico/lixeira |

## 5. Requisitos Não Funcionais

- **Offline total:** nenhuma funcionalidade essencial deve depender de rede.
- **Privacidade:** nenhum dado financeiro trafega para fora do dispositivo por padrão; sem login obrigatório.
- **Performance:** listagens e dashboard devem responder em \<300ms mesmo com milhares de lançamentos (uso de índices no banco local).
- **Integridade:** transações no banco (ACID) para operações que envolvem múltiplas tabelas (ex.: parcelamento, transferência).
- **Portabilidade de dados:** backup/restore sem corrupção nem duplicação.
- **Extensibilidade:** novos módulos (ex.: backup em nuvem) não devem exigir reescrever o núcleo.
- **Testabilidade:** regras de cálculo financeiro cobertas por testes automatizados, não apenas inspeção visual.
- **Acessibilidade:** contraste adequado, tamanhos de fonte ajustáveis, suporte a leitores de tela nos elementos principais.
- **Segurança proporcional:** o bloqueio protege o acesso pela interface. No MVP, o SQLite permanece no armazenamento privado do aplicativo, sem criptografia integral. Os backups portáteis terão criptografia própria.

## 6. Regras de Negócio (principais)

1. Transferência entre contas **não** é receita nem despesa — é um lançamento de tipo próprio que debita uma conta e credita outra.
2. Compra parcelada no cartão gera N parcelas futuras vinculadas a uma compra-mãe; a alteração de uma parcela não deve, por padrão, afetar as demais já pagas.
3. Pagamento de fatura do cartão **quita** as parcelas do período, sem gerar uma nova despesa duplicada — a despesa real já ocorreu no momento da compra.
4. Aporte em investimento reduz o saldo disponível da conta de origem, mas não é categorizado como despesa; resgate faz o caminho inverso.
5. Categoria com lançamentos vinculados nunca é apagada fisicamente — apenas arquivada/desativada, preservando o histórico.
6. Conta com movimentações não pode ser excluída sem tratamento explícito (arquivar, ou exigir realocação dos lançamentos).
7. Conta a pagar cujo vencimento já passou e status ainda é "pendente" deve ser automaticamente classificada como "atrasada" ao ser consultada/exibida.
8. Toda alteração de saldo deve ser resultado de um lançamento rastreável — nunca uma edição direta e não auditável do saldo da conta.
9. Recorrências geram ocorrências futuras (não o lançamento inteiro de uma vez), permitindo pausar/cancelar sem afetar o que já foi gerado.
10. Exclusão de lançamento é lógica (soft delete) por padrão, permitindo recuperação via "lixeira".

---

## 7. Comparação Flutter x Kotlin/Jetpack Compose

| Critério | Flutter + Dart | Kotlin + Jetpack Compose |
| --- | --- | --- |
| Dev Android | Muito bom, curva de aprendizado suave | Nativo, acesso total à API Android |
| Futuro iOS | Mesmo código-base, esforço baixo | Exigiria reescrever em Swift/SwiftUI |
| UI/Interface | Motor de renderização próprio, altíssimo controle visual, hot reload rápido | Compose é declarativo e moderno, mas restrito ao ecossistema Android |
| Banco local | Ótimo suporte (Drift, Isar, sqflite) | Excelente (Room é o padrão de fato) |
| Notificações locais | Bom suporte via plugins (flutter_local_notifications) | Suporte nativo direto |
| Performance | Muito boa para apps de dados/CRUD; compila para código nativo (AOT) | Nativa, ligeiramente superior em cenários extremos |
| Manutenção solo | Um único código-base para manter | Um código-base, mas restrito a Android |
| Ecossistema/bibliotecas | Grande e maduro para apps de produtividade/finanças | Grande, mas mais disperso entre Java/Kotlin legado |
| Geração de APK | Direta (`flutter build apk`) | Direta (Gradle) |
| Complexidade para 1 dev | Menor, por unificar UI declarativa + lógica em uma linguagem | Um pouco maior devido ao ecossistema Android (Gradle, XML legado em partes) |

**Recomendação:** manter **Flutter + Dart**, como você já havia planejado. O ganho decisivo é a possibilidade real de gerar uma versão iOS no futuro sem reescrever o app, combinado com um ecossistema de banco local (Drift/Isar) tão maduro quanto o Room do Android nativo. Para um app pessoal mantido por um único desenvolvedor, a unificação de linguagem e UI reduz bastante a carga cognitiva.

---

## 8. Stack Tecnológica Recomendada

- **Framework:** Flutter (Dart) — canal stable
- **Gerenciamento de estado:** Riverpod (ver justificativa na seção 10)
- **Banco de dados local:** Drift (ver seção 9)
- **Notificações locais:** `flutter_local_notifications` + `timezone` (para agendamento preciso)
- **Backup/exportação:** `file_picker` + `share_plus` para exportar/importar arquivos; `path_provider` para diretórios locais
- **Segurança:** `flutter_secure_storage` com Android Keystore para o verificador, `local_auth` para consultar a disponibilidade e `BiometricPrompt` do AndroidX para vincular a autenticação à chave biométrica.
- **Gráficos:** `fl_chart` (leve, nativo Flutter, sem dependências de WebView)
- **Geração de PDF (futuro, relatórios):** `pdf` + `printing`

## 9. Banco de Dados Local Recomendado

| Opção | Prós | Contras |
| --- | --- | --- |
| SQLite puro | Padrão, universal | Verboso, sem type-safety |
| **Drift** | SQL type-safe, migrações versionadas, relacionamentos, streams reativos, ótima integração com Riverpod | Curva de aprendizado inicial um pouco maior |
| Isar | Muito rápido, NoSQL orientado a objetos | Menos natural para dados fortemente relacionais como os deste app (contas ↔ lançamentos ↔ parcelas ↔ categorias) |
| Hive | Simples, leve | Sem suporte real a relacionamentos/consultas complexas — inadequado para um modelo financeiro relacional |

**Recomendação: Drift.** O modelo de dados deste app é essencialmente relacional (contas, lançamentos, parcelas, categorias, tags se cruzam o tempo todo), então um banco relacional type-safe com migrações versionadas é a escolha mais segura para integridade de longo prazo — exatamente o que um app financeiro exige.

---

## 10. Arquitetura Recomendada

**Clean Architecture simplificada, feature-first**, evitando o over-engineering de uma Clean Architecture "de livro" para um app pessoal:

```
lib/
  core/            (temas, utils, erros, constantes)
  data/
    local/         (Drift: tabelas, DAOs, banco)
  features/
    accounts/
      domain/      (entidades, repositório abstrato, use cases)
      data/        (implementação do repositório)
      presentation/(telas, widgets, controllers/providers)
    transactions/
    credit_cards/
    bills/
    investments/
    goals/
    budget/
    dashboard/
    notifications/
    backup/
    security/
    settings/
```

Cada feature é isolada, com uma camada de domínio (regras de negócio puras, testáveis sem Flutter) e uma camada de dados (Drift). Isso permite adicionar módulos futuros (ex.: sincronização em nuvem) sem tocar no núcleo.

## 11. Gerenciamento de Estado

**Recomendação: Riverpod.**

- Integra-se naturalmente com Drift via streams reativos (a UI atualiza sozinha quando o banco muda).
- Testável sem widget tree (ótimo para testar cálculos de saldo, orçamento, etc.).
- Evita boilerplate excessivo do Bloc para um app deste porte, mas mantém uma separação de responsabilidades clara — diferente do Provider puro, que fica limitado em apps maiores.

---

## 12. Modelo Inicial das Entidades (conceitual)

Principais entidades e relacionamentos-chave:

- **Account** (id, nome, tipo, saldo_inicial, saldo_atual, cor, status, criado_em)
- **Category** (id, nome, tipo\[entrada/saída\], categoria_pai_id?, status)
- **Tag** (id, nome)
- **Transaction** (id, tipo\[entrada/saída/transferência\], valor, data, conta_id, categoria_id?, cartão_id?, conta_destino_id?\[transferência\], observação, status, recorrência_id?, excluído_em?)
- **TransactionTag** (transaction_id, tag_id) — N:N
- **CreditCard** (id, nome, limite, dia_fechamento, dia_vencimento, banco, status)
- **CreditCardPurchase** (id, cartão_id, valor_total, num_parcelas, categoria_id, data_compra)
- **Installment** (id, compra_id, número, valor, mês_referência, status\[paga/pendente\])
- **Bill** (contas a pagar) (id, nome, categoria_id, valor, vencimento, tipo\[fixa/recorrente/eventual\], status, conta_pagamento_id?)
- **Recurrence** (id, transaction_template, frequência, dia, data_fim?, qtd_ocorrências?, status)
- **Investment** (id, tipo, instituição, nome)
- **InvestmentTransaction** (id, investimento_id, tipo\[aporte/resgate/rendimento\], valor, data)
- **Goal** (id, nome, valor_alvo, valor_atual, prazo, conta_vinculada?)
- **Budget** (id, categoria_id, valor_limite, mês/ano)
- **NotificationSetting** (id, tipo, dias_antes, horário, ativo)
- **BackupMetadata** (id, data, versão_schema, hash)

**Relacionamentos-chave:** Transaction pertence a uma Account; pode referenciar CreditCard (compra) ou uma Account de destino (transferência); Installment pertence a uma CreditCardPurchase; Bill pode gerar uma Transaction quando marcada como paga; Recurrence gera múltiplas Transaction.

---

## 13. Estrutura de Navegação

Proposta revisada (Bottom Navigation com 5 itens, mais enxuto que a sugestão inicial de 6, com Metas/Relatórios agrupados dentro do Dashboard/Menu para não sobrecarregar a barra):

1. **Início** (dashboard)
2. **Movimentações** (lista + busca/filtros)
3. **+ (botão central de ação rápida)** — registrar lançamento
4. **Contas** (contas, cartões, investimentos)
5. **Mais** (metas, orçamento, relatórios, configurações, backup, segurança)

## 14. Lista de Telas (principais)

Dashboard · Lista de Movimentações · Novo/Editar Lançamento · Detalhe do Lançamento · Contas (lista) · Detalhe da Conta · Novo/Editar Conta · Transferência entre Contas · Cartões (lista) · Detalhe do Cartão/Fatura · Nova Compra no Cartão · Contas a Pagar (lista) · Nova/Editar Conta a Pagar · Investimentos (lista) · Detalhe do Investimento · Novo Aporte/Resgate · Metas (lista) · Detalhe/Nova Meta · Orçamento (mensal) · Categorias (gestão) · Tags (gestão) · Relatórios/Análises · Busca Avançada · Backup/Restauração · Segurança (senha local e biometria) · Configurações · Lixeira/Histórico.

---

## 15. MVP

Contas/carteiras · Categorias · Entradas · Saídas · Transferências · Dashboard básico · Histórico · Contas a pagar · Recorrências básicas · Metas básicas · Banco local (Drift) · Backup/restauração básico · Notificações locais essenciais · Dark/Light mode.

*(Cartões de crédito com parcelamento e Investimentos entram logo na v1.1, por serem módulos com regras próprias que merecem o MVP estabilizado primeiro.)*

## 16. Roadmap

**v1.1:** Cartões de crédito + parcelamento e faturas · Investimentos (registro manual) · Tags · Busca/filtros avançados.

**v1.2:** Orçamento planejado x realizado com indicadores visuais · Análises descritivas e variações anormais · Exportação CSV/JSON · Segurança (senha local e biometria).

**Futuro:** Backup em nuvem opcional (Drive/OneDrive/Dropbox) · Relatórios em PDF · Previsão de saldo futuro (cálculo determinístico) · Controle de dívidas/empréstimos entre pessoas · Widget de saldo na home · OCR de comprovantes · Versão iOS.

## 17. Riscos e Decisões Arquiteturais Importantes

- **Risco:** modelar parcelamento/recorrência de forma simplista demais pode dificultar edição futura (ex.: renegociar uma compra parcelada). *Mitigação:* desenhar `Installment` como entidade própria desde o início, nunca como texto livre.
- **Risco:** migração de schema do Drift mal planejada pode corromper dados do usuário em updates do app. *Mitigação:* testar migrações com dados reais antes de cada release; versionar backups.
- **Risco:** dashboard "inteligente" (seção 31 do seu documento) pode ficar lento se todos os cálculos forem feitos on-the-fly a cada abertura. *Mitigação:* considerar tabelas/views materializadas ou cache incremental no Drift à medida que o volume de dados cresce.
- **Decisão:** o bloqueio exige autenticação antes de exibir telas financeiras. A senha de acesso pertence à instalação e a criptografia de backup tem uma senha independente.
- **Decisão:** todo cálculo de saldo é derivado de lançamentos (nunca editável diretamente), o que facilita auditoria e testes automatizados.

## 18. Acesso local no Android

- Na primeira abertura, inclusive após atualizar uma instalação que ainda não tem proteção, a pessoa cria e confirma uma senha de 8 a 128 caracteres. O cadastro preserva o banco existente. Toda nova inicialização do processo começa bloqueada.
- O verificador versionado usa PBKDF2-HMAC-SHA-256 com 600 mil iterações e salt aleatório de 16 bytes. O aplicativo persiste o verificador e o estado do bloqueio em armazenamento protegido pelo Android Keystore, sem gravar a senha. Se o registro existente estiver ilegível, o app mantém o acesso bloqueado.
- A biometria é opcional. A pessoa pode ativá-la depois de cadastrar a senha ou em **Mais → Configurações → Segurança**, mediante confirmação da senha nesse segundo caso. O Android valida biometria forte com uma chave que exige autenticação a cada uso. Após uma mudança de cadastro que invalide a chave, é preciso usar a senha do app e reativar a biometria. Cancelamento, falha ou indisponibilidade do sensor permitem voltar à senha. O app nunca recebe impressões digitais nem dados faciais.
- Em **Segurança**, a pessoa pode alterar a senha após confirmar a atual, desativar a biometria e selecionar o prazo de bloqueio ao sair do primeiro plano. As opções são **imediatamente**, **30 segundos** (padrão), **1 minuto** e **5 minutos**. O conteúdo fica oculto enquanto o app estiver fora de primeiro plano. Ao voltar depois do prazo, a tela de desbloqueio é exibida antes dos dados financeiros.
- A partir do terceiro erro de senha consecutivo, a espera começa em 5 segundos, dobra a cada erro subsequente e é limitada a 5 minutos. O prazo e a contagem de erros persistem entre aberturas, e a tela avisa quando será possível tentar novamente. A validação da senha correta reinicia a contagem.

## 19. Backup criptografado e recuperação

- A senha de acesso é local ao aparelho. A senha de criptografia protege os backups portáteis e continua válida para backups anteriores quando a senha de acesso muda. Backups incluem os dados financeiros e a versão do esquema. Credenciais locais, tentativas de acesso e chaves biométricas ficam fora do arquivo.
- Antes de oferecer restauração, implementar um formato versionado com criptografia autenticada, salt aleatório e parâmetros de derivação documentados. Verificar autenticidade, integridade e compatibilidade antes de substituir dados. Uma falha de senha, leitura, validação ou importação deve preservar o banco existente.
- A integração opcional com o Drive permitirá vincular a conta Google, buscar um backup e usar a senha de criptografia para validá-lo. Em outro aparelho, o desbloqueio dos dados restaurados exigirá o cadastro de uma senha de acesso local. O login Google concede acesso ao arquivo. A senha do backup concede acesso aos dados.
- O envio automático dependerá de autorização explícita. A chave de envio deverá ficar protegida no Android Keystore e só viabilizar a criação de arquivos criptografados. A restauração em outro Android deverá depender da senha do backup e do arquivo, sem depender do Keystore original.
- O app funciona sem servidor e não oferece recuperação de senha por e-mail. Quando a restauração estiver disponível, o fluxo de senha esquecida exigirá um backup válido e sua senha de criptografia antes de substituir os dados locais e cadastrar uma nova senha de acesso. Sem essa etapa implementada, o desbloqueio depende da senha local ou da biometria previamente ativada e ainda válida.
