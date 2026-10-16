import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:language_islands_app/core/models/kanji_entry.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';
import 'package:language_islands_app/features/kanji/providers/kanji_controller.dart';

class KanjiStudySessionScreen extends ConsumerStatefulWidget {
  const KanjiStudySessionScreen({super.key, required this.studyCards});

  final List<KanjiEntry> studyCards;

  @override
  ConsumerState<KanjiStudySessionScreen> createState() => _KanjiStudySessionScreenState();
}

class _KanjiStudySessionScreenState extends ConsumerState<KanjiStudySessionScreen>
    with SingleTickerProviderStateMixin {
  late List<KanjiEntry> _cards;
  int _currentIndex = 0;
  bool _isFlipped = false;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  int _completedReviews = 0;
  bool _isSessionFinished = false;

  @override
  void initState() {
    super.initState();
    _cards = List<KanjiEntry>.from(widget.studyCards);
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  void _nextCard() {
    if (_currentIndex < _cards.length - 1) {
      if (_isFlipped) {
        _flipController.reverse();
        _isFlipped = false;
      }
      setState(() {
        _currentIndex++;
      });
    } else {
      setState(() {
        _isSessionFinished = true;
      });
    }
  }

  void _prevCard() {
    if (_currentIndex > 0) {
      if (_isFlipped) {
        _flipController.reverse();
        _isFlipped = false;
      }
      setState(() {
        _currentIndex--;
      });
    }
  }

  Future<void> _rateCard(int score) async {
    final currentCard = _cards[_currentIndex];
    await ref.read(kanjiControllerProvider.notifier).updateMastery(currentCard.kanji, score);
    _completedReviews++;

    // Zaktualizuj stan lokalnej karty
    _cards[_currentIndex] = currentCard.copyWith(
      masteryScore: score,
      totalReps: currentCard.totalReps + 1,
    );

    _nextCard();
  }

  @override
  Widget build(BuildContext context) {
    if (_cards.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.bgDark,
        appBar: AppBar(title: const Text('Nauka Kanji')),
        body: const Center(
          child: Text(
            'Brak kart do nauki.',
            style: TextStyle(color: AppTheme.textMuted),
          ),
        ),
      );
    }

    if (_isSessionFinished) {
      return _buildFinishedScreen();
    }

    final card = _cards[_currentIndex];
    final progress = (_currentIndex + 1) / _cards.length;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text(
          'Karta ${_currentIndex + 1} z ${_cards.length}',
          style: const TextStyle(color: AppTheme.textLight, fontSize: 16),
        ),
        backgroundColor: AppTheme.bgDark,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.surfaceBorder,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.sakuraPrimary),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Karta z animacją obrotu
              Expanded(
                child: GestureDetector(
                  onTap: _toggleFlip,
                  child: AnimatedBuilder(
                    animation: _flipAnimation,
                    builder: (context, child) {
                      final angle = _flipAnimation.value * math.pi;
                      final isUnder = _flipAnimation.value >= 0.5;

                      return Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(angle),
                        alignment: Alignment.center,
                        child: isUnder
                            ? Transform(
                                transform: Matrix4.identity()..rotateY(math.pi),
                                alignment: Alignment.center,
                                child: _buildBack(card),
                              )
                            : _buildFront(card),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Pasek oceny (jeśli karta jest odwrócona lub widoczna)
              _buildRatingBar(card),
              const SizedBox(height: 12),

              // Pasek nawigacji: Poprzednia, Odwróć, Następna
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton.filledTonal(
                    onPressed: _currentIndex > 0 ? _prevCard : null,
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: 'Poprzednia karta',
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.sakuraPrimary,
                      side: const BorderSide(color: AppTheme.sakuraPrimary),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: _toggleFlip,
                    icon: Icon(_isFlipped ? Icons.flip_to_front_rounded : Icons.flip_to_back_rounded),
                    label: Text(_isFlipped ? 'Pokaż przód' : 'Odwróć kartę'),
                  ),
                  IconButton.filledTonal(
                    onPressed: _nextCard,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    tooltip: 'Następna karta',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // PRZÓD FISZKI (Kanji)
  Widget _buildFront(KanjiEntry card) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.bgDark,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'JLPT ${card.jlptLevel}',
                  style: const TextStyle(
                    color: AppTheme.sakuraPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              if (card.strokeCount != null)
                Text(
                  '${card.strokeCount} kresek',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
            ],
          ),
          const Spacer(),
          Text(
            card.kanji,
            style: const TextStyle(
              fontSize: 104,
              fontWeight: FontWeight.bold,
              color: AppTheme.sakuraPrimary,
              height: 1.1,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.bgDark,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app_rounded, size: 16, color: AppTheme.yellowPrompt),
                SizedBox(width: 8),
                Text(
                  'Dotknij karty, aby sprawdzić odpowiedź',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TYŁ FISZKI (Odpowiedź)
  Widget _buildBack(KanjiEntry card) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.sakuraPrimary.withValues(alpha: 0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Górny mały znak Kanji i znaczenia
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.bgDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  card.kanji,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.sakuraPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.meaningsDisplay,
                      style: const TextStyle(
                        color: AppTheme.textLight,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'JLPT ${card.jlptLevel} · ${card.strokeCount ?? '?'} kresek',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.surfaceBorder),
          const SizedBox(height: 6),

          // Czytania
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _readingChip(
                    title: "On'yomi (音読み):",
                    reading: card.onyomiDisplay,
                    color: AppTheme.sakuraAccent,
                  ),
                  const SizedBox(height: 8),
                  _readingChip(
                    title: "Kun'yomi (訓読み):",
                    reading: card.kunyomiDisplay,
                    color: AppTheme.yellowPrompt,
                  ),
                  const SizedBox(height: 14),

                  if (card.examples.isNotEmpty) ...[
                    const Text(
                      'Przykładowe słówka:',
                      style: TextStyle(
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final ex in card.examples)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.bgDark,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.surfaceBorder),
                        ),
                        child: Row(
                          children: [
                            Text(
                              ex.word,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.sakuraPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              ex.reading,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                            const Spacer(),
                            Text(
                              ex.meaning,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _readingChip({
    required String title,
    required String reading,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.bgDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(
            reading,
            style: const TextStyle(fontSize: 14, color: AppTheme.textLight, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // PASEK OCENY (1-5 GWIAZDEK)
  Widget _buildRatingBar(KanjiEntry card) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        children: [
          const Text(
            'Jak dobrze pamiętasz ten znak?',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (int star = 1; star <= 5; star++)
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _rateCard(star),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Column(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 30,
                          color: star <= card.masteryScore
                              ? (card.masteryScore == 5
                                  ? AppTheme.greenMatcha
                                  : AppTheme.yellowPrompt)
                              : AppTheme.textMuted.withValues(alpha: 0.4),
                        ),
                        Text(
                          '$star★',
                          style: TextStyle(
                            fontSize: 10,
                            color: star <= card.masteryScore
                                ? AppTheme.textLight
                                : AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinishedScreen() {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 72,
                color: AppTheme.greenMatcha,
              ),
              const SizedBox(height: 16),
              const Text(
                'Sesja ukończona! 🎉',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Przejrzano $_completedReviews powtórek kart.',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 15),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textLight,
                      side: const BorderSide(color: AppTheme.surfaceBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: () {
                      setState(() {
                        _currentIndex = 0;
                        _isFlipped = false;
                        _isSessionFinished = false;
                        _completedReviews = 0;
                      });
                    },
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('Powtórz jeszcze raz'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.sakuraPrimary,
                      foregroundColor: AppTheme.bgDark,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Wróć do listy', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
