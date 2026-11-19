# Avaliações públicas: contrato e validação de sessão

Verificado em 19/11/2026, com GET sem `Authorization`, no ambiente
`https://tvscore-backend.onrender.com/api`, usando o conteúdo 1396 e `tipoConteudo=TV`:

| Endpoint | Resposta sem JWT |
| --- | --- |
| `/avaliacoes/conteudo/1396/resumo?tipoConteudo=TV` | 200; média e total de avaliações |
| `/avaliacoes/filme/1396?tipoConteudo=TV` | 200; avaliações e comentários públicos |
| `/avaliacoes/filme/1396/paginadas?tipoConteudo=TV&pagina=0&tamanho=3` | 200; avaliações e comentários paginados |
| `/favoritos` | 401; dados pessoais protegidos |

As listagens que retornavam 401 na etapa anterior agora permitem GET anônimo no
ambiente consultado. Nenhuma alteração de backend foi feita nesta tarefa.
Comentários pertencem ao DTO de avaliação; não há um endpoint separado de comentários
nesse controller. A listagem não recebe `AuthenticationPrincipal`.

## Regras a preservar no Spring Boot

Manter pública apenas a leitura das avaliações por conteúdo, antes de
`.anyRequest().authenticated()` em `SecurityConfig`:

```java
.requestMatchers(HttpMethod.GET,
    "/api/avaliacoes/filme/*",
    "/api/avaliacoes/filme/*/paginadas"
).permitAll()
```

Preservar a proteção de `/api/avaliacoes/minhas`, `/minhas/paginadas`, POST,
PUT e DELETE. Não liberar `/api/avaliacoes/**` indiscriminadamente.
O filtro JWT deve continuar permitindo requisições sem token nos caminhos públicos.

O contrato paginado existente contém `content`, `totalPages` e `totalElements`.
Cada avaliação usa `id`, `nomeUsuario`, `fotoUsuarioUrl` (opcional), `nota`,
`comentario` (opcional), `dataCriacao` e `tipoConteudo`. Preservar somente os dados
públicos do autor, sem acrescentar e-mail, credenciais ou informações privadas.
Validar também o acesso anônimo às URLs de foto e o CORS da origem Flutter Web.

## Comportamento do Flutter

- Resumo, listagem e paginação são consultados sem JWT, inclusive com conta ativa
  e após logout. Uma falha nessas leituras públicas não encerra a sessão.
- HTTP 401/403 para visitantes exibe indisponibilidade pública com nova tentativa;
  não há token artificial, troca de endpoint para contornar a proteção ou login forçado.
- Falhas na listagem não ocultam o resumo público TVScore.
- “Entrar para avaliar” abre o login existente sobre os detalhes. Ao autenticar,
  retorna à mesma rota e conteúdo, inclusive via cadastro. Cancelar mantém a origem.
  Nenhuma avaliação é enviada sem uma ação explícita no formulário.

## Validação pendente no ambiente final

Validar na origem Web publicada o CORS, as fotos públicas e a paginação completa.
Com duas contas de teste, verificar expiração real, troca de conta e retorno do
background no Android/Web. Confirmar que criação, edição e exclusão continuam
protegidas; a consulta de favoritos sem JWT foi verificada e continua retornando 401.
Os testes Flutter cobrem também leituras antes/depois de sair, respostas privadas
atrasadas, cancelamento de login e ausência de publicação automática, sem rede real.
