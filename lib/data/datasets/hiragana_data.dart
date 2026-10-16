enum KanaGroup {
  seion,
  dakuon,
  yoon,
}

class KanaItem {
  const KanaItem({
    required this.kana,
    required this.romaji,
    required this.example,
    required this.group,
  });

  final String kana;
  final String romaji;
  final String example;
  final KanaGroup group;
}

class HiraganaData {
  static const List<KanaItem> seionList = [
    // Wiersz A
    KanaItem(kana: 'あ', romaji: 'a', example: 'あさ (asa) · rano', group: KanaGroup.seion),
    KanaItem(kana: 'い', romaji: 'i', example: 'いぬ (inu) · pies', group: KanaGroup.seion),
    KanaItem(kana: 'う', romaji: 'u', example: 'うみ (umi) · morze', group: KanaGroup.seion),
    KanaItem(kana: 'え', romaji: 'e', example: 'えき (eki) · stacja', group: KanaGroup.seion),
    KanaItem(kana: 'お', romaji: 'o', example: 'お茶 (ocha) · herbata', group: KanaGroup.seion),

    // Wiersz Ka
    KanaItem(kana: 'か', romaji: 'ka', example: 'かさ (kasa) · parasol', group: KanaGroup.seion),
    KanaItem(kana: 'き', romaji: 'ki', example: 'き (ki) · drzewo', group: KanaGroup.seion),
    KanaItem(kana: 'く', romaji: 'ku', example: 'くるま (kuruma) · auto', group: KanaGroup.seion),
    KanaItem(kana: 'け', romaji: 'ke', example: 'けさ (kesa) · dziś rano', group: KanaGroup.seion),
    KanaItem(kana: 'こ', romaji: 'ko', example: 'こども (kodomo) · dziecko', group: KanaGroup.seion),

    // Wiersz Sa
    KanaItem(kana: 'さ', romaji: 'sa', example: 'さくら (sakura) · wiśnia', group: KanaGroup.seion),
    KanaItem(kana: 'し', romaji: 'shi', example: 'しろ (shiro) · biały', group: KanaGroup.seion),
    KanaItem(kana: 'す', romaji: 'su', example: 'すし (sushi) · sushi', group: KanaGroup.seion),
    KanaItem(kana: 'せ', romaji: 'se', example: 'せんせい (sensei) · nauczyciel', group: KanaGroup.seion),
    KanaItem(kana: 'そ', romaji: 'so', example: 'そら (sora) · niebo', group: KanaGroup.seion),

    // Wiersz Ta
    KanaItem(kana: 'た', romaji: 'ta', example: 'たまご (tamago) · jajko', group: KanaGroup.seion),
    KanaItem(kana: 'ち', romaji: 'chi', example: 'ちち (chichi) · ojciec', group: KanaGroup.seion),
    KanaItem(kana: 'つ', romaji: 'tsu', example: 'つき (tsuki) · księżyc', group: KanaGroup.seion),
    KanaItem(kana: 'て', romaji: 'te', example: 'て (te) · ręka', group: KanaGroup.seion),
    KanaItem(kana: 'と', romaji: 'to', example: 'ともだち (tomodachi) · przyjaciel', group: KanaGroup.seion),

    // Wiersz Na
    KanaItem(kana: 'な', romaji: 'na', example: 'なつ (natsu) · lato', group: KanaGroup.seion),
    KanaItem(kana: 'に', romaji: 'ni', example: 'にほん (nihon) · Japonia', group: KanaGroup.seion),
    KanaItem(kana: 'ぬ', romaji: 'nu', example: 'ぬいぐるみ (nuigurumi) · maskotka', group: KanaGroup.seion),
    KanaItem(kana: 'ね', romaji: 'ne', example: 'ねこ (neko) · kot', group: KanaGroup.seion),
    KanaItem(kana: 'の', romaji: 'no', example: 'のみもの (nomimono) · napój', group: KanaGroup.seion),

    // Wiersz Ha
    KanaItem(kana: 'は', romaji: 'ha', example: 'はな (hana) · kwiat', group: KanaGroup.seion),
    KanaItem(kana: 'ひ', romaji: 'hi', example: 'ひと (hito) · człowiek', group: KanaGroup.seion),
    KanaItem(kana: 'ふ', romaji: 'fu', example: 'ふゆ (fuyu) · zima', group: KanaGroup.seion),
    KanaItem(kana: 'へ', romaji: 'he', example: 'へや (heya) · pokój', group: KanaGroup.seion),
    KanaItem(kana: 'ほ', romaji: 'ho', example: 'ほん (hon) · książka', group: KanaGroup.seion),

    // Wiersz Ma
    KanaItem(kana: 'ま', romaji: 'ma', example: 'まち (machi) · miasto', group: KanaGroup.seion),
    KanaItem(kana: 'み', romaji: 'mi', example: 'みず (mizu) · woda', group: KanaGroup.seion),
    KanaItem(kana: 'む', romaji: 'mu', example: 'むし (mushi) · owad', group: KanaGroup.seion),
    KanaItem(kana: 'め', romaji: 'me', example: 'め (me) · oko', group: KanaGroup.seion),
    KanaItem(kana: 'も', romaji: 'mo', example: 'もり (mori) · las', group: KanaGroup.seion),

    // Wiersz Ya
    KanaItem(kana: 'や', romaji: 'ya', example: 'やま (yama) · góra', group: KanaGroup.seion),
    KanaItem(kana: 'ゆ', romaji: 'yu', example: 'ゆき (yuki) · śnieg', group: KanaGroup.seion),
    KanaItem(kana: 'よ', romaji: 'yo', example: 'よる (yoru) · noc', group: KanaGroup.seion),

    // Wiersz Ra
    KanaItem(kana: 'ら', romaji: 'ra', example: 'らいおん (raion) · lew', group: KanaGroup.seion),
    KanaItem(kana: 'り', romaji: 'ri', example: 'りんご (ringo) · jabłko', group: KanaGroup.seion),
    KanaItem(kana: 'る', romaji: 'ru', example: 'くるま (kuruma) · samochód', group: KanaGroup.seion),
    KanaItem(kana: 'れ', romaji: 're', example: 'れきし (rekishi) · historia', group: KanaGroup.seion),
    KanaItem(kana: 'ろ', romaji: 'ro', example: 'ろうそく (rousoku) · świeca', group: KanaGroup.seion),

    // Wiersz Wa i N
    KanaItem(kana: 'わ', romaji: 'wa', example: 'わたし (watashi) · ja', group: KanaGroup.seion),
    KanaItem(kana: 'を', romaji: 'wo', example: 'ほんをよむ · partykuła biernika', group: KanaGroup.seion),
    KanaItem(kana: 'ん', romaji: 'n', example: 'ほん (hon) · książka', group: KanaGroup.seion),
  ];

  static const List<KanaItem> dakuonList = [
    // Ga
    KanaItem(kana: 'が', romaji: 'ga', example: 'がっこう (gakkou) · szkoła', group: KanaGroup.dakuon),
    KanaItem(kana: 'ぎ', romaji: 'gi', example: 'ぎんこう (ginkou) · bank', group: KanaGroup.dakuon),
    KanaItem(kana: 'ぐ', romaji: 'gu', example: 'ぐらい (gurai) · około', group: KanaGroup.dakuon),
    KanaItem(kana: 'げ', romaji: 'ge', example: 'げんき (genki) · zdrowy', group: KanaGroup.dakuon),
    KanaItem(kana: 'ご', romaji: 'go', example: 'ごはん (gohan) · ryż / posiłek', group: KanaGroup.dakuon),

    // Za
    KanaItem(kana: 'ざ', romaji: 'za', example: 'ざっし (zasshi) · magazyn', group: KanaGroup.dakuon),
    KanaItem(kana: 'じ', romaji: 'ji', example: 'じかん (jikan) · czas', group: KanaGroup.dakuon),
    KanaItem(kana: 'ず', romaji: 'zu', example: 'ちず (chizu) · mapa', group: KanaGroup.dakuon),
    KanaItem(kana: 'ぜ', romaji: 'ze', example: 'ぜんぶ (zenbu) · wszystko', group: KanaGroup.dakuon),
    KanaItem(kana: 'ぞ', romaji: 'zo', example: 'ぞう (zou) · słoń', group: KanaGroup.dakuon),

    // Da
    KanaItem(kana: 'だ', romaji: 'da', example: 'だいがく (daigaku) · uniwersytet', group: KanaGroup.dakuon),
    KanaItem(kana: 'ぢ', romaji: 'ji', example: 'はなぢ (hanaji) · krwotok z nosa', group: KanaGroup.dakuon),
    KanaItem(kana: 'づ', romaji: 'zu', example: 'つづく (tsuzuku) · trwać', group: KanaGroup.dakuon),
    KanaItem(kana: 'で', romaji: 'de', example: 'でんしゃ (densha) · pociąg', group: KanaGroup.dakuon),
    KanaItem(kana: 'ど', romaji: 'do', example: 'どこ (doko) · gdzie', group: KanaGroup.dakuon),

    // Ba
    KanaItem(kana: 'ば', romaji: 'ba', example: 'ばんごはん (bangohan) · kolacja', group: KanaGroup.dakuon),
    KanaItem(kana: 'び', romaji: 'bi', example: 'びょういん (byouin) · szpital', group: KanaGroup.dakuon),
    KanaItem(kana: 'ぶ', romaji: 'bu', example: 'ぶんしょう (bunshou) · zdanie', group: KanaGroup.dakuon),
    KanaItem(kana: 'べ', romaji: 'be', example: 'べんきょう (benkyou) · nauka', group: KanaGroup.dakuon),
    KanaItem(kana: 'ぼ', romaji: 'bo', example: 'ぼうし (boushi) · czapka', group: KanaGroup.dakuon),

    // Pa (Handakuon)
    KanaItem(kana: 'ぱ', romaji: 'pa', example: 'ぱん (pan) · chleb', group: KanaGroup.dakuon),
    KanaItem(kana: 'ぴ', romaji: 'pi', example: 'ぴかぴか (pikapika) · błyszczący', group: KanaGroup.dakuon),
    KanaItem(kana: 'ぷ', romaji: 'pu', example: 'ぷりん (purin) · budyń', group: KanaGroup.dakuon),
    KanaItem(kana: 'ぺ', romaji: 'pe', example: 'ぺん (pen) · długopis', group: KanaGroup.dakuon),
    KanaItem(kana: 'ぽ', romaji: 'po', example: 'ぽすと (posuto) · skrzynka', group: KanaGroup.dakuon),
  ];

  static const List<KanaItem> yoonList = [
    KanaItem(kana: 'きゃ', romaji: 'kya', example: 'きゃく (kyaku) · gość', group: KanaGroup.yoon),
    KanaItem(kana: 'きゅ', romaji: 'kyu', example: 'きゅう (kyuu) · dziewięć', group: KanaGroup.yoon),
    KanaItem(kana: 'きょ', romaji: 'kyo', example: 'きょう (kyou) · dzisiaj', group: KanaGroup.yoon),

    KanaItem(kana: 'しゃ', romaji: 'sha', example: 'しゃしん (shashin) · zdjęcie', group: KanaGroup.yoon),
    KanaItem(kana: 'しゅ', romaji: 'shu', example: 'しゅくだい (shukudai) · zadanie', group: KanaGroup.yoon),
    KanaItem(kana: 'しょ', romaji: 'sho', example: 'しょくどう (shokudou) · stołówka', group: KanaGroup.yoon),

    KanaItem(kana: 'ちゃ', romaji: 'cha', example: 'おちゃ (ocha) · herbata', group: KanaGroup.yoon),
    KanaItem(kana: 'ちゅ', romaji: 'chu', example: 'ちゅうごく (chuugoku) · Chiny', group: KanaGroup.yoon),
    KanaItem(kana: 'ちょ', romaji: 'cho', example: 'ちょっと (chotto) · chwilkę / trochę', group: KanaGroup.yoon),

    KanaItem(kana: 'にゃ', romaji: 'nya', example: 'にゃー (nyaa) · miau', group: KanaGroup.yoon),
    KanaItem(kana: 'にゅ', romaji: 'nyu', example: 'ぎゅうにゅう (gyuunyuu) · mleko', group: KanaGroup.yoon),
    KanaItem(kana: 'にょ', romaji: 'nyo', example: 'にょろにょろ · wijący się', group: KanaGroup.yoon),

    KanaItem(kana: 'ひゃ', romaji: 'hya', example: 'ひゃく (hyaku) · sto', group: KanaGroup.yoon),
    KanaItem(kana: 'ひゅ', romaji: 'hyu', example: 'ひゅうひゅう · świst wiatru', group: KanaGroup.yoon),
    KanaItem(kana: 'ひょ', romaji: 'hyo', example: 'ひょう (hyou) · tabela', group: KanaGroup.yoon),

    KanaItem(kana: 'みゃ', romaji: 'mya', example: 'みゃく (myaku) · puls', group: KanaGroup.yoon),
    KanaItem(kana: 'みゅ', romaji: 'myu', example: 'みゅーじかる · musical', group: KanaGroup.yoon),
    KanaItem(kana: 'みょ', romaji: 'myo', example: 'みょうじ (myouji) · nazwisko', group: KanaGroup.yoon),

    KanaItem(kana: 'りゃ', romaji: 'rya', example: 'りゃく (ryaku) · skrót', group: KanaGroup.yoon),
    KanaItem(kana: 'りゅ', romaji: 'ryu', example: 'りゅうがく (ryuugaku) · studia za granicą', group: KanaGroup.yoon),
    KanaItem(kana: 'りょ', romaji: 'ryo', example: 'りょこう (ryokou) · podróż', group: KanaGroup.yoon),

    KanaItem(kana: 'ぎゃ', romaji: 'gya', example: 'ぎゃく (gyaku) · odwrotnie', group: KanaGroup.yoon),
    KanaItem(kana: 'ぎゅ', romaji: 'gyu', example: 'ぎゅうにく (gyuuniku) · wołowina', group: KanaGroup.yoon),
    KanaItem(kana: 'ぎょ', romaji: 'gyo', example: 'ぎょぎょう (gyogyou) · rybołówstwo', group: KanaGroup.yoon),

    KanaItem(kana: 'じゃ', romaji: 'ja', example: 'じゃあ (jaa) · a więc', group: KanaGroup.yoon),
    KanaItem(kana: 'じゅ', romaji: 'ju', example: 'じゅぎょう (jugyou) · lekcja', group: KanaGroup.yoon),
    KanaItem(kana: 'じょ', romaji: 'jo', example: 'じょせい (josei) · kobieta', group: KanaGroup.yoon),

    KanaItem(kana: 'びゃ', romaji: 'bya', example: 'さんびゃく (sanbyaku) · trzysta', group: KanaGroup.yoon),
    KanaItem(kana: 'びゅ', romaji: 'byu', example: 'びゅーてぃー · beauty', group: KanaGroup.yoon),
    KanaItem(kana: 'びょ', romaji: 'byo', example: 'びょういん (byouin) · szpital', group: KanaGroup.yoon),

    KanaItem(kana: 'ぴゃ', romaji: 'pya', example: 'ろっぴゃく (roppyaku) · sześćset', group: KanaGroup.yoon),
    KanaItem(kana: 'ぴゅ', romaji: 'pyu', example: 'ぴゅー · psszt', group: KanaGroup.yoon),
    KanaItem(kana: 'ぴょ', romaji: 'pyo', example: 'ぴょんぴょん · skakanie', group: KanaGroup.yoon),
  ];
}
