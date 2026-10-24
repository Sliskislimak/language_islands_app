import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// High-performance client for Microsoft Edge Read Aloud Neural TTS.
///
/// Implements the Sec-MS-GEC v2 anti-abuse protocol required by Microsoft
/// endpoints as of late 2026, with automatic clock skew calibration.
class EdgeTtsClient {
  static const String _trustedClientToken = '6A5AA1D4EAFF4E9FB37E23D68491D6F4';
  static const String _chromiumFullVersion = '143.0.3650.75';
  static const String _chromiumMajorVersion = '143';
  static const String _secMsGecVersion = '2-$_chromiumFullVersion';
  static const String _wssUrl =
      'wss://speech.platform.bing.com/consumer/speech/synthesize/readaloud/edge/v1';
  static const String _voiceListUrl =
      'https://speech.platform.bing.com/consumer/speech/synthesize/readaloud/voices/list?trustedclienttoken=$_trustedClientToken';

  static double _clockSkewSeconds = 0.0;

  /// Synthesizes [text] using Edge Neural voice [voice] and returns raw MP3 bytes.
  static Future<Uint8List> synthesize({
    required String text,
    required String voice,
    String rate = '+0%',
    String pitch = '+0Hz',
    String volume = '+0%',
  }) async {
    return _synthesizeWithRetry(
      text: text,
      voice: voice,
      rate: rate,
      pitch: pitch,
      volume: volume,
      retriesLeft: 2,
    );
  }

  static Future<Uint8List> _synthesizeWithRetry({
    required String text,
    required String voice,
    required String rate,
    required String pitch,
    required String volume,
    required int retriesLeft,
  }) async {
    try {
      return await _performSynthesis(
        text: text,
        voice: voice,
        rate: rate,
        pitch: pitch,
        volume: volume,
      );
    } catch (e) {
      if (retriesLeft > 0) {
        // Calibrate clock in case of clock drift leading to token rejection
        await _calibrateClock();
        return _synthesizeWithRetry(
          text: text,
          voice: voice,
          rate: rate,
          pitch: pitch,
          volume: volume,
          retriesLeft: retriesLeft - 1,
        );
      }
      rethrow;
    }
  }

  static Future<void> _calibrateClock() async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(_voiceListUrl));
      final response = await request.close();
      final dateStr = response.headers.value(HttpHeaders.dateHeader);
      if (dateStr != null) {
        final serverTime = HttpDate.parse(dateStr).toUtc();
        final localTime = DateTime.now().toUtc();
        _clockSkewSeconds =
            serverTime.difference(localTime).inMilliseconds / 1000.0;
      }
      client.close(force: true);
    } catch (_) {
      // Best-effort calibration
    }
  }

  static Future<Uint8List> _performSynthesis({
    required String text,
    required String voice,
    required String rate,
    required String pitch,
    required String volume,
  }) async {
    final connectionId = _generateUuidHex();
    final requestId = _generateUuidHex();
    final gec = _generateSecMsGecV2();
    final muid = _generateMuid();

    final wsUrlString = '$_wssUrl?TrustedClientToken=$_trustedClientToken'
        '&ConnectionId=$connectionId'
        '&Sec-MS-GEC=$gec'
        '&Sec-MS-GEC-Version=$_secMsGecVersion';

    final httpClient = HttpClient()..userAgent = null;
    final ws = await WebSocket.connect(
      wsUrlString,
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/$_chromiumMajorVersion.0.0.0 Safari/537.36 '
            'Edg/$_chromiumMajorVersion.0.0.0',
        'Accept-Encoding': 'gzip, deflate, br, zstd',
        'Accept-Language': 'en-US,en;q=0.9',
        'Pragma': 'no-cache',
        'Cache-Control': 'no-cache',
        'Origin': 'chrome-extension://jdiccldimpdaibmpdkjnbmckianbfold',
        'Sec-WebSocket-Version': '13',
        'Cookie': 'muid=$muid;',
      },
      compression: CompressionOptions.compressionDefault,
      customClient: httpClient,
    );

    final timestamp = _generateTimestamp();
    final configMsg = 'X-Timestamp:$timestamp\r\n'
        'Content-Type:application/json; charset=utf-8\r\n'
        'Path:speech.config\r\n'
        '\r\n'
        '{"context":{"synthesis":{"audio":{"metadataoptions":'
        '{"sentenceBoundaryEnabled":"false","wordBoundaryEnabled":"false"},'
        '"outputFormat":"audio-24khz-48kbitrate-mono-mp3"}'
        '}}}\r\n';
    ws.add(configMsg);

    final ssml = '<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" '
        'xmlns:mstts="https://www.w3.org/2001/mstts" xml:lang="en-US">\r\n'
        '<voice name="$voice">\r\n'
        '<prosody pitch="$pitch" rate="$rate" volume="$volume">\r\n'
        '${_escapeXml(text)}\r\n'
        '</prosody>\r\n'
        '</voice>\r\n'
        '</speak>';

    final requestMsg = 'X-RequestId:$requestId\r\n'
        'Content-Type:application/ssml+xml\r\n'
        'X-Timestamp:$_timestampZ\r\n'
        'Path:ssml\r\n'
        '\r\n'
        '$ssml';
    ws.add(requestMsg);

    final audioBuilder = BytesBuilder(copy: false);
    final completer = Completer<Uint8List>();

    ws.listen(
      (message) {
        if (message is String) {
          if (message.contains('Path:turn.end')) {
            ws.close();
            if (!completer.isCompleted) {
              completer.complete(audioBuilder.toBytes());
            }
          }
        } else if (message is List<int>) {
          final data =
              message is Uint8List ? message : Uint8List.fromList(message);
          if (data.length >= 2) {
            final headerLen = (data[0] << 8) | data[1];
            if (data.length > 2 + headerLen) {
              final audioBytes = data.sublist(2 + headerLen);
              audioBuilder.add(audioBytes);
            }
          }
        }
      },
      onError: (e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete(audioBuilder.toBytes());
      },
      cancelOnError: true,
    );

    return completer.future;
  }

  // ---------------------------------------------------------------------------
  // DRM v2 Token Implementation (CS64 + SHA-256)
  // ---------------------------------------------------------------------------

  static const int _winEpoch = 11644473600;
  static const int _u32Mask = 0xFFFFFFFF;

  static const List<int> _sha256Initial = [
    0x6A09E667, 0xBB67AE85, 0x3C6EF372, 0xA54FF53A,
    0x510E527F, 0x9B05688C, 0x1F83D9AB, 0x5BE0CD19,
  ];

  static const List<int> _sha256State = [
    0xFD9FBEA2, 0x91243CE7, 0xBE499094, 0xCD2E1E0A,
    0x6C006F49, 0x04BD35AB, 0xFEB0A7E4, 0x03EFFBD2,
  ];

  static const List<int> _sha256Schedule = [
    0xEB24BF9E, 0x1558691F, 0xA0C09EE2, 0x0CFA32BA,
    0xA622EE8C, 0xD1DD9491, 0xC0DD25A0, 0xF9E70AB6,
    0xF0C31573, 0x7058CE4E, 0x7188E606, 0x00E5AB33,
    0xD258B060, 0x72766564,
  ];

  static const List<int> _sha256RoundConstants = [
    0x428A2F98, 0x71374491, 0xB5C0FBCF, 0xE9B5DBA5, 0x3956C25B, 0x59F111F1, 0x923F82A4, 0xAB1C5ED5,
    0xD807AA98, 0x12835B01, 0x243185BE, 0x550C7DC3, 0x72BE5D74, 0x80DEB1FE, 0x9BDC06A7, 0xC19BF174,
    0xE49B69C1, 0xEFBE4786, 0x0FC19DC6, 0x240CA1CC, 0x2DE92C6F, 0x4A7484AA, 0x5CB0A9DC, 0x76F988DA,
    0x983E5152, 0xA831C66D, 0xB00327C8, 0xBF597FC7, 0xC6E00BF3, 0xD5A79147, 0x06CA6351, 0x14292967,
    0x27B70A85, 0x2E1B2138, 0x4D2C6DFC, 0x53380D13, 0x650A7354, 0x766A0ABB, 0x81C2C92E, 0x92722C85,
    0xA2BFE8A1, 0xA81A664B, 0xC24B8B70, 0xC76C51A3, 0xD192E819, 0xD6990624, 0xF40E3585, 0x106AA070,
    0x19A4C116, 0x1E376C08, 0x2748774C, 0x34B0BCB5, 0x391C0CB3, 0x4ED8AA4A, 0x5B9CCA4F, 0x682E6FF3,
    0x748F82EE, 0x78A5636F, 0x84C87814, 0x8CC70208, 0x90BEFFFA, 0xA4506CEB, 0xBEF9A3F7, 0xC67178F2,
  ];

  static const int _sha256Adjustment = 0xC9DC06A7;
  static final List<int> _sha256BlockConstants = [
    ..._sha256RoundConstants.sublist(0, 14),
    _sha256Adjustment,
    ..._sha256RoundConstants.sublist(15),
  ];

  static const int _sha256Sigma0Adjustment = 0x059C0B80;
  static const int _sha256Sigma1Adjustment = 0x000B92C0;

  static const List<List<int>> _cs64Coefficients = [
    [0xE82E91B1, 0xB32700D0],
    [0x44DE24C6, 0x88DFF51D],
    [0x3BEB65BC, 0x29514038],
    [0xC89C5933, 0xB328CBDF],
    [0x8D1EC211, 0xD405B4D5],
    [0x314EF5D5, 0x26E55F3C],
    [0xE92491B1, 0x607801C6],
    [0xF0A5B9D5, 0x82B2C1FB],
    [0x06064CF3, 0xFA51A3DA],
    [0xDA79FA60, 0x207CC464],
    [0xBED20560, 0x3C3C74F3],
    [0x89F9C9F8, 0xD2D14B61],
    [0x35FA38C6, 0xBB04A2C1],
    [0xCB49E3C6, 0xC5626167],
  ];

  static const int _cs64Factor = 0x82893933;
  static const int _cs64Adjustment0 = 0xF2F90B1A;
  static const int _cs64Adjustment1 = 0x0B1A0000;

  static int _rol16(int value) {
    value &= _u32Mask;
    return (((value << 16) | (value >> 16))) & _u32Mask;
  }

  static List<int> _wordsLe4Even(Uint8List data) {
    final rem = (-data.length) % 4;
    final padCount = rem < 0 ? rem + 4 : rem;
    final padded = Uint8List(data.length + padCount);
    padded.setRange(0, data.length, data);
    if (padded.isEmpty) return [];
    final bd = ByteData.sublistView(padded);
    final words = <int>[];
    for (int i = 0; i < padded.length; i += 4) {
      words.add(bd.getUint32(i, Endian.little));
    }
    if (words.length % 2 != 0) {
      words.add(0);
    }
    return words;
  }

  static int _sigma0(int value) {
    return (((value >> 7) ^
            (value << 25) ^
            (value >> 18) ^
            (value << 14) ^
            (value >> 3))) &
        _u32Mask;
  }

  static int _sigma1(int value) {
    return (((value >> 17) ^
            (value << 15) ^
            (value >> 19) ^
            (value << 13) ^
            (value >> 10))) &
        _u32Mask;
  }

  static List<int> _sha256Rounds(List<int> state, List<int> words,
      [int firstRound = 0]) {
    int a = state[0], b = state[1], c = state[2], d = state[3];
    int e = state[4], f = state[5], g = state[6], h = state[7];
    final constants =
        firstRound == 14 ? _sha256BlockConstants : _sha256RoundConstants;
    final aligned = ((firstRound + 7) ~/ 8) * 8;
    final firstLimit = aligned < 64 ? aligned : 64;

    for (int i = firstRound; i < firstLimit; i++) {
      final rotE = e * 0x100000001;
      final rotA = a * 0x100000001;
      final t1 = (h +
              ((rotE >> 6) ^ (rotE >> 11) ^ (rotE >> 25)) +
              (g ^ (e & (f ^ g))) +
              constants[i] +
              words[i]) &
          _u32Mask;
      final t2 = (((rotA >> 2) ^ (rotA >> 13) ^ (rotA >> 22)) +
              ((a & b) | (c & (a | b)))) &
          _u32Mask;
      h = g;
      g = f;
      f = e;
      e = (d + t1) & _u32Mask;
      d = c;
      c = b;
      b = a;
      a = (t1 + t2) & _u32Mask;
    }

    for (int index = firstLimit; index < 64; index += 8) {
      int rotE = e * 0x100000001;
      int rotA = a * 0x100000001;
      int t1 = (h +
              ((rotE >> 6) ^ (rotE >> 11) ^ (rotE >> 25)) +
              (g ^ (e & (f ^ g))) +
              constants[index] +
              words[index]) &
          _u32Mask;
      d = (d + t1) & _u32Mask;
      h = (t1 +
              ((rotA >> 2) ^ (rotA >> 13) ^ (rotA >> 22)) +
              ((a & b) | (c & (a | b)))) &
          _u32Mask;

      rotE = d * 0x100000001;
      rotA = h * 0x100000001;
      t1 = (g +
              ((rotE >> 6) ^ (rotE >> 11) ^ (rotE >> 25)) +
              (f ^ (d & (e ^ f))) +
              constants[index + 1] +
              words[index + 1]) &
          _u32Mask;
      c = (c + t1) & _u32Mask;
      g = (t1 +
              ((rotA >> 2) ^ (rotA >> 13) ^ (rotA >> 22)) +
              ((h & a) | (b & (h | a)))) &
          _u32Mask;

      rotE = c * 0x100000001;
      rotA = g * 0x100000001;
      t1 = (f +
              ((rotE >> 6) ^ (rotE >> 11) ^ (rotE >> 25)) +
              (e ^ (c & (d ^ e))) +
              constants[index + 2] +
              words[index + 2]) &
          _u32Mask;
      b = (b + t1) & _u32Mask;
      f = (t1 +
              ((rotA >> 2) ^ (rotA >> 13) ^ (rotA >> 22)) +
              ((g & h) | (a & (g | h)))) &
          _u32Mask;

      rotE = b * 0x100000001;
      rotA = f * 0x100000001;
      t1 = (e +
              ((rotE >> 6) ^ (rotE >> 11) ^ (rotE >> 25)) +
              (d ^ (b & (c ^ d))) +
              constants[index + 3] +
              words[index + 3]) &
          _u32Mask;
      a = (a + t1) & _u32Mask;
      e = (t1 +
              ((rotA >> 2) ^ (rotA >> 13) ^ (rotA >> 22)) +
              ((f & g) | (h & (f | g)))) &
          _u32Mask;

      rotE = a * 0x100000001;
      rotA = e * 0x100000001;
      t1 = (d +
              ((rotE >> 6) ^ (rotE >> 11) ^ (rotE >> 25)) +
              (c ^ (a & (b ^ c))) +
              constants[index + 4] +
              words[index + 4]) &
          _u32Mask;
      h = (h + t1) & _u32Mask;
      d = (t1 +
              ((rotA >> 2) ^ (rotA >> 13) ^ (rotA >> 22)) +
              ((e & f) | (g & (e | f)))) &
          _u32Mask;

      rotE = h * 0x100000001;
      rotA = d * 0x100000001;
      t1 = (c +
              ((rotE >> 6) ^ (rotE >> 11) ^ (rotE >> 25)) +
              (b ^ (h & (a ^ b))) +
              constants[index + 5] +
              words[index + 5]) &
          _u32Mask;
      g = (g + t1) & _u32Mask;
      c = (t1 +
              ((rotA >> 2) ^ (rotA >> 13) ^ (rotA >> 22)) +
              ((d & e) | (f & (d | e)))) &
          _u32Mask;

      rotE = g * 0x100000001;
      rotA = c * 0x100000001;
      t1 = (b +
              ((rotE >> 6) ^ (rotE >> 11) ^ (rotE >> 25)) +
              (a ^ (g & (h ^ a))) +
              constants[index + 6] +
              words[index + 6]) &
          _u32Mask;
      f = (f + t1) & _u32Mask;
      b = (t1 +
              ((rotA >> 2) ^ (rotA >> 13) ^ (rotA >> 22)) +
              ((c & d) | (e & (c | d)))) &
          _u32Mask;

      rotE = f * 0x100000001;
      rotA = b * 0x100000001;
      t1 = (a +
              ((rotE >> 6) ^ (rotE >> 11) ^ (rotE >> 25)) +
              (h ^ (f & (g ^ h))) +
              constants[index + 7] +
              words[index + 7]) &
          _u32Mask;
      e = (e + t1) & _u32Mask;
      a = (t1 +
              ((rotA >> 2) ^ (rotA >> 13) ^ (rotA >> 22)) +
              ((b & c) | (d & (b | c)))) &
          _u32Mask;
    }
    return [a, b, c, d, e, f, g, h];
  }

  static void _expandSha256Schedule(List<int> words, [int firstWord = 16]) {
    for (int index = firstWord; index < 64; index++) {
      final x = words[index - 2];
      final y = words[index - 15];
      final sigma1 =
          ((x >> 17) ^ (x << 15) ^ (x >> 19) ^ (x << 13) ^ (x >> 10)) & _u32Mask;
      final sigma0 =
          ((y >> 7) ^ (y << 25) ^ (y >> 18) ^ (y << 14) ^ (y >> 3)) & _u32Mask;
      words.add(
          (sigma1 + words[index - 7] + sigma0 + words[index - 16]) & _u32Mask);
    }
  }

  static List<int> _sha256Init(Uint8List data) {
    final words = List<int>.filled(14, 0, growable: true);
    final bd = ByteData.sublistView(data);
    final w14 = (data[0] << 16) | (data[1] << 8) | data[2];
    words.add(w14);
    words.add(bd.getUint32(3, Endian.big));

    for (int index = 16; index < 30; index++) {
      int value = _sha256Schedule[index - 16];
      if (index - 2 >= 14) {
        value += index == 16
            ? (_sigma1(words[index - 2]) ^ _sha256Sigma1Adjustment)
            : _sigma1(words[index - 2]);
      }
      if (index - 7 >= 14) {
        value += words[index - 7];
      }
      if (index - 15 >= 14) {
        value += index == 29
            ? (_sigma0(words[index - 15]) ^ _sha256Sigma0Adjustment)
            : _sigma0(words[index - 15]);
      }
      words.add(value & _u32Mask);
    }
    words.add((_sigma1(words[28]) +
            words[23] +
            _sigma0(words[15]) +
            words[14] +
            _sha256Adjustment -
            _sha256RoundConstants[14]) &
        _u32Mask);
    _expandSha256Schedule(words, 31);
    final working = _sha256Rounds(_sha256State, words, 14);
    return List.generate(8, (i) => (_sha256Initial[i] + working[i]) & _u32Mask);
  }

  static Uint8List _sha256Digest(Uint8List data) {
    if (data.length < 7) {
      throw ArgumentError('Token salt must contain at least 7 bytes');
    }
    final length = 57 + data.length;
    final zeroPadCount = (55 - length) % 64;
    final padded = BytesBuilder();
    padded.add(data.sublist(7));
    padded.addByte(0x80);
    padded.add(Uint8List(zeroPadCount < 0 ? zeroPadCount + 64 : zeroPadCount));

    final lenBytes = ByteData(8);
    lenBytes.setUint64(0, length * 8, Endian.big);
    padded.add(lenBytes.buffer.asUint8List());

    final paddedBytes = padded.toBytes();
    var state = _sha256Init(data.sublist(0, 7));
    final bd = ByteData.sublistView(paddedBytes);

    for (int offset = 0; offset < paddedBytes.length; offset += 64) {
      final words = <int>[];
      for (int i = 0; i < 64; i += 4) {
        words.add(bd.getUint32(offset + i, Endian.big));
      }
      _expandSha256Schedule(words);
      final working = _sha256Rounds(state, words);
      state = List.generate(8, (i) => (state[i] + working[i]) & _u32Mask);
    }

    final outBd = ByteData(32);
    for (int i = 0; i < 8; i++) {
      outBd.setUint32(i * 4, state[i], Endian.big);
    }
    return outBd.buffer.asUint8List();
  }

  static List<int> _cs64Digest(Uint8List data, Uint8List digest) {
    final bd = ByteData.sublistView(digest);
    int keyA = bd.getUint32(0, Endian.little) | 1;
    int keyB = bd.getUint32(4, Endian.little) | 1;

    final factors = [
      (keyA * _cs64Factor) & _u32Mask,
      (keyB * _cs64Factor) & _u32Mask,
    ];

    final terms = <int>[];
    final offsets = <int>[];

    for (int i = 0; i < _cs64Coefficients.length; i++) {
      terms.add((_cs64Coefficients[i][0] * factors[i % 2]) & _u32Mask);
      offsets.add(_cs64Coefficients[i][1]);
    }

    final inputData = Uint8List(data.length + 1);
    inputData.setRange(1, inputData.length, data);
    final words = _wordsLe4Even(inputData);

    for (int index = 0; index < words.length; index++) {
      final word = words[index];
      int term = (word * (index % 2 == 0 ? keyA : keyB)) & _u32Mask;
      int offset =
          (_rol16(word) * (index % 2 == 0 ? 0xEF0569FB : 0xC31713DB)) & _u32Mask;
      if (index == 0) {
        term = (term + _cs64Adjustment0 * factors[0]) & _u32Mask;
        offset = (offset + _cs64Adjustment1) & _u32Mask;
      }
      terms.add(term);
      offsets.add(offset);
    }

    int swapAcc = 0;
    int swapLast = 0;
    int state = 0;
    int acc = 0;

    for (int i = 0; i < terms.length; i += 2) {
      final x = terms[i];
      final y = terms[i + 1];

      int t = _rol16((offsets[i] + x) & _u32Mask);
      int q = (t * 0x76F50F34) & _u32Mask;
      swapAcc = (swapAcc + (_rol16(q) * 0xC3EFEA97 + q)) & _u32Mask;

      t = _rol16((offsets[i + 1] + y) & _u32Mask);
      q = (t * 0x1881CE3C) & _u32Mask;
      swapLast = ((_rol16(q) * 0x35BD1EC9) + q) & _u32Mask;
      swapAcc = (swapAcc + swapLast) & _u32Mask;

      state = (state * keyA + x) & _u32Mask;
      state = (_rol16(state) * 0xCF98B111) & _u32Mask;
      state = (_rol16(state) * 0x87085B9F) & _u32Mask;
      state = (_rol16(state) * 0x12CEB96D) & _u32Mask;
      state = (_rol16(state) * 0x257E1D83) & _u32Mask;
      acc = (acc + state) & _u32Mask;

      t = (state * keyB + y) & _u32Mask;
      t = (_rol16(t) * 0xA27416F5) & _u32Mask;
      t = (_rol16(t) * 0xD38396FF) & _u32Mask;
      state = (_rol16((_rol16(t) * 0x7C932B89) & _u32Mask) * 0xBFA49F69) &
          _u32Mask;
      acc = (acc + state) & _u32Mask;
    }

    return [swapLast ^ state, swapAcc ^ acc];
  }

  static String _generateSecMsGecV2() {
    double ticks = (DateTime.now().toUtc().millisecondsSinceEpoch / 1000.0) +
        _clockSkewSeconds;
    ticks += _winEpoch;
    ticks -= ticks % 300;
    ticks *= 1e7;

    final strToHash = '${ticks.toStringAsFixed(0)}$_trustedClientToken';
    final data = Uint8List.fromList(ascii.encode(strToHash));

    final digest = _sha256Digest(data);
    final cs64Words = _cs64Digest(data, digest);

    final cs64Bytes = ByteData(8);
    cs64Bytes.setUint32(0, cs64Words[0], Endian.little);
    cs64Bytes.setUint32(4, cs64Words[1], Endian.little);

    final cs64Hex = cs64Bytes.buffer
        .asUint8List()
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
    final sha256Hex = digest
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();

    return '$cs64Hex-$sha256Hex';
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static String _generateUuidHex() {
    final random = Random.secure();
    return List.generate(32, (_) => random.nextInt(16).toRadixString(16)).join();
  }

  static String _generateMuid() {
    final random = Random.secure();
    return List.generate(32, (_) => random.nextInt(16).toRadixString(16))
        .join()
        .toUpperCase();
  }

  static String _generateTimestamp() {
    final now = DateTime.now().toUtc();
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    final wd = weekdays[now.weekday - 1];
    final mo = months[now.month - 1];
    final d = now.day.toString().padLeft(2, '0');
    final h = now.hour.toString().padLeft(2, '0');
    final mi = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');

    return '$wd $mo $d ${now.year} $h:$mi:$s GMT+0000 (Coordinated Universal Time)';
  }

  static String get _timestampZ {
    final now = DateTime.now().toUtc();
    return '${now.toIso8601String().replaceAll('T', ' ').substring(0, 23)}Z';
  }

  static String _escapeXml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
