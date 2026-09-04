/// Ponto único para substituir os dados de exemplo por chamadas HTTP.
class ApiService {
  Future<List<Map<String, String>>> getHighlights() async {
    return const [
      {'title': 'Oppenheimer', 'year': '2023', 'score': '8.9'},
      {'title': 'The Last of Us', 'year': '2023', 'score': '7.9'},
      {'title': 'Interestelar', 'year': '2014', 'score': '8.7'},
    ];
  }

  Future<void> login(String email, String password) async {}
}
