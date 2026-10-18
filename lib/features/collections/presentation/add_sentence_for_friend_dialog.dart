import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:language_islands_app/core/models/remote_database_config.dart';
import 'package:language_islands_app/core/models/sentence.dart';
import 'package:language_islands_app/core/models/sentence_collection.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';
import 'package:language_islands_app/features/collections/providers/collections_controller.dart';
import 'package:language_islands_app/features/collections/providers/remote_sync_controller.dart';

Future<void> showAddSentenceForFriendDialog(
  BuildContext context, {
  String? defaultTargetLanguage,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AddSentenceForFriendDialog(
      defaultTargetLanguage: defaultTargetLanguage,
    ),
  );
}

class AddSentenceForFriendDialog extends ConsumerStatefulWidget {
  const AddSentenceForFriendDialog({
    super.key,
    this.defaultTargetLanguage,
  });

  final String? defaultTargetLanguage;

  @override
  ConsumerState<AddSentenceForFriendDialog> createState() =>
      _AddSentenceForFriendDialogState();
}

class _AddSentenceForFriendDialogState
    extends ConsumerState<AddSentenceForFriendDialog> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _targetTextController = TextEditingController();
  final _katakanaController = TextEditingController();
  final _romajiController = TextEditingController();
  final _sourceTextController = TextEditingController();
  final _notesController = TextEditingController();

  // Quick GitHub setup controllers (if needed)
  final _gistUrlController = TextEditingController();
  final _githubTokenController = TextEditingController();
  bool _showGitHubConfig = false;

  late String _currentLanguageMode; // 'ja' (Japanese for Jakub) or 'pl' (Polish for Friend)
  String? _selectedCollectionId;
  String _newCollectionTitle = '';
  bool _isCreatingNewCollection = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentLanguageMode =
        (widget.defaultTargetLanguage == 'pl') ? 'pl' : 'ja';

    final config = ref.read(remoteDatabaseConfigProvider).valueOrNull;
    if (config != null) {
      _gistUrlController.text = config.url;
      _githubTokenController.text = config.apiKey;
    }
  }

  @override
  void dispose() {
    _targetTextController.dispose();
    _katakanaController.dispose();
    _romajiController.dispose();
    _sourceTextController.dispose();
    _notesController.dispose();
    _gistUrlController.dispose();
    _githubTokenController.dispose();
    super.dispose();
  }

  bool get _isJapaneseMode => _currentLanguageMode == 'ja';

  Future<void> _handleSaveQuickGitHubConfig() async {
    final url = _gistUrlController.text.trim();
    final token = _githubTokenController.text.trim();

    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wprowadź adres URL Gista / Gist URLを入力してください')),
      );
      return;
    }

    try {
      await ref.read(remoteDatabaseConfigProvider.notifier).updateConfig(
            url: url,
            apiKey: token,
          );

      if (!mounted) return;
      setState(() {
        _showGitHubConfig = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Zapisano konfigurację GitHuba! / GitHub設定を保存しました'),
          backgroundColor: AppTheme.greenMatcha,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd zapisu / エラー: $e')),
      );
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final targetText = _targetTextController.text.trim();
    final katakana = _katakanaController.text.trim();
    final romaji = _romajiController.text.trim();
    final sourceText = _sourceTextController.text.trim();
    final notes = _notesController.text.trim();

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final sentenceId = 's_${DateTime.now().millisecondsSinceEpoch}';
    final sentence = Sentence(
      id: sentenceId,
      targetText: targetText,
      katakana: katakana.isNotEmpty ? katakana : null,
      phoneticReading: romaji.isNotEmpty ? romaji : null,
      sourceText: sourceText,
      notes: notes.isNotEmpty ? notes : null,
    );

    String collectionId = _selectedCollectionId ?? 'shared_friend_island';
    String collectionTitle = 'Wspólna lista zdań (Jakub & Koharu)';

    if (_isCreatingNewCollection && _newCollectionTitle.trim().isNotEmpty) {
      collectionId = 'col_${DateTime.now().millisecondsSinceEpoch}';
      collectionTitle = _newCollectionTitle.trim();
    }

    try {
      final result = await ref
          .read(remoteDatabaseConfigProvider.notifier)
          .addSentenceAndPush(
            sentence: sentence,
            collectionId: collectionId,
            collectionTitle: collectionTitle,
          );

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      if (result.success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppTheme.greenMatcha),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _isJapaneseMode
                        ? 'Zwrot wysłany i zapisany! 送信完了しました！'
                        : 'Nowe zdanie zostało dodane i wysłane!',
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.surfaceElevated,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() {
          _errorMessage = result.message;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Wystąpił nieoczekiwany błąd: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final collectionsAsync = ref.watch(collectionsControllerProvider);
    final remoteConfig = ref.watch(remoteDatabaseConfigProvider).valueOrNull;
    final isGistConfigured = remoteConfig != null &&
        remoteConfig.isGitHubGist &&
        remoteConfig.apiKey.isNotEmpty;

    final collections = collectionsAsync.valueOrNull ?? [];
    if (_selectedCollectionId == null && collections.isNotEmpty) {
      _selectedCollectionId = collections.first.id;
    }

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.surfaceBorder, width: 1.5),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header & Mode Toggle
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.surfaceBorder)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.sakuraPrimary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: AppTheme.sakuraPrimary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isJapaneseMode
                              ? 'Dla Jakuba / Jakubへフレーズを送る'
                              : 'Dla Koharu / こはるちゃんへポーランド語作成',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textLight,
                          ),
                        ),
                        Text(
                          _isJapaneseMode
                              ? 'Wpisz japoński zwrot i wyślij dla Jakuba 1 kliknięciem'
                              : 'Twórz zdania po polsku dla Koharu do wspólnej listy',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Scrollable Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Language Mode Switcher Pills
                      _buildLanguageSegmentedControl(),
                      const SizedBox(height: 14),

                      // GitHub Gist Status & Setup Card
                      _buildGitHubStatusCard(isGistConfigured, remoteConfig),
                      const SizedBox(height: 16),

                      // Collection Picker Dropdown
                      _buildCollectionPicker(collections),
                      const SizedBox(height: 16),

                      // Field 1: Target Sentence (Kanji/Hiragana or Polish)
                      _buildSectionLabel(
                        title: _isJapaneseMode
                            ? '1. 日本語（漢字・ひらがな）'
                            : '1. Zdanie po polsku (Polski)',
                        badge: _isJapaneseMode ? 'KANJI / KANA' : 'POLSKI',
                        badgeColor: AppTheme.sakuraPrimary,
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        key: const ValueKey('add_sentence_target_input'),
                        controller: _targetTextController,
                        maxLines: 2,
                        style: const TextStyle(color: AppTheme.textLight, fontSize: 15),
                        decoration: _inputDecoration(
                          hintText: _isJapaneseMode
                              ? '例: これ、すごく美味しいよ！'
                              : 'np. Cześć, jak minął Twój dzień?',
                          prefixIcon: Icons.edit_note_rounded,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return _isJapaneseMode
                                ? '日本語の文を入力してください (Wpisz zdanie)'
                                : 'Wprowadź zdanie po polsku';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Field 2: Katakana pronunciation
                      _buildSectionLabel(
                        title: _isJapaneseMode
                            ? '2. カタカナ読み (Wymowa w katakanie)'
                            : '2. カタカナ発音 (Katakana dla Japończyka)',
                        badge: 'KATAKANA',
                        badgeColor: const Color(0xFF64B5F6),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        key: const ValueKey('add_sentence_katakana_input'),
                        controller: _katakanaController,
                        style: const TextStyle(color: AppTheme.textLight, fontSize: 14),
                        decoration: _inputDecoration(
                          hintText: _isJapaneseMode
                              ? '例: コレ、スゴク オイシイ ヨ！'
                              : '例: チェシチ、ヤク ミノン トヴイ ジエン？',
                          prefixIcon: Icons.record_voice_over_outlined,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Field 3: Romaji / Latin pronunciation
                      _buildSectionLabel(
                        title: _isJapaneseMode
                            ? '3. ローマ字 (Rōmaji)'
                            : '3. Transkrypcja fonetyczna / Rōmaji',
                        badge: 'RŌMAJI',
                        badgeColor: const Color(0xFFFFB74D),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        key: const ValueKey('add_sentence_romaji_input'),
                        controller: _romajiController,
                        style: const TextStyle(color: AppTheme.textLight, fontSize: 14),
                        decoration: _inputDecoration(
                          hintText: _isJapaneseMode
                              ? '例: Kore, sugoku oishii yo!'
                              : 'np. Czeszć, jak minął twój dzień?',
                          prefixIcon: Icons.spellcheck_rounded,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Field 4: Translation (English / Polish or Japanese)
                      _buildSectionLabel(
                        title: _isJapaneseMode
                            ? '4. 英語・ポーランド語訳 (Znaczenie)'
                            : '4. 日本語・英語訳 (Tłumaczenie dla niej)',
                        badge: 'ZNACZENIE',
                        badgeColor: AppTheme.greenMatcha,
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        key: const ValueKey('add_sentence_source_input'),
                        controller: _sourceTextController,
                        maxLines: 2,
                        style: const TextStyle(color: AppTheme.textLight, fontSize: 14),
                        decoration: _inputDecoration(
                          hintText: _isJapaneseMode
                              ? '例: This is so delicious! / To jest przepyszne!'
                              : '例: こんにちは、今日はどんな一日だった？',
                          prefixIcon: Icons.translate_rounded,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return _isJapaneseMode
                                ? '意味や訳を入力してください (Podaj tłumaczenie)'
                                : 'Podaj znaczenie po japońsku lub angielsku';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Field 5: Context, Grammar notes, Nuance
                      _buildSectionLabel(
                        title: _isJapaneseMode
                            ? '5. メモ・使い方 (Wskazówki & Kontekst)'
                            : '5. Notatka / Wyjaśnienie gramatyczne',
                        badge: 'OPCJONALNIE',
                        badgeColor: AppTheme.textMuted,
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        key: const ValueKey('add_sentence_notes_input'),
                        controller: _notesController,
                        maxLines: 2,
                        style: const TextStyle(color: AppTheme.textLight, fontSize: 13),
                        decoration: _inputDecoration(
                          hintText: _isJapaneseMode
                              ? '例: カジュアルな表現。仲の良い友達に使えるよ！'
                              : 'np. Luźne przywitanie wieczorne wśród znajomych.',
                          prefixIcon: Icons.notes_rounded,
                        ),
                      ),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade900.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.redAccent.shade100),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: Colors.redAccent, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                      color: Colors.redAccent, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Actions Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.surfaceBorder)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    child: Text(
                      _isJapaneseMode ? 'キャンセル' : 'Anuluj',
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.sakuraPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 3,
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 16),
                      label: Text(
                        _isSubmitting
                            ? (_isJapaneseMode ? '送信中...' : 'Wysyłanie...')
                            : (_isJapaneseMode
                                ? '送信 & 保存'
                                : 'Wyślij do GitHuba i Zapisz'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSegmentedControl() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                setState(() {
                  _currentLanguageMode = 'ja';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _isJapaneseMode
                      ? AppTheme.sakuraPrimary.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: _isJapaneseMode
                      ? Border.all(color: AppTheme.sakuraPrimary)
                      : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🇯🇵', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Japoński (Dla Jakuba)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _isJapaneseMode ? FontWeight.bold : FontWeight.normal,
                          color: _isJapaneseMode ? AppTheme.sakuraPrimary : AppTheme.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                setState(() {
                  _currentLanguageMode = 'pl';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: !_isJapaneseMode
                      ? AppTheme.greenMatcha.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: !_isJapaneseMode
                      ? Border.all(color: AppTheme.greenMatcha)
                      : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🇵🇱', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Polski (Dla Koharu)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: !_isJapaneseMode ? FontWeight.bold : FontWeight.normal,
                          color: !_isJapaneseMode ? AppTheme.greenMatcha : AppTheme.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGitHubStatusCard(bool isConfigured, dynamic remoteConfig) {
    if (isConfigured && !_showGitHubConfig) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.greenMatcha.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.greenMatcha.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_done_rounded, color: AppTheme.greenMatcha, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _isJapaneseMode
                    ? 'GitHub Gist 接続完了 (ID: ${remoteConfig.gistId})'
                    : 'GitHub Gist połączony (${remoteConfig.gistId})',
                style: const TextStyle(
                  color: AppTheme.textLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined, size: 18, color: AppTheme.textMuted),
              tooltip: 'Zmień ustawienia / 設定変更',
              onPressed: () {
                setState(() {
                  _showGitHubConfig = true;
                });
              },
            ),
          ],
        ),
      );
    }

    // Quick Config Card (when not configured or user clicked settings)
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link_rounded, color: AppTheme.sakuraPrimary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isJapaneseMode
                      ? 'GitHub Gist設定 (Prywatne połączenie)'
                      : 'Konfiguracja prywatnego GitHub Gist',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textLight,
                  ),
                ),
              ),
              if (isConfigured)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => setState(() => _showGitHubConfig = false),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isJapaneseMode
                ? 'GistのURLとPersonal Access Token (PAT) を入力すると、お互いのアプリへ瞬時に送信されます。'
                : 'Podaj URL prywatnego Gista i token (PAT) z uprawnieniem "gist", aby współdzielić zwroty.',
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _gistUrlController,
            style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
            decoration: _inputDecoration(
              hintText: 'https://gist.github.com/... lub ID Gista',
              prefixIcon: Icons.code_rounded,
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.auto_awesome, size: 13, color: AppTheme.sakuraPrimary),
              label: Text(
                _isJapaneseMode
                    ? '共通Gistアドレスを自動入力 (Wspólny Gist)'
                    : 'Wstaw adres wspólnego Gista (Jakub & Przyjaciółka)',
                style: const TextStyle(fontSize: 11, color: AppTheme.sakuraPrimary),
              ),
              onPressed: () {
                setState(() {
                  _gistUrlController.text = RemoteDatabaseConfig.sharedPreset.url;
                });
              },
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _githubTokenController,
            obscureText: true,
            style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
            decoration: _inputDecoration(
              hintText: 'GitHub Token (ghp_...) z uprawnieniem "gist"',
              prefixIcon: Icons.vpn_key_rounded,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _handleSaveQuickGitHubConfig,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.surfaceBorder,
                foregroundColor: AppTheme.textLight,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: Text(
                _isJapaneseMode ? '設定を保存 (Zapisz)' : 'Zapisz dane połączenia',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionPicker(List<SentenceCollection> collections) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(
          title: _isJapaneseMode
              ? 'リスト / コレクション選択 (Wybierz listę)'
              : 'Wybierz listę docelową',
          badge: 'LISTA',
          badgeColor: AppTheme.textMuted,
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.surfaceBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _isCreatingNewCollection ? '__new__' : _selectedCollectionId,
              isExpanded: true,
              dropdownColor: AppTheme.surfaceElevated,
              style: const TextStyle(color: AppTheme.textLight, fontSize: 13),
              icon: const Icon(Icons.arrow_drop_down, color: AppTheme.textMuted),
              items: [
                ...collections.map(
                  (col) => DropdownMenuItem<String>(
                    value: col.id,
                    child: Text(
                      '${col.title} (${col.sentences.length} zdań)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DropdownMenuItem<String>(
                  value: '__new__',
                  child: Row(
                    children: [
                      const Icon(Icons.add_circle_outline_rounded,
                          color: AppTheme.sakuraPrimary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        _isJapaneseMode
                            ? '+ 新規リスト作成 (+ Nowa lista)'
                            : '+ Utwórz nową listę',
                        style: const TextStyle(
                          color: AppTheme.sakuraPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  if (value == '__new__') {
                    _isCreatingNewCollection = true;
                  } else {
                    _isCreatingNewCollection = false;
                    _selectedCollectionId = value;
                  }
                });
              },
            ),
          ),
        ),
        if (_isCreatingNewCollection) ...[
          const SizedBox(height: 8),
          TextFormField(
            autofocus: true,
            style: const TextStyle(fontSize: 13, color: AppTheme.textLight),
            decoration: _inputDecoration(
              hintText: _isJapaneseMode
                  ? '新しいリストの名前 (np. 友達との会話 / Rozmówki codzienne)'
                  : 'Tytuł nowej listy (np. Wspólne zwroty codzienne)',
              prefixIcon: Icons.folder_open_rounded,
            ),
            onChanged: (value) => _newCollectionTitle = value,
            validator: (value) {
              if (_isCreatingNewCollection && (value == null || value.trim().isEmpty)) {
                return 'Wprowadź tytuł nowej listy';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSectionLabel({
    required String title,
    required String badge,
    required Color badgeColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.textLight,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            badge,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: badgeColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: AppTheme.textMuted.withValues(alpha: 0.55),
        fontSize: 13,
      ),
      filled: true,
      fillColor: AppTheme.surfaceElevated,
      prefixIcon: Icon(prefixIcon, color: AppTheme.textMuted, size: 18),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.surfaceBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.sakuraPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}
