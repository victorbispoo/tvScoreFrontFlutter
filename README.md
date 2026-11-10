<div align="center">
  <img src="lib/assets/tvScoreLogin.png" alt="Logo do TV Score" width="180" />

  <h1>TV Score</h1>
  <p><strong>Sua próxima boa história começa aqui.</strong></p>
  <p>Descubra filmes e séries, saiba onde assistir e receba recomendações feitas para você.</p>

  <img src="https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Material_3-091426?style=flat-square&logo=materialdesign&logoColor=white" alt="Material 3" />
  <img src="https://img.shields.io/badge/Plataforma-Android-3DDC84?style=flat-square&logo=android&logoColor=white" alt="Android" />
</div>

---

## Sobre o projeto

O **TV Score** é um aplicativo de descoberta e avaliação de filmes e séries, desenvolvido em Flutter como Trabalho de Conclusão de Curso. Ele reúne catálogo TMDB, disponibilidade em plataformas de streaming, favoritos, avaliações da comunidade e recomendações personalizadas em uma interface com tema escuro e Material 3.

O aplicativo integra uma API Java e um serviço de recomendações em Python. A API gerencia autenticação, catálogo e biblioteca pessoal; o recomendador utiliza as preferências e o histórico de avaliações para sugerir filmes e séries. A sessão é armazenada de forma segura no dispositivo, permitindo retomar o acesso ao reabrir o app.

## Escopo do projeto

O TV Score reúne em um único aplicativo a descoberta de conteúdos, a consulta de onde assistir e a organização da experiência de cada usuário com filmes e séries. O público inclui pessoas que buscam novos títulos, acompanham suas preferências e consultam opiniões antes de escolher o que assistir.

O escopo contempla o fluxo completo: criar uma conta, explorar e pesquisar o catálogo, aplicar filtros, consultar detalhes e plataformas disponíveis, salvar favoritos, publicar e gerenciar avaliações e receber recomendações personalizadas. A biblioteca permanece vinculada à conta, permitindo recuperar favoritos e avaliações em novos acessos.

A solução compreende o aplicativo Android em Flutter, a API Java, a persistência dos dados pessoais e o serviço Python de recomendação, com integração aos dados do TMDB e à disponibilidade de streaming fornecida pelo JustWatch via TMDB.

## Funcionalidades

| Recurso | Descrição |
| --- | --- |
| Catálogo | Carrosséis com destaques, títulos ordenados por nota e ano, categorias por gênero e séries. |
| Pesquisa | Busca por título diretamente no backend, com filtro entre filmes e séries e carregamento de novas páginas durante a rolagem. |
| Filtros do catálogo | Exploração por gênero, ano, faixa de notas e plataforma de streaming. |
| Detalhes | Pôster, imagem de fundo, sinopse, ano, gêneros e nota TMDB. |
| Onde assistir | Plataformas disponíveis no Brasil para cada título, separadas por assinatura, aluguel e compra, com acesso à consulta de disponibilidade. |
| Recomendações personalizadas | Sugestões de filmes e séries com base nas preferências e avaliações do usuário, acompanhadas de explicações sobre a recomendação. |
| Episódios | Seleção de temporada e grid com número, nota TMDB e cores por faixa de avaliação. Episódios sem votos recebem uma indicação própria. |
| Favoritos | Adição, consulta e remoção de títulos, com persistência vinculada à conta no backend. |
| Avaliações pessoais | Notas de 0 a 10 em passos de 0,5, com comentário opcional, edição e exclusão. |
| Comunidade | Avaliações de outros usuários, média TVScore e quantidade de avaliações por título. |
| Minhas avaliações | Consulta do histórico pessoal e ordenação por data ou nota. |
| Conta e sessão | Cadastro, login, restauração de sessão, verificação de expiração do token e logout. |
| Perfil | Contagens de favoritos e avaliações, acesso à biblioteca e personalização local do nome exibido. |

As notas **TMDB**, a média da comunidade **TVScore** e a **avaliação pessoal** são apresentadas separadamente. O score de recomendação indica a relevância de uma sugestão para o usuário e não representa uma nota do título. Filmes e séries são identificados pelo ID TMDB e pelo tipo de conteúdo.

O aplicativo apresenta estados de carregamento, lista vazia, erro e nova tentativa. Quando não há informações de streaming para um título, exibe “Disponibilidade não informada”. Contas sem histórico recebem orientação para informar preferências e avaliar conteúdos.

## Tecnologias

| Tecnologia | Aplicação |
| --- | --- |
| Flutter e Dart | Interface, navegação e lógica do aplicativo |
| Material 3 | Componentes visuais e tema escuro |
| Dio | Comunicação HTTP com a API |
| Flutter Secure Storage | Armazenamento seguro da sessão |
| Shared Preferences | Preferências locais do perfil |
| Flutter SVG | Renderização de elementos vetoriais |
| Google Fonts | Tipografia Work Sans |
| HugeIcons | Ícones da interface |
| Flutter Test | Testes de serviços, sessão e widgets |
| Java e Spring Boot | API, autenticação JWT e regras de negócio |
| MySQL | Persistência das contas, favoritos e avaliações |
| Python | Serviço de recomendações personalizadas |
| TMDB | Catálogo, imagens, gêneros e notas de filmes, séries e episódios |
| JustWatch via TMDB | Disponibilidade dos títulos em plataformas de streaming |

## Integração da solução

- **Aplicativo Flutter:** apresenta o catálogo, a pesquisa, os detalhes, a biblioteca pessoal e as recomendações.
- **Backend Java:** autentica usuários, persiste favoritos e avaliações e consulta dados de conteúdos e disponibilidade no TMDB.
- **Serviço Python:** processa preferências e avaliações para produzir recomendações personalizadas de filmes e séries.

Os repositórios dos três componentes estão disponíveis em **Repositórios relacionados**.

## Como executar

### Pré-requisitos

- Flutter com versão do Dart compatível com `^3.12.2`, conforme o [pubspec.yaml](pubspec.yaml).
- Android SDK configurado.
- Emulador Android ou dispositivo com depuração USB habilitada.
- Git e conexão com a internet para acesso à API e às imagens.

### Instalação

```bash
git clone https://github.com/victorbispoo/tvScoreFrontFlutter.git
cd tvScoreFrontFlutter
flutter pub get
flutter doctor
flutter run
```

Para escolher um dispositivo:

```bash
flutter devices
flutter run -d ID_DO_DISPOSITIVO
```

Ao abrir o aplicativo, crie uma conta pela tela de cadastro ou entre com uma conta existente.

### Configuração da API

O endereço padrão do backend é:

```text
https://tvscore-backend.onrender.com/api
```

Para utilizar outro servidor, altere o `baseUrl` do Dio em [lib/services/api_services.dart](lib/services/api_services.dart). O endereço deve ser acessível pelo emulador ou dispositivo.

O frontend consome o backend Java; as credenciais de acesso ao TMDB são configuradas no servidor.

### Catálogo de demonstração

Para substituir os destaques da tela Início por um catálogo fixo:

```bash
flutter run --dart-define=USE_MOCK_MOVIES=true
```

Os dados ficam em [lib/data/mock_contents.dart](lib/data/mock_contents.dart). A opção altera o catálogo da Home; pesquisa, autenticação, favoritos, avaliações e episódios continuam consultando o backend. As imagens também dependem de conexão com a internet.

## Organização do código

```text
lib/
├── assets/        # Logos e recursos visuais
├── controllers/   # Controle dos formulários de autenticação
├── core/          # Tema e estilos compartilhados
├── data/          # Catálogo de demonstração
├── models/        # Modelo de avaliação
├── pages/         # Telas do aplicativo
├── services/      # Autenticação, conteúdos, favoritos e avaliações
├── widgets/       # Cards, carrosséis, formulários e grid de episódios
└── main.dart      # Inicialização, restauração da sessão e navegação

test/
├── support/       # Backend simulado para os testes
└── *_test.dart    # Testes de serviços e interface
```

## Qualidade e testes

Para analisar o código e executar a suíte:

```bash
flutter analyze
flutter test
```

Os testes cobrem autenticação e restauração de sessão, isolamento entre contas, favoritos, avaliações, pesquisa, conversão de gêneros e fluxos de navegação. As respostas HTTP são simuladas nos testes para que a suíte não dependa do backend publicado.

Para conferir a formatação:

```bash
dart format --output=none --set-exit-if-changed lib test
```

## Gerar o APK

```bash
flutter build apk --release
```

O arquivo gerado fica em:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Repositórios relacionados

- [Aplicativo Flutter](https://github.com/victorbispoo/tvScoreFrontFlutter)
- [Backend Java](https://github.com/GuedesSiilva/BackEnd_Projeto_TvScore)
- [Serviço de recomendações Python](https://github.com/Kaique-Ramiro/recomendador-TvScore)

## Créditos

Dados de filmes, séries, episódios e imagens são fornecidos pelo [TMDB](https://www.themoviedb.org/). Este produto utiliza a API do TMDB, mas não é endossado nem certificado pelo TMDB.

As informações sobre onde assistir são fornecidas pelo **JustWatch**, por meio da integração de disponibilidade do TMDB, considerando a região do Brasil.

---

<p align="center">TV Score · Descubra, avalie e encontre sua próxima história favorita.</p>
