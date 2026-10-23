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

O **TV Score** é um aplicativo desenvolvido em Flutter para explorar um catálogo de filmes e séries e organizar sua experiência com cada história. A interface usa tema escuro, carrosséis por categoria e banners nas telas de detalhes.

O projeto está em desenvolvimento. O catálogo mockado permite navegar pelo app enquanto o backend está indisponível.

## O que dá para fazer

- **Explorar o catálogo:** destaques, títulos mais bem avaliados, lançamentos por ano e categorias por gênero.
- **Encontrar filmes e séries:** busca por título ou gênero, sem precisar digitar os acentos.
- **Consultar detalhes:** pôster, backdrop, sinopse, ano, gênero e nota do catálogo.
- **Salvar favoritos:** adicionar e remover títulos da sua lista.
- **Registrar avaliações:** dar notas de 1 a 10 e escrever comentários.
- **Gerenciar suas opiniões:** editar, excluir e ordenar avaliações por data ou nota.
- **Personalizar o perfil:** editar o nome e consultar suas contagens de favoritos e avaliações.

Favoritos, avaliações e nome do perfil são armazenados localmente com Shared Preferences, separados pelo e-mail da conta. As avaliações exibidas são pessoais; ainda não há uma lista de comentários de outros usuários.

## Executar o app

### Requisitos

- Flutter com Dart compatível com `^3.12.2`, conforme o [pubspec.yaml](pubspec.yaml).
- Android SDK e um emulador ou dispositivo Android configurado para desenvolvimento.
- Git para clonar o repositório.

Confira a configuração do ambiente:

```bash
flutter doctor
```

### Instalação

```bash
git clone https://github.com/victorbispoo/tvScoreFrontFlutter.git
cd tvScoreFrontFlutter
flutter pub get
flutter run
```

Se houver mais de um dispositivo disponível, consulte `flutter devices` e execute `flutter run -d ID_DO_DISPOSITIVO`.

### Acesso de demonstração

Na tela de login, toque em **Entrar**. Atualmente, o botão abre uma conta local de teste, sem autenticar as credenciais digitadas no backend.

O cadastro ainda faz uma requisição ao servidor e depende de sua disponibilidade. Para explorar a demonstração, não é necessário criar uma conta.

## Catálogo mockado

Os dados estão em [lib/data/mock_movies.dart](lib/data/mock_movies.dart), com filmes e séries, sinopses, notas de demonstração e URLs de pôsteres e backdrops.

O modo mockado vem **ativado por padrão**. Para executá-lo explicitamente:

```bash
flutter run --dart-define=USE_MOCK_MOVIES=true
```

Os dados do catálogo não dependem do backend nesse modo. As imagens são carregadas pelos servidores de imagem do TMDB e precisam de conexão com a internet.

### Voltar ao backend

1. Ajuste o `baseUrl` do Dio em [lib/services/api_services.dart](lib/services/api_services.dart) para o endereço acessível do seu servidor.
2. Com o backend disponível, execute:

```bash
flutter run --dart-define=USE_MOCK_MOVIES=false
```

Essa opção altera apenas a origem do catálogo, que passa a consultar `GET /filmes/em-alta`. Ela não ativa o login real nem sincroniza os favoritos e as avaliações com o servidor.

O serviço de autenticação já contém chamadas para `POST /auth/login` e `POST /auth/cadastrar`. A conexão do botão de login ao fluxo real ainda está pendente. O mapeamento de `backdrop_path` no catálogo remoto também está pendente.

## Organização do código

```text
lib/
├── assets/        # Logos e arquivos visuais
├── controllers/   # Controllers dos formulários e da busca
├── core/          # Tema, cores e estilos compartilhados
├── data/          # Catálogo mockado
├── models/        # Modelos de filme e avaliação
├── pages/         # Telas do aplicativo
├── services/      # API, autenticação e persistência da biblioteca
├── widgets/       # Componentes reutilizáveis
└── main.dart      # Inicialização e navegação principal

test/
├── api_service_test.dart   # Persistência local e regras das avaliações
└── library_flow_test.dart # Fluxos de navegação, busca e biblioteca
```

## Tecnologias

| Tecnologia | Uso no projeto |
| --- | --- |
| Flutter e Dart | Interface e lógica do aplicativo |
| Material 3 | Componentes e tema escuro |
| Dio | Requisições HTTP ao backend |
| Shared Preferences | Persistência local de favoritos, avaliações e perfil |
| Flutter SVG | Renderização das logos em SVG |
| Google Fonts | Tipografia Work Sans |
| HugeIcons | Ícones da navegação e das telas |
| Flutter Test | Testes de lógica e widgets |

## Verificação

Analisar o código:

```bash
dart analyze
```

Executar os testes com o catálogo mockado padrão:

```bash
flutter test
```

Formatar os arquivos Dart:

```bash
dart format lib test
```

---

<p align="center">TV Score · Sua próxima boa história começa aqui.</p>
