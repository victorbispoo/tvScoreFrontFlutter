<p align="center">
  <a href="assets/readme/mobile/banner.png"><img src="assets/readme/mobile/banner.png" alt="TVScore Mobile com as telas de catálogo, detalhes e perfil" width="760" /></a>
</p>

<div align="center">
  <p>O TVScore é um Trabalho de Conclusão de Curso desenvolvido em Flutter para Android e Web. Explore filmes e séries, descubra onde assistir e receba recomendações com base nas suas preferências e avaliações.</p>
  <p>
    <a href="https://tvscore-landing.pages.dev/"><img src="https://img.shields.io/badge/Conhecer%20o%20TVScore-2563EB?style=for-the-badge" alt="Conhecer o TVScore" /></a>
    <a href="https://tvscore.pages.dev/"><img src="https://img.shields.io/badge/Abrir%20no%20navegador-26384F?style=for-the-badge" alt="Abrir no navegador" /></a>
    <a href="https://github.com/victorbispoo/tvScoreFrontFlutter/releases"><img src="https://img.shields.io/badge/Baixar%20APK-26384F?style=for-the-badge" alt="Baixar APK para Android" /></a>
  </p>
  <p><a href="#tvscore-mobile">Mobile</a> · <a href="#tvscore-web">Web</a> · <a href="#como-executar">Como executar</a></p>
</div>

## TVScore Mobile

<p align="center">
  <a href="assets/readme/mobile/01-descubra.png"><img src="assets/readme/mobile/01-descubra.png" alt="Catálogo e recomendações personalizadas no TVScore Mobile" width="13%" /></a>
  <a href="assets/readme/mobile/02-explore.png"><img src="assets/readme/mobile/02-explore.png" alt="Detalhes de Breaking Bad, notas e opções de streaming" width="13%" /></a>
  <a href="assets/readme/mobile/03-avalie.png"><img src="assets/readme/mobile/03-avalie.png" alt="Notas por episódio, edição da avaliação e opiniões da comunidade" width="13%" /></a>
  <a href="assets/readme/mobile/04-personalize.png"><img src="assets/readme/mobile/04-personalize.png" alt="Seleção de gêneros favoritos para personalizar recomendações" width="13%" /></a>
  <a href="assets/readme/mobile/05-escolha.png"><img src="assets/readme/mobile/05-escolha.png" alt="Seleção de filmes e séries preferidos" width="13%" /></a>
  <a href="assets/readme/mobile/06-seu-espaco.png"><img src="assets/readme/mobile/06-seu-espaco.png" alt="Perfil com estatísticas, biblioteca e tema do aplicativo" width="13%" /></a>
  <a href="assets/readme/mobile/07-comece-agora.png"><img src="assets/readme/mobile/07-comece-agora.png" alt="Tela para entrar, criar conta ou continuar explorando" width="13%" /></a>
</p>

## TVScore Web

<details>
<summary>Ver galeria Web</summary>

<p align="center">
  <a href="assets/readme/web/01-tvscore-web.png"><img src="assets/readme/web/01-tvscore-web.png" alt="Catálogo do TVScore Web aberto em um notebook" width="760" /></a>
</p>

<p align="center">
  <a href="assets/readme/web/02-responsividade.png"><img src="assets/readme/web/02-responsividade.png" alt="Detalhes de uma série em tablet, desktop e celular" width="370" /></a>
  <a href="assets/readme/web/03-aparencia.png"><img src="assets/readme/web/03-aparencia.png" alt="Perfil e opções de tema claro, escuro e do sistema" width="370" /></a>
</p>

<p align="center">
  <a href="assets/readme/web/04-avaliacoes.png"><img src="assets/readme/web/04-avaliacoes.png" alt="Formulário de avaliação e resenhas da comunidade" width="370" /></a>
  <a href="assets/readme/web/05-favoritos.png"><img src="assets/readme/web/05-favoritos.png" alt="Biblioteca de filmes e séries favoritos" width="370" /></a>
</p>

</details>

## Funcionalidades

- **Catálogo e busca.** Explore destaques, busque por título e filtre por gênero, ano, nota ou serviço de streaming. Consulte sinopse, gêneros e nota do TMDB nos detalhes.
- **Onde assistir.** Veja as opções de streaming no Brasil por assinatura, aluguel ou compra.
- **Avaliações e episódios.** Dê notas de 0 a 10, com comentário opcional, consulte avaliações da comunidade e acompanhe as notas dos episódios por temporada.
- **Favoritos e histórico.** Salve títulos na conta e consulte ou edite suas avaliações no perfil. Escolha entre os temas claro, escuro e do sistema.
- **Recomendações.** Selecione gêneros e títulos preferidos para receber sugestões com base nas suas escolhas e avaliações.

A interface mostra separadamente a **nota do TMDB**, a **média da comunidade TVScore** e a **sua avaliação**. A pontuação de recomendação indica quanto uma sugestão combina com as suas preferências.

## Como executar

Instale o Flutter com uma versão do Dart compatível com `^3.12.2`, conforme o [pubspec.yaml](pubspec.yaml). Use o Git para clonar o projeto e uma conexão com a internet para acessar a API e as imagens.

```bash
git clone https://github.com/victorbispoo/tvScoreFrontFlutter.git
cd tvScoreFrontFlutter
flutter doctor
flutter pub get
```

### Android

Configure o Android SDK e inicie um emulador ou conecte um dispositivo com depuração USB habilitada. Use o ID exibido por `flutter devices`.

```bash
flutter devices
flutter run -d ID_DO_ANDROID
```

Para instalar a versão publicada, baixe o arquivo `.apk` na seção **Assets** do [GitHub Releases](https://github.com/victorbispoo/tvScoreFrontFlutter/releases).

### Web

Com o Chrome instalado, execute:

```bash
flutter run -d chrome
```

### Configuração da API

O endereço padrão do backend é:

```text
https://tvscore-backend.onrender.com/api
```

Para utilizar outro servidor, altere o `baseUrl` do Dio em [lib/services/api_services.dart](lib/services/api_services.dart). O endereço deve ser acessível pelo emulador ou dispositivo.

O frontend consome o backend Java. As credenciais de acesso ao TMDB são configuradas no servidor.

### Catálogo de demonstração

Para substituir os destaques da tela Início por um catálogo fixo:

```bash
flutter run --dart-define=USE_MOCK_MOVIES=true
```

Os dados ficam em [lib/data/mock_contents.dart](lib/data/mock_contents.dart). A opção altera o catálogo da tela inicial. Pesquisa, autenticação, favoritos, avaliações e episódios continuam consultando o backend. As imagens também dependem de conexão com a internet.

## Tecnologias

| Tecnologia | Aplicação |
| --- | --- |
| Flutter e Dart | Interface, navegação e lógica do aplicativo |
| Material 3 | Componentes visuais e temas claro, escuro e do sistema |
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
