// Catálogo de demonstração usado enquanto o backend está indisponível.
const mockMovies = <Map<String, String>>[
  {
    'id': 'mock-avatar-2',
    'backdrop_path':
        'https://image.tmdb.org/t/p/w780/s16H6tpK2utvwDtzZ8Qy4qm5Emw.jpg',
    'title': 'Avatar: O Caminho da Água',
    'overview':
        'Jake e Neytiri buscam abrigo com um povo dos oceanos de Pandora e precisam proteger sua família de uma nova ameaça.',
    'year': '2022',
    'score': '7.6',
    'poster_path':
        'https://image.tmdb.org/t/p/w500/t6HIqrRAclMCA60NsSmeqe9RmNV.jpg',
    'genre_ids': '878 | 12',
    'genre': 'Ficção Científica • Aventura',
    'type': 'movie',
  },
  {
    'id': 'mock-interstellar',
    'backdrop_path':
        'https://image.tmdb.org/t/p/w780/xJHokMbljvjADYdit5fK5VQsXEG.jpg',
    'title': 'Interestelar',
    'overview':
        'Uma equipe de exploradores atravessa um buraco de minhoca em busca de um novo lar para a humanidade.',
    'year': '2014',
    'score': '8.7',
    'poster_path':
        'https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg',
    'genre_ids': '878 | 18',
    'genre': 'Ficção Científica • Drama',
    'type': 'movie',
  },
  {
    'id': 'mock-inception',
    'backdrop_path':
        'https://image.tmdb.org/t/p/w780/s3TBrRGB1iav7gFOCNx3H31MoES.jpg',
    'title': 'A Origem',
    'overview':
        'Um especialista em invadir sonhos recebe a missão de implantar uma ideia na mente de um herdeiro.',
    'year': '2010',
    'score': '8.4',
    'poster_path':
        'https://image.tmdb.org/t/p/w500/oYuLEt3zVCKq57qu2F8dT7NIa6f.jpg',
    'genre_ids': '28 | 878',
    'genre': 'Ação • Ficção Científica',
    'type': 'movie',
  },
  {
    'id': 'mock-dark-knight',
    'backdrop_path':
        'https://image.tmdb.org/t/p/w780/pbEkjhdfP7yuDcMB78YEZwgD4IN.jpg',
    'title': 'Batman: O Cavaleiro das Trevas',
    'overview':
        'Batman enfrenta o Coringa enquanto Gotham vive uma onda de caos que coloca seus heróis à prova.',
    'year': '2008',
    'score': '9.0',
    'poster_path':
        'https://image.tmdb.org/t/p/w500/qJ2tW6WMUDux911r6m7haRef0WH.jpg',
    'genre_ids': '28 | 18',
    'genre': 'Ação • Drama',
    'type': 'movie',
  },
  {
    'id': 'mock-dune-2',
    'backdrop_path':
        'https://image.tmdb.org/t/p/w780/o869RihWTdTyBcEZBjz0izvEsVf.jpg',
    'title': 'Duna: Parte Dois',
    'overview':
        'Paul Atreides se une aos Fremen e precisa escolher entre seu amor e o destino de um império.',
    'year': '2024',
    'score': '8.2',
    'poster_path':
        'https://image.tmdb.org/t/p/w500/1pdfLvkbY9ohJlCjQH2CZjjYVvJ.jpg',
    'genre_ids': '878 | 12',
    'genre': 'Ficção Científica • Aventura',
    'type': 'movie',
  },
  {
    'id': 'mock-stranger-things',
    'backdrop_path':
        'https://image.tmdb.org/t/p/w780/56v2KjBlU4XaOv9rVYEQypROD7P.jpg',
    'title': 'Stranger Things',
    'overview':
        'Um grupo de amigos investiga o desaparecimento de um garoto e descobre experiências secretas e um mundo assustador.',
    'year': '2016',
    'score': '8.6',
    'poster_path':
        'https://image.tmdb.org/t/p/w500/49WJfeN0moxb9IPfGn8AIqMGskD.jpg',
    'genre_ids': '878 | 9648',
    'genre': 'Ficção Científica • Mistério',
    'type': 'series',
  },
  {
    'id': 'mock-breaking-bad',
    'backdrop_path':
        'https://image.tmdb.org/t/p/w780/tsRy63Mu5cu8etL1X7ZLyf7UP1M.jpg',
    'title': 'Breaking Bad',
    'overview':
        'Um professor de química toma decisões cada vez mais perigosas ao entrar no mundo do crime.',
    'year': '2008',
    'score': '9.5',
    'poster_path':
        'https://image.tmdb.org/t/p/w500/3xnWaLQjelJDDF7LT1WBo6f4BRe.jpg',
    'genre_ids': '18 | 80',
    'genre': 'Drama • Crime',
    'type': 'series',
  },
  {
    'id': 'mock-last-of-us',
    'backdrop_path':
        'https://image.tmdb.org/t/p/w780/uDgy6hyPd82kOHh6I95FLtLnj6p.jpg',
    'title': 'The Last of Us',
    'overview':
        'Um sobrevivente e uma adolescente atravessam um país devastado e criam uma ligação que muda suas vidas.',
    'year': '2023',
    'score': '8.7',
    'poster_path':
        'https://image.tmdb.org/t/p/w500/uKvVjHNqB5VmOrdxqAt2F7J78ED.jpg',
    'genre_ids': '18 | 28',
    'genre': 'Drama • Ação',
    'type': 'series',
  },
  {
    'id': 'mock-dark',
    'backdrop_path':
        'https://image.tmdb.org/t/p/w780/75HgaphatW0PDI3XIHQWZUpbhn6.jpg',
    'title': 'Dark',
    'overview':
        'O desaparecimento de duas crianças revela segredos de quatro famílias e uma ligação entre diferentes épocas em uma pequena cidade.',
    'year': '2017',
    'score': '8.7',
    'poster_path':
        'https://image.tmdb.org/t/p/w500/apbrbWs8M9lyOpJYU5WXrpFbk1Z.jpg',
    'genre_ids': '878 | 9648',
    'genre': 'Ficção Científica • Mistério',
    'type': 'series',
  },
  {
    'id': 'mock-game-of-thrones',
    'backdrop_path':
        'https://image.tmdb.org/t/p/w780/suopoADq0k8YZr4dQXcU6pToj6s.jpg',
    'title': 'Game of Thrones',
    'overview':
        'Famílias rivais disputam o controle dos Sete Reinos enquanto uma antiga ameaça desperta além da Muralha.',
    'year': '2011',
    'score': '9.2',
    'poster_path':
        'https://image.tmdb.org/t/p/w500/1XS1oqL89opfnbLl8WnZY1O1uJx.jpg',
    'genre_ids': '14 | 18',
    'genre': 'Fantasia • Drama',
    'type': 'series',
  },
  {
    'id': 'mock-the-office',
    'backdrop_path':
        'https://image.tmdb.org/t/p/w780/vNpuAxGTl9HsUbHqam3E9CzqCvX.jpg',
    'title': 'The Office',
    'overview':
        'Uma equipe de documentário acompanha as situações absurdas e os relacionamentos dos funcionários de uma empresa de papel.',
    'year': '2005',
    'score': '9.0',
    'poster_path':
        'https://image.tmdb.org/t/p/w500/7DJKHzAi83BmQrWLrYYOqcoKfhR.jpg',
    'genre_ids': '35',
    'genre': 'Comédia',
    'type': 'series',
  },
  {
    'id': 'mock-the-mandalorian',
    'backdrop_path':
        'https://image.tmdb.org/t/p/w780/9ijMGlJKqcslswWUzTEwScm82Gs.jpg',
    'title': 'The Mandalorian',
    'overview':
        'Um caçador de recompensas atravessa os confins da galáxia para proteger uma criança misteriosa de antigos inimigos.',
    'year': '2019',
    'score': '8.5',
    'poster_path':
        'https://image.tmdb.org/t/p/w500/sWgBv7LV2PRoQgkxwlibdGXKz1S.jpg',
    'genre_ids': '28 | 878',
    'genre': 'Ação • Ficção Científica',
    'type': 'series',
  },
];
