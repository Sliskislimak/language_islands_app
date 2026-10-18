import 'dart:convert';

const String kDefaultRemoteDatabaseUrl = String.fromEnvironment(
  'DEFAULT_GIST_URL',
  defaultValue: 'https://gist.github.com/Sliskislimak/8d8efa2b1884930a0894553eec419283',
);

const String kDefaultRemoteDatabaseApiKey = String.fromEnvironment(
  'DEFAULT_GIST_TOKEN',
  defaultValue: '',
);

class RemoteDatabaseConfig {
  const RemoteDatabaseConfig({
    this.url = '',
    this.apiKey = '',
    this.autoSyncOnStartup = false,
    this.lastSyncedAt,
    this.lastSyncStatus,
  });

  /// The pre-configured shared Gist database for Jakub and his friend.
  static const RemoteDatabaseConfig sharedPreset = RemoteDatabaseConfig(
    url: kDefaultRemoteDatabaseUrl,
    apiKey: kDefaultRemoteDatabaseApiKey,
    autoSyncOnStartup: true,
  );

  final String url;
  final String apiKey;
  final bool autoSyncOnStartup;
  final DateTime? lastSyncedAt;
  final String? lastSyncStatus;

  bool get isConfigured => url.trim().isNotEmpty;

  /// Extracts the GitHub Gist ID if the URL points to a GitHub Gist, or null otherwise.
  String? get gistId {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;

    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.host.isNotEmpty) {
      final host = uri.host.toLowerCase();
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

      if (host == 'api.github.com' &&
          segments.length >= 2 &&
          segments[0] == 'gists') {
        return segments[1];
      }

      if (host == 'gist.githubusercontent.com' && segments.length >= 2) {
        return segments[1];
      }

      if (host == 'gist.github.com' && segments.isNotEmpty) {
        return segments.length >= 2 ? segments[1] : segments[0];
      }
    }

    if (RegExp(r'^[a-fA-F0-9]{20,40}$').hasMatch(trimmed)) {
      return trimmed;
    }

    return null;
  }

  bool get isGitHubGist => gistId != null;

  RemoteDatabaseConfig copyWith({
    String? url,
    String? apiKey,
    bool? autoSyncOnStartup,
    DateTime? lastSyncedAt,
    bool clearLastSyncedAt = false,
    String? lastSyncStatus,
    bool clearLastSyncStatus = false,
  }) {
    return RemoteDatabaseConfig(
      url: url ?? this.url,
      apiKey: apiKey ?? this.apiKey,
      autoSyncOnStartup: autoSyncOnStartup ?? this.autoSyncOnStartup,
      lastSyncedAt: clearLastSyncedAt ? null : (lastSyncedAt ?? this.lastSyncedAt),
      lastSyncStatus: clearLastSyncStatus ? null : (lastSyncStatus ?? this.lastSyncStatus),
    );
  }

  factory RemoteDatabaseConfig.fromMap(Map<String, dynamic> map) {
    DateTime? parsedDate;
    if (map['lastSyncedAt'] != null) {
      parsedDate = DateTime.tryParse(map['lastSyncedAt'].toString());
    }
    return RemoteDatabaseConfig(
      url: (map['url'] as String? ?? '').trim(),
      apiKey: (map['apiKey'] as String? ?? '').trim(),
      autoSyncOnStartup: map['autoSyncOnStartup'] == true,
      lastSyncedAt: parsedDate,
      lastSyncStatus: map['lastSyncStatus'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'url': url,
      'apiKey': apiKey,
      'autoSyncOnStartup': autoSyncOnStartup,
    };
    if (lastSyncedAt != null) {
      map['lastSyncedAt'] = lastSyncedAt!.toIso8601String();
    }
    if (lastSyncStatus != null) {
      map['lastSyncStatus'] = lastSyncStatus;
    }
    return map;
  }

  factory RemoteDatabaseConfig.fromJsonString(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic>) {
        return RemoteDatabaseConfig.fromMap(decoded);
      }
    } catch (_) {}
    return const RemoteDatabaseConfig();
  }

  String toJsonString() => const JsonEncoder.withIndent('  ').convert(toMap());
}
