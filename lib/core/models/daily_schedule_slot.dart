/// Single block in the zero-decision daily protocol for the 90-day plan.
class DailyScheduleSlot {
  const DailyScheduleSlot({
    required this.id,
    required this.title,
    required this.timeWindow,
    required this.modeLabel,
    required this.actionSummary,
    required this.presetConfig,
    required this.isCore,
    required this.order,
  });

  final String id;
  final String title;
  final String timeWindow;
  final String modeLabel;
  final String actionSummary;
  final String presetConfig;
  final bool isCore;
  final int order;

  static const String coreMorningId = 'core_morning';
  static const String coreCommuteId = 'core_commute';
  static const String coreMiddayId = 'core_midday';
  static const String coreEveningId = 'core_evening';

  static const List<DailyScheduleSlot> defaultCoreSlots = [
    DailyScheduleSlot(
      id: coreMorningId,
      title: 'Poranek: Rozruch & Shadowing',
      timeWindow: '07:00 - 07:30',
      modeLabel: 'Shadowing (Autopilot)',
      actionSummary:
          'ZAKAZ Active Recall rano! Zalanie ucha dźwiękiem podczas mycia zębów i kawy.',
      presetConfig: 'Shadowing | Reps: 2x-3x | Pause: 1.5s | Tekst odsłonięty',
      isCore: true,
      order: 0,
    ),
    DailyScheduleSlot(
      id: coreCommuteId,
      title: 'Dojazd / Przemieszczanie się',
      timeWindow: '08:00 - 08:40',
      modeLabel: 'Audio Hands-Free',
      actionSummary:
          'Głośne powtarzanie w aucie lub ciche powtarzanie w myślach w transporcie.',
      presetConfig: 'Shadowing | Reps: 1x | Pause: 1.0s',
      isCore: true,
      order: 1,
    ),
    DailyScheduleSlot(
      id: coreMiddayId,
      title: 'Przerwa w ciągu dnia / Obiad',
      timeWindow: '13:00 - 13:20',
      modeLabel: 'Active Recall Sprint (10-15 min)',
      actionSummary:
          'Mózg na obrotach. Tłumacz z pamięci na głos przed odsłonięciem odpowiedzi.',
      presetConfig: 'Recall | Think Time: 2.0s-2.5s',
      isCore: true,
      order: 2,
    ),
    DailyScheduleSlot(
      id: coreEveningId,
      title: 'Wieczór przed snem',
      timeWindow: '21:30 - 22:15',
      modeLabel: 'Główny Trening & Słabe Punkty',
      actionSummary:
          'Active Recall + filtr trudnych zdań (<4★) z Reps 5x. Nocna konsolidacja pamięci.',
      presetConfig: 'Recall + filtr słabych zdań | Reps: 5x',
      isCore: true,
      order: 3,
    ),
  ];

  /// Allowed task types when adding a custom break slot.
  static const String customTypeShortShadowing =
      'Krótki Shadowing (Autopilot)';
  static const String customTypeRecallSprint = 'Active Recall Sprint (10 min)';

  static const List<String> allowedCustomTaskTypes = [
    customTypeShortShadowing,
    customTypeRecallSprint,
  ];

  DailyScheduleSlot copyWith({
    String? id,
    String? title,
    String? timeWindow,
    String? modeLabel,
    String? actionSummary,
    String? presetConfig,
    bool? isCore,
    int? order,
  }) {
    return DailyScheduleSlot(
      id: id ?? this.id,
      title: title ?? this.title,
      timeWindow: timeWindow ?? this.timeWindow,
      modeLabel: modeLabel ?? this.modeLabel,
      actionSummary: actionSummary ?? this.actionSummary,
      presetConfig: presetConfig ?? this.presetConfig,
      isCore: isCore ?? this.isCore,
      order: order ?? this.order,
    );
  }

  factory DailyScheduleSlot.fromMap(Map<String, dynamic> map) {
    return DailyScheduleSlot(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      timeWindow: map['timeWindow'] as String? ?? '',
      modeLabel: map['modeLabel'] as String? ?? '',
      actionSummary: map['actionSummary'] as String? ?? '',
      presetConfig: map['presetConfig'] as String? ?? '',
      isCore: map['isCore'] as bool? ?? false,
      order: map['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'timeWindow': timeWindow,
      'modeLabel': modeLabel,
      'actionSummary': actionSummary,
      'presetConfig': presetConfig,
      'isCore': isCore,
      'order': order,
    };
  }

  /// Builds a user-defined break block from the modal form.
  static DailyScheduleSlot customFromForm({
    required String id,
    required String title,
    required String timeWindow,
    required String taskType,
    required int order,
  }) {
    switch (taskType) {
      case customTypeRecallSprint:
        return DailyScheduleSlot(
          id: id,
          title: title,
          timeWindow: timeWindow,
          modeLabel: customTypeRecallSprint,
          actionSummary:
              'Mówi na głos z pamięci. Odsłoń odpowiedź dopiero po próbie.',
          presetConfig: 'Recall | Think Time: 2.0s | Tekst ukryty',
          isCore: false,
          order: order,
        );
      case customTypeShortShadowing:
      default:
        return DailyScheduleSlot(
          id: id,
          title: title,
          timeWindow: timeWindow,
          modeLabel: 'Shadowing (Autopilot)',
          actionSummary:
              'Włóż słuchawki, włącz Play, nie analizuj gramatyki.',
          presetConfig: 'Shadowing | Reps: 2x | Pause: 1.5s | Tekst odsłonięty',
          isCore: false,
          order: order,
        );
    }
  }

  /// Parses the start of [timeWindow] (e.g. `07:00 - 07:30`) for sorting.
  static int startMinutesFromTimeWindow(String timeWindow) {
    final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(timeWindow.trim());
    if (match == null) return 0;
    final hour = int.tryParse(match.group(1) ?? '') ?? 0;
    final minute = int.tryParse(match.group(2) ?? '') ?? 0;
    return hour * 60 + minute;
  }

  static List<DailyScheduleSlot> sortedByTime(
    Iterable<DailyScheduleSlot> slots,
  ) {
    final list = List<DailyScheduleSlot>.from(slots);
    list.sort((a, b) {
      final byTime = startMinutesFromTimeWindow(a.timeWindow)
          .compareTo(startMinutesFromTimeWindow(b.timeWindow));
      if (byTime != 0) return byTime;
      return a.order.compareTo(b.order);
    });
    return list;
  }
}
