/// Ponto único para substituir os dados de exemplo por chamadas HTTP.
class ApiService {
  Future<List<Map<String, String>>> getHighlights() async {
    return const [
      {'title': 'Oppenheimer', 'year': '2023', 'score': '8.9','genre':'Ação'},
      {'title': 'Barbie', 'year': '2023', 'score': '7.3','genre':'Comédia'},
      {'title': 'Avatar: O Caminho da Água', 'year': '2022', 'score': '7.8','genre':'Aventura'},
      {'title': 'Homem-Aranha: Através do Aranhaverso', 'year': '2023', 'score': '8.9','genre':'Animação'},
      {'title': 'Duna: Parte Dois', 'year': '2023', 'score': '8.1','genre':'Ficção Científica'},
      {'title': 'Missão: Impossível - Efeito Fallout', 'year': '2018', 'score': '7.7','genre':'Ação'},
      {'title': 'Top Gun: Maverick', 'year': '2022', 'score': '8.4','genre':'Ação'},
      {'title': 'Vingadores: Ultimato', 'year': '2019', 'score': '8.4','genre':'Ação'},
      {'title': 'O Poderoso Chefão', 'year': '1972', 'score': '9.2','genre':'Crime'},
      {'title': 'Pulp Fiction: Tempo de Violência', 'year': '1994', 'score': '8.9','genre':'Crime'},
      {'title': 'The Last of Us', 'year': '2023', 'score': '7.9','genre':'Aventura'},
      {'title': 'Interestelar', 'year': '2014', 'score': '8.7','genre':'Ficção Científica'},
    ];
  }

  Future<void> login(String email, String password) async {}
}
