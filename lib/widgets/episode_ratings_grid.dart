import 'package:flutter/material.dart';

class EpisodeRatingsGrid extends StatelessWidget {
  const EpisodeRatingsGrid({super.key});

    static const _ratings = <List<double?>>[
    [8.2, 9.1, 7.4, 8.6, 9.3],
    [7.8, 8.5, 6.3, 9.0, 8.7],
    [9.2, 8.0, 5.8, 7.6, 4.2],
    [8.6, 9.4, 7.2, 2.0, null],
  ];

Color _ratingColor(double? rating) {
  if (rating == null) return const Color(0xFF64748B);

  if (rating >= 9.0) return const Color(0xFF854DFF);
  if (rating >= 8.0) return const Color(0xFF008F83);
  if (rating >= 7.0) return const Color(0xFF638500);
  if (rating >= 6.0) return const Color.fromARGB(255, 126, 133, 0);
  if (rating >= 5.0) return const Color(0xFFB87500);
  if (rating >= 3.0) return const Color(0xFFE05224);

  return const Color(0xFFD52250);
}


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        const Text(
          'Notas dos episódios',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16,),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const FixedColumnWidth(64),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                children: [
                  const SizedBox(height: 36,),
                  for(var season =1; season <=5; season++)
                  Center(child: Text('T$season'),)
                ]
              ),
              for(var episode = 0; episode <_ratings.length; episode++)
              TableRow(
                children: [
                  Text('E${episode+1}',
                  style: const TextStyle(color: Colors.white60),
                  ),
                  for(var season = 0; season < 5; season++)
                  Container(
                    height: 44,
                    margin: const EdgeInsets.all(4),
                    alignment: .center,
                    decoration: BoxDecoration(
                      color: _ratingColor(_ratings[episode][season]),
                      borderRadius: .circular(8),
                    ),
                    child: Text(
                      _ratings[episode][season]?.toStringAsFixed(1) ?? '-',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: .bold,
                      ),
                      semanticsLabel: 
                      'Temporada ${season + 1}, '
                      'episódio ${episode + 1}: '
                      '${_ratings[episode][season] ?? 'sem nota'}'
                    ),
                  )
                ]
              )
            ],
          ),
        ),
        const SizedBox(height: 10,),
        const Text(
          '9+ Excelente • 8+ Ótimo • 7+ Bom\n'
          '6+ Regular • Abaixo de 6 Baixo • Cinza: sem nota',
          style: TextStyle(fontSize: 12, color: Colors.white60),
        ),
      ],
    );
  }
}