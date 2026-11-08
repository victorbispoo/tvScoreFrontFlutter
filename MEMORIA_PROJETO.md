## Latest publication decision - 2026-11-08

User explicitly authorized including the unfinished episode grid draft in the componentization commit and pushing ONLY victor. This overrides the earlier instruction below to exclude the grid. The grid uses hardcoded sample ratings, has no backend integration, and remains unfinished for tomorrow. Previous componentization checks: 32 tests passed and analysis was clean before the user added this grid draft; the draft has not been verified. Main must not be updated.

## Update before push - 2026-11-08

- Extracted the details backdrop, community review card, and review form into widgets; extracted the Home carousel into a widget. The page still owns state, controllers, HTTP calls, and callbacks.
- Verification for this extraction: 32 Flutter tests passed and flutter analyze reported no issues. No device test was run for the extraction.
- User requested commit and push of the componentization. Episode ratings grid work is explicitly deferred until tomorrow; keep episode_ratings_grid.dart and its DetailsPage insertion out of this commit, preserving the user's local changes.
- Current branch at this update: victor. After publishing, continue the episode grid from its local draft; do not merge to main unless the user asks.

# TVScore — memória de continuidade

Atualizado em 08/11/2026. Este documento registra contexto e evidências; confira o código local e o Git antes de continuar. Não contém credenciais.

## Última sessão — estado para retomada

- **Atualização mais recente: simplificações após concluir avaliações.** Usuário autorizou commit, push em victor e integração/push em main das alterações abaixo. Base anterior: `299e65f`. Manter victor para continuar o trabalho.
- Proteção de sessão: `_sessionVersion` em ApiService é incrementada ao limpar a conta; consultas e mutações de favoritos/avaliações verificam a versão antes de atualizar estado compartilhado. Respostas antigas geram StateError em vez de repor dados após logout, inclusive com token igual num novo login.
- `ProfilePage.isActive` informado pelo AppShell: contagem consultada ao entrar no Perfil e ao voltar de Minhas avaliações, sem consulta a cada troca para outra aba.
- Conversão de conteúdo unificada em `_mapContent()` e de avaliação em `Review.fromJson()`. Preservados mapas, extensions e estado atual; sem nova arquitetura.
- Resumo e comentários carregam em paralelo via record `.wait`. Textos de ano/gênero/TMDB e nomes longos acomodados com Wrap/Expanded.
- Removidos arquivos sem referências: `controllers/search_controller.dart`, `models/content.dart`, `widgets/app_page.dart`, `widgets/empty_state.dart`; removida dependência phosphoricons_flutter e atualizado lockfile pelo cache offline.
- Verificação automática da simplificação: suíte com **32 testes passando**, incluindo respostas pendentes em seis operações, chamadas do Perfil e texto longo em tela estreita; análise sem problemas. A revisão manual dessas últimas simplificações no aparelho ainda não foi realizada pelo assistente. Não confundir com validação manual anterior das avaliações já confirmada pelo usuário.
- **Nova intenção do usuário: notas por episódio de séries.** Flutter ainda sem integração de episódios. Consultado no GitHub: EpisodioController oferece GET `/series/{id}/episodios/painel`, `/series/{id}/temporadas/{temporada}` e `/series/{id}/temporadas/{temporada}/episodios/{episodio}`; dados incluem notas TMDB, não cadastro de avaliação pessoal. Antes de implementar, esclarecer se quer mostrar nota TMDB ou permitir nota pessoal; pergunta ainda sem resposta. Não houve alteração de código para episódios nem teste das rotas publicadas.
- A polida visual ampla dos detalhes foi discutida, mas não definida; somente os ajustes pequenos acima foram autorizados e feitos. Recomendações/onde assistir/pesquisa continuam pendentes. Seguir a prioridade que o usuário confirmar na retomada.
- Os itens antigos abaixo são histórico; em caso de conflito, prevalece esta atualização mais recente.

- **Avaliações concluídas para o escopo do TCC.** Usuário confirmou em 08/11/2026 a validação manual final dos fluxos solicitados, incluindo recuperação, edição, exclusão, comunidade, contagem e contas distintas. Autorizou commit, push da victor e integração/push na main.
- Contagem remota do Perfil implementada; corrigido o retorno por `mounted` invertido ao voltar da lista. Exclusão bloqueada desde a confirmação até terminar a requisição. Comentário nulo tratado e logs temporários de resposta removidos.
- Testes antigos atualizados para ausência de persistência local e HTTP simulado exclusivamente nos testes. Suíte completa: **25 testes passando**; `flutter analyze`: **No issues found!**. Esses testes não fazem chamadas ao backend real.
- **Próximo trabalho: recomendações personalizadas reais.** Conferir contrato atual do Python/Java antes de orientar. Depois onde assistir, pesquisa/paginação e preparação do APK. Continuar uma etapa por vez, sem alterações automáticas.
- Integração autorizada nesta sessão: enviar victor e main por avanço direto se possível; preservar victor para continuidade. Confirmar estado final com Git. Os registros abaixo sobre pendências anteriores são históricos e foram superados por este fechamento.
- Commit de progresso criado: `113aa4f` — `feat: carrega avaliações pessoais e comunidade do backend`. Usuário autorizou agora o push para `origin/victor`. Esta atualização de memória será enviada em um commit de documentação adicional; conferir o resultado do push no Git ao retomar.
- Avaliação pessoal agora carrega diretamente nos detalhes pela Home via `loadMyReviewFor()`, reaproveitando o conteúdo aberto. Usuário confirmou funcionamento após corrigir a chave `tipoConteudo` e a condição do botão salvar.
- Comunidade conectada: busca lista e resumo, guarda no estado, exibe autor/nota/comentário e filtra a avaliação pessoal pelo ID do registro. `_saveReview()` recarrega resumo e comunidade após salvar. Exibição com duas contas ainda exige teste manual.
- Removidos catch duplicado e erro de texto TMBD; incluídos título da comunidade e singular/plural da contagem.
- Decisão atual de notas: **double, intervalo 0 a 10 e slider em passos de 0,5**. Validação de salvar e carregar alinhada, incluindo rejeição de NaN/infinito.
- Última execução de `flutter analyze` no estado final: **No issues found!**. Não foi executada a suíte completa nesta revisão; testes antigos ainda precisam ser atualizados.
- A contagem, limpeza de logs e alinhamento dos testes foram finalizados; o usuário confirmou os fluxos finais e autorizou integrar na main.

## Como trabalhar com o usuário

- Sempre que o usuário pedir push de um commit, atualizar este arquivo de memória antes do envio, registrando o estado atual, verificações, pendências e próximo passo. Incluir a atualização no commit a enviar; se ele já existir, criar um novo commit de documentação, sem reescrever o histórico. Depois realizar o push autorizado.
- O usuário quer orientação e aprendizado, uma etapa por vez. Ler o código é permitido. Não editar arquivos, instalar dependências, criar branches, fazer commits, push, PR ou alterar serviços sem pedido explícito para a ação.
- Explicar o problema, arquivo, classe e método; mostrar o trecho e dizer se deve adicionar, substituir ou remover; explicar como verificar; esperar o resultado antes de avançar.
- Quando houver autorização explícita para executar uma mudança, fazê-la e verificar, preservando as alterações existentes do usuário.
- Evitar grandes refatorações, arquitetura sofisticada e mudanças de stack. Explicar Dart/Flutter no contexto: Future, await, initState, mounted, setState e estado compartilhado.
- Avisar quando a branch estiver estável para integrar à main. Merge/push na main requer autorização. Não tratar a autorização de um commit anterior como autorização permanente.

## Objetivo e escopo

TCC com entrega em **24/11/2026**. Aplicativo Flutter de descoberta de filmes/séries, onde assistir, favoritos, avaliações pessoais/comunidade e recomendações personalizadas. Priorizar fluxos funcionais, apresentáveis, persistidos e explicáveis pela equipe.

Repositórios:

- Flutter: https://github.com/victorbispoo/tvScoreFrontFlutter
- Java: https://github.com/GuedesSiilva/BackEnd_Projeto_TvScore
- Python: https://github.com/Kaique-Ramiro/recomendador-TvScore

O código local é a referência inicial; não substituir mudanças locais por versões remotas.

Frontend: Flutter/Dart, Dio, FlutterSecureStorage, SharedPreferences, alguns ChangeNotifier. Serviços em `lib/services/` usam `part/part of` e extensions de `ApiService`. Estado compartilhado ainda usa campos static; não refatorar tudo.

Backend Java: Spring Boot, JWT, MySQL, integração TMDB. Base URL atual em `api_services.dart`: `https://tvscore-backend.onrender.com/api`.

## Estado do Git e transporte para outro PC

Na inspeção desta data: branch `victor`, último commit `9a5450c` (README), sincronizado com `origin/victor` antes das mudanças locais. A main foi trazida para victor por fast-forward e victor recebeu push nessa ocasião.

**Há trabalho de avaliações ainda sem commit**, além de alterações feitas pelo usuário. Conferir `git status` e `git diff`; não descartar nada. `test/review_rating_test.dart` também está sem rastreamento na inspeção atual.

O usuário preferiu esperar fechar o fluxo de avaliações para fazer commit. Este documento também precisa ser levado ao outro PC: arquivos sem commit/push não aparecem em um clone/pull. Fazer commit/push somente quando solicitado, ou o usuário pode transferir os arquivos por outro meio. Não incluir senhas, tokens ou arquivos secretos.

## Decisões já adotadas

- Conteúdos são identificados por **ID TMDB + tipo**, nunca por título.
- Tipos internos e enviados ao Java foram padronizados como **MOVIE e TV**. Evitar reintroduzir movie/tv minúsculos. Rotas continuam `/filmes` e `/series`.
- Somente favoritos; sem estados de acompanhamento.
- Favoritos e avaliações têm o backend como fonte persistente. Listas static continuam em memória para as telas.
- `Review.rating`, parâmetro de `saveReview()` e estado da nota nos detalhes são `double`. Leitura JSON usa `(valor as num).toDouble()`.
- Slider de 0 a 10, com passos de 0,5, alinhado à validação atual; notas são double. Java aceita 0 a 10 e decimais.
- Nome editado continua apenas local; não apresentar como alteração persistida no servidor.

## O que já foi feito e verificado

### Favoritos

- `getFavorites`, `loadFavorites`, adicionar/remover e tela com carregamento, erro, nova tentativa e vazio.
- `getContent()` corrigido: `/filmes/{id}` e `/series/{id}`, em vez de rotas inglesas.
- Usuário confirmou adicionar/remover, recuperação após logout/login, cards e contagem atualizados nos testes manuais.
- Persistência local dos favoritos removida; registros antigos são limpos por `open()` ao abrir cada conta.
- Atenção ainda necessária: remoção na lista não bloqueia múltiplos toques; Future.wait falha por inteiro se um detalhe falha; erros de sessão continuam genéricos; consultas assíncronas durante troca de conta ainda merecem revisão.

### Conta e armazenamento local

- Login/cadastro reais, sessão no FlutterSecureStorage; não persistir senha. Logout limpa estado em memória.
- `open()` define usuário, restaura somente nome local, limpa listas em memória e remove chaves antigas `saved` e `reviews` da biblioteca local.
- `_saveLibrary()` foi removido. `updateName()` grava apenas o nome em SharedPreferences.
- `open()` é chamado antes de atribuir o token em login/restauração: não inserir chamada autenticada ali sem considerar essa ordem.

### Avaliações pessoais

- `saveReview()` faz POST real e atualiza lista em memória por ID+tipo; `deleteReview()` faz DELETE usando ID do registro da avaliação.
- Corrigidos dois erros comprovados pela resposta real: nota é double, e data vem em **dataCriacao**, não em data.
- Usuário confirmou salvar, editar, comentário vazio e ausência de duplicação no fluxo testado.
- `getMyReviews()` e `loadMyReviews()` implementados. O carregamento busca detalhes dos títulos para montar `Review`.
- `MyReviewsPage` já chama `_loadMyReviews()` no initState, com carregamento, erro, nova tentativa e vazio. Usuário confirmou recuperação remota funcionando.
- Detalhes pela Home recuperam a avaliação pessoal pelo serviço antes de liberar a edição; não dependem mais de visitar Minhas avaliações primeiro.

### Comunidade e resumo — ponto atual

- Consultas `getContentReviews()` e `getContentReviewSummary()` adicionadas ao serviço.
- Backend público foi inspecionado via GitHub em 08/11/2026. Arquivos relevantes: `controller/AvaliacaoController.java`, `dto/AvaliacaoDTO.java`, `dto/ResumoAvaliacaoDTO.java`, `avaliacao/AvaliacaoService.java` sob `src/main/java/br/com/senai/tv_score/`.
- Teste real confirmou lista e resumo: filme 1423191, tipo MOVIE, média 6.0, total 1. Isso é evidência do teste, não dado para fixar no código.
- Erro 404 anterior era URL local incorreta `/avaliacoes/filme/{id}/resumo`; corrigida para `/avaliacoes/conteudo/{id}/resumo`.
- `DetailsPage` agora contém `_reviewSummary`, `_loadingCommunity`, `_communityError`; `_checkCommunityReviews()` consulta somente resumo; há widget de média/quantidade, progresso e nova tentativa.
- Resumo e cards da comunidade estão conectados à interface. Confirmar comportamento com duas contas na verificação manual final.
- Catch duplicado, rótulo TMDB e singular/plural foram corrigidos e conferidos no código.
- `_saveReview()` atualiza resumo e comunidade após salvar.

## Contratos de avaliações confirmados

Todos os caminhos abaixo são relativos à base `/api`:

- GET `/avaliacoes/minhas`: lista pessoal autenticada.
- POST `/avaliacoes`: cria ou atualiza por usuário + ID TMDB + tipo. Corpo: `filmeSerieId`, `tipoConteudo`, `nota`, `comentario`.
- DELETE `/avaliacoes/{id}`: ID do registro da avaliação, não ID TMDB.
- GET `/avaliacoes/filme/{filmeSerieId}?tipoConteudo=MOVIE|TV`: lista por conteúdo; apesar do nome “filme”, também atende séries.
- GET `/avaliacoes/conteudo/{filmeSerieId}/resumo?tipoConteudo=MOVIE|TV`: média/quantidade.

Resposta de avaliação: `id`, `filmeSerieId`, `nota`, `comentario`, `nomeUsuario`, `dataCriacao`, `tipoConteudo`.

Resumo: `filmeSerieId`, `tipoConteudo`, `media`, `totalAvaliacoes`. Considerar média nula sem avaliações; não representar como nota zero.

A lista por conteúdo inclui a avaliação do próprio usuário. Separá-la usando ID do registro identificado na lista pessoal; nome do autor não identifica conta. DTO não fornece campo de spoiler nem ID do autor. Não inventar campos.

## Próximas etapas combinadas

Uma etapa por vez, com inspeção atual antes de orientar:

1. Avaliações fechadas: contagem remota, carregamento pessoal, comunidade, resumo e exclusão implementados; testes automatizados e validação manual final concluídos.
2. Retomar pelas recomendações reais, conferindo o contrato antes de propor integração. Não presumir que as observações antigas dos serviços continuam atuais.

Depois:

- Recomendações reais do Python: verificar contrato atual. Inspeção antiga dizia que `/recomendacoes/personalizadas` era mock e `/recomendacoes/filmes/java` e `/recomendacoes/series/java` usavam Java/token. Não assumir que continuam iguais. Adaptar campos/tipos, tratar conta sem histórico, erro/carregamento e explicações. Score de recomendação não é nota nem probabilidade. Não reescrever algoritmo.
- Onde assistir (obrigatório): verificar operação Java por título. Separar Brasil/assinatura/aluguel/compra, atribuir JustWatch, usar link de consulta TMDB quando disponível. Sem dados: “Disponibilidade não informada”. Listar plataformas/filtro de catálogo não equivale à consulta por título.
- Pesquisa via backend, filtro filme/série e paginação: atualmente SearchPage filtra catálogo em alta; conferir estado atual antes de mudar.
- Detalhes completos e indisponibilidade de dados/imagens; conferir gêneros em resposta de detalhes (`genre_ids` vs `genres`). Separar TMDB, média TVScore e nota pessoal.
- Mensagens de conexão, credenciais e sessão expirada; revisar restauração/isolamento entre contas.
- APK Android, teste de demonstração, README/configuração sem segredos, créditos TMDB/JustWatch.

Não são requisitos: nova arquitetura, modelos para todos os mapas, cache sofisticado, ampla cobertura, Play Store, seguidores/curtidas/respostas ou episódios.

## Verificações e limitações

- Houve `flutter analyze` sem problemas e três testes de conversão de nota passando após padronização de tipos. Usuário também executou analyze com sucesso antes dos últimos ajustes de UI. Isso não certifica o estado atual inteiro.
- `test/review_rating_test.dart` cobre resposta numérica e envio MOVIE; fixture usa `dataCriacao`.
- Testes de biblioteca/sessão alinhados à integração HTTP e retirada de persistência local; suíte completa passou com 25 testes na sessão de fechamento.
- Logs temporários dos campos e datas removidos de `saveReview()`. Manter diagnóstico de erros sem registrar token/senha.

## Mensagem para retomar em outro PC

> Leia MEMORIA_PROJETO.md e confira o código local/Git. Quero orientação, sem alterações automáticas. Avaliações de filmes/séries concluídas; simplificações verificadas automaticamente. Minha intenção mais recente é adicionar notas por episódio: primeiro esclarecer se são notas TMDB ou pessoais. Recomendações, onde assistir e pesquisa ainda pendentes. Trabalhe uma etapa por vez; não faça commit/push sem eu pedir.
