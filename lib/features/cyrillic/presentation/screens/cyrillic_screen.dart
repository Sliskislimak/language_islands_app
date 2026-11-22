import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:language_islands_app/core/providers/app_providers.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';
import 'package:language_islands_app/data/datasets/cyrillic_data.dart';

class CyrillicScreen extends ConsumerStatefulWidget {
  const CyrillicScreen({super.key});

  @override
  ConsumerState<CyrillicScreen> createState() => _CyrillicScreenState();
}

class _CyrillicScreenState extends ConsumerState<CyrillicScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text(
          'Cyrylica · Азбука',
          style: TextStyle(color: AppTheme.textLight, fontSize: 18),
        ),
        backgroundColor: AppTheme.bgDark,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppTheme.sakuraPrimary,
          labelColor: AppTheme.sakuraPrimary,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(text: 'Alfabet (33)'),
            Tab(text: 'Samogłoski (10)'),
            Tab(text: 'Spółgłoski (21)'),
            Tab(text: 'Znaki (2)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGrid(CyrillicData.allLetters, crossAxisCount: 4),
          _buildGrid(CyrillicData.vowels, crossAxisCount: 4),
          _buildGrid(CyrillicData.consonants, crossAxisCount: 4),
          _buildGrid(CyrillicData.signs, crossAxisCount: 2),
        ],
      ),
    );
  }

  Widget _buildGrid(List<CyrillicItem> items, {required int crossAxisCount}) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: crossAxisCount == 2 ? 1.4 : 0.95,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _CyrillicTile(
          item: item,
          onTap: () => _showLetterDetails(item),
        );
      },
    );
  }

  void _showLetterDetails(CyrillicItem item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CyrillicDetailsSheet(item: item),
    );
  }
}

class _CyrillicTile extends StatelessWidget {
  const _CyrillicTile({required this.item, required this.onTap});

  final CyrillicItem item;
  final VoidCallback onTap;

  Color _accentColorForGroup(CyrillicGroup group) {
    return switch (group) {
      CyrillicGroup.vowel => AppTheme.sakuraPrimary,
      CyrillicGroup.consonant => AppTheme.textLight,
      CyrillicGroup.sign => AppTheme.yellowPrompt,
    };
  }

  @override
  Widget build(BuildContext context) {
    final letterColor = _accentColorForGroup(item.group);

    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.surfaceBorder),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.displayPair,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: letterColor,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.transliteration,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CyrillicDetailsSheet extends ConsumerStatefulWidget {
  const _CyrillicDetailsSheet({required this.item});

  final CyrillicItem item;

  @override
  ConsumerState<_CyrillicDetailsSheet> createState() =>
      _CyrillicDetailsSheetState();
}

class _CyrillicDetailsSheetState extends ConsumerState<_CyrillicDetailsSheet> {
  bool _isPlayingLetter = false;
  bool _isPlayingExample = false;

  Future<void> _playAudio({
    required String text,
    required String cacheKey,
    required bool isExample,
  }) async {
    setState(() {
      if (isExample) {
        _isPlayingExample = true;
      } else {
        _isPlayingLetter = true;
      }
    });

    try {
      final tts = ref.read(azureTtsServiceProvider);
      final playerService = ref.read(audioPlaybackServiceProvider);
      final audioPath = await tts.synthesizeRussianText(text, key: cacheKey);
      if (audioPath != null) {
        await playerService.player.setFilePath(audioPath);
        await playerService.player.play();
      }
    } catch (_) {
      // Audio playback is best effort
    } finally {
      if (mounted) {
        setState(() {
          if (isExample) {
            _isPlayingExample = false;
          } else {
            _isPlayingLetter = false;
          }
        });
      }
    }
  }

  String _groupLabel(CyrillicGroup group) {
    return switch (group) {
      CyrillicGroup.vowel => 'Samogłoska',
      CyrillicGroup.consonant => 'Spółgłoska',
      CyrillicGroup.sign => 'Znak specjalny',
    };
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isBusy = _isPlayingLetter || _isPlayingExample;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              item.displayPair,
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: AppTheme.sakuraPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Wymowa: /${item.transliteration}/ · ${_groupLabel(item.group)}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Nazwa litery: «${item.letterName}»',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
              ),
            ),
            if (item.note != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.yellowPrompt.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.yellowPrompt.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 16,
                      color: AppTheme.yellowPrompt,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.note!,
                        style: const TextStyle(
                          color: AppTheme.textLight,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.bgDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Przykład w słowie:',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.exampleFormatted,
                    style: const TextStyle(
                      color: AppTheme.textLight,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.sakuraPrimary,
                      foregroundColor: AppTheme.bgDark,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: isBusy
                        ? null
                        : () => _playAudio(
                              text: item.ttsText,
                              cacheKey: 'cyrillic_letter_${item.uppercase.codeUnitAt(0)}',
                              isExample: false,
                            ),
                    icon: _isPlayingLetter
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.bgDark,
                            ),
                          )
                        : const Icon(Icons.volume_up_rounded),
                    label: const Text(
                      'Odsłuchaj literę',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.sakuraPrimary,
                      side: const BorderSide(color: AppTheme.sakuraPrimary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: isBusy
                        ? null
                        : () => _playAudio(
                              text: item.exampleWord,
                              cacheKey: 'cyrillic_word_${item.uppercase.codeUnitAt(0)}',
                              isExample: true,
                            ),
                    icon: _isPlayingExample
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.sakuraPrimary,
                            ),
                          )
                        : const Icon(Icons.record_voice_over_rounded),
                    label: const Text(
                      'Przykład',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
