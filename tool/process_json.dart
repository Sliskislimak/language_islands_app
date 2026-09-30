// ignore_for_file: avoid_print
import 'dart:io';
import 'package:language_islands_app/core/models/sentence.dart';
import 'package:language_islands_app/core/models/sentence_collection.dart';
import 'package:language_islands_app/core/services/visual_cue_detector.dart';

void main(List<String> args) {
  final targetPath = args.isNotEmpty
      ? args.first
      : 'collections/particles_and_pronouns_n5.json';

  final file = File(targetPath);
  if (!file.existsSync()) {
    stderr.writeln('Błąd: Plik nie istnieje: $targetPath');
    exit(1);
  }

  final raw = file.readAsStringSync();
  final collection = SentenceCollection.fromJsonString(raw);

  print('Kolekcja: ${collection.id} - ${collection.title}');
  print('Liczba zdań: ${collection.sentences.length}');

  int detectedCount = 0;
  final updatedSentences = <Sentence>[];

  for (final s in collection.sentences) {
    final cues = VisualCueDetector.detectEmojis(
      targetText: s.targetText,
      sourceText: s.sourceText,
      phoneticReading: s.phoneticReading,
      katakana: s.katakana,
    );

    final combinedEmojis = <String>[...s.emojis];
    for (final cue in cues) {
      if (!combinedEmojis.contains(cue)) {
        combinedEmojis.add(cue);
      }
    }

    if (combinedEmojis.isNotEmpty) {
      detectedCount++;
    }

    updatedSentences.add(s.copyWith(emojis: combinedEmojis));
  }

  print('Zaktualizowano zdań z emotkami: $detectedCount / ${collection.sentences.length}');

  final updatedCollection = collection.copyWith(sentences: updatedSentences);
  file.writeAsStringSync(updatedCollection.toJsonString(pretty: true));
  print('Zapisano zaktualizowaną kolekcję do: $targetPath');
}
