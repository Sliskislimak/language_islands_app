import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_islands_app/core/models/sentence_collection.dart';
import 'package:language_islands_app/features/collections/providers/collections_controller.dart';
import 'package:language_islands_app/main.dart';

class _EmptyCollectionsController extends CollectionsController {
  @override
  Future<List<SentenceCollection>> build() async => [];
}

void main() {
  testWidgets('Shows empty collections state', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          collectionsControllerProvider.overrideWith(
            _EmptyCollectionsController.new,
          ),
        ],
        child: const LanguageIslandsApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Brak kolekcji'), findsOneWidget);
    expect(find.text('Language Islands'), findsOneWidget);
  });
}
