import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_score_front_flutter/core/rating_scale.dart';
import 'package:tv_score_front_flutter/widgets/review_form.dart';

void main() {
  testWidgets('seletor altera faixa em meio ponto e respeita limites', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var rating = 9.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SingleChildScrollView(
              child: ReviewForm(
                isEditing: false,
                rating: rating,
                commentController: controller,
                enabled: true,
                isSaving: false,
                onRatingChanged: (value) => setState(() => rating = value),
                onSave: () {},
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Excepcional'), findsOneWidget);
    await tester.tap(find.byTooltip('Aumentar nota'));
    await tester.pump();
    expect(rating, 9.5);
    await tester.pumpAndSettle();
    expect(find.text('Obra-prima'), findsOneWidget);
    expect(
      DefaultTextStyle.of(tester.element(find.text('9.5'))).style.color,
      RatingScale.color(9.5),
    );
    await tester.tap(find.byTooltip('Aumentar nota'));
    await tester.pump();
    expect(rating, 10.0);
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (w) => w is IconButton && w.tooltip == 'Aumentar nota',
            ),
          )
          .onPressed,
      isNull,
    );
    for (var i = 0; i < 20; i++) {
      await tester.tap(find.byTooltip('Diminuir nota'));
      await tester.pump();
    }
    expect(rating, 0.0);
    expect(find.text('Horrível'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (w) => w is IconButton && w.tooltip == 'Diminuir nota',
            ),
          )
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
}
