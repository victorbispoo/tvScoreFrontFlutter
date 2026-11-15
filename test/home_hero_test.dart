import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_score_front_flutter/pages/details_page.dart';
import 'package:tv_score_front_flutter/pages/home_page.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';
import 'package:tv_score_front_flutter/widgets/content_card.dart';
import 'package:tv_score_front_flutter/widgets/content_carousel.dart';
import 'package:tv_score_front_flutter/widgets/poster_hero_tag.dart';
import 'package:tv_score_front_flutter/widgets/ranked_content_carousel.dart';

import 'support/backend_http.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const movie = {
    'id': '42',
    'type': 'MOVIE',
    'title': 'Filme repetido',
    'poster_path': '',
  };

  testWidgets('mesmo conteúdo em seções diferentes recebe tags únicas', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              ContentCarousel(
                title: 'Para você',
                contents: const [movie],
                heroSection: 'personalized',
                onChanged: () {},
              ),
              ContentCarousel(
                title: 'Drama',
                contents: const [movie],
                heroSection: 'genre:drama',
                onChanged: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    final tags = tester
        .widgetList<Hero>(find.byType(Hero))
        .map((hero) => hero.tag)
        .toList();
    expect(tags, hasLength(2));
    expect(tags.toSet(), hasLength(2));
    expect(posterHeroTag('home:personalized', movie), tags.first);
  });

  testWidgets('Home leva pôster de filme aos Detalhes e devolve ao voltar', (
    tester,
  ) async {
    final backend = BackendHttp();
    final previous = HttpOverrides.current;
    HttpOverrides.global = backend;
    addTearDown(() => HttpOverrides.global = previous);
    ApiService.token = 'test-token';
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HomePage())),
    );
    await tester.pumpAndSettle();
    final card = find.byType(ContentCard).first;
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    final source = tester.widget<ContentCard>(card);
    expect(source.content['type'], 'MOVIE');
    expect(source.heroTag, isNotNull);
    await tester.tap(card);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(
      tester.widget<DetailsPage>(find.byType(DetailsPage)).heroTag,
      source.heroTag,
    );
    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(HomePage), findsOneWidget);
    expect(
      tester.widget<ContentCard>(find.byType(ContentCard).first).heroTag,
      source.heroTag,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('carrossel ranqueado passa a tag do pôster aos Detalhes', (
    tester,
  ) async {
    final backend = BackendHttp();
    final previous = HttpOverrides.current;
    HttpOverrides.global = backend;
    addTearDown(() => HttpOverrides.global = previous);
    ApiService.token = 'test-token';
    final tag = posterHeroTag('home:top-rated', movie);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RankedContentCarousel(
            contents: const [movie],
            heroSection: 'top-rated',
            onChanged: () {},
          ),
        ),
      ),
    );
    expect(tester.widget<Hero>(find.byType(Hero)).tag, tag);
    await tester.tap(find.text('Filme repetido'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(tester.widget<DetailsPage>(find.byType(DetailsPage)).heroTag, tag);
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(tester.takeException(), isNull);
  });

  testWidgets('retorno é seguro se o pôster de origem sair da árvore', (
    tester,
  ) async {
    final backend = BackendHttp();
    final previous = HttpOverrides.current;
    HttpOverrides.global = backend;
    addTearDown(() => HttpOverrides.global = previous);
    ApiService.token = 'test-token';
    final visible = ValueNotifier(true);
    addTearDown(visible.dispose);
    final tag = posterHeroTag('home:personalized', movie);
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<bool>(
          valueListenable: visible,
          builder: (context, show, _) => Scaffold(
            body: show
                ? SizedBox(
                    width: 144,
                    height: 300,
                    child: ContentCard(content: movie, heroTag: tag),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(ContentCard));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    visible.value = false;
    await tester.pump();
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(ContentCard), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('série no carrossel usa Hero e outras telas não recebem tag', (
    tester,
  ) async {
    final backend = BackendHttp();
    final previous = HttpOverrides.current;
    HttpOverrides.global = backend;
    addTearDown(() => HttpOverrides.global = previous);
    ApiService.token = 'test-token';
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HomePage())),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Séries').first);
    await tester.pumpAndSettle();
    final card = find.byType(ContentCard).first;
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    final source = tester.widget<ContentCard>(card);
    expect(source.content['type'], 'TV');
    await tester.tap(card);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(
      tester.widget<DetailsPage>(find.byType(DetailsPage)).heroTag,
      source.heroTag,
    );
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 144,
            height: 300,
            child: ContentCard(content: movie),
          ),
        ),
      ),
    );
    expect(find.byType(Hero), findsNothing);
  });
}
