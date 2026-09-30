class VisualCueDetector {
  VisualCueDetector._();

  static const List<VisualCueRule> _rules = [
    // Cat / Kot / Gato
    VisualCueRule(
      emoji: '🐱',
      japaneseSubstrings: ['猫', 'ねこ'],
      latinWords: [
        'gato', 'gata', 'gatos', 'gatas', 'neko', 'cat', 'cats', 'kitten', 'kitty',
        'kot', 'kota', 'kotu', 'kotem', 'kocie', 'koty', 'kotów', 'kotami', 'kotek', 'kotka', 'kicia',
      ],
    ),
    // Hospital / Szpital / Byōin / Bioni
    VisualCueRule(
      emoji: '🏥',
      japaneseSubstrings: ['病院', 'びょういん'],
      latinWords: [
        'bioni', 'byoin', 'byōin', 'byouin', 'hospital', 'hospitales',
        'szpital', 'szpitala', 'szpitalu', 'szpitalem', 'szpitale', 'szpitali',
      ],
    ),
    // Dog / Pies / Perro
    VisualCueRule(
      emoji: '🐶',
      japaneseSubstrings: ['犬', 'いぬ'],
      latinWords: [
        'perro', 'perra', 'perros', 'perras', 'inu', 'dog', 'dogs', 'puppy',
        'pies', 'psa', 'psu', 'psem', 'psie', 'psy', 'psów', 'psami', 'piesek', 'pieska',
      ],
    ),
    // Bird / Ptak / Pájaro
    VisualCueRule(
      emoji: '🐦',
      japaneseSubstrings: ['鳥', 'とり'],
      latinWords: [
        'pajaro', 'pájaro', 'ave', 'ptak', 'ptaka', 'ptaki', 'ptakiem', 'bird', 'birds', 'tori',
      ],
    ),
    // Fish / Ryba / Pez
    VisualCueRule(
      emoji: '🐟',
      japaneseSubstrings: ['魚', 'さかな'],
      latinWords: [
        'pez', 'pescado', 'ryba', 'ryby', 'rybę', 'rybie', 'rybą', 'fish', 'sakana',
      ],
    ),
    // Coffee / Kawa
    VisualCueRule(
      emoji: '☕',
      japaneseSubstrings: ['コーヒー', '珈琲'],
      latinWords: [
        'cafe', 'café', 'kawa', 'kawy', 'kawie', 'kawę', 'kawą', 'coffee', 'koohii', 'kōhī', 'kohi',
      ],
    ),
    // Tea / Herbata / Ocha
    VisualCueRule(
      emoji: '🍵',
      japaneseSubstrings: ['お茶', '緑茶'],
      latinWords: [
        'herbata', 'herbaty', 'herbacie', 'herbatę', 'herbatą', 'tea', 'ocha', 'matcha',
      ],
    ),
    // Water / Woda / Agua / Mizu
    VisualCueRule(
      emoji: '💧',
      japaneseSubstrings: ['水', 'お水', 'みず'],
      latinWords: [
        'woda', 'wody', 'wodzie', 'wodę', 'wodą', 'water', 'agua', 'mizu',
      ],
    ),
    // Beer / Piwo / Cerveza
    VisualCueRule(
      emoji: '🍺',
      japaneseSubstrings: ['ビール'],
      latinWords: [
        'piwo', 'piwa', 'piwem', 'beer', 'cerveza', 'biiru', 'bīru',
      ],
    ),
    // Bread / Chleb / Pan
    VisualCueRule(
      emoji: '🍞',
      japaneseSubstrings: ['パン'],
      latinWords: [
        'chleb', 'chleba', 'chlebem', 'bread',
      ],
    ),
    // Apple / Jabłko / Manzana
    VisualCueRule(
      emoji: '🍎',
      japaneseSubstrings: ['りんご', 'リンゴ', '林檎'],
      latinWords: [
        'jabłko', 'jabłka', 'jabłkiem', 'apple', 'apples', 'manzana', 'ringo',
      ],
    ),
    // Rice / Meal / Ryż / Gohan
    VisualCueRule(
      emoji: '🍚',
      japaneseSubstrings: ['ご飯', 'ごはん', 'お米', '白米'],
      latinWords: [
        'ryż', 'ryżu', 'arroz', 'rice', 'gohan',
      ],
    ),
    // Meat / Mięso / Carne / Niku
    VisualCueRule(
      emoji: '🥩',
      japaneseSubstrings: ['肉', 'お肉', 'にく'],
      latinWords: [
        'mięso', 'mięsa', 'mięsem', 'meat', 'carne', 'niku',
      ],
    ),
    // Pizza
    VisualCueRule(
      emoji: '🍕',
      japaneseSubstrings: ['ピザ'],
      latinWords: [
        'pizza', 'pizzy', 'pizzę',
      ],
    ),
    // Eating / Restaurant / Jeść
    VisualCueRule(
      emoji: '🍽️',
      japaneseSubstrings: ['レストラン', '食べる', '食べます', '食事'],
      latinWords: [
        'restauracja', 'restauracji', 'restaurant', 'restaurante', 'resutoran',
        'jeść', 'jem', 'jemy', 'jedzenie', 'obiad', 'eat', 'eating', 'comer', 'taberu',
      ],
    ),
    // Drinking / Napój / Pić
    VisualCueRule(
      emoji: '🥤',
      japaneseSubstrings: ['飲む', '飲みます', 'ジュース'],
      latinWords: [
        'pić', 'piję', 'pijemy', 'napój', 'drink', 'drinking', 'beber', 'nomu',
      ],
    ),
    // Car / Samochód / Auto / Kuruma
    VisualCueRule(
      emoji: '🚗',
      japaneseSubstrings: ['車', 'くるま'],
      excludeJapaneseSubstrings: ['電車', '自転車'],
      latinWords: [
        'samochód', 'samochodu', 'samochodem', 'samochody', 'auto', 'auta', 'autem',
        'car', 'cars', 'coche', 'carro', 'kuruma',
      ],
    ),
    // Train / Pociąg / Densha
    VisualCueRule(
      emoji: '🚆',
      japaneseSubstrings: ['電車', '新幹線', 'でんしゃ'],
      latinWords: [
        'pociąg', 'pociągu', 'pociągiem', 'train', 'tren', 'densha', 'shinkansen',
      ],
    ),
    // Bus / Autobus
    VisualCueRule(
      emoji: '🚌',
      japaneseSubstrings: ['バス'],
      latinWords: [
        'autobus', 'autobusu', 'autobusem', 'bus', 'basu',
      ],
    ),
    // Bicycle / Rower / Jitensha
    VisualCueRule(
      emoji: '🚲',
      japaneseSubstrings: ['自転車', 'じてんしゃ'],
      latinWords: [
        'rower', 'roweru', 'rowerem', 'bicycle', 'bike', 'bicicleta', 'bici', 'jitensha',
      ],
    ),
    // Airplane / Airport / Samolot / Lotnisko
    VisualCueRule(
      emoji: '✈️',
      japaneseSubstrings: ['飛行機', '空港', 'ひこうき', 'くうこう'],
      latinWords: [
        'samolot', 'samolotu', 'samolotem', 'lotnisko', 'lotnisku', 'airplane', 'plane', 'airport',
        'avion', 'avión', 'aeropuerto', 'hikouki', 'hikōki', 'kuukou', 'kūkō',
      ],
    ),
    // House / Home / Dom / Ie
    VisualCueRule(
      emoji: '🏠',
      japaneseSubstrings: ['家', 'うち', 'いえ'],
      latinWords: [
        'dom', 'domu', 'domem', 'domy', 'domek', 'house', 'home', 'casa', 'uchi', 'ie',
      ],
    ),
    // School / Szkoła / Gakkō
    VisualCueRule(
      emoji: '🏫',
      japaneseSubstrings: ['学校', 'がっこう'],
      latinWords: [
        'szkoła', 'szkole', 'szkoły', 'szkołę', 'school', 'escuela', 'colegio', 'gakkou', 'gakkō', 'gakko',
      ],
    ),
    // Store / Shop / Sklep / Mise
    VisualCueRule(
      emoji: '🏪',
      japaneseSubstrings: ['店', 'お店', 'みせ', 'コンビニ'],
      latinWords: [
        'sklep', 'sklepie', 'sklepu', 'shop', 'store', 'tienda', 'mise', 'konbini',
      ],
    ),
    // Station / Stacja / Eki
    VisualCueRule(
      emoji: '🚉',
      japaneseSubstrings: ['駅', 'えき'],
      latinWords: [
        'stacja', 'stacji', 'dworzec', 'station', 'estacion', 'estación', 'eki',
      ],
    ),
    // Hotel
    VisualCueRule(
      emoji: '🏨',
      japaneseSubstrings: ['ホテル'],
      latinWords: [
        'hotel', 'hotelu', 'hotele', 'hoteru',
      ],
    ),
    // Bank
    VisualCueRule(
      emoji: '🏦',
      japaneseSubstrings: ['銀行', 'ぎんこう'],
      latinWords: [
        'bank', 'banku', 'banco', 'ginkou', 'ginkō', 'ginko',
      ],
    ),
    // Library / Biblioteka
    VisualCueRule(
      emoji: '📚',
      japaneseSubstrings: ['図書館', 'としょかん'],
      latinWords: [
        'biblioteka', 'bibliotece', 'library', 'biblioteca', 'toshokan',
      ],
    ),
    // Book / Książka / Hon
    VisualCueRule(
      emoji: '📖',
      japaneseSubstrings: ['本', 'ほん'],
      latinWords: [
        'książka', 'książki', 'książkę', 'książce', 'book', 'books', 'libro', 'hon',
      ],
    ),
    // Pharmacy / Medicine / Lek / Apteka
    VisualCueRule(
      emoji: '💊',
      japaneseSubstrings: ['薬局', '薬', 'くすり', 'やっきょく'],
      latinWords: [
        'apteka', 'aptece', 'lek', 'lekarstwo', 'leki', 'pharmacy', 'medicine',
        'farmacia', 'medicamento', 'kusuri', 'yakkyoku',
      ],
    ),
    // Phone / Telefon
    VisualCueRule(
      emoji: '📱',
      japaneseSubstrings: ['電話', 'スマホ', 'でんわ'],
      latinWords: [
        'telefon', 'telefonu', 'telefonem', 'smartfon', 'phone', 'smartphone',
        'telefono', 'teléfono', 'denwa', 'sumaho',
      ],
    ),
    // Computer / Komputer
    VisualCueRule(
      emoji: '💻',
      japaneseSubstrings: ['パソコン'],
      latinWords: [
        'komputer', 'komputera', 'laptop', 'computer', 'computadora', 'ordenador', 'pasokon',
      ],
    ),
    // Money / Pieniądze / Okane
    VisualCueRule(
      emoji: '💰',
      japaneseSubstrings: ['お金', 'おかね', '円'],
      latinWords: [
        'pieniądze', 'pieniędzy', 'pieniędzmi', 'money', 'dinero', 'okane',
      ],
    ),
    // Letter / List / Tegami
    VisualCueRule(
      emoji: '✉️',
      japaneseSubstrings: ['手紙', 'てがみ'],
      latinWords: [
        'list', 'listu', 'listem', 'letter', 'carta', 'tegami',
      ],
    ),
    // Music / Muzyka / Ongaku
    VisualCueRule(
      emoji: '🎵',
      japaneseSubstrings: ['音楽', 'おんがく', '歌', 'うた'],
      latinWords: [
        'muzyka', 'muzyki', 'muzykę', 'piosenka', 'music', 'musica', 'música', 'song', 'ongaku', 'uta',
      ],
    ),
    // Clock / Time / Czas / Zegarek
    VisualCueRule(
      emoji: '⏰',
      japaneseSubstrings: ['時計', '時間', 'とけい', 'じかん'],
      latinWords: [
        'zegarek', 'zegar', 'czas', 'godzina', 'time', 'clock', 'wristwatch', 'reloj', 'hora', 'tokei', 'jikan',
      ],
    ),
    // Sun / Słońce
    VisualCueRule(
      emoji: '☀️',
      japaneseSubstrings: ['太陽', 'たいよう'],
      latinWords: [
        'słońce', 'słońca', 'słonecznie', 'sun', 'sunny', 'sol', 'taiyou', 'taiyō',
      ],
    ),
    // Rain / Deszcz
    VisualCueRule(
      emoji: '🌧️',
      japaneseSubstrings: ['雨', 'あめ'],
      latinWords: [
        'deszcz', 'deszczu', 'pada', 'rain', 'rainy', 'lluvia', 'ame',
      ],
    ),
    // Snow / Śnieg
    VisualCueRule(
      emoji: '❄️',
      japaneseSubstrings: ['雪', 'ゆき'],
      latinWords: [
        'śnieg', 'śniegu', 'snow', 'snowy', 'nieve', 'yuki',
      ],
    ),
    // Flower / Kwiat / Sakura
    VisualCueRule(
      emoji: '🌸',
      japaneseSubstrings: ['花', 'お花', '桜', 'さくら'],
      latinWords: [
        'kwiat', 'kwiaty', 'kwiatów', 'sakura', 'flower', 'flowers', 'flor',
      ],
    ),
    // Tree / Forest / Drzewo / Las
    VisualCueRule(
      emoji: '🌳',
      japaneseSubstrings: ['木', '森', 'もり'],
      latinWords: [
        'drzewo', 'drzewa', 'las', 'tree', 'trees', 'forest', 'arbol', 'árbol', 'mori',
      ],
    ),
    // Sea / Beach / Morze
    VisualCueRule(
      emoji: '🌊',
      japaneseSubstrings: ['海', 'うみ'],
      latinWords: [
        'morze', 'morza', 'plaża', 'sea', 'ocean', 'beach', 'mar', 'playa', 'umi',
      ],
    ),
    // Mountain / Góra / Yama
    VisualCueRule(
      emoji: '⛰️',
      japaneseSubstrings: ['山', 'やま', '富士山'],
      latinWords: [
        'góra', 'góry', 'górach', 'mountain', 'mount', 'montaña', 'yama', 'fuji',
      ],
    ),
    // Key / Klucz / Kagi
    VisualCueRule(
      emoji: '🔑',
      japaneseSubstrings: ['鍵', 'かぎ'],
      latinWords: [
        'klucz', 'klucza', 'klucze', 'key', 'keys', 'llave', 'kagi',
      ],
    ),
    // Camera / Aparat / Kamera
    VisualCueRule(
      emoji: '📷',
      japaneseSubstrings: ['カメラ', 'かめら'],
      latinWords: [
        'aparat', 'kamera', 'camera', 'kamera',
      ],
    ),
    // Umbrella / Parasol / Kasa
    VisualCueRule(
      emoji: '☂️',
      japaneseSubstrings: ['傘', 'かさ'],
      latinWords: [
        'parasol', 'parasolka', 'umbrella', 'paraguas', 'kasa',
      ],
    ),
    // Photo / Zdjęcie / Shashin
    VisualCueRule(
      emoji: '📸',
      japaneseSubstrings: ['写真', 'しゃしん'],
      latinWords: [
        'zdjęcie', 'zdjęcia', 'fotografia', 'photo', 'photos', 'picture', 'shashin',
      ],
    ),
    // Window / Okno / Mado
    VisualCueRule(
      emoji: '🪟',
      japaneseSubstrings: ['窓', 'まど'],
      latinWords: [
        'okno', 'okna', 'window', 'ventana', 'mado',
      ],
    ),
    // Light / Światło / Denki
    VisualCueRule(
      emoji: '💡',
      japaneseSubstrings: ['電気', 'でんき'],
      latinWords: [
        'światło', 'prąd', 'elektryczność', 'light', 'electricity', 'luz', 'denki',
      ],
    ),
    // Pen / Długopis / Pióro
    VisualCueRule(
      emoji: '🖊️',
      japaneseSubstrings: ['ペン', 'ボールペン'],
      latinWords: [
        'długopis', 'pióro', 'pen', 'boligrafo', 'bolígrafo',
      ],
    ),
    // Scissors / Nożyczki / Hasami
    VisualCueRule(
      emoji: '✂️',
      japaneseSubstrings: ['はさみ', 'ハサミ', '鋏'],
      latinWords: [
        'nożyczki', 'scissors', 'tijeras', 'hasami',
      ],
    ),
    // Chair / Krzesło / Isu
    VisualCueRule(
      emoji: '🪑',
      japaneseSubstrings: ['椅子', 'いす'],
      latinWords: [
        'krzesło', 'krzesła', 'chair', 'silla', 'isu',
      ],
    ),
    // Desk / Biurko / Tsukue
    VisualCueRule(
      emoji: '🪵',
      japaneseSubstrings: ['机', 'つくえ'],
      latinWords: [
        'biurko', 'biurka', 'desk', 'tsukue',
      ],
    ),
    // Park / Kouen
    VisualCueRule(
      emoji: '🏞️',
      japaneseSubstrings: ['公園', 'こうえん'],
      latinWords: [
        'park', 'parku', 'kouen', 'kōen',
      ],
    ),
    // Subway / Metro / Chikatetsu
    VisualCueRule(
      emoji: '🚇',
      japaneseSubstrings: ['地下鉄', 'ちかてつ'],
      latinWords: [
        'metro', 'metrem', 'subway', 'chikatetsu',
      ],
    ),
    // Student / Uczeń / Gakusei
    VisualCueRule(
      emoji: '🎒',
      japaneseSubstrings: ['学生', 'がくせい'],
      latinWords: [
        'student', 'studenci', 'uczeń', 'gakusei', 'studentka',
      ],
    ),
    // Clothes / Ubranie / Fuku
    VisualCueRule(
      emoji: '👕',
      japaneseSubstrings: ['服', '洋服', 'ふく'],
      latinWords: [
        'ubranie', 'ubrania', 'clothes', 'clothing', 'ropa', 'fuku',
      ],
    ),
    // Dictionary / Słownik / Jisho
    VisualCueRule(
      emoji: '📕',
      japaneseSubstrings: ['辞書', 'じしょ'],
      latinWords: [
        'słownik', 'dictionary', 'diccionario', 'jisho',
      ],
    ),
    // Room / Pokój / Heya
    VisualCueRule(
      emoji: '🛋️',
      japaneseSubstrings: ['部屋', 'へや'],
      latinWords: [
        'pokój', 'pokoju', 'room', 'habitacion', 'habitación', 'heya',
      ],
    ),
    // Doctor / Lekarz
    VisualCueRule(
      emoji: '👨‍⚕️',
      japaneseSubstrings: ['医者', 'お医者さん', 'いしゃ'],
      latinWords: [
        'lekarz', 'lekarza', 'doktor', 'doctor', 'medico', 'médico', 'isha',
      ],
    ),
    // Teacher / Nauczyciel / Sensei
    VisualCueRule(
      emoji: '🧑‍🏫',
      japaneseSubstrings: ['先生', 'せんせい'],
      latinWords: [
        'nauczyciel', 'nauczyciela', 'profesor', 'teacher', 'sensei',
      ],
    ),
    // Friend / Przyjaciel / Tomodachi
    VisualCueRule(
      emoji: '👥',
      japaneseSubstrings: ['友達', 'ともだち'],
      latinWords: [
        'przyjaciel', 'przyjaciela', 'znajomy', 'friend', 'friends', 'amigo', 'amiga', 'tomodachi',
      ],
    ),
    // Sleep / Sen / Spać
    VisualCueRule(
      emoji: '😴',
      japaneseSubstrings: ['寝る', '寝ます', 'ねる', '眠る'],
      latinWords: [
        'spać', 'sen', 'śpię', 'zasnąć', 'sleep', 'sleeping', 'dormir', 'neru', 'nemuru',
      ],
    ),
    // Love / Like / Miłość
    VisualCueRule(
      emoji: '❤️',
      japaneseSubstrings: ['好き', '大好き', '愛', '愛してる', 'すき'],
      latinWords: [
        'kochać', 'miłość', 'lubić', 'uwielbiam', 'love', 'like', 'amor', 'amar', 'suki', 'daisuki',
      ],
    ),
  ];

  /// Detects visual cue emojis for a given sentence.
  /// If [explicitEmojis] is provided and non-empty, it is returned directly.
  /// Otherwise, searches through target, source, phonetic, and katakana texts.
  static List<String> detectEmojis({
    required String targetText,
    String? sourceText,
    String? phoneticReading,
    String? katakana,
    List<String>? explicitEmojis,
    int maxEmojis = 3,
  }) {
    if (explicitEmojis != null && explicitEmojis.isNotEmpty) {
      return explicitEmojis;
    }

    final combinedLatin = [
      sourceText ?? '',
      phoneticReading ?? '',
      targetText,
    ].join(' ');

    final latinWords = _extractLatinWords(combinedLatin);

    final japaneseHaystack = [
      targetText,
      katakana ?? '',
      phoneticReading ?? '',
    ].join(' ');

    final matched = <String>{};

    for (final rule in _rules) {
      if (matched.length >= maxEmojis) break;

      // 1. Check Japanese kanji/kana substrings
      var hit = false;
      for (final sub in rule.japaneseSubstrings) {
        if (japaneseHaystack.contains(sub)) {
          if (rule.excludeJapaneseSubstrings.isNotEmpty) {
            var remaining = japaneseHaystack;
            for (final exc in rule.excludeJapaneseSubstrings) {
              remaining = remaining.replaceAll(exc, '');
            }
            if (remaining.contains(sub)) {
              hit = true;
              break;
            }
          } else {
            hit = true;
            break;
          }
        }
      }

      // 2. Check Latin words
      if (!hit) {
        for (final word in rule.latinWords) {
          if (latinWords.contains(word)) {
            hit = true;
            break;
          }
        }
      }

      if (hit) {
        matched.add(rule.emoji);
      }
    }

    return matched.toList();
  }

  static Set<String> _extractLatinWords(String text) {
    final clean = text
        .toLowerCase()
        .replaceAll('ō', 'o')
        .replaceAll('ū', 'u')
        .replaceAll('ā', 'a')
        .replaceAll('ē', 'e')
        .replaceAll('ī', 'i');

    return clean
        .split(RegExp(r'[^a-ząćęłńóśźż0-9]+'))
        .where((w) => w.isNotEmpty)
        .toSet();
  }
}

class VisualCueRule {
  const VisualCueRule({
    required this.emoji,
    this.japaneseSubstrings = const [],
    this.latinWords = const [],
    this.excludeJapaneseSubstrings = const [],
  });

  final String emoji;
  final List<String> japaneseSubstrings;
  final List<String> latinWords;
  final List<String> excludeJapaneseSubstrings;
}
