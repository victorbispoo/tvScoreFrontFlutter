/// Ponto único para substituir os dados de exemplo por chamadas HTTP.
class ApiService {
  Future<List<Map<String, String>>> getHighlights() async {
    return const [
      {
        'title': 'Oppenheimer',
        'poster_path': 'https://image.tmdb.org/t/p/w500/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg',
        'year': '2023',
        'score': '8.9',
        'genre': 'Biografia / Drama',
      },
      {
        'title': 'Barbie',
        'poster_path': 'https://image.tmdb.org/t/p/w500/iuFNMS8U5cb6xfzi51Dbkovj7vM.jpg',
        'year': '2023',
        'score': '7.3',
        'genre': 'Comédia',
      },
      {
        'title': 'Avatar: O Caminho da Água',
        'poster_path': 'https://image.tmdb.org/t/p/w500/t6HIqrRAclMCA60NsSmeqe9RmNV.jpg',
        'year': '2022',
        'score': '7.8',
        'genre': 'Ficção Científica',
      },
      {
        'title': 'Homem-Aranha: Através do Aranhaverso',
        'poster_path': 'https://image.tmdb.org/t/p/w500/8HWnnrO0a4aY18y2rN83g7c88P6.jpg',
        'year': '2023',
        'score': '8.9',
        'genre': 'Animação',
      },
      {
        'title': 'Duna: Parte Dois',
        'poster_path': 'https://image.tmdb.org/t/p/w500/8b8R8l88Qje9dn9OE8PY05Nxl1X.jpg',
        'year': '2024',
        'score': '8.5',
        'genre': 'Ficção Científica',
      },
      {
        'title': 'Missão: Impossível - Efeito Fallout',
        'poster_path': 'https://image.tmdb.org/t/p/w500/AkJQpmRyz9JwX7opAVQby6zyALv.jpg',
        'year': '2018',
        'score': '7.7',
        'genre': 'Ação',
      },
      {
        'title': 'Top Gun: Maverick',
        'poster_path': 'https://image.tmdb.org/t/p/w500/62HCnUTziyWcpDaBO2i1DX17ljH.jpg',
        'year': '2022',
        'score': '8.3',
        'genre': 'Ação',
      },
      {
        'title': 'Vingadores: Ultimato',
        'poster_path': 'https://image.tmdb.org/t/p/w500/or06FN3Dka5tukK1e9sl16pB3iy.jpg',
        'year': '2019',
        'score': '8.4',
        'genre': 'Ação',
      },
      {
        'title': 'O Poderoso Chefão',
        'poster_path': 'https://image.tmdb.org/t/p/w500/3bhkrj58Vtu7enYsRolD1fZdja1.jpg',
        'year': '1972',
        'score': '9.2',
        'genre': 'Crime / Drama',
      },
      {
        'title': 'Pulp Fiction: Tempo de Violência',
        'poster_path': 'https://image.tmdb.org/t/p/w500/tptX04nGe6P9k9XvN6s1lqE5c1P.jpg',
        'year': '1994',
        'score': '8.9',
        'genre': 'Crime / Drama',
      },
      {
        'title': 'Interestelar',
        'poster_path': 'https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg',
        'year': '2014',
        'score': '8.7',
        'genre': 'Ficção Científica',
      },
    ];
  }

  // Contas fictícias para testes locais, sem persistência.
  static const mockUsers = [
    {'id': '1', 'name': 'José Silva', 'email': 'jose@teste.com', 'password': '123456'},
    {'id': '2', 'name': 'Ana Souza', 'email': 'ana@teste.com', 'password': '123456'},
    {'id': '3', 'name': 'Victor Lima', 'email': 'victor@teste.com', 'password': '123456'},
  ];

  Future<void> login(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    final valid = mockUsers.any(
      (user) => user['email'] == normalizedEmail && user['password'] == password,
    );
    if (!valid) {
      throw const FormatException('Email ou senha incorretos.');
    }
  }
}

