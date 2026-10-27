// Language Islands Guide - Interactive & i18n Controller

const translations = {
  ja: {
    // Navigation
    navBrand: "Language Islands",
    navSub: "iPhone導入ガイド",
    navWhy: "概要",
    navSideStore: "SideStore導入",
    navAppInstall: "アプリ入手",
    navPolishConfig: "ポーランド語設定",
    navExchange: "フレーズ交換",
    navVersions: "リリース一覧",
    navFaq: "FAQ",
    viewAllVersionsBtn: "📦 バージョン一覧・詳細はこちら ↗",
    versionCardTitle: "現在の最新版: v1.0.0 (安定版)",
    versionCardDesc: "こはるちゃん専用の語学交換機能・ポーランド語ニューラル音声・カタカナ発音補助を搭載。",

    // Hero
    heroBadge: "🌸 こはるちゃんへ贈る特別ガイド",
    heroTitle: "iPhoneで始める<br><span class=\"highlight\">ポーランド語 & 日本語</span> 相互学習",
    heroDesc: "公式App Storeにはない、私たち2人だけの特製語学学習アプリ「Language Islands」。SideStoreを使ってiPhoneに無料でインストールし、毎日フレーズを交換しながら楽しく学べるまでの全手順をまとめました。",
    
    // Personal Letter
    letterHeader: "💌 Jakubからこはるちゃんへ",
    letterBody: "「こはるちゃん、こんにちは！私たちが一緒にポーランド語と日本語を学び合えるアプリを作りました。私のアプリにはこはるちゃんが教えてくれた日本語が表示され、こはるちゃんのアプリには私が作ったポーランド語（ネイティブ音声＆カタカナ発音付き）が届きます！最初の設定だけ少し手順がありますが、このページを見ながら進めれば大丈夫です。一緒に頑張ろうね！」",
    letterSign: "— Jakub より",

    // Checklist Progress
    progressTitle: "設定ステップ完了度",
    step1Check: "1. LocalDevVPN & SideStore 導入",
    step2Check: "2. アプリ (Runner.ipa) インストール",
    step3Check: "3. ポーランド語 (Polski) 学習設定",
    step4Check: "4. 文の共有 (Gist) 接続完了",

    // Two-Way Learning Box
    twoWayTitle: "アプリで実現する2人の学習交換",
    twoWayFriendTitle: "こはるちゃん (Koharu)",
    twoWayFriendTarget: "🇵🇱 ポーランド語を学習",
    twoWayFriendF1: "ネイティブのポーランド語音声（Marek / Zofia）",
    twoWayFriendF2: "難しい発音も安心な「カタカナ読み補助」",
    twoWayFriendF3: "シャドーイング＆アクティブリコール特訓",
    twoWayFriendF4: "ワンタップでJakubへ日本語フレーズを送信！",

    twoWayJakubTitle: "Jakub (Poland)",
    twoWayJakubTarget: "🇯🇵 日本語を学習",
    twoWayJakubF1: "こはるちゃんが送信した日常の日本語を練習",
    twoWayJakubF2: "漢字・カタカナ・ローマ字対応",
    twoWayJakubF3: "こはるちゃんが学ぶためのポーランド語文を作成して送信",

    twoWayCenterBadge: "Gistで双方向同期",

    // Section 1: Why SideStore
    sec1Tag: "OVERVIEW",
    sec1Title: "SideStore（サイドストア）とは？ なぜ必要なの？",
    sec1Desc: "Appleの公式App Storeは、年間約15,000円の開発者登録費や審査が必要です。個人間のプライベートアプリをiPhoneに入れるため、Apple公式の仕組みを利用した「サイドローディング（SideStore）」を使用します。",
    sec1SafeTitle: "安全性について安心してください",
    sec1SafeBody: "脱獄（Jailbreak）ではありません。Appleが公式に提供している個人デベロッパ証明書を使って、あなたのiPhoneだけに直接署名してインストールする完全合法かつ安全な方法です。",
    sec1Feature1Title: "PC不要でワイヤレス更新",
    sec1Feature1Desc: "最初の1回だけPCを使えば、以後はiPhone内のLocalDevVPNを使ってどこでもワイヤレス更新できます（iTunesやiCloudのインストールも一切不要です！）。",

    // Section 2: SideStore Setup
    sec2Tag: "STEP 1",
    sec2Title: "SideStoreの初期セットアップ（最初の1回のみ）",
    sec2Desc: "初回のみ、パソコン（Windows または Mac）を使ってSideStoreをiPhoneに転送します。iTunesやiCloudは不要で、約10分で完了します。",
    prepTitle: "準備するもの",
    prepItem1: "お使いのiPhone（iOS 14以降、iOS 16/17/18対応）",
    prepItem2: "パソコン（Windows または Mac）※初回1回のみ使用（iTunes/iCloudは不要！）",
    prepItem3: "iPhoneとPCを繋ぐUSBケーブル",
    prepItem4: "Apple ID（普段お使いのものでOK）",

    step11Title: "iPhoneに「LocalDevVPN」をインストール（App Store）",
    step11Desc: "SideStoreがiPhone単体でアプリをワイヤレス更新できるように、App Store公式の「LocalDevVPN」を使用します。設定ファイルのダウンロードは不要です！",
    vpnAppStoreBtn: "App StoreでLocalDevVPNを入手 ↗",
    vpnConnectNote: "インストール後、LocalDevVPNを開いて「Connect」をタップし、iOSのVPN構成追加ポップアップで「許可」を選択してパスコードを入力します。",

    step12Title: "iPhoneの「デベロッパモード」をONにする（iOS 16以降）",
    step12Desc: "iOS 16、17、18をお使いの場合、外部アプリの起動を許可するモードを有効にします。",
    devModePath: "設定 → プライバシーとセキュリティ → デベロッパモード",
    devModeNote: "スイッチをONにするとiPhoneの再起動を求められます。再起動後に「オンにする」をタップし、パスコードを入力すれば完了です。",

    step13Title: "パソコンで「iloader」を使ってSideStoreを導入",
    winTab: "Windows の場合",
    macTab: "Mac の場合",
    winStep1: "1. <strong>iloader (Windows版 .msi)</strong> をダウンロードしてインストールします（<strong>iTunesやiCloudのインストールは一切不要です！</strong>）。",
    winStep2: "2. iPhoneをUSBケーブルでPCに接続し、iPhone画面で「このコンピュータを信頼する」をタップします。",
    winStep3: "3. iloaderを起動し、お使いの<strong>Apple ID</strong>でサインインします（※メールアドレスの大文字・小文字は正確に入力してください）。",
    winStep4: "4. 接続されたiPhoneを選択し、<strong>「Install SideStore (Stable)」</strong>をクリックします。自動的にSideStoreがiPhoneに転送されます！",
    macStep1: "1. <strong>iloader (macOS版 .dmg)</strong> をダウンロードし、「アプリケーション」フォルダへ移動して起動します（iTunes/iCloud不要）。",
    macStep2: "2. iPhoneをケーブルでMacに接続し、FinderまたはiPhone画面で「信頼」をタップします。",
    macStep3: "3. iloaderでお使いの<strong>Apple ID</strong>でサインインします（※メールアドレスは大文字・小文字を区別します）。",
    macStep4: "4. 接続されたiPhoneを選択し、<strong>「Install SideStore (Stable)」</strong>をクリックします。",

    step14Title: "iPhoneでデベロッパアプリを「信頼」する",
    trustPath: "設定 → 一般 → VPNとデバイス管理 → デベロッパApp (あなたのApple ID)",
    trustNote: "「（Apple ID）を信頼」をタップして確認を押します。これでSideStoreが起動できるようになります！",

    step15Title: "SideStoreの初期起動＆セットアップ完了",
    step15Desc: "<strong>LocalDevVPN</strong>を開いて「Connect」をタップした状態で、<strong>SideStore</strong>を開きます。Apple IDでサインインし、「My Apps」画面の<strong>「7 DAYS」</strong>カウンターをタップして初回の更新を完了させます。",

    // Section 3: App Install
    sec3Tag: "STEP 2",
    sec3Title: "アプリ（Language Islands）をiPhoneにインストール",
    sec3Desc: "SideStoreの準備ができたら、いよいよアプリ本体（Runner.ipa）をインストールします。",
    downloadIpaBtn: "Runner.ipa (最新版アプリ) をダウンロード",
    appInstallStep1: "1. iPhoneのSafariで上記の「Runner.ipa をダウンロード」ボタンをタップします。",
    appInstallStep2: "2. <strong>LocalDevVPN</strong> アプリを開き、接続中（Connected / 画面上のVPNアイコン）になっていることを確認します。",
    appInstallStep3: "3. <strong>SideStore</strong> を開き、下の「My Apps」タブを表示します。",
    appInstallStep4: "4. 左上の <strong>「＋」</strong> アイコンをタップし、先ほどダウンロードした <code>Runner.ipa</code> を選択します。",
    appInstallStep5: "5. インストールが進行し、完了するとiPhoneのホーム画面に <strong>Language Islands</strong> のアイコンが追加されます！🎉",
    weeklyRefreshTitle: "💡 週に1回のリフレッシュについて（5秒で完了）",
    weeklyRefreshDesc: "無料のApple IDで入れたアプリは7日間の有効期限があります。期限が切れる前に、iPhoneで「LocalDevVPNをON」にし、「SideStoreを開いて Refresh All を押す」だけで自動延長されます（PCはもう不要です！）。",

    // Section 4: Polish Config
    sec4Tag: "STEP 3",
    sec4Title: "アプリで「ポーランド語学習」を設定する",
    sec4Desc: "アプリを起動したら、あなたがポーランド語を学べるように学習言語（Target Language）を設定します。",
    polishStep1: "1. iPhoneのホーム画面から <strong>Language Islands</strong> をタップして開きます。",
    polishStep2: "2. 画面右上にある <strong>3つの点メニュー「︙」</strong> をタップします。",
    polishStep3: "3. メニューから <strong>「Język nauki (docelowy)」(学習言語の選択)</strong> をタップします。",
    polishStep4: "4. 一覧から <strong>「🇵🇱 Polski (Marek / Zofia - Polish Neural)」</strong> を選択します。",
    polishStep5: "5. これでターゲット言語がポーランド語に切り替わります！",
    
    practiceHowToTitle: "どうやって勉強するの？",
    shadowingTitle: "🎧 シャドーイング（Shadowing）モード",
    shadowingDesc: "ポーランド語の音声が流れます。耳で聴きながら声に出して真似しましょう。文の下に <strong>カタカナ読み補助</strong>（例: 「チェシチ！ヤク シェ マシュ？」）が表示されるので、難しい発音も一目でわかります！",
    recallTitle: "🧠 アクティブリコール（Active Recall）モード",
    recallDesc: "日本語の意味が表示されます。それを声に出してポーランド語で言ってみてください。カードをタップするとポーランド語の正解とネイティブ音声が再生され、1〜5つ星で自己評価できます。",

    // Section 5: Sentence Exchange
    sec5Tag: "STEP 4",
    sec5Title: "文の共有・送受信設定（Gistでつながる）",
    sec5Desc: "あなたとJakubのアプリをGitHub Gistで連携させます。これであなたが送った日本語がJakubのアプリに届き、Jakubが作ったポーランド語があなたのアプリに届きます！",
    
    syncSetupTitle: "1. 共有データベース（Gist）の接続・受信設定",
    syncStep1: "1. アプリ右上の <strong>「︙」</strong> メニューをタップします。",
    syncStep2: "2. <strong>「Zdalna baza zdań / Synchronizacja」</strong>（雲の同期アイコン）をタップします。",
    syncStep3: "3. <strong>「Adres URL bazy danych / JSON」</strong> の入力欄を設定します：",
    syncQuickBtnTitle: "【最速・ワンタップ入力】",
    syncQuickBtnDesc: "URL入力欄のすぐ下にある紫色のボタン <code>✨ Wstaw domyślny wspólny Gist (Jakub & Przyjaciółka)</code> をタップするだけで、共有Gistのアドレスが一瞬で自動入力されます！",
    syncManualHint: "または、以下の共有URLをコピーして直接貼り付けることもできます：",
    copyGistBtn: "Gist URLをコピー",
    syncApiKeyHintTitle: "【Klucz API / Token autoryzacji 欄について】",
    syncApiKeyHint: "Jakubからのレッスンを受信・閲覧・同期するだけなら、この欄は <strong>【空欄（空っぽ）】</strong> のままで大丈夫です！（パスワード不要で誰でもダウンロードできます）",
    syncStep4: "4. <strong>「起動時に自動同期」</strong>（Auto-sync on startup）のスイッチをONにします。",
    syncStep5: "5. <strong>「今すぐ同期」</strong>（Synchronizuj teraz）をタップします。これでJakubがこはるちゃんのために作ったポーランド語レッスンが一気に届きます！🎉",

    sendPhraseTitle: "2. こはるちゃんからJakubへ「日本語フレーズ」を送る方法",
    sendIntro: "Jakubに勉強してほしい日常会話や好きな表現をいつでも送れます！",
    sendStep1: "1. 画面右下のピンクのハートボタン <strong>「＋」</strong> または右上のメニュー「︙」から <strong>「Dla Jakuba / Jakubへフレーズを送る」</strong> をタップします。",
    sendStep2: "2. 上部の切替タブが <strong>「🇯🇵 日本語 (Dla Jakuba)」</strong> になっていることを確認します。",
    sendStep3: "3. 以下の項目を入力します：",
    sendF1: "・ <strong>1. 日本語（漢字・ひらがな）</strong>：例「これ、すごく美味しいよ！」",
    sendF2: "・ <strong>2. カタカナ読み</strong>：例「コレ、スゴク オイシイ ヨ！」",
    sendF3: "・ <strong>3. ローマ字 (Rōmaji)</strong>：例「Kore, sugoku oishii yo!」",
    sendF4: "・ <strong>4. 意味・メモ (Znaczenie)</strong>：例「To jest naprawdę pyszne! / This is so delicious!」",
    sendF5: "・ <strong>5. メモ・使い方（任意）</strong>：例「食事の時に使うカジュアルな表現」",
    sendTokenTitle: "【初回のみ】フレーズ送信の接続設定（GitHub Token）",
    sendTokenDesc: "Gistへ新しい文を追加（送信）するには書き込み権限が必要です。フォーム内の「GitHub Gist設定 (Prywatne połączenie)」を開き：<br>・<strong>Gist URL</strong>: <code>共通Gistアドレスを自動入力</code> をタップ<br>・<strong>GitHub Token</strong>: Jakubから受け取った専用のGitHubトークン（PAT）を入力して「設定を保存」します。",
    sendStep4: "4. 画面下の <strong>「送信 & 保存 (Wyślij do GitHuba i Zapisz)」</strong> ボタンをタップします！",
    sendResult: "これだけで共有データベースに送信され、Jakubがアプリを開いたときに自動的にこはるちゃんの日本語フレーズが学習リストに加わります！🌸",

    // Mockup Section
    mockupTitle: "アプリの画面プレビュー",
    mockTab1: "学習カード（ポーランド語）",
    mockTab2: "Jakubへフレーズ送信画面",
    mockTab3: "リモート同期画面",

    // FAQ Section
    faqTitle: "よくある質問・トラブルシューティング",
    faqQ1: "SideStoreで「Cannot connect to SideServer / Device」などの接続エラーが出ます",
    faqA1: "LocalDevVPNアプリを開き、VPNが接続中（Connected / 画面上にVPNアイコン表示）になっていることを確認してください。VPNが切れているとSideStoreは動作しません。",
    faqQ2: "アプリを開こうとすると「信頼されていない開発元」と出ます",
    faqA2: "iPhoneの「設定」→「一般」→「VPNとデバイス管理」を開き、あなたのApple IDをタップして「信頼」を押してください。",
    faqQ3: "音声が再生されません",
    faqA3: "iPhone本体の左側面にある着信/消音スイッチ（マナーモード）が消音（オレンジ色）になっていないか、音量がゼロになっていないか確認してください。",
    faqQ4: "7日経つとアプリが消えてしまいますか？",
    faqA4: "消えません！学習データや送った文もすべてiPhone内に安全に残ります。LocalDevVPNをONにしてSideStoreで「Refresh All」を押せば、いつでもすぐに復活します。",
    faqQ5: "新しいバージョンが出たときはどうすればいいですか？",
    faqA5: "新しい「Runner.ipa」をダウンロードし、SideStoreの「＋」ボタンから追加で読み込むだけです。これまでのデータは消えずにそのままアップデートされます。",

    // Resource Hub
    resourceTitle: "ダウンロード＆リンク集",
    resVpnTitle: "LocalDevVPN (iOS)",
    resVpnDesc: "App Store公式のSideStore用VPNアプリ（設定ファイル不要）",
    resAppTitle: "Language Islands IPA",
    resAppDesc: "最新のRunner.ipaアプリ本体",
    resIloaderWin: "iloader (Windows)",
    resIloaderWinDesc: "iTunes/iCloud不要の最新インストーラー (.msi)",
    resIloaderMac: "iloader (macOS)",
    resIloaderMacDesc: "Mac用公式インストーラー (.dmg)",

    // Releases Page
    relPageTitle: "Language Islands • バージョン一覧 & IPAダウンロード",
    relNavHome: "ガイドTOP",
    relNavSideStore: "SideStore導入",
    relNavVersions: "リリース一覧",
    relHeroBadge: "🌸 アプリ配布・バージョン一覧",
    relHeroTitle: "Language Islands<br><span class=\"highlight\">IPA ダウンロード</span>",
    relHeroDesc: "SideStoreを使ってiPhoneにインストールできる `Runner.ipa` の配布ページです。こはるちゃんのiPhoneから直接ワンタップで最新版や過去バージョンをダウンロードできます。",
    relLatestBadge: "🌸 最新安定版 (Recommended)",
    relV120Title: "Language Islands v1.2.0",
    relV120Date: "2026年10月28日 公開 • ビルド #3",
    rel120F1: "🎙️ <strong>双方向音声録音（Koharu & Jakub）</strong>：外部録音ツール不要！こはるちゃんは日本語、Jakubはポーランド語の生の声を直接アプリ内で録音",
    rel120F2: "☁️ <strong>GitHub Gist 音声自動同期（Base64）</strong>：録音した高音質AAC音声を自動圧縮してGist経由で2人のiPhoneに即座に相互配信",
    rel120F3: "🎧 <strong>肉声音声の最優先再生</strong>：録音があるカードでは機械合成(TTS)ではなく、お互いの本物の声を自動優先再生",
    rel120F4: "📊 <strong>録音状況カウンター & バッジ</strong>：グループ管理画面に録音済みフラッシュカード数とマイクアイコンを表示",
    rel120F5: "📱 <strong>完全オフライン再生 & 再録音</strong>：同期された音声は端末に自動保存され、圏外でもクリアに再生・いつでも録音やり直し可能",
    relV110Title: "Language Islands v1.1.0",
    relV110Date: "2026年10月28日 公開 • ビルド #2",
    relV110Desc: "単一フラッシュカード追加・編集画面・グループ管理機能",
    relV100Title: "Language Islands v1.0.0",
    relV100Date: "2026年10月18日 公開 • ビルド #1",
    relDownloadBtn: "Runner.ipa を直接ダウンロード ↓ (28 MB)",
    relMirrorGhBtn: "GitHub Releases ページ ↗",
    relMirrorActionsBtn: "CI/CD ビルド成果物 (Actions) ↗",
    relChangelogTitle: "📋 バージョン 1.0.0 の更新内容",
    relF1: "🌸 <strong>こはるちゃん専用カスタマイズ</strong>：Jakubと2人で相互学習できるように画面やメッセージを最適化",
    relF2: "🇵🇱 <strong>ポーランド語学習モード</strong>：ネイティブニューラル音声（Marek / Zofia）によるクリアな発音",
    relF3: "🔤 <strong>カタカナ読み補助</strong>：ポーランド語特有の難しい発音も一目でわかる親切表記",
    relF4: "☁️ <strong>Gist リモート双方向同期</strong>：こはるちゃんがアプリから送信した日本語がJakubの学習リストに即座に反映",
    relF5: "🔁 <strong>シャドーイング＆アクティブリコール</strong>：記憶の定着を加速する2大特訓モード完備",
    relSpecsTitle: "📱 動作要件・詳細情報",
    relSpecIos: "対応OS: iOS 14.0 〜 iOS 18.x (iPhone / iPad)",
    relSpecBundle: "Bundle ID: com.example.languageIslandsApp",
    relSpecFormat: "ファイル形式: .ipa (iOS Application Archive)",
    relSpecInstall: "インストール方法: SideStore経由（脱獄不要・完全無料）",
    relHowToTitle: "💡 ダウンロード後のインストール手順（SideStore）",
    relHowToStep1: "1. Safariで上の「Runner.ipa を直接ダウンロード」をタップします。",
    relHowToStep2: "2. <strong>LocalDevVPN</strong> アプリを開き、Connected（接続済み）にします。",
    relHowToStep3: "3. <strong>SideStore</strong> を開き、下の「My Apps」タブをタップします。",
    relHowToStep4: "4. 左上の <strong>「＋」</strong> ボタンを押し、ダウンロードした <code>Runner.ipa</code> を選択します。",
    relHowToStep5: "5. ホーム画面にアイコンが追加され、すぐに学習を開始できます！🎉",
    relHowToUpdateNote: "※アップデート時も同様の手順で新しいIPAを追加するだけで上書き更新されます。これまでの学習履歴や送受信したフレーズは一切消えません。",
    relArchiveTitle: "📦 過去のバージョン (Archive)",
    relBetaTitle: "v1.0.0-beta (プロトタイプ初期版)",
    relBetaDate: "2026年10月10日 • アーカイブ",
    relBetaDesc: "Edge-TTS音声エンジンと基本カードUIの初期検証ビルド",
    relBetaBtn: "v1.0.0-beta IPA をダウンロード ↓",
    relUpcomingTitle: "🚧 次期バージョン予定: v1.1.0",
    relUpcomingDesc: "オフライン音声キャッシュ、学習ストリーク（連続日数）ウィジェットを準備中です。",

    // Footer
    footerNote: "JakubとKoharuのための特製語学学習プロジェクト",
    footerCopy: "© 2026 Language Islands • All rights reserved."
  },

  en: {
    navBrand: "Language Islands",
    navSub: "iPhone Guide",
    navWhy: "Overview",
    navSideStore: "SideStore Setup",
    navAppInstall: "Install App",
    navPolishConfig: "Polish Config",
    navExchange: "Exchange Sentences",
    navVersions: "Releases",
    navFaq: "FAQ",
    viewAllVersionsBtn: "📦 View All Versions & Changelog ↗",
    versionCardTitle: "Current Release: v1.0.0 (Stable)",
    versionCardDesc: "Personalized for Koharu with two-way exchange, Polish neural voices, and Katakana phonetic guides.",

    heroBadge: "🌸 Special Guide for Koharu",
    heroTitle: "Learn <span class=\"highlight\">Polish & Japanese</span><br>Together on iPhone",
    heroDesc: "A custom language exchange app built exclusively for the two of us. Step-by-step instructions on how to install 'Language Islands' via SideStore on your iPhone for free, configure Polish learning, and exchange daily sentences seamlessly.",

    letterHeader: "💌 A message from Jakub to Koharu",
    letterBody: "\"Hello Koharu! I built this application so we can learn Polish and Japanese together. In my app, I practice the Japanese sentences you give me. In your app, you receive the Polish sentences I prepare with native neural audio and Katakana phonetic guides! It only takes a few minutes to set up, and this guide walks you through every step. Let's do our best!\"",
    letterSign: "— From Jakub",

    progressTitle: "Setup Completion Progress",
    step1Check: "1. LocalDevVPN & SideStore Setup",
    step2Check: "2. Install App (Runner.ipa)",
    step3Check: "3. Configure Polish (Polski) Mode",
    step4Check: "4. Connect Shared Gist Database",

    twoWayTitle: "Our Two-Way Language Exchange",
    twoWayFriendTitle: "Koharu (Japan)",
    twoWayFriendTarget: "🇵🇱 Learning Polish",
    twoWayFriendF1: "Native Polish neural audio (Marek / Zofia)",
    twoWayFriendF2: "Katakana phonetic reading guide for tricky Polish sounds",
    twoWayFriendF3: "Shadowing & Active Recall practice modes",
    twoWayFriendF4: "1-tap send Japanese phrases straight to Jakub!",

    twoWayJakubTitle: "Jakub (Poland)",
    twoWayJakubTarget: "🇯🇵 Learning Japanese",
    twoWayJakubF1: "Practices everyday Japanese sentences sent by Koharu",
    twoWayJakubF2: "Kanji, Katakana & Romaji support",
    twoWayJakubF3: "Creates Polish sentences for Koharu to study",

    twoWayCenterBadge: "Gist Two-Way Sync",

    sec1Tag: "OVERVIEW",
    sec1Title: "What is SideStore and Why do we use it?",
    sec1Desc: "Publishing to the official Apple App Store costs $99/year and requires public review. SideStore is a free, safe, open-source tool that allows us to sideload our private app directly onto your personal iPhone.",
    sec1SafeTitle: "Completely Safe & Legal",
    sec1SafeBody: "This is NOT jailbreaking. It uses Apple's official personal developer signing system to sign and install the app inside a safe sandbox on your iPhone.",
    sec1Feature1Title: "Wirelessly Refreshes Without a PC",
    sec1Feature1Desc: "Unlike older AltStore methods, you only need a PC once for the initial setup. After that, SideStore refreshes apps directly on your iPhone using LocalDevVPN! (Neither iTunes nor iCloud is required!)",

    sec2Tag: "STEP 1",
    sec2Title: "Initial SideStore Setup (One-time only)",
    sec2Desc: "You will only need a computer (Windows PC or Mac) for the first 10 minutes. Neither iTunes nor iCloud is required!",
    prepTitle: "Prerequisites",
    prepItem1: "Your iPhone (iOS 14+, supports iOS 16/17/18)",
    prepItem2: "A computer (Windows or Mac) - only for initial setup (No iTunes or iCloud needed!)",
    prepItem3: "USB cable to connect iPhone to PC",
    prepItem4: "Your regular Apple ID",

    step11Title: "Install LocalDevVPN on iPhone (from App Store)",
    step11Desc: "LocalDevVPN allows SideStore to sign and refresh apps directly on your iPhone without any computer. No configuration files needed!",
    vpnAppStoreBtn: "Get LocalDevVPN on App Store ↗",
    vpnConnectNote: "After downloading, open LocalDevVPN -> tap 'Connect' -> tap 'Allow' on the iOS VPN prompt and enter your passcode.",

    step12Title: "Turn ON Developer Mode (iOS 16, 17, 18)",
    step12Desc: "Required on iOS 16+ to run custom sideloaded apps.",
    devModePath: "Settings → Privacy & Security → Developer Mode",
    devModeNote: "Toggle it ON and restart your iPhone. After reboot, tap 'Turn On' and enter your passcode.",

    step13Title: "Install SideStore using iloader on PC / Mac",
    winTab: "Windows",
    macTab: "macOS",
    winStep1: "1. Download and run <strong>iloader for Windows</strong> (.msi). <strong>Neither iTunes nor iCloud is required!</strong>",
    winStep2: "2. Connect your iPhone to your PC with a USB cable and tap 'Trust this computer' on your iPhone.",
    winStep3: "3. Launch iloader and sign in with your <strong>Apple ID</strong> (note: email is case-sensitive).",
    winStep4: "4. Select your connected iPhone from the list and click <strong>'Install SideStore (Stable)'</strong>. It installs automatically!",
    macStep1: "1. Download <strong>iloader for macOS</strong> (.dmg) and drag it to your Applications folder (no iTunes/iCloud required).",
    macStep2: "2. Connect your iPhone to your Mac with a USB cable and tap 'Trust' on both Mac and iPhone.",
    macStep3: "3. Launch iloader and sign in with your <strong>Apple ID</strong> (case-sensitive).",
    macStep4: "4. Select your connected iPhone and click <strong>'Install SideStore (Stable)'</strong>.",

    step14Title: "Trust Developer Certificate on iPhone",
    trustPath: "Settings → General → VPN & Device Management → Developer App (Your Apple ID)",
    trustNote: "Tap 'Trust (Your Apple ID)' to confirm. You can now launch SideStore!",

    step15Title: "First Launch & Complete Pairing",
    step15Desc: "Open <strong>LocalDevVPN</strong> and make sure it is Connected. Then open <strong>SideStore</strong>, sign in with your Apple ID, go to the 'My Apps' tab, and tap the <strong>'7 DAYS'</strong> counter to perform the initial refresh and complete setup.",

    sec3Tag: "STEP 2",
    sec3Title: "Install Language Islands (Runner.ipa)",
    sec3Desc: "Now you can install the Language Islands app onto your iPhone home screen.",
    downloadIpaBtn: "Download Runner.ipa (Latest App Build)",
    appInstallStep1: "1. Tap 'Download Runner.ipa' above in Safari on your iPhone.",
    appInstallStep2: "2. Open <strong>LocalDevVPN</strong> and ensure it is <strong>Connected</strong> (VPN icon appears in status bar).",
    appInstallStep3: "3. Open <strong>SideStore</strong> and go to the 'My Apps' tab.",
    appInstallStep4: "4. Tap the <strong>'+'</strong> button in the top left and select <code>Runner.ipa</code> from Downloads.",
    appInstallStep5: "5. Installation will complete and the <strong>Language Islands</strong> icon appears on your home screen! 🎉",
    weeklyRefreshTitle: "💡 The 7-Day Refresh (Takes 5 seconds)",
    weeklyRefreshDesc: "Apps installed with a free Apple ID last 7 days. Once a week, simply connect LocalDevVPN on your iPhone, open SideStore, and tap 'Refresh All'. No PC needed ever again!",

    sec4Tag: "STEP 3",
    sec4Title: "Configure Polish Learning Mode in the App",
    sec4Desc: "Open the app and set the target learning language to Polish.",
    polishStep1: "1. Tap <strong>Language Islands</strong> on your iPhone home screen.",
    polishStep2: "2. Tap the <strong>3 dots menu '︙'</strong> in the top right corner.",
    polishStep3: "3. Select <strong>'Język nauki (docelowy)' (Target Language)</strong>.",
    polishStep4: "4. Choose <strong>'🇵🇱 Polski (Marek / Zofia - Polish Neural)'</strong>.",
    polishStep5: "5. The app will now feature Polish sentences and native audio!",

    practiceHowToTitle: "How to Practice",
    shadowingTitle: "🎧 Shadowing Mode",
    shadowingDesc: "Listen to the Polish sentence and repeat it immediately. Follow the Katakana pronunciation guide below each sentence to nail tricky Polish sounds!",
    recallTitle: "🧠 Active Recall Mode",
    recallDesc: "See the Japanese meaning -> Try saying the Polish translation out loud -> Tap to reveal the correct Polish sentence and listen to native audio -> Rate yourself 1-5 stars.",

    sec5Tag: "STEP 4",
    sec5Title: "Connecting the Shared Database & Exchanging Phrases",
    sec5Desc: "Connect to the shared GitHub Gist so Jakub receives your Japanese sentences, and you receive Jakub's Polish sentences!",

    syncSetupTitle: "1. Connect Shared Gist & Download Lessons",
    syncStep1: "1. Tap the <strong>'︙'</strong> menu in the app.",
    syncStep2: "2. Tap <strong>'Zdalna baza zdań / Synchronizacja'</strong> (Remote Sync).",
    syncStep3: "3. Configure the <strong>'Adres URL bazy danych / JSON'</strong> field:",
    syncQuickBtnTitle: "[Fastest: 1-Click Auto-Fill]",
    syncQuickBtnDesc: "Simply tap the purple button <code>✨ Wstaw domyślny wspólny Gist (Jakub & Przyjaciółka)</code> right beneath the URL field to fill in the shared Gist URL instantly!",
    syncManualHint: "Or you can copy and paste the shared Gist URL directly below:",
    copyGistBtn: "Copy Gist URL",
    syncApiKeyHintTitle: "[About the API Key / Token field]",
    syncApiKeyHint: "Leave <strong>'Klucz API / Token autoryzacji'</strong> <strong>[BLANK]</strong>! No key or password is required for reading and downloading lessons.",
    syncStep4: "4. Turn ON <strong>'Auto-sync on startup'</strong> (Automatyczna synchronizacja przy starcie).",
    syncStep5: "5. Tap <strong>'Synchronizuj teraz' (Sync now)</strong> to download all Polish lessons Jakub prepared for Koharu! 🎉",

    sendPhraseTitle: "2. How Koharu Sends Japanese Sentences to Jakub",
    sendIntro: "Whenever you think of a useful Japanese expression, you can send it to Jakub in 1 tap!",
    sendStep1: "1. Tap the pink Heart button <strong>'+'</strong> in the bottom right corner or menu '︙' -> <strong>'Dla Jakuba / Jakubへフレーズを送る'</strong>.",
    sendStep2: "2. Make sure the tab is set to <strong>'🇯🇵 日本語 (Dla Jakuba)'</strong>.",
    sendStep3: "3. Enter the fields:",
    sendF1: "• <strong>1. Japanese (Kanji/Kana)</strong>: e.g. これ、すごく美味しいよ！",
    sendF2: "• <strong>2. Katakana Reading</strong>: e.g. コレ、スゴク オイシイ ヨ！",
    sendF3: "• <strong>3. Romaji (Rōmaji)</strong>: e.g. Kore, sugoku oishii yo!",
    sendF4: "• <strong>4. Meaning / Translation (Znaczenie)</strong>: e.g. 'To jest naprawdę pyszne! / This is so delicious!'",
    sendF5: "• <strong>5. Usage Notes (Optional)</strong>: e.g. 'Casual expression recommended during meals'",
    sendTokenTitle: "[First Time Only] Phrase Upload Connection (GitHub Token)",
    sendTokenDesc: "To publish new phrases to the shared Gist, write access is needed. Expand 'GitHub Gist Configuration':<br>• <strong>Gist URL</strong>: Tap <code>共通Gistアドレスを自動入力</code> (Auto-fill)<br>• <strong>GitHub Token</strong>: Enter the personal GitHub token (PAT) provided by Jakub and tap 'Save'.",
    sendStep4: "4. Tap <strong>'送信 & 保存' (Send & Save to GitHub)</strong> at the bottom of the screen!",
    sendResult: "The sentence is saved to the shared database. When Jakub opens his app, Koharu's Japanese sentence appears in his daily study queue! 🌸",

    mockupTitle: "Interactive App Preview",
    mockTab1: "Practice Card (Polish)",
    mockTab2: "Send Phrase to Jakub",
    mockTab3: "Remote Sync Dialog",

    faqTitle: "Frequently Asked Questions & Troubleshooting",
    faqQ1: "SideStore says 'Cannot connect to SideServer / Device'?",
    faqA1: "Open the LocalDevVPN app and ensure it is Connected (VPN icon appears in status bar). SideStore requires LocalDevVPN to communicate on-device.",
    faqQ2: "iPhone says 'Untrusted Developer' when opening the app?",
    faqA2: "Go to iPhone Settings -> General -> VPN & Device Management -> Tap your Apple ID -> Tap 'Trust'.",
    faqQ3: "I can't hear any audio playback?",
    faqA3: "Check the physical Ring/Silent switch on the left side of your iPhone to make sure it's not on silent (orange), and increase media volume.",
    faqQ4: "Will my app disappear after 7 days?",
    faqA4: "No! Your sentences and history remain completely safe. Just connect LocalDevVPN, open SideStore, and tap 'Refresh All' to renew the 7-day certificate.",
    faqQ5: "How do I update when Jakub releases a new version?",
    faqA5: "Download the new Runner.ipa and tap the '+' button in SideStore. It will update in place without losing any data!",

    resourceTitle: "Download & Resource Hub",
    resVpnTitle: "LocalDevVPN (iOS)",
    resVpnDesc: "Official App Store VPN for SideStore (no config file needed)",
    resAppTitle: "Language Islands IPA",
    resAppDesc: "Latest Runner.ipa application file",
    resIloaderWin: "iloader (Windows)",
    resIloaderWinDesc: "Modern installer for Windows (.msi) - No iTunes/iCloud",
    resIloaderMac: "iloader (macOS)",
    resIloaderMacDesc: "Modern installer for macOS (.dmg)",

    // Releases Page
    relPageTitle: "Language Islands • Releases & IPA Downloads",
    relNavHome: "Guide Home",
    relNavSideStore: "SideStore Setup",
    relNavVersions: "Releases",
    relHeroBadge: "🌸 Official Releases & IPA Archive",
    relHeroTitle: "Language Islands<br><span class=\"highlight\">IPA Downloads</span>",
    relHeroDesc: "Directory of `Runner.ipa` packages to install via SideStore on iOS. Tap directly from your iPhone in Safari to download the latest or previous versions.",
    relLatestBadge: "🌸 Latest Stable (Recommended)",
    relV120Title: "Language Islands v1.2.0",
    relV120Date: "Released Oct 28, 2026 • Build #3",
    rel120F1: "🎙️ <strong>Bilingual Voice Recording (Koharu & Jakub)</strong>: Record native voice directly inside the app — Japanese for Koharu, Polish for Jakub (AAC-LC 48kbps mono)",
    rel120F2: "☁️ <strong>Voice Cloud Sync via GitHub Gist (Base64)</strong>: Automatic high-efficiency audio compression and sync directly embedded in sentences.json",
    rel120F3: "🎧 <strong>Human Voice Priority over TTS</strong>: Flashcards with recorded audio prioritize Koharu & Jakub's real voice over synthetic TTS",
    rel120F4: "📊 <strong>Voice Recording Stats & Badges</strong>: Live recording progress counter (X/Y) in collections and microphone badges on flashcards",
    rel120F5: "📱 <strong>Offline Playback & Re-recording</strong>: Downloaded voice recordings are stored locally for instant offline playback with full re-recording and deletion support",
    relV110Title: "Language Islands v1.1.0",
    relV110Date: "Released Oct 28, 2026 • Build #2",
    relV110Desc: "Single card add & edit dialog, collection management screen, and full search",
    relV100Title: "Language Islands v1.0.0",
    relV100Date: "Released Oct 18, 2026 • Build #1",
    relDownloadBtn: "Direct Download Runner.ipa ↓ (28 MB)",
    relMirrorGhBtn: "GitHub Releases Page ↗",
    relMirrorActionsBtn: "CI/CD Build Artifacts (Actions) ↗",
    relChangelogTitle: "📋 What's New in Version 1.0.0",
    relF1: "🌸 <strong>Customized for Koharu</strong>: Tailored UI and warm interaction flow for reciprocal study with Jakub",
    relF2: "🇵🇱 <strong>Polish Learning Mode</strong>: Native neural voices (Marek & Zofia) with high acoustic clarity",
    relF3: "🔤 <strong>Katakana Phonetic Guides</strong>: Intuitive pronunciation helpers below tricky Polish phrases",
    relF4: "☁️ <strong>Gist Two-Way Sync</strong>: Japanese sentences sent by Koharu sync immediately to Jakub's study queue",
    relF5: "🔁 <strong>Shadowing & Active Recall</strong>: Two powerful scientific memory retention study modes",
    relSpecsTitle: "📱 System Requirements & Metadata",
    relSpecIos: "Compatibility: iOS 14.0 to iOS 18.x (iPhone / iPad)",
    relSpecBundle: "Bundle ID: com.example.languageIslandsApp",
    relSpecFormat: "Package Format: .ipa (iOS Application Archive)",
    relSpecInstall: "Installation: Via SideStore (100% Free, No Jailbreak)",
    relHowToTitle: "💡 How to Install in SideStore after Download",
    relHowToStep1: "1. Tap 'Direct Download Runner.ipa' above in Safari on your iPhone.",
    relHowToStep2: "2. Open <strong>LocalDevVPN</strong> and verify it is Connected.",
    relHowToStep3: "3. Open <strong>SideStore</strong> and go to the 'My Apps' tab.",
    relHowToStep4: "4. Tap <strong>'+'</strong> in the top left and choose the downloaded <code>Runner.ipa</code>.",
    relHowToStep5: "5. The app icon appears on your home screen! Start learning! 🎉",
    relHowToUpdateNote: "Note: When updating to future releases, just import the new IPA through SideStore; your study progress and sent phrases will never be erased.",
    relArchiveTitle: "📦 Previous Releases (Archive)",
    relBetaTitle: "v1.0.0-beta (Initial Prototype)",
    relBetaDate: "Oct 10, 2026 • Archived",
    relBetaDesc: "Initial verification prototype for Edge-TTS and flashcard UI",
    relBetaBtn: "Download v1.0.0-beta IPA ↓",
    relUpcomingTitle: "🚧 Upcoming: v1.1.0",
    relUpcomingDesc: "Offline voice caching and daily study streak tracker currently in development.",

    footerNote: "Custom language exchange app for Jakub & Koharu",
    footerCopy: "© 2026 Language Islands • All rights reserved."
  },

  pl: {
    navBrand: "Language Islands",
    navSub: "Instrukcja iPhone",
    navWhy: "O co chodzi",
    navSideStore: "Instalacja SideStore",
    navAppInstall: "Pobieranie IPA",
    navPolishConfig: "Nauka polskiego",
    navExchange: "Wymiana zdań",
    navVersions: "Wersje",
    navFaq: "FAQ",
    viewAllVersionsBtn: "📦 Zobacz wszystkie wersje i historię ↗",
    versionCardTitle: "Aktualne wydanie: v1.0.0 (Stabilna)",
    versionCardDesc: "Wersja dla Koharu: dwukierunkowa wymiana zdań, polski lektor neuralny i zapis w katakanie.",

    heroBadge: "🌸 Przewodnik dla Koharu",
    heroTitle: "Wspólna nauka <span class=\"highlight\">polskiego i japońskiego</span><br>na iPhone",
    heroDesc: "Aplikacja stworzona specjalnie dla nas do wzajemnej nauki języków. Kompletna instrukcja krok po kroku: jak za darmo zainstalować aplikację na iPhone za pomocą SideStore, jak ustawić naukę języka polskiego i jak przesyłać sobie nawzajem zdania.",

    letterHeader: "💌 Wiadomość od Jakuba dla Koharu",
    letterBody: "„Cześć Koharu! Stworzyłem tę aplikację, abyśmy mogli wspólnie uczyć się polskiego i japońskiego. W mojej aplikacji ćwiczę japońskie zdania, które mi przesyłasz, a w Twojej aplikacji pojawiają się zdania po polsku z polskim lektorem i transkrypcją w katakanie! Pierwsza konfiguracja zajmuje tylko chwilę — przygotowałem tę stronę, aby poprowadzić Cię krok po kroku. Damy radę!”",
    letterSign: "— Jakub",

    progressTitle: "Postęp konfiguracji",
    step1Check: "1. Instalacja LocalDevVPN i SideStore",
    step2Check: "2. Instalacja aplikacji (Runner.ipa)",
    step3Check: "3. Konfiguracja języka polskiego",
    step4Check: "4. Połączenie wspólnej bazy (Gist)",

    twoWayTitle: "Dwukierunkowa wymiana zdań",
    twoWayFriendTitle: "Koharu (Japonia)",
    twoWayFriendTarget: "🇵🇱 Uczy się polskiego",
    twoWayFriendF1: "Polski lektor neuralny (Marek / Zofia)",
    twoWayFriendF2: "Wymowa w katakanie pod każdym zdaniem",
    twoWayFriendF3: "Trening Shadowing i Active Recall",
    twoWayFriendF4: "1 kliknięciem wysyła zdania po japońsku dla Jakuba!",

    twoWayJakubTitle: "Jakub (Polska)",
    twoWayJakubTarget: "🇯🇵 Uczy się japońskiego",
    twoWayJakubF1: "Ćwiczy japońskie zdania przesłane przez Koharu",
    twoWayJakubF2: "Kanji, kana, katakana i romaji",
    twoWayJakubF3: "Przygotowuje zdania po polsku dla Koharu",

    twoWayCenterBadge: "Synchronizacja przez Gist",

    sec1Tag: "PRZEGLĄD",
    sec1Title: "Czym jest SideStore i dlaczego go używamy?",
    sec1Desc: "Oficjalny App Store Apple wymaga opłaty 99$ rocznie i publicznej weryfikacji. SideStore to darmowe, bezpieczne narzędzie open-source, które pozwala zainstalować naszą prywatną aplikację bezpośrednio na Twoim iPhone.",
    sec1SafeTitle: "Całkowicie bezpieczne i legalne",
    sec1SafeBody: "To NIE jest żaden jailbreak. Używa oficjalnego mechanizmu Apple dla prywatnych deweloperów i działa w bezpiecznej piaskownicy iOS.",
    sec1Feature1Title: "Odświeżanie bez komputera",
    sec1Feature1Desc: "W przeciwieństwie do AltStore, komputer jest potrzebny tylko raz na start. Później SideStore odświeża certyfikat bezpośrednio na iPhone przez LocalDevVPN! (Nie trzeba instalować iTunes ani iCloud!)",

    sec2Tag: "KROK 1",
    sec2Title: "Wstępna instalacja SideStore (tylko 1 raz)",
    sec2Desc: "Komputer (Windows lub Mac) będzie Ci potrzebny tylko na około 10 minut na sam start. Nie musisz instalować iTunes ani iCloud!",
    prepTitle: "Co jest potrzebne:",
    prepItem1: "Twój iPhone (iOS 14+, w tym iOS 16/17/18)",
    prepItem2: "Komputer (Windows lub Mac) – tylko na start (nie wymaga iTunes ani iCloud!)",
    prepItem3: "Kabel USB do połączenia telefonu z komputerem",
    prepItem4: "Twoje konto Apple ID",

    step11Title: "Zainstaluj LocalDevVPN na iPhone (App Store)",
    step11Desc: "LocalDevVPN pozwala SideStore odświeżać aplikacje bezpośrednio na telefonie bez użycia komputera. Nie wymaga pobierania żadnych plików konfiguracyjnych!",
    vpnAppStoreBtn: "Pobierz LocalDevVPN z App Store ↗",
    vpnConnectNote: "Po zainstalowaniu otwórz LocalDevVPN -> kliknij „Connect” -> zezwól na dodanie konfiguracji VPN w wyskakującym okienku iOS i podaj kod blokady.",

    step12Title: "Włącz Tryb Dewelopera (iOS 16, 17, 18)",
    step12Desc: "Wymagane na nowszych iOS, aby uruchamiać własne aplikacje.",
    devModePath: "Ustawienia → Prywatność i ochrona → Tryb dewelopera",
    devModeNote: "Włącz przełącznik i uruchom ponownie iPhone. Po restarcie kliknij „Włącz” i wpisz kod blokady.",

    step13Title: "Instalacja SideStore przez iloader na komputerze",
    winTab: "Windows",
    macTab: "macOS",
    winStep1: "1. Pobierz i zainstaluj <strong>iloader dla Windows</strong> (.msi). <strong>Nie musisz instalować ani iTunes, ani iCloud!</strong>",
    winStep2: "2. Podłącz iPhone kablem USB do komputera i kliknij „Ufaj temu komputerowi” na ekranie iPhone'a.",
    winStep3: "3. Uruchom iloader i zaloguj się swoim <strong>Apple ID</strong> (wielkość liter w e-mailu ma znaczenie).",
    winStep4: "4. Wybierz swój iPhone z listy i kliknij <strong>„Install SideStore (Stable)”</strong>. SideStore zainstaluje się automatycznie!",
    macStep1: "1. Pobierz <strong>iloader dla macOS</strong> (.dmg), przenieś do folderu Aplikacje i uruchom (brak potrzeby iTunes/iCloud).",
    macStep2: "2. Podłącz iPhone kablem do Maca i kliknij „Zaufaj”.",
    macStep3: "3. W iloader zaloguj się swoim <strong>Apple ID</strong> (wielkość liter ma znaczenie).",
    macStep4: "4. Wybierz swój iPhone i kliknij <strong>„Install SideStore (Stable)”</strong>.",

    step14Title: "Zaufaj certyfikatowi na iPhone",
    trustPath: "Ustawienia → Ogólne → VPN i zarządzanie urządzeniami → Aplikacja dewelopera",
    trustNote: "Kliknij swój adres Apple ID i wybierz „Zaufaj”.",

    step15Title: "Pierwsze uruchomienie SideStore i dokończenie konfiguracji",
    step15Desc: "Włącz <strong>LocalDevVPN</strong> (kliknij „Connect”). Otwórz <strong>SideStore</strong>, zaloguj się swoim Apple ID, wejdź w zakładkę „My Apps” i kliknij licznik <strong>„7 DAYS”</strong>, aby wykonać pierwsze odświeżenie i zakończyć instalację.",

    sec3Tag: "KROK 2",
    sec3Title: "Instalacja aplikacji Language Islands (Runner.ipa)",
    sec3Desc: "Gdy SideStore działa, wystarczy wgrać plik aplikacji na iPhone.",
    downloadIpaBtn: "Pobierz Runner.ipa (Aplikacja)",
    appInstallStep1: "1. Kliknij „Pobierz Runner.ipa” powyżej w Safari na iPhone.",
    appInstallStep2: "2. Upewnij się, że <strong>LocalDevVPN</strong> jest połączony (<strong>Connected</strong> / ikona VPN w pasku stanu).",
    appInstallStep3: "3. Otwórz <strong>SideStore</strong> i przejdź do zakładki 'My Apps'.",
    appInstallStep4: "4. Kliknij ikonę <strong>'+'</strong> w lewym górnym rogu i wybierz plik <code>Runner.ipa</code> z Pobranych.",
    appInstallStep5: "5. Aplikacja <strong>Language Islands</strong> pojawi się na Twoim ekranie głównym! 🎉",
    weeklyRefreshTitle: "💡 Odświeżanie co 7 dni (zajmuje 5 sekund)",
    weeklyRefreshDesc: "Darmowe konto Apple ID wymaga odświeżenia aplikacji co 7 dni. Wystarczy raz w tygodniu połączyć LocalDevVPN na telefonie, wejść do SideStore i kliknąć 'Refresh All' (bez użycia komputera!).",

    sec4Tag: "KROK 3",
    sec4Title: "Ustawienie nauki języka polskiego",
    sec4Desc: "W aplikacji wybierz język polski jako docelowy język nauki.",
    polishStep1: "1. Otwórz <strong>Language Islands</strong> na iPhone.",
    polishStep2: "2. Dotknij menu <strong>3 kropek '︙'</strong> w prawym górnym rogu.",
    polishStep3: "3. Wybierz <strong>'Język nauki (docelowy)'</strong>.",
    polishStep4: "4. Zaznacz <strong>'🇵🇱 Polski (Marek / Zofia - Polish Neural)'</strong>.",
    polishStep5: "5. Aplikacja natychmiast przełączy się na lekcje polskiego z polskim audio!",

    practiceHowToTitle: "Jak ćwiczyć w aplikacji?",
    shadowingTitle: "🎧 Tryb Shadowing (Powtarzanie)",
    shadowingDesc: "Aplikacja odtwarza polskie zdanie, a Ty powtarzasz je na głos. Pod każdym zdaniem znajduje się fonetyczny zapis w katakanie, który ułatwia poprawną wymowę!",
    recallTitle: "🧠 Tryb Active Recall (Aktywne przypominanie)",
    recallDesc: "Widzisz znaczenie po japońsku -> Próbujesz powiedzieć to po polsku na głos -> Klikasz kartę, by odsłonić polskie zdanie i usłyszeć lektora -> Oceniasz siebie od 1 do 5 gwiazdek.",

    sec5Tag: "KROK 4",
    sec5Title: "Wspólna baza i wymiana zdań (GitHub Gist)",
    sec5Desc: "Połączenie aplikacji przez Gist pozwala na dwukierunkową wymianę zdań: Jakub przygotowuje lekcje polskiego dla Koharu, a Koharu wysyła japońskie zwroty dla Jakuba!",

    syncSetupTitle: "1. Połączenie ze wspólnym Gistem i pobieranie lekcji",
    syncStep1: "1. Otwórz menu <strong>'︙'</strong> w prawym górnym rogu aplikacji.",
    syncStep2: "2. Kliknij <strong>'Zdalna baza zdań / Synchronizacja'</strong> (ikona chmury).",
    syncStep3: "3. Uzupełnij pole <strong>'Adres URL bazy danych / JSON'</strong>:",
    syncQuickBtnTitle: "✨ [Najszybsza opcja: 1 Kliknięcie]",
    syncQuickBtnDesc: "Wystarczy kliknąć fioletowy przycisk <code>✨ Wstaw domyślny wspólny Gist (Jakub & Przyjaciółka)</code> bezpośrednio pod polem URL, a adres wspólnego Gista uzupełni się automatycznie!",
    syncManualHint: "Możesz także skopiować i wkleić poniższy bezpośredni adres URL:",
    copyGistBtn: "Kopiuj adres Gist URL",
    syncApiKeyHintTitle: "💡 [Pole Klucz API / Token autoryzacji]",
    syncApiKeyHint: "Do odbioru i nauki lekcji od Jakuba pole to pozostaw <strong>[PUSTE]</strong>! Baza pobiera się bez żadnego hasła i tokena.",
    syncStep4: "4. Włącz opcję <strong>'Automatyczna synchronizacja przy starcie'</strong> (Auto-sync on startup).",
    syncStep5: "5. Kliknij <strong>'Synchronizuj teraz'</strong>, aby natychmiast pobrać lekcje polskiego przygotowane przez Jakuba dla Koharu! 🎉",

    sendPhraseTitle: "2. Jak Koharu wysyła zdania po japońsku dla Jakuba",
    sendIntro: "Gdy chcesz przekazać Jakubowi przydatny japoński zwrot:",
    sendStep1: "1. Kliknij różową ikonę serca <strong>'+'</strong> w prawym dolnym rogu lub w menu '︙' -> <strong>'Dla Jakuba / Jakubへフレーズを送る'</strong>.",
    sendStep2: "2. Upewnij się, że wybrana jest zakładka <strong>'🇯🇵 日本語 (Dla Jakuba)'</strong>.",
    sendStep3: "3. Wypełnij pola formularza:",
    sendF1: "• <strong>1. Japoński (Kanji/Kana)</strong>: np. これ、すごく美味しいよ！",
    sendF2: "• <strong>2. Wymowa w katakanie</strong>: np. コレ、スゴク オイシイ ヨ！",
    sendF3: "• <strong>3. Transkrypcja fonetyczna / Rōmaji</strong>: np. Kore, sugoku oishii yo!",
    sendF4: "• <strong>4. Znaczenie / Tłumaczenie</strong>: np. 'To jest naprawdę pyszne! / This is delicious!'",
    sendF5: "• <strong>5. Wskazówki / Kontekst (Opcjonalnie)</strong>: np. 'Zwrot nieformalny, polecany podczas posiłków'",
    sendTokenTitle: "🔑 [Tylko za pierwszym razem] Autoryzacja wysyłania zdań (GitHub Token)",
    sendTokenDesc: "Aby móc wysyłać nowe zdania do chmury na GitHubie, wymagane jest jednorazowe podanie uprawnień: w sekcji 'Konfiguracja prywatnego GitHub Gist' kliknij <code>Wstaw adres wspólnego Gista</code>, a w polu Token wpisz Token (PAT) z uprawnieniem 'gist' przekazany przez Jakuba i kliknij 'Zapisz'.",
    sendStep4: "4. Kliknij przycisk <strong>'Wyślij do GitHuba i Zapisz (送信 & 保存)'</strong> na dole formularza!",
    sendResult: "Zdanie trafi do wspólnej bazy, a Jakub zobaczy japońskie zdanie od Koharu w swojej aplikacji! 🌸",

    mockupTitle: "Podgląd ekranów aplikacji",
    mockTab1: "Karta nauki polskiego",
    mockTab2: "Wysyłanie zwrotu do Jakuba",
    mockTab3: "Zdalna synchronizacja",

    faqTitle: "Często zadawane pytania (FAQ)",
    faqQ1: "SideStore zgłasza błąd 'Cannot connect to SideServer / Device'?",
    faqA1: "Otwórz LocalDevVPN i upewnij się, że VPN jest połączony (napis Connected i ikona VPN w pasku stanu). SideStore wymaga aktywnego LocalDevVPN.",
    faqQ2: "Komunikat 'Nie zaufano deweloperowi' przy otwieraniu aplikacji?",
    faqA2: "Wejdź w Ustawienia iPhone -> Ogólne -> VPN i zarządzanie urządzeniami -> Wybierz swój Apple ID -> Kliknij „Zaufaj”.",
    faqQ3: "Brak dźwięku w aplikacji?",
    faqA3: "Sprawdź fizyczny przełącznik wyciszenia z boku iPhone'a (czy nie widać pomarańczowego paska) oraz podgłośnij dźwięk multimediów.",
    faqQ4: "Czy po 7 dniach aplikacja zniknie z telefonu?",
    faqA4: "Nie! Wystarczy raz w tygodniu połączyć LocalDevVPN na telefonie i kliknąć 'Refresh All' w SideStore.",
    faqQ5: "Jak zaktualizować aplikację do nowszej wersji?",
    faqA5: "Pobierz nowy plik Runner.ipa i dodaj go przez ikonę '+' w SideStore. Żadne dane nie zostaną utracone!",

    resourceTitle: "Centrum pobierania",
    resVpnTitle: "LocalDevVPN (iOS)",
    resVpnDesc: "Oficjalny klient VPN z App Store (bez plików konfiguracyjnych)",
    resAppTitle: "Language Islands IPA",
    resAppDesc: "Plik instalacyjny Runner.ipa",
    resIloaderWin: "iloader (Windows)",
    resIloaderWinDesc: "Nowoczesny instalator (.msi) – brak potrzeby iTunes/iCloud",
    resIloaderMac: "iloader (macOS)",
    resIloaderMacDesc: "Instalator na macOS (.dmg)",

    // Releases Page
    relPageTitle: "Language Islands • Wersje aplikacji i pliki IPA",
    relNavHome: "Strona główna",
    relNavSideStore: "Instalacja SideStore",
    relNavVersions: "Wersje",
    relHeroBadge: "🌸 Wydania aplikacji i pliki IPA",
    relHeroTitle: "Language Islands<br><span class=\"highlight\">Pobieranie plików IPA</span>",
    relHeroDesc: "Katalog wydań i bezpośrednich plików instalacyjnych `Runner.ipa` dla iPhone przez SideStore. Możesz pobrać plik bezpośrednio z Safari na telefonie.",
    relLatestBadge: "🌸 Najnowsza wersja stabilna (Zalecana)",
    relV120Title: "Language Islands v1.2.0",
    relV120Date: "Wydano 28 października 2026 • Build #3",
    rel120F1: "🎙️ <strong>Dwujęzyczne nagrywanie głosu (Koharu & Jakub)</strong>: Nagrywaj własną wymowę bezpośrednio w aplikacji — japoński dla Koharu, polski dla Jakuba (AAC-LC 48kbps mono)",
    rel120F2: "☁️ <strong>Synchronizacja nagrań przez GitHub Gist (Base64)</strong>: Automatyczna kompresja i przesyłanie nagrań audio bezpośrednio w pliku sentences.json",
    rel120F3: "🎧 <strong>Priorytet żywego głosu nad TTS</strong>: Fiszki z nagraniem lektora odtwarzają prawdziwy głos Koharu lub Jakuba zamiast syntezatora Edge TTS",
    rel120F4: "📊 <strong>Licznik nagrań i oznaczenia fiszek</strong>: Statystyki nagranych fiszek w zespole (X/Y) oraz ikona mikrofonu na fiszkach",
    rel120F5: "📱 <strong>Odtwarzanie i edycja offline</strong>: Pobierane nagrania zapisują się w pamięci urządzenia i działają offline z możliwością ponownego nagrania lub usunięcia",
    relV110Title: "Language Islands v1.1.0",
    relV110Date: "Wydano 28 października 2026 • Build #2",
    relV110Desc: "Dodawanie i edycja pojedynczych fiszek oraz tryb zarządzania zbiorem",
    relV100Title: "Language Islands v1.0.0",
    relV100Date: "Wydano 18 października 2026 • Build #1",
    relDownloadBtn: "Pobierz bezpośrednio Runner.ipa ↓ (28 MB)",
    relMirrorGhBtn: "Strona wydań na GitHubie ↗",
    relMirrorActionsBtn: "Artefakty z GitHub Actions ↗",
    relChangelogTitle: "📋 Co nowego w wersji 1.0.0",
    relF1: "🌸 <strong>Dedykowana personalizacja dla Koharu</strong>: Zoptymalizowany interfejs do wspólnej nauki z Jakubem",
    relF2: "🇵🇱 <strong>Tryb nauki języka polskiego</strong>: Polskie głosy neuralne (Marek i Zofia) o naturalnym brzmieniu",
    relF3: "🔤 <strong>Wymowa w katakanie</strong>: Fonetyczny zapis pod każdym polskim zdaniem ułatwiający naukę",
    relF4: "☁️ <strong>Synchronizacja przez Gist</strong>: Zdania japońskie wysłane przez Koharu natychmiast trafiają do aplikacji Jakuba",
    relF5: "🔁 <strong>Trening Shadowing i Active Recall</strong>: Dwa zaawansowane tryby utrwalania pamięciowego",
    relSpecsTitle: "📱 Wymagania systemowe i dane techniczne",
    relSpecIos: "Kompatybilność: iOS 14.0 do iOS 18.x (iPhone / iPad)",
    relSpecBundle: "Bundle ID: com.example.languageIslandsApp",
    relSpecFormat: "Format pliku: .ipa (iOS Application Archive)",
    relSpecInstall: "Metoda instalacji: Przez SideStore (bez jailbreaku, za darmo)",
    relHowToTitle: "💡 Jak zainstalować plik w SideStore po pobraniu",
    relHowToStep1: "1. Kliknij „Pobierz bezpośrednio Runner.ipa” powyżej w Safari na telefonie.",
    relHowToStep2: "2. Włącz <strong>LocalDevVPN</strong> na telefonie (Connected).",
    relHowToStep3: "3. Otwórz <strong>SideStore</strong> i wejdź w zakładkę 'My Apps'.",
    relHowToStep4: "4. Kliknij <strong>'+'</strong> w lewym górnym rogu i wybierz pobrany plik <code>Runner.ipa</code>.",
    relHowToStep5: "5. Ikona aplikacji pojawi się na ekranie głównym! Możesz zacząć naukę! 🎉",
    relHowToUpdateNote: "Uwaga: Przy aktualizacji do nowszej wersji po prostu wgraj nowy plik IPA przez SideStore. Żadne dane nauki ani przesłane zwroty nie zostaną skasowane.",
    relArchiveTitle: "📦 Poprzednie wydania (Archiwum)",
    relBetaTitle: "v1.0.0-beta (Wersja testowa)",
    relBetaDate: "10 października 2026 • Zarchiwizowana",
    relBetaDesc: "Wczesny prototyp silnika Edge-TTS i interfejsu fiszek",
    relBetaBtn: "Pobierz v1.0.0-beta IPA ↓",
    relUpcomingTitle: "🚧 Nadchodzące wydanie: v1.1.0",
    relUpcomingDesc: "Prace nad buforowaniem dźwięku offline i licznikiem codziennej nauki (streak).",

    footerNote: "Aplikacja do wspólnej nauki języków dla Jakuba i Koharu",
    footerCopy: "© 2026 Language Islands • Wszelkie prawa zastrzeżone."
  }
};

// State variables
let currentLang = 'ja';

// Initialize on DOM load
document.addEventListener('DOMContentLoaded', () => {
  initLanguage();
  initTheme();
  initChecklist();
  initTabs();
  initFaq();
  initMockupTabs();
  initScrollSpy();
  initCopyButtons();
});

// Language initialization & switching
function initLanguage() {
  const urlParams = new URLSearchParams(window.location.search);
  const paramLang = urlParams.get('lang');
  const paramGist = urlParams.get('gist');

  const DEFAULT_GIST = 'https://gist.github.com/Sliskislimak/8d8efa2b1884930a0894553eec419283';
  const effectiveGist = paramGist || DEFAULT_GIST;
  const gistUrlText = document.getElementById('gistUrlText');
  const copyGistBtn = document.querySelector('[data-i18n="copyGistBtn"]');
  if (gistUrlText) gistUrlText.textContent = effectiveGist;
  if (copyGistBtn) copyGistBtn.setAttribute('data-copy', effectiveGist);

  const savedLang = localStorage.getItem('lang_islands_lang');
  if (paramLang && translations[paramLang]) {
    currentLang = paramLang;
  } else if (savedLang && translations[savedLang]) {
    currentLang = savedLang;
  } else {
    currentLang = 'ja'; // Default to Japanese for friend
  }
  applyLanguage(currentLang);

  // Dropdown toggle
  const langBtn = document.getElementById('langBtn');
  const langDropdown = document.getElementById('langDropdown');

  if (langBtn && langDropdown) {
    langBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      langDropdown.classList.toggle('open');
    });

    document.addEventListener('click', () => {
      langDropdown.classList.remove('open');
    });
  }

  document.querySelectorAll('.lang-opt').forEach((btn) => {
    btn.addEventListener('click', () => {
      const selected = btn.getAttribute('data-lang');
      if (translations[selected]) {
        currentLang = selected;
        localStorage.setItem('lang_islands_lang', currentLang);
        applyLanguage(currentLang);
        if (langDropdown) langDropdown.classList.remove('open');
      }
    });
  });
}

function applyLanguage(lang) {
  const dict = translations[lang] || translations.ja;

  // Update text of elements with data-i18n
  document.querySelectorAll('[data-i18n]').forEach((el) => {
    const key = el.getAttribute('data-i18n');
    if (dict[key] !== undefined) {
      el.innerHTML = dict[key];
    }
  });

  // Update button label
  const langLabels = { ja: '🇯🇵 日本語', en: '🇬🇧 English', pl: '🇵🇱 Polski' };
  const currentLangLabel = document.getElementById('currentLangLabel');
  if (currentLangLabel) {
    currentLangLabel.textContent = langLabels[lang] || '🇯🇵 日本語';
  }

  // Update active state in dropdown
  document.querySelectorAll('.lang-opt').forEach((btn) => {
    btn.classList.toggle('selected', btn.getAttribute('data-lang') === lang);
  });

  // Update document language
  document.documentElement.lang = lang;
}

// Theme handling (dark default, light option)
function initTheme() {
  const themeToggle = document.getElementById('themeToggle');
  const savedTheme = localStorage.getItem('lang_islands_theme') || 'dark';

  document.documentElement.setAttribute('data-theme', savedTheme);
  updateThemeIcon(savedTheme);

  if (themeToggle) {
    themeToggle.addEventListener('click', () => {
      const active = document.documentElement.getAttribute('data-theme') === 'light' ? 'dark' : 'light';
      document.documentElement.setAttribute('data-theme', active);
      localStorage.setItem('lang_islands_theme', active);
      updateThemeIcon(active);
    });
  }
}

function updateThemeIcon(theme) {
  const themeToggle = document.getElementById('themeToggle');
  if (!themeToggle) return;
  themeToggle.innerHTML = theme === 'light' ? '🌙' : '☀️';
  themeToggle.setAttribute('title', theme === 'light' ? 'Switch to Dark Mode' : 'Switch to Light Mode');
}

// Checklist & progress calculation
function initChecklist() {
  const checkboxes = document.querySelectorAll('.checklist-item input[type="checkbox"]');
  const progressBar = document.getElementById('progressBar');
  const progressPct = document.getElementById('progressPct');

  if (!progressBar || !progressPct || checkboxes.length === 0) return;

  function calculateProgress() {
    const total = checkboxes.length;
    let checkedCount = 0;
    checkboxes.forEach((cb, idx) => {
      const parent = cb.closest('.checklist-item');
      if (cb.checked) {
        checkedCount++;
        parent.classList.add('completed');
      } else {
        parent.classList.remove('completed');
      }
    });

    const pct = Math.round((checkedCount / total) * 100);
    progressBar.style.width = pct + '%';
    progressPct.textContent = pct + '%';

    // Save states
    const states = Array.from(checkboxes).map(c => c.checked);
    localStorage.setItem('lang_islands_checklist', JSON.stringify(states));
  }

  // Load saved states
  try {
    const saved = JSON.parse(localStorage.getItem('lang_islands_checklist') || '[]');
    checkboxes.forEach((cb, idx) => {
      if (saved[idx] !== undefined) {
        cb.checked = saved[idx];
      }
    });
  } catch (e) {
    // Ignore JSON errors
  }

  checkboxes.forEach((cb) => {
    cb.addEventListener('change', calculateProgress);
  });

  calculateProgress();
}

// Windows / Mac tabs
function initTabs() {
  const tabBtns = document.querySelectorAll('.tab-btn');
  tabBtns.forEach((btn) => {
    btn.addEventListener('click', () => {
      const target = btn.getAttribute('data-tab');
      const container = btn.closest('.tab-container');

      container.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
      container.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));

      btn.classList.add('active');
      const targetContent = container.querySelector('#' + target);
      if (targetContent) {
        targetContent.classList.add('active');
      }
    });
  });
}

// Mockup screen switcher
function initMockupTabs() {
  const mockTabs = document.querySelectorAll('.mockup-tab-btn');
  const screens = {
    screen1: document.getElementById('mockPracticeScreen'),
    screen2: document.getElementById('mockSendScreen'),
    screen3: document.getElementById('mockSyncScreen')
  };

  mockTabs.forEach((tab) => {
    tab.addEventListener('click', () => {
      const target = tab.getAttribute('data-mockup');
      mockTabs.forEach(t => t.classList.remove('active'));
      tab.classList.add('active');

      Object.keys(screens).forEach((key) => {
        if (screens[key]) {
          screens[key].style.display = (key === target) ? 'block' : 'none';
        }
      });
    });
  });
}

// FAQ Accordion
function initFaq() {
  const faqItems = document.querySelectorAll('.faq-item');
  faqItems.forEach((item) => {
    const question = item.querySelector('.faq-question');
    question.addEventListener('click', () => {
      const isOpen = item.classList.contains('open');
      faqItems.forEach(i => i.classList.remove('open'));
      if (!isOpen) {
        item.classList.add('open');
      }
    });
  });
}

// Copy to clipboard helper
function initCopyButtons() {
  document.querySelectorAll('.copy-btn').forEach((btn) => {
    btn.addEventListener('click', () => {
      const textToCopy = btn.getAttribute('data-copy');
      if (!textToCopy) return;

      navigator.clipboard.writeText(textToCopy).then(() => {
        const originalText = btn.innerHTML;
        btn.innerHTML = '✓ ' + (currentLang === 'ja' ? 'コピー完了' : currentLang === 'pl' ? 'Skopiowano' : 'Copied');
        btn.classList.add('copied');
        showToast(currentLang === 'ja' ? 'クリップボードにコピーしました！' : currentLang === 'pl' ? 'Skopiowano do schowka!' : 'Copied to clipboard!');

        setTimeout(() => {
          btn.innerHTML = originalText;
          btn.classList.remove('copied');
        }, 2200);
      });
    });
  });
}

// Toast notification
function showToast(message) {
  let container = document.querySelector('.toast-container');
  if (!container) {
    container = document.createElement('div');
    container.className = 'toast-container';
    document.body.appendChild(container);
  }

  const toast = document.createElement('div');
  toast.className = 'toast';
  toast.innerHTML = '<span>🌸</span> ' + message;
  container.appendChild(toast);

  setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transform = 'translateY(10px)';
    toast.style.transition = 'all 0.3s ease';
    setTimeout(() => toast.remove(), 300);
  }, 2600);
}

// Scroll spy for navigation
function initScrollSpy() {
  const sections = document.querySelectorAll('section[id]');
  const navLinks = document.querySelectorAll('.nav-links a');

  window.addEventListener('scroll', () => {
    let current = '';
    const scrollY = window.pageYOffset;

    sections.forEach((section) => {
      const sectionHeight = section.offsetHeight;
      const sectionTop = section.offsetTop - 120;
      if (scrollY >= sectionTop && scrollY < sectionTop + sectionHeight) {
        current = section.getAttribute('id');
      }
    });

    navLinks.forEach((link) => {
      link.classList.remove('active');
      if (link.getAttribute('href') === '#' + current) {
        link.classList.add('active');
      }
    });
  });

  // Mobile menu toggle
  const mobileToggle = document.getElementById('mobileNavToggle');
  const navLinksContainer = document.getElementById('navLinks');
  if (mobileToggle && navLinksContainer) {
    mobileToggle.addEventListener('click', () => {
      navLinksContainer.classList.toggle('open');
    });

    navLinksContainer.querySelectorAll('a').forEach((link) => {
      link.addEventListener('click', () => {
        navLinksContainer.classList.remove('open');
      });
    });
  }
}
