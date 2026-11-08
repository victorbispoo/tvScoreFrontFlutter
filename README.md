<div align="center">
  <img src="lib/assets/tvScoreLogin.png" alt="Logo do TV Score" width="180" />

  <h1>TV Score</h1>
  <p>Descubra sua próxima história favorita.</p>
  <p>Explore filmes e séries, monte sua lista e registre o que achou de cada título.</p>

  <img src="https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Material_3-091426?style=flat-square&logo=materialdesign&logoColor=white" alt="Material 3" />
  <img src="https://img.shields.io/badge/Status-Em_desenvolvimento-4F8DF7?style=flat-square" alt="Em desenvolvimento" />
</div>

---

## Sobre o projeto

O **TV Score** é um aplicativo Flutter para descobrir filmes e séries, guardar favoritos e registrar notas e comentários. A interface usa Material 3, tema escuro, carrosséis na tela inicial e banners nas telas de detalhes.

## O que dá para fazer

- **Explorar o catálogo** pela tela Início, com destaques, títulos mais bem avaliados, lançamentos ordenados por ano e carrosséis por gênero.
- **Pesquisar** por título ou gênero, com ou sem acentos, pelo ícone no cabeçalho da tela Início. A busca filtra o catálogo carregado pelo app.
- **Consultar detalhes** de um título, com pôster, imagem de fundo, sinopse, ano, gênero e nota do catálogo quando disponíveis.
- **Adicionar, consultar e remover favoritos** na conta. A aba Favoritos carrega a lista da API e oferece nova tentativa se a consulta falhar. Cada título é identificado pelo ID e pelo tipo (filme ou série).
- **Acessar a conta** por login ou cadastro. O app guarda a sessão em armazenamento seguro, verifica a expiração do JWT ao reabrir e permite sair pelo Perfil.
- **Personalizar o perfil** e acessar Favoritos e Minhas avaliações. O nome editado fica no dispositivo, separado por e-mail, via Shared Preferences.

### Avaliações em integração

A tela de detalhes aceita notas de 1 a 10 e comentários. O serviço envia o formulário com `POST /avaliacoes` e solicita exclusão com `DELETE /avaliacoes/{id}`. As duas operações exigem uma sessão autenticada.

A tela **Minhas avaliações** usa a lista em memória, permite ordenar por data ou nota e abre o formulário de detalhes para edição. Esse formulário usa o mesmo `POST` do cadastro de avaliações. A integração ainda tem as limitações descritas em **Pendências conhecidas**.

## Executar no Android

- Flutter com Dart compatível com `^3.12.2`, conforme o [pubspec.yaml](pubspec.yaml).
- Android SDK e um emulador ou dispositivo Android configurado para desenvolvimento.
- Git para clonar o repositório.
- Acesso ao backend e uma conta cadastrada, que pode ser criada na tela de cadastro.

```bash
flutter doctor
git clone https://github.com/victorbispoo/tvScoreFrontFlutter.git
cd tvScoreFrontFlutter
flutter pub get
flutter run
```

Use `flutter devices` para listar os dispositivos e `flutter run -d ID_DO_DISPOSITIVO` para selecionar um.

Por padrão, o app usa a API para o catálogo, com `GET /filmes/em-alta` e `GET /series/em-alta`. O endereço configurado é `https://tvscore-backend.onrender.com/api`. Para usar outro servidor, ajuste o `baseUrl` do Dio em [lib/services/api_services.dart](lib/services/api_services.dart) para um endereço acessível pelo dispositivo.

### Catálogo mockado

Use os filmes e séries de [lib/data/mock_contents.dart](lib/data/mock_contents.dart) para testar o catálogo e a busca com dados fixos.

```bash
flutter run --dart-define=USE_MOCK_MOVIES=true
```

A opção troca a fonte do catálogo exibido no Início e na busca. Login, cadastro, favoritos (incluindo os detalhes carregados na aba) e as operações de avaliação continuam usando o backend. As imagens do catálogo mockado vêm do TMDB e dependem de conexão com a internet.

## Organização do código

```text
lib/
├── assets/        # Logos e arquivos visuais
├── controllers/   # Controllers de login e cadastro
├── core/          # Tema e estilos compartilhados
├── data/          # Catálogo mockado
├── models/        # Modelos de conteúdo e avaliação
├── pages/         # Telas do aplicativo
├── services/      # Sessão, catálogo, favoritos e avaliações
├── widgets/       # Componentes reutilizáveis
└── main.dart      # Inicialização, restauração de sessão e navegação
```

## Tecnologias

| Tecnologia | Uso no projeto |
| --- | --- |
| Flutter e Dart | Interface e lógica do aplicativo |
| Material 3 | Componentes e tema escuro |
| Dio | Requisições HTTP ao backend |
| Flutter Secure Storage | Armazenamento da sessão |
| Shared Preferences | Nome do perfil e leitura das avaliações locais antigas |
| Flutter SVG | Renderização das logos em SVG |
| Google Fonts | Tipografia Work Sans |
| HugeIcons | Ícones da navegação e das telas |
| Flutter Test | Testes de lógica e widgets |

## Testes e verificação

```bash
flutter analyze
flutter test --dart-define=USE_MOCK_MOVIES=true
dart format lib test
```

O parâmetro fornece os dados fixos esperados pelos testes da tela Início e da busca.

| Arquivo | Cenários previstos |
| --- | --- |
| [auth_session_test.dart](test/auth_session_test.dart) | Login, restauração de sessão, expiração do JWT e saída da conta |
| [api_service_test.dart](test/api_service_test.dart) | Persistência do perfil, limpeza de favoritos locais antigos e regras de avaliações |
| [library_flow_test.dart](test/library_flow_test.dart) | Navegação, busca, favoritos, perfil e fluxos de avaliação na interface |

## Pendências conhecidas

- **Compilação** — Em [lib/models/review.dart](lib/models/review.dart), o construtor aceita omitir `id`, mas o campo é um `int` não anulável. A incompatibilidade precisa ser corrigida para rodar o app e a suíte completa.
- **Avaliações** — Após salvar uma avaliação pela API, o app atualiza a lista em memória. Falta recarregar as avaliações do servidor ao abrir a conta e definir como editar no servidor e tratar registros locais antigos sem ID remoto.
- **Testes** — Parte da suíte ainda pressupõe favoritos e avaliações locais. Os casos que exercitam essas operações precisam de respostas simuladas da API, sessão e identificadores válidos. O modo mockado do catálogo cobre apenas os dados de início e busca.

---

<p align="center">TV Score · Sua próxima boa história começa aqui.</p>
