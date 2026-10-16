import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:language_islands_app/core/providers/app_providers.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';
import 'package:language_islands_app/data/datasets/hiragana_data.dart';

class HiraganaScreen extends ConsumerStatefulWidget {
  const HiraganaScreen({super.key});

  @override
  ConsumerState<HiraganaScreen> createState() => _HiraganaScreenState();
}

class _HiraganaScreenState extends ConsumerState<HiraganaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
          'Hiragana · ひらがな',
          style: TextStyle(color: AppTheme.textLight, fontSize: 18),
        ),
        backgroundColor: AppTheme.bgDark,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.sakuraPrimary,
          labelColor: AppTheme.sakuraPrimary,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(text: 'Podstawowe (46)'),
            Tab(text: 'Dźwięczne (25)'),
            Tab(text: 'Złożone (33)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildKanaGrid(HiraganaData.seionList, crossAxisCount: 5),
          _buildKanaGrid(HiraganaData.dakuonList, crossAxisCount: 5),
          _buildKanaGrid(HiraganaData.yoonList, crossAxisCount: 3),
        ],
      ),
    );
  }

  Widget _buildKanaGrid(List<KanaItem> items, {required int crossAxisCount}) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: crossAxisCount == 3 ? 1.4 : 0.95,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _KanaTile(
          item: item,
          onTap: () => _showKanaDetails(item),
        );
      },
    );
  }

  void _showKanaDetails(KanaItem item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _KanaDetailsSheet(item: item),
    );
  }
}

class _KanaTile extends StatelessWidget {
  const _KanaTile({required this.item, required this.onTap});

  final KanaItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
              Text(
                item.kana,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.sakuraPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.romaji,
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

class _KanaDetailsSheet extends ConsumerStatefulWidget {
  const _KanaDetailsSheet({required this.item});

  final KanaItem item;

  @override
  ConsumerState<_KanaDetailsSheet> createState() => _KanaDetailsSheetState();
}

class _KanaDetailsSheetState extends ConsumerState<_KanaDetailsSheet> {
  bool _isPlaying = false;

  Future<void> _playAudio() async {
    setState(() => _isPlaying = true);
    try {
      final tts = ref.read(azureTtsServiceProvider);
      final playerService = ref.read(audioPlaybackServiceProvider);
      final audioPath = await tts.synthesizeJapaneseText(
        widget.item.kana,
        key: 'kana_${widget.item.romaji}',
      );
      if (audioPath != null) {
        await playerService.player.setFilePath(audioPath);
        await playerService.player.play();
      }
    } catch (_) {
      // Audio playback is best effort
    } finally {
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 18),
            Text(
              widget.item.kana,
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: AppTheme.sakuraPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Romaji: /${widget.item.romaji}/',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 14),
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
                    widget.item.example,
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _isPlaying ? null : _playAudio,
                    icon: _isPlaying
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.bgDark),
                          )
                        : const Icon(Icons.volume_up_rounded),
                    label: const Text('Odsłuchaj wymowę', style: TextStyle(fontWeight: FontWeight.bold)),
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
