import 'package:flutter/material.dart';

import '../services/api_services.dart';
import '../widgets/movie_card.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LegacyHomePage extends StatefulWidget {
  const LegacyHomePage({super.key});

  @override
  State<LegacyHomePage> createState() => _HomePageState();
}

class _HomePageState extends State<LegacyHomePage>
    with AutomaticKeepAliveClientMixin {
  late final Future<List<Map<String, String>>> _highlightsFuture;

  @override
  void initState() {
    super.initState();
    _highlightsFuture = ApiService().getHighlights();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<Map<String, String>>>(
      future: _highlightsFuture,
      builder: (context, snapshot) {
        final movies = snapshot.data ?? const <Map<String, String>>[];
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 60),
            Align(
              alignment: Alignment.centerLeft,
              child: SvgPicture.asset(
                'lib/assets/logoTvScore.svg',
                width: 120,
                height: 120,
              ),
            ),

            const SizedBox(height: 10),
            const Text(
              'Tenha acesso a avaliações dos melhores filmes e séries.',
              style: TextStyle(color: Colors.white70, fontSize: 20),
            ),
            const SizedBox(height: 28),
            Text.rich(
              TextSpan(
                children: [
                  WidgetSpan(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedRanking,
                      size: 28,
                      color: Colors.amber,
                    ),
                  ),
                  TextSpan(
                    text: ' Destaques',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // GridView.builder(
            //   shrinkWrap: true,
            //   physics: const NeverScrollableScrollPhysics(),
            //   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            //     crossAxisCount: 2,
            //     crossAxisSpacing: 12,
            //     mainAxisSpacing: 16,
            //     childAspectRatio: 0.60,
            //   ),
            //   itemCount: movies.length,
            //   itemBuilder: (_, i) => MovieCard(movie: movies[i]),
            // ),
            SizedBox(
              height:270,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: movies.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (_, i) => SizedBox(
                  width: 160,
                  child: MovieCard(movie: movies[i]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class HomePage extends LegacyHomePage {
  const HomePage({super.key});
}
