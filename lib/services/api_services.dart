/// Ponto único para substituir os dados de exemplo por chamadas HTTP.
class ApiService {
  Future<List<Map<String, String>>> getHighlights() async {
    return const [
      {'title': 'Oppenheimer','poster_path': 'https://www.themoviedb.org/t/p/w600_and_h900_face/dUPQszWoRSE9FucJTbVp2bwEi9G.jpg', 'year': '2023', 'score': '8.9','genre':'Ação'},
      {'title': 'Barbie', 'poster_path': 'https://www.themoviedb.org/t/p/w600_and_h900_face/9gbHTm127348592.jpg', 'year': '2023', 'score': '7.3','genre':'Comédia'},
      {'title': 'Avatar: O Caminho da Água', 'poster_path': 'https://www.themoviedb.org/t/p/w600_and_h900_face/8Vt6mWEReuy4Of61Lnj5Xj704m8.jpg', 'year': '2022', 'score': '7.8','genre':'Aventura'},
      {'title': 'Homem-Aranha: Através do Aranhaverso', 'poster_path': 'https://www.themoviedb.org/t/p/w600_and_h900_face/iiZZdoQBEYB3HeqJODzKBOL7P4l.jpg', 'year': '2023', 'score': '8.9','genre':'Animação'},
      {'title': 'Duna: Parte Dois', 'poster_path': 'https://www.themoviedb.org/t/p/w600_and_h900_face/5WVrHsN1FvZdLpGgKcHkRJQvZ1J.jpg', 'year': '2023', 'score': '8.1','genre':'Ficção Científica'},
      {'title': 'Missão: Impossível - Efeito Fallout', 'poster_path': 'https://www.themoviedb.org/t/p/w600_and_h900_face/8Vt6mWEReuy4Of61Lnj5Xj704m8.jpg', 'year': '2018', 'score': '7.7','genre':'Ação'},
      {'title': 'Top Gun: Maverick', 'poster_path': 'https://www.themoviedb.org/t/p/w600_and_h900_face/9gbHTm127348592.jpg', 'year': '2022', 'score': '8.4','genre':'Ação'},
      {'title': 'Vingadores: Ultimato', 'poster_path': 'https://www.themoviedb.org/t/p/w600_and_h900_face/8Vt6mWEReuy4Of61Lnj5Xj704m8.jpg',('year'):('2019'), ('score'):('8.4'),('genre'):('Ação')},
      {'title':('O Poderoso Chefão'), ('poster_path'):(''), ('year'):('1972'), ('score'):('9.2'),('genre'):('Crime')},
      {'title':('Pulp Fiction: Tempo de Violência'), ('poster_path'):(''), ('year'):('1994'), ('score'):('8.9'),('genre'):('Crime')},
      {'title':('Interestelar'),('poster_path'):(''), ('year'):('2014'), ('score'):('8.7'),('genre'):('Ficção Científica')},
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

