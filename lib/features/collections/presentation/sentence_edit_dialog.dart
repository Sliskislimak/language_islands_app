import 'dart:async';

import 'package:flutter/material.dart';
import 'package:language_islands_app/core/models/app_language.dart';
import 'package:language_islands_app/core/models/sentence.dart';
import 'package:language_islands_app/core/services/audio_playback_service.dart';
import 'package:language_islands_app/core/services/audio_recording_service.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';

/// Dialog to add a new flashcard or edit an existing one, including bilingual voice recordings.
class SentenceEditDialog extends StatefulWidget {
  const SentenceEditDialog({
    super.key,
    required this.collectionId,
    this.sentence,
    this.targetLanguageCode,
    this.recordingService,
    this.playbackService,
    this.onSave,
  });

  final String collectionId;
  final Sentence? sentence;
  final String? targetLanguageCode;
  final AudioRecordingService? recordingService;
  final AudioPlaybackService? playbackService;
  final Future<void> Function(Sentence savedSentence)? onSave;

  bool get isEditing => sentence != null;

  @override
  State<SentenceEditDialog> createState() => _SentenceEditDialogState();
}

class _SentenceEditDialogState extends State<SentenceEditDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _targetTextController;
  late final TextEditingController _sourceTextController;
  late final TextEditingController _phoneticController;
  late final TextEditingController _katakanaController;
  late final TextEditingController _notesController;

  late final AudioRecordingService _recordingService;
  late final AudioPlaybackService _playbackService;
  bool _ownsRecordingService = false;
  bool _ownsPlaybackService = false;

  late final String _sentenceId;

  String? _targetAudioPath;
  String? _targetAudioBase64;
  bool _isRecordingTarget = false;
  bool _isPlayingTarget = false;
  int _recordTargetSeconds = 0;
  Timer? _recordTargetTimer;

  String? _translationAudioPath;
  String? _translationAudioBase64;
  bool _isRecordingTranslation = false;
  bool _isPlayingTranslation = false;
  int _recordTranslationSeconds = 0;
  Timer? _recordTranslationTimer;

  bool _showAdvanced = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final s = widget.sentence;
    _sentenceId = s?.id ?? 's_${DateTime.now().millisecondsSinceEpoch}';

    _targetTextController = TextEditingController(text: s?.targetText ?? '');
    _sourceTextController = TextEditingController(text: s?.sourceText ?? '');
    _phoneticController = TextEditingController(text: s?.phoneticReading ?? '');
    _katakanaController = TextEditingController(text: s?.katakana ?? '');
    _notesController = TextEditingController(text: s?.notes ?? '');

    _targetAudioPath = s?.targetAudioPath;
    _targetAudioBase64 = s?.targetAudioBase64;
    _translationAudioPath = s?.translationAudioPath;
    _translationAudioBase64 = s?.translationAudioBase64;

    if (widget.recordingService != null) {
      _recordingService = widget.recordingService!;
    } else {
      _recordingService = RecordAudioRecordingService();
      _ownsRecordingService = true;
    }

    if (widget.playbackService != null) {
      _playbackService = widget.playbackService!;
    } else {
      _playbackService = AudioPlaybackService();
      _ownsPlaybackService = true;
    }

    if (s != null &&
        (s.phoneticReading != null ||
            s.katakana != null ||
            s.hasNotes ||
            s.hasCustomTargetAudio ||
            s.hasCustomTranslationAudio)) {
      _showAdvanced = true;
    }
  }

  @override
  void dispose() {
    _recordTargetTimer?.cancel();
    _recordTranslationTimer?.cancel();

    if (_isRecordingTarget || _isRecordingTranslation) {
      _recordingService.cancelRecording();
    }
    _playbackService.stop();

    if (_ownsRecordingService) {
      _recordingService.dispose();
    }
    if (_ownsPlaybackService) {
      _playbackService.player.dispose();
    }

    _targetTextController.dispose();
    _sourceTextController.dispose();
    _phoneticController.dispose();
    _katakanaController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _startRecordingTarget() async {
    final hasPerm = await _recordingService.hasPermission();
    if (!hasPerm) {
      setState(() => _errorMessage = 'Brak uprawnień do mikrofonu.');
      return;
    }
    try {
      await _recordingService.startRecording(
        sentenceId: _sentenceId,
        isTargetLanguage: true,
      );
      setState(() {
        _isRecordingTarget = true;
        _recordTargetSeconds = 0;
        _errorMessage = null;
      });
      _recordTargetTimer?.cancel();
      _recordTargetTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() => _recordTargetSeconds++);
        }
      });
    } catch (e) {
      setState(() => _errorMessage = 'Błąd rozpoczęcia nagrywania: $e');
    }
  }

  Future<void> _stopRecordingTarget() async {
    _recordTargetTimer?.cancel();
    try {
      final path = await _recordingService.stopRecording();
      if (path != null) {
        final b64 = await _recordingService.convertAudioFileToBase64(path);
        setState(() {
          _isRecordingTarget = false;
          _targetAudioPath = path;
          _targetAudioBase64 = b64;
        });
      } else {
        setState(() => _isRecordingTarget = false);
      }
    } catch (e) {
      setState(() {
        _isRecordingTarget = false;
        _errorMessage = 'Błąd zapisu nagrania: $e';
      });
    }
  }

  Future<void> _cancelRecordingTarget() async {
    _recordTargetTimer?.cancel();
    await _recordingService.cancelRecording();
    setState(() => _isRecordingTarget = false);
  }

  Future<void> _deleteTargetRecording() async {
    _playbackService.stop();
    await _recordingService.deleteRecordingFile(
      sentenceId: _sentenceId,
      isTargetLanguage: true,
    );
    setState(() {
      _targetAudioPath = null;
      _targetAudioBase64 = null;
      _isPlayingTarget = false;
    });
  }

  Future<void> _playTargetRecording() async {
    if (_targetAudioPath == null) return;
    if (_isPlayingTarget) {
      _playbackService.stop();
      setState(() => _isPlayingTarget = false);
      return;
    }

    setState(() => _isPlayingTarget = true);
    try {
      await _playbackService.playFileUntilComplete(_targetAudioPath!);
    } catch (e) {
      setState(() => _errorMessage = 'Błąd odtwarzania nagrania: $e');
    } finally {
      if (mounted) {
        setState(() => _isPlayingTarget = false);
      }
    }
  }

  Future<void> _startRecordingTranslation() async {
    final hasPerm = await _recordingService.hasPermission();
    if (!hasPerm) {
      setState(() => _errorMessage = 'Brak uprawnień do mikrofonu.');
      return;
    }
    try {
      await _recordingService.startRecording(
        sentenceId: _sentenceId,
        isTargetLanguage: false,
      );
      setState(() {
        _isRecordingTranslation = true;
        _recordTranslationSeconds = 0;
        _errorMessage = null;
      });
      _recordTranslationTimer?.cancel();
      _recordTranslationTimer =
          Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() => _recordTranslationSeconds++);
        }
      });
    } catch (e) {
      setState(() => _errorMessage = 'Błąd rozpoczęcia nagrywania: $e');
    }
  }

  Future<void> _stopRecordingTranslation() async {
    _recordTranslationTimer?.cancel();
    try {
      final path = await _recordingService.stopRecording();
      if (path != null) {
        final b64 = await _recordingService.convertAudioFileToBase64(path);
        setState(() {
          _isRecordingTranslation = false;
          _translationAudioPath = path;
          _translationAudioBase64 = b64;
        });
      } else {
        setState(() => _isRecordingTranslation = false);
      }
    } catch (e) {
      setState(() {
        _isRecordingTranslation = false;
        _errorMessage = 'Błąd zapisu nagrania: $e';
      });
    }
  }

  Future<void> _cancelRecordingTranslation() async {
    _recordTranslationTimer?.cancel();
    await _recordingService.cancelRecording();
    setState(() => _isRecordingTranslation = false);
  }

  Future<void> _deleteTranslationRecording() async {
    _playbackService.stop();
    await _recordingService.deleteRecordingFile(
      sentenceId: _sentenceId,
      isTargetLanguage: false,
    );
    setState(() {
      _translationAudioPath = null;
      _translationAudioBase64 = null;
      _isPlayingTranslation = false;
    });
  }

  Future<void> _playTranslationRecording() async {
    if (_translationAudioPath == null) return;
    if (_isPlayingTranslation) {
      _playbackService.stop();
      setState(() => _isPlayingTranslation = false);
      return;
    }

    setState(() => _isPlayingTranslation = true);
    try {
      await _playbackService.playFileUntilComplete(_translationAudioPath!);
    } catch (e) {
      setState(() => _errorMessage = 'Błąd odtwarzania nagrania: $e');
    } finally {
      if (mounted) {
        setState(() => _isPlayingTranslation = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final targetText = _targetTextController.text.trim();
    final sourceText = _sourceTextController.text.trim();
    final phonetic = _phoneticController.text.trim();
    final katakana = _katakanaController.text.trim();
    final notes = _notesController.text.trim();

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final Sentence saved;
      if (widget.isEditing) {
        final prev = widget.sentence!;
        final targetChanged = prev.targetText != targetText;
        final sourceChanged = prev.sourceText != sourceText;

        saved = prev.copyWith(
          targetText: targetText,
          sourceText: sourceText,
          phoneticReading: phonetic.isNotEmpty ? phonetic : null,
          clearPhoneticReading: phonetic.isEmpty,
          katakana: katakana.isNotEmpty ? katakana : null,
          clearKatakana: katakana.isEmpty,
          notes: notes.isNotEmpty ? notes : null,
          clearNotes: notes.isEmpty,
          targetAudioPath: _targetAudioPath,
          clearTargetAudioPath: _targetAudioPath == null ||
              (targetChanged && _targetAudioBase64 == null),
          targetAudioBase64: _targetAudioBase64,
          clearTargetAudioBase64: _targetAudioBase64 == null,
          translationAudioPath: _translationAudioPath,
          clearTranslationAudioPath: _translationAudioPath == null ||
              (sourceChanged && _translationAudioBase64 == null),
          translationAudioBase64: _translationAudioBase64,
          clearTranslationAudioBase64: _translationAudioBase64 == null,
        );
      } else {
        saved = Sentence(
          id: _sentenceId,
          targetText: targetText,
          sourceText: sourceText,
          phoneticReading: phonetic.isNotEmpty ? phonetic : null,
          katakana: katakana.isNotEmpty ? katakana : null,
          notes: notes.isNotEmpty ? notes : null,
          targetAudioPath: _targetAudioPath,
          targetAudioBase64: _targetAudioBase64,
          translationAudioPath: _translationAudioPath,
          translationAudioBase64: _translationAudioBase64,
        );
      }

      if (widget.onSave != null) {
        await widget.onSave!(saved);
      }

      if (mounted) {
        Navigator.of(context).pop(saved);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Błąd zapisu: $e';
        });
      }
    }
  }

  Widget _buildRecordingSection({
    required String sectionTitle,
    required String recordButtonLabel,
    required bool isRecording,
    required int recordSeconds,
    required bool isPlaying,
    required String? audioPath,
    required String? audioBase64,
    required VoidCallback onStartRecord,
    required VoidCallback onStopRecord,
    required VoidCallback onCancelRecord,
    required VoidCallback onPlay,
    required VoidCallback onDelete,
  }) {
    final hasAudio = (audioPath != null && audioPath.isNotEmpty) ||
        (audioBase64 != null && audioBase64.isNotEmpty);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isRecording
              ? Colors.redAccent.withValues(alpha: 0.8)
              : hasAudio
                  ? AppTheme.greenMatcha.withValues(alpha: 0.4)
                  : AppTheme.surfaceBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasAudio
                    ? Icons.mic_rounded
                    : isRecording
                        ? Icons.fiber_manual_record_rounded
                        : Icons.mic_none_rounded,
                size: 16,
                color: isRecording
                    ? Colors.redAccent
                    : hasAudio
                        ? AppTheme.greenMatcha
                        : AppTheme.textMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  sectionTitle,
                  style: TextStyle(
                    color: isRecording
                        ? Colors.redAccent
                        : hasAudio
                            ? AppTheme.textLight
                            : AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (hasAudio && !isRecording)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.greenMatcha.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Nagrano ✓',
                    style: TextStyle(
                      color: AppTheme.greenMatcha,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (isRecording) ...[
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.fiber_manual_record,
                        size: 12,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Nagrywanie: ${_formatDuration(recordSeconds)}',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onCancelRecord,
                  child: const Text(
                    'Anuluj',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 6),
                FilledButton.icon(
                  onPressed: onStopRecord,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.stop_rounded, size: 16),
                  label: const Text('Zakończ'),
                ),
              ],
            ),
          ] else if (hasAudio) ...[
            Row(
              children: [
                FilledButton.tonalIcon(
                  onPressed: onPlay,
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        AppTheme.greenMatcha.withValues(alpha: 0.2),
                    foregroundColor: AppTheme.greenMatcha,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                  icon: Icon(
                    isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    size: 18,
                  ),
                  label: Text(isPlaying ? 'Zatrzymaj' : 'Odsłuchaj'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onStartRecord,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textLight,
                    side: const BorderSide(color: AppTheme.surfaceBorder),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Nagraj ponownie',
                      style: TextStyle(fontSize: 12)),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Usuń nagranie',
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: Colors.redAccent,
                  ),
                  onPressed: onDelete,
                ),
              ],
            ),
          ] else ...[
            OutlinedButton.icon(
              onPressed: onStartRecord,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.sakuraPrimary,
                side: BorderSide(
                    color: AppTheme.sakuraPrimary.withValues(alpha: 0.5)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.mic_rounded, size: 18),
              label: Text(
                recordButtonLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final targetLang = widget.targetLanguageCode != null
        ? AppLanguage.fromCode(widget.targetLanguageCode!)
        : null;
    final targetLangLabel = targetLang != null
        ? '${targetLang.flagEmoji} ${targetLang.nativeName}'
        : 'język docelowy';

    final isJapaneseTarget = targetLang?.code == 'ja';
    final targetVoicePrompt = isJapaneseTarget
        ? '🎙️ Nagraj japońską wymowę (Koharu)'
        : '🎙️ Nagraj własną wymowę docelową';
    final translationVoicePrompt = isJapaneseTarget
        ? '🎙️ Nagraj polską wymowę (Jakub)'
        : '🎙️ Nagraj wymowę tłumaczenia';

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.surfaceBorder),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 740),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.sakuraPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        widget.isEditing
                            ? Icons.edit_note_rounded
                            : Icons.add_circle_outline_rounded,
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
                            widget.isEditing
                                ? 'Edytuj fiszkę'
                                : 'Dodaj nową fiszkę',
                            style: const TextStyle(
                              color: AppTheme.textLight,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.isEditing
                                ? 'Tekst, tłumaczenie oraz własny głos Koharu & Jakuba'
                                : 'Pojedyncza fiszka z opcjonalnym głosem native speakera',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: AppTheme.textMuted),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: Colors.red.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Body fields (scrollable)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Target Text
                        Text(
                          'Treść zdania / Fiszka ($targetLangLabel)',
                          style: const TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _targetTextController,
                          maxLines: 3,
                          minLines: 1,
                          style: const TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'np. 今日はとても楽しかったです。 lub Dzień dobry!',
                            hintStyle: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                            ),
                            filled: true,
                            fillColor: AppTheme.surfaceElevated,
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppTheme.surfaceBorder,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppTheme.surfaceBorder,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppTheme.sakuraPrimary,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Treść fiszki nie może być pusta.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),

                        // Target Voice Recording Section
                        _buildRecordingSection(
                          sectionTitle: 'Głos docelowy ($targetLangLabel)',
                          recordButtonLabel: targetVoicePrompt,
                          isRecording: _isRecordingTarget,
                          recordSeconds: _recordTargetSeconds,
                          isPlaying: _isPlayingTarget,
                          audioPath: _targetAudioPath,
                          audioBase64: _targetAudioBase64,
                          onStartRecord: _startRecordingTarget,
                          onStopRecord: _stopRecordingTarget,
                          onCancelRecord: _cancelRecordingTarget,
                          onPlay: _playTargetRecording,
                          onDelete: _deleteTargetRecording,
                        ),
                        const SizedBox(height: 14),

                        // Source Text (Translation)
                        const Text(
                          'Tłumaczenie (znaczenie w Twoim języku)',
                          style: TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _sourceTextController,
                          maxLines: 3,
                          minLines: 1,
                          style: const TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'np. Dzisiaj było bardzo wesoło / Dzisiejszy dzień był miły.',
                            hintStyle: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                            ),
                            filled: true,
                            fillColor: AppTheme.surfaceElevated,
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppTheme.surfaceBorder,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppTheme.surfaceBorder,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppTheme.sakuraPrimary,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Tłumaczenie nie może być puste.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),

                        // Translation Voice Recording Section
                        _buildRecordingSection(
                          sectionTitle: 'Głos tłumaczenia (Twój język)',
                          recordButtonLabel: translationVoicePrompt,
                          isRecording: _isRecordingTranslation,
                          recordSeconds: _recordTranslationSeconds,
                          isPlaying: _isPlayingTranslation,
                          audioPath: _translationAudioPath,
                          audioBase64: _translationAudioBase64,
                          onStartRecord: _startRecordingTranslation,
                          onStopRecord: _stopRecordingTranslation,
                          onCancelRecord: _cancelRecordingTranslation,
                          onPlay: _playTranslationRecording,
                          onDelete: _deleteTranslationRecording,
                        ),
                        const SizedBox(height: 14),

                        // Advanced / Optional toggle
                        InkWell(
                          onTap: () {
                            setState(() {
                              _showAdvanced = !_showAdvanced;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Icon(
                                  _showAdvanced
                                      ? Icons.arrow_drop_down_rounded
                                      : Icons.arrow_right_rounded,
                                  color: AppTheme.sakuraPrimary,
                                ),
                                const SizedBox(width: 4),
                                const Flexible(
                                  child: Text(
                                    'Więcej opcji (wymowa, fonetyka, notatki)',
                                    style: TextStyle(
                                      color: AppTheme.sakuraPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (_showAdvanced) ...[
                          const SizedBox(height: 10),
                          // Phonetic reading / Romaji
                          const Text(
                            'Czytanie fonetyczne (Romaji / Pinyin / Wymowa)',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _phoneticController,
                            style: const TextStyle(
                              color: AppTheme.textLight,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'np. Kyou wa totemo tanoshikatta desu.',
                              hintStyle: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                              ),
                              filled: true,
                              fillColor: AppTheme.surfaceElevated,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppTheme.surfaceBorder,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Katakana
                          const Text(
                            'Zapis Katakana (dla Koharu / fonetyka japońska)',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _katakanaController,
                            style: const TextStyle(
                              color: AppTheme.textLight,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'np. ジェン ドブリ (dla zdań po polsku)',
                              hintStyle: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                              ),
                              filled: true,
                              fillColor: AppTheme.surfaceElevated,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppTheme.surfaceBorder,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Notes
                          const Text(
                            'Notatki gramatyczne / Wskazówki (rewers fiszki)',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _notesController,
                            maxLines: 3,
                            minLines: 1,
                            style: const TextStyle(
                              color: AppTheme.textLight,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'np. Używane w sytuacjach nieformalnych...',
                              hintStyle: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                              ),
                              filled: true,
                              fillColor: AppTheme.surfaceElevated,
                              contentPadding: const EdgeInsets.all(12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppTheme.surfaceBorder,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                // Footer buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.of(context).pop(),
                      child: const Text(
                        'Anuluj',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.sakuraPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(widget.isEditing
                              ? Icons.check_rounded
                              : Icons.add_rounded),
                      label: Text(
                        widget.isEditing ? 'Zapisz zmiany' : 'Dodaj fiszkę',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper method to open the sentence edit dialog.
Future<Sentence?> showSentenceEditDialog(
  BuildContext context, {
  required String collectionId,
  Sentence? sentence,
  String? targetLanguageCode,
  AudioRecordingService? recordingService,
  AudioPlaybackService? playbackService,
  Future<void> Function(Sentence savedSentence)? onSave,
}) {
  return showDialog<Sentence>(
    context: context,
    builder: (context) => SentenceEditDialog(
      collectionId: collectionId,
      sentence: sentence,
      targetLanguageCode: targetLanguageCode,
      recordingService: recordingService,
      playbackService: playbackService,
      onSave: onSave,
    ),
  );
}
