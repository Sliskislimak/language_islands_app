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
    navFaq: "FAQ",

    // Hero
    heroBadge: "🌸 日本の友だちへ贈る特別ガイド",
    heroTitle: "iPhoneで始める<br><span class=\"highlight\">ポーランド語 & 日本語</span> 相互学習",
    heroDesc: "公式App Storeにはない、私たち2人だけの特製語学学習アプリ「Language Islands」。SideStoreを使ってiPhoneに無料でインストールし、毎日フレーズを交換しながら楽しく学べるまでの全手順をまとめました。",
    
    // Personal Letter
    letterHeader: "💌 Jakubからのメッセージ",
    letterBody: "「こんにちは！私たちが一緒にポーランド語と日本語を学び合えるアプリを作りました。私のアプリにはあなたが教えてくれた日本語が表示され、あなたのアプリには私が作ったポーランド語（ネイティブ音声＆カタカナ発音付き）が届きます！最初の設定だけ少し手順がありますが、このページを見ながら進めれば大丈夫です。一緒に頑張りましょう！」",
    letterSign: "— Jakub より",

    // Checklist Progress
    progressTitle: "設定ステップ完了度",
    step1Check: "1. WireGuard & SideStore 導入",
    step2Check: "2. アプリ (Runner.ipa) インストール",
    step3Check: "3. ポーランド語 (Polski) 学習設定",
    step4Check: "4. 文の共有 (Gist) 接続完了",

    // Two-Way Learning Box
    twoWayTitle: "アプリで実現する2人の学習交換",
    twoWayFriendTitle: "あなた (Friend in Japan)",
    twoWayFriendTarget: "🇵🇱 ポーランド語を学習",
    twoWayFriendF1: "ネイティブのポーランド語音声（Marek / Zofia）",
    twoWayFriendF2: "難しい発音も安心な「カタカナ読み補助」",
    twoWayFriendF3: "シャドーイング＆アクティブリコール特訓",
    twoWayFriendF4: "ワンタップでJakubへ日本語フレーズを送信！",

    twoWayJakubTitle: "Jakub (Poland)",
    twoWayJakubTarget: "🇯🇵 日本語を学習",
    twoWayJakubF1: "あなたが送信した日常の日本語を練習",
    twoWayJakubF2: "漢字・カタカナ・ローマ字対応",
    twoWayJakubF3: "あなたが学ぶためのポーランド語文を作成して送信",

    twoWayCenterBadge: "Gistで双方向同期",

    // Section 1: Why SideStore
    sec1Tag: "OVERVIEW",
    sec1Title: "SideStore（サイドストア）とは？ なぜ必要なの？",
    sec1Desc: "Appleの公式App Storeは、年間約15,000円の開発者登録費や審査が必要です。個人間のプライベートアプリをiPhoneに入れるため、Apple公式の仕組みを利用した「サイドローディング（SideStore）」を使用します。",
    sec1SafeTitle: "安全性について安心してください",
    sec1SafeBody: "脱獄（Jailbreak）ではありません。Appleが公式に提供している個人デベロッパ証明書を使って、あなたのiPhoneだけに直接署名してインストールする完全合法かつ安全な方法です。",
    sec1Feature1Title: "PC不要で更新可能",
    sec1Feature1Desc: "従来のAltStoreと違い、最初の1回だけPCを使えば、以後はiPhone内のWireGuard VPNを使ってどこでもワイヤレス更新できます。",

    // Section 2: SideStore Setup
    sec2Tag: "STEP 1",
    sec2Title: "SideStoreの初期セットアップ（最初の1回のみ）",
    sec2Desc: "初回のみ、パソコン（Windows または Mac）を使ってSideStoreをiPhoneに転送します。約10〜15分で完了します。",
    prepTitle: "準備するもの",
    prepItem1: "お使いのiPhone（iOS 14以降、iOS 16/17/18対応）",
    prepItem2: "パソコン（Windows または Mac）※初回1回のみ使用",
    prepItem3: "iPhoneとPCを繋ぐUSBケーブル",
    prepItem4: "Apple ID（普段お使いのものでOK）",

    step11Title: "iPhoneでWireGuardをインストール＆設定",
    step11Desc: "SideStoreがiPhone単体でアプリを更新できるように、仮想VPN「WireGuard」を使用します。",
    wireguardAppStoreBtn: "App StoreでWireGuardを入手",
    downloadConfBtn: "SideStore.conf をダウンロード",
    wireguardNote: "ダウンロード後、WireGuardアプリを開き「トンネルの追加」→「ファイルからインポート」で「SideStore.conf」を選択して有効化（緑色のON）にしてください。",

    step12Title: "iPhoneの「デベロッパモード」をONにする（iOS 16以降）",
    step12Desc: "iOS 16、17、18をお使いの場合、外部アプリの起動を許可するモードを有効にします。",
    devModePath: "設定 → プライバシーとセキュリティ → デベロッパモード",
    devModeNote: "スイッチをONにするとiPhoneの再起動を求められます。再起動後に「オンにする」をタップし、パスコードを入力すれば完了です。",

    step13Title: "パソコンでのSideServerインストール",
    winTab: "Windows の場合",
    macTab: "Mac の場合",
    winStep1: "1. Apple公式サイトから <strong>iTunes</strong> と <strong>iCloud</strong>（※Microsoft Store版ではなく、必ずスタンドアロン版）をインストールします。",
    winStep2: "2. <strong>SideServer for Windows</strong> をダウンロードして解凍し、起動します。",
    winStep3: "3. iPhoneをUSBケーブルでPCに接続し、iPhone画面で「このコンピュータを信頼する」をタップします。",
    winStep4: "4. タスクバー右下のSideServerアイコンをクリックし、「Install SideStore」からお使いのiPhoneを選択し、Apple IDとパスワードを入力します。",
    macStep1: "1. <strong>SideServer for macOS</strong> をダウンロードし、「アプリケーション」フォルダへ移動します。",
    macStep2: "2. SideServerを起動し、メニューバーのアイコンをクリックします。",
    macStep3: "3. iPhoneをケーブルでMacに接続し、Finderで「信頼」をクリックします。",
    macStep4: "4. SideServerメニューから「Install SideStore」を選択し、Apple IDを入力します。",

    step14Title: "iPhoneでデベロッパアプリを「信頼」する",
    trustPath: "設定 → 一般 → VPNとデバイス管理 → デベロッパApp (あなたのApple ID)",
    trustNote: "「（Apple ID）を信頼」をタップして確認を押します。これでSideStoreが起動できるようになります！",

    step15Title: "SideStoreの初期起動＆ペアリングファイル",
    step15Desc: "WireGuardでVPNをON（有効）にした状態でSideStoreを開きます。画面の指示に従ってペアリングファイルを選択し、Apple IDでサインインします。",

    // Section 3: App Install
    sec3Tag: "STEP 2",
    sec3Title: "アプリ（Language Islands）をiPhoneにインストール",
    sec3Desc: "SideStoreの準備ができたら、いよいよアプリ本体（Runner.ipa）をインストールします。",
    downloadIpaBtn: "Runner.ipa (最新版アプリ) をダウンロード",
    appInstallStep1: "1. iPhoneのSafariで上記の「Runner.ipa をダウンロード」ボタンをタップします。",
    appInstallStep2: "2. <strong>WireGuard</strong> アプリを開き、VPNが <strong>ON（有効）</strong> になっていることを確認します。",
    appInstallStep3: "3. <strong>SideStore</strong> を開き、下の「My Apps」タブを表示します。",
    appInstallStep4: "4. 左上の <strong>「＋」</strong> アイコンをタップし、先ほどダウンロードした <code>Runner.ipa</code> を選択します。",
    appInstallStep5: "5. インストールが進行し、完了するとiPhoneのホーム画面に <strong>Language Islands</strong> のアイコンが追加されます！🎉",
    weeklyRefreshTitle: "💡 週に1回のリフレッシュについて（5秒で完了）",
    weeklyRefreshDesc: "無料のApple IDで入れたアプリは7日間の有効期限があります。期限が切れる前に、iPhoneで「WireGuardのVPNをON」にし、「SideStoreを開いて Refresh All を押す」だけで自動延長されます（PCはもう不要です！）。",

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
    
    syncSetupTitle: "1. 共有データベース（Gist）の接続",
    syncStep1: "1. アプリ右上の <strong>「︙」</strong> メニューをタップします。",
    syncStep2: "2. <strong>「Zdalna baza zdań / Synchronizacja」</strong>（雲の同期アイコン）をタップします。",
    syncStep3: "3. 以下の「共有URL」をコピーして、入力欄に貼り付けます。",
    copyGistBtn: "Gist URLをコピー",
    syncStep4: "4. <strong>「起動時に自動同期」</strong>（Auto-sync on startup）のスイッチをONにします。",
    syncStep5: "5. <strong>「今すぐ同期」</strong>（Synchronizuj teraz）をタップします。これでJakubが作ったポーランド語レッスンが一気に届きます！",

    sendPhraseTitle: "2. あなたからJakubへ「日本語フレーズ」を送る方法",
    sendIntro: "Jakubに勉強してほしい日常会話や好きな表現をいつでも送れます！",
    sendStep1: "1. アプリ上部の <strong>紙飛行機 / ハートアイコン</strong> またはメニュー「︙」から <strong>「Dla Przyjaciela / Wyślij zwrot」</strong> をタップします。",
    sendStep2: "2. 上部の切替タブが <strong>「日本語 (Dla Jakuba / 友だちへ)」</strong> になっていることを確認します。",
    sendStep3: "3. 以下の4項目を入力します：",
    sendF1: "・ <strong>1. 日本語（漢字・ひらがな）</strong>：例「これ、すごく美味しいよ！」",
    sendF2: "・ <strong>2. カタカナ読み</strong>：例「コレ、スゴク オイシイ ヨ！」",
    sendF3: "・ <strong>3. ローマ字</strong>：例「Kore, sugoku oishii yo!」",
    sendF4: "・ <strong>4. 意味・メモ</strong>：例「To jest naprawdę pyszne!」やシチュエーション",
    sendStep4: "4. <strong>「送信 / 送る」</strong> ボタンをタップします！",
    sendResult: "これだけで共有データベースに送信され、Jakubがアプリを開いたときに自動的にあなたの日本語フレーズが学習リストに加わります！🌸",

    // Mockup Section
    mockupTitle: "アプリの画面プレビュー",
    mockTab1: "学習カード（ポーランド語）",
    mockTab2: "Jakubへフレーズ送信画面",
    mockTab3: "リモート同期画面",

    // FAQ Section
    faqTitle: "よくある質問・トラブルシューティング",
    faqQ1: "SideStoreで「Cannot connect to SideServer / Device」と出ます",
    faqA1: "WireGuardアプリを開き、VPNが有効（緑色のスイッチON）になっていることを確認してください。VPNが切れているとSideStoreは動作しません。",
    faqQ2: "アプリを開こうとすると「信頼されていない開発元」と出ます",
    faqA2: "iPhoneの「設定」→「一般」→「VPNとデバイス管理」を開き、あなたのApple IDをタップして「信頼」を押してください。",
    faqQ3: "音声が再生されません",
    faqA3: "iPhone本体の左側面にある着信/消音スイッチ（マナーモード）が消音（オレンジ色）になっていないか、音量がゼロになっていないか確認してください。",
    faqQ4: "7日経つとアプリが消えてしまいますか？",
    faqA4: "消えません！学習データや送った文もすべてiPhone内に安全に残ります。WireGuardをONにしてSideStoreで「Refresh All」を押せば、いつでもすぐに復活します。",
    faqQ5: "新しいバージョンが出たときはどうすればいいですか？",
    faqA5: "新しい「Runner.ipa」をダウンロードし、SideStoreの「＋」ボタンから追加で読み込むだけです。これまでのデータは消えずにそのままアップデートされます。",

    // Resource Hub
    resourceTitle: "ダウンロード＆リンク集",
    resWireguardTitle: "WireGuard (iOS)",
    resWireguardDesc: "SideStore動作に必須の公式VPNアプリ",
    resConfTitle: "SideStore.conf",
    resConfDesc: "WireGuard用設定ファイル（ダウンロードして読み込み）",
    resAppTitle: "Language Islands IPA",
    resAppDesc: "最新のRunner.ipaアプリ本体",
    resSideServerWin: "SideServer (Windows)",
    resSideServerWinDesc: "Windows用初期インストーラー",
    resSideServerMac: "SideServer (macOS)",
    resSideServerMacDesc: "Mac用初期インストーラー",

    // Footer
    footerNote: "Jakubと友だちのための特製語学学習プロジェクト",
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
    navFaq: "FAQ",

    heroBadge: "🌸 Special Guide for My Friend in Japan",
    heroTitle: "Learn <span class=\"highlight\">Polish & Japanese</span><br>Together on iPhone",
    heroDesc: "A custom language exchange app built exclusively for the two of us. Step-by-step instructions on how to install 'Language Islands' via SideStore on your iPhone for free, configure Polish learning, and exchange daily sentences seamlessly.",

    letterHeader: "💌 A message from Jakub",
    letterBody: "\"Hello! I built this application so we can learn Polish and Japanese together. In my app, I practice the Japanese sentences you give me. In your app, you receive the Polish sentences I prepare with native neural audio and Katakana phonetic guides! It only takes a few minutes to set up, and this guide walks you through every step. Let's do our best!\"",
    letterSign: "— From Jakub",

    progressTitle: "Setup Completion Progress",
    step1Check: "1. WireGuard & SideStore Setup",
    step2Check: "2. Install App (Runner.ipa)",
    step3Check: "3. Configure Polish (Polski) Mode",
    step4Check: "4. Connect Shared Gist Database",

    twoWayTitle: "Our Two-Way Language Exchange",
    twoWayFriendTitle: "You (Friend in Japan)",
    twoWayFriendTarget: "🇵🇱 Learning Polish",
    twoWayFriendF1: "Native Polish neural audio (Marek / Zofia)",
    twoWayFriendF2: "Katakana phonetic reading guide for tricky Polish sounds",
    twoWayFriendF3: "Shadowing & Active Recall practice modes",
    twoWayFriendF4: "1-tap send Japanese phrases straight to Jakub!",

    twoWayJakubTitle: "Jakub (Poland)",
    twoWayJakubTarget: "🇯🇵 Learning Japanese",
    twoWayJakubF1: "Practices everyday Japanese sentences sent by you",
    twoWayJakubF2: "Kanji, Katakana & Romaji support",
    twoWayJakubF3: "Creates Polish sentences for you to study",

    twoWayCenterBadge: "Gist Two-Way Sync",

    sec1Tag: "OVERVIEW",
    sec1Title: "What is SideStore and Why do we use it?",
    sec1Desc: "Publishing to the official Apple App Store costs $99/year and requires public review. SideStore is a free, safe, open-source tool that allows us to sideload our private app directly onto your personal iPhone.",
    sec1SafeTitle: "Completely Safe & Legal",
    sec1SafeBody: "This is NOT jailbreaking. It uses Apple's official personal developer signing system to sign and install the app inside a safe sandbox on your iPhone.",
    sec1Feature1Title: "Wirelessly Refreshes Without a PC",
    sec1Feature1Desc: "Unlike older AltStore methods, you only need a PC once for the initial setup. After that, SideStore refreshes apps directly on your iPhone using the local WireGuard VPN!",

    sec2Tag: "STEP 1",
    sec2Title: "Initial SideStore Setup (One-time only)",
    sec2Desc: "You will only need a computer (Windows PC or Mac) for the first 10-15 minutes.",
    prepTitle: "Prerequisites",
    prepItem1: "Your iPhone (iOS 14+, supports iOS 16/17/18)",
    prepItem2: "A computer (Windows or Mac) - only for initial setup",
    prepItem3: "USB cable to connect iPhone to PC",
    prepItem4: "Your regular Apple ID",

    step11Title: "Install WireGuard on iPhone & Import SideStore Config",
    step11Desc: "WireGuard acts as an on-device loopback VPN so SideStore can sign apps wirelessly.",
    wireguardAppStoreBtn: "Get WireGuard on App Store",
    downloadConfBtn: "Download SideStore.conf",
    wireguardNote: "After downloading, open WireGuard -> tap 'Add tunnel' -> 'Import from file' -> choose 'SideStore.conf' -> toggle it ON (green switch).",

    step12Title: "Turn ON Developer Mode (iOS 16, 17, 18)",
    step12Desc: "Required on iOS 16+ to run custom sideloaded apps.",
    devModePath: "Settings → Privacy & Security → Developer Mode",
    devModeNote: "Toggle it ON and restart your iPhone. After reboot, tap 'Turn On' and enter your passcode.",

    step13Title: "Install SideServer on your PC / Mac",
    winTab: "Windows",
    macTab: "macOS",
    winStep1: "1. Install standalone <strong>iTunes</strong> and <strong>iCloud</strong> from Apple (do NOT use Microsoft Store versions).",
    winStep2: "2. Download and extract <strong>SideServer for Windows</strong> and run it.",
    winStep3: "3. Connect iPhone to PC with USB cable, tap 'Trust this computer' on your iPhone.",
    winStep4: "4. Click SideServer in system tray -> 'Install SideStore' -> select your iPhone -> enter Apple ID.",
    macStep1: "1. Download <strong>SideServer for macOS</strong> and move to Applications.",
    macStep2: "2. Open SideServer from the menu bar.",
    macStep3: "3. Connect iPhone with cable, trust computer in Finder.",
    macStep4: "4. Click SideServer -> 'Install SideStore' -> enter Apple ID.",

    step14Title: "Trust Developer Certificate on iPhone",
    trustPath: "Settings → General → VPN & Device Management → Developer App (Your Apple ID)",
    trustNote: "Tap 'Trust (Your Apple ID)' to confirm. You can now launch SideStore!",

    step15Title: "First Launch & Pairing File",
    step15Desc: "With WireGuard VPN turned ON, open SideStore. Follow the prompt to select the pairing file and sign in with your Apple ID.",

    sec3Tag: "STEP 2",
    sec3Title: "Install Language Islands (Runner.ipa)",
    sec3Desc: "Now you can install the Language Islands app onto your iPhone home screen.",
    downloadIpaBtn: "Download Runner.ipa (Latest App Build)",
    appInstallStep1: "1. Tap 'Download Runner.ipa' above in Safari on your iPhone.",
    appInstallStep2: "2. Ensure <strong>WireGuard</strong> VPN is <strong>ON</strong>.",
    appInstallStep3: "3. Open <strong>SideStore</strong> and go to the 'My Apps' tab.",
    appInstallStep4: "4. Tap the <strong>'+'</strong> button in the top left and select <code>Runner.ipa</code> from Downloads.",
    appInstallStep5: "5. Installation will complete and the <strong>Language Islands</strong> icon appears on your home screen! 🎉",
    weeklyRefreshTitle: "💡 The 7-Day Refresh (Takes 5 seconds)",
    weeklyRefreshDesc: "Apps installed with a free Apple ID last 7 days. Once a week, simply turn WireGuard VPN ON, open SideStore, and tap 'Refresh All'. No PC needed ever again!",

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

    syncSetupTitle: "1. Connect Shared Gist",
    syncStep1: "1. Tap the <strong>'︙'</strong> menu in the app.",
    syncStep2: "2. Tap <strong>'Zdalna baza zdań / Synchronizacja'</strong> (Remote Sync).",
    syncStep3: "3. Copy the Gist URL below and paste it into the URL field.",
    copyGistBtn: "Copy Gist URL",
    syncStep4: "4. Turn ON <strong>'Auto-sync on startup'</strong>.",
    syncStep5: "5. Tap <strong>'Synchronizuj teraz' (Sync now)</strong> to download all Polish lessons from Jakub!",

    sendPhraseTitle: "2. How to Send Japanese Sentences to Jakub",
    sendIntro: "Whenever you think of a useful Japanese expression, you can send it to Jakub in 1 tap!",
    sendStep1: "1. Tap the <strong>Send / Heart icon</strong> or menu '︙' -> <strong>'Dla Przyjaciela / Wyślij zwrot'</strong>.",
    sendStep2: "2. Make sure the tab is set to <strong>'日本語 (Dla Jakuba / 友だちへ)'</strong>.",
    sendStep3: "3. Enter the 4 fields:",
    sendF1: "• <strong>1. Japanese (Kanji/Kana)</strong>: e.g. これ、すごく美味しいよ！",
    sendF2: "• <strong>2. Katakana Reading</strong>: e.g. コレ、スゴク オイシイ ヨ！",
    sendF3: "• <strong>3. Romaji</strong>: e.g. Kore, sugoku oishii yo!",
    sendF4: "• <strong>4. Meaning / Notes</strong>: e.g. 'To jest naprawdę pyszne!'",
    sendStep4: "4. Tap <strong>'送信 / Send'</strong>!",
    sendResult: "The sentence is saved to the shared database. When Jakub opens his app, your Japanese sentence appears in his daily study queue! 🌸",

    mockupTitle: "Interactive App Preview",
    mockTab1: "Practice Card (Polish)",
    mockTab2: "Send Phrase to Jakub",
    mockTab3: "Remote Sync Dialog",

    faqTitle: "Frequently Asked Questions & Troubleshooting",
    faqQ1: "SideStore says 'Cannot connect to SideServer / Device'?",
    faqA1: "Open the WireGuard app and ensure the VPN is turned ON (green switch). SideStore requires WireGuard to communicate on-device.",
    faqQ2: "iPhone says 'Untrusted Developer' when opening the app?",
    faqA2: "Go to iPhone Settings -> General -> VPN & Device Management -> Tap your Apple ID -> Tap 'Trust'.",
    faqQ3: "I can't hear any audio playback?",
    faqA3: "Check the physical Ring/Silent switch on the left side of your iPhone to make sure it's not on silent (orange), and increase media volume.",
    faqQ4: "Will my app disappear after 7 days?",
    faqA4: "No! Your sentences and history remain completely safe. Just toggle WireGuard ON, open SideStore, and tap 'Refresh All' to renew the 7-day certificate.",
    faqQ5: "How do I update when Jakub releases a new version?",
    faqA5: "Download the new Runner.ipa and tap the '+' button in SideStore. It will update in place without losing any data!",

    resourceTitle: "Download & Resource Hub",
    resWireguardTitle: "WireGuard (iOS)",
    resWireguardDesc: "Official VPN client required for wireless refreshes",
    resConfTitle: "SideStore.conf",
    resConfDesc: "WireGuard configuration file (import into WireGuard)",
    resAppTitle: "Language Islands IPA",
    resAppDesc: "Latest Runner.ipa application file",
    resSideServerWin: "SideServer (Windows)",
    resSideServerWinDesc: "One-time installer for Windows",
    resSideServerMac: "SideServer (macOS)",
    resSideServerMacDesc: "One-time installer for macOS",

    footerNote: "Custom language exchange app for Jakub & his friend in Japan",
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
    navFaq: "FAQ",

    heroBadge: "🌸 Przewodnik dla mojej przyjaciółki z Japonii",
    heroTitle: "Wspólna nauka <span class=\"highlight\">polskiego i japońskiego</span><br>na iPhone",
    heroDesc: "Aplikacja stworzona specjalnie dla nas do wzajemnej nauki języków. Kompletna instrukcja krok po kroku: jak za darmo zainstalować aplikację na iPhone za pomocą SideStore, jak ustawić naukę języka polskiego i jak przesyłać sobie nawzajem zdania.",

    letterHeader: "💌 Wiadomość od Jakuba",
    letterBody: "„Cześć! Stworzyłem tę aplikację, abyśmy mogli wspólnie uczyć się polskiego i japońskiego. W mojej aplikacji ćwiczę japońskie zdania, które mi przesyłasz, a w Twojej aplikacji pojawiają się zdania po polsku z polskim lektorem i transkrypcją w katakanie! Pierwsza konfiguracja zajmuje tylko chwilę — przygotowałem tę stronę, aby poprowadzić Cię krok po kroku. Damy radę!”",
    letterSign: "— Jakub",

    progressTitle: "Postęp konfiguracji",
    step1Check: "1. Instalacja WireGuard i SideStore",
    step2Check: "2. Instalacja aplikacji (Runner.ipa)",
    step3Check: "3. Konfiguracja języka polskiego",
    step4Check: "4. Połączenie wspólnej bazy (Gist)",

    twoWayTitle: "Dwukierunkowa wymiana zdań",
    twoWayFriendTitle: "Przyjaciółka (Japonia)",
    twoWayFriendTarget: "🇵🇱 Uczy się polskiego",
    twoWayFriendF1: "Polski lektor neuralny (Marek / Zofia)",
    twoWayFriendF2: "Wymowa w katakanie pod każdym zdaniem",
    twoWayFriendF3: "Trening Shadowing i Active Recall",
    twoWayFriendF4: "1 kliknięciem wysyła zdania po japońsku dla Jakuba!",

    twoWayJakubTitle: "Jakub (Polska)",
    twoWayJakubTarget: "🇯🇵 Uczy się japońskiego",
    twoWayJakubF1: "Ćwiczy japońskie zdania przesłane przez Ciebie",
    twoWayJakubF2: "Kanji, kana, katakana i romaji",
    twoWayJakubF3: "Przygotowuje zdania po polsku z wyjaśnieniami",

    twoWayCenterBadge: "Synchronizacja przez Gist",

    sec1Tag: "PRZEGLĄD",
    sec1Title: "Czym jest SideStore i dlaczego go używamy?",
    sec1Desc: "Oficjalny App Store Apple wymaga opłaty 99$ rocznie i publicznej weryfikacji. SideStore to darmowe, bezpieczne narzędzie open-source, które pozwala zainstalować naszą prywatną aplikację bezpośrednio na Twoim iPhone.",
    sec1SafeTitle: "Całkowicie bezpieczne i legalne",
    sec1SafeBody: "To NIE jest żaden jailbreak. Używa oficjalnego mechanizmu Apple dla prywatnych deweloperów i działa w bezpiecznej piaskownicy iOS.",
    sec1Feature1Title: "Odświeżanie bez komputera",
    sec1Feature1Desc: "W przeciwieństwie do AltStore, komputer jest potrzebny tylko raz. Później SideStore odświeża certyfikat bezpośrednio na iPhone przez WireGuard VPN!",

    sec2Tag: "KROK 1",
    sec2Title: "Wstępna instalacja SideStore (tylko 1 raz)",
    sec2Desc: "Komputer (Windows lub Mac) będzie Ci potrzebny tylko na około 10-15 minut na sam start.",
    prepTitle: "Co jest potrzebne:",
    prepItem1: "Twój iPhone (iOS 14+, w tym iOS 16/17/18)",
    prepItem2: "Komputer (Windows lub Mac) – tylko na start",
    prepItem3: "Kabel USB do połączenia telefonu z komputerem",
    prepItem4: "Twoje konto Apple ID",

    step11Title: "Zainstaluj WireGuard na iPhone i dodaj SideStore.conf",
    step11Desc: "WireGuard służy jako lokalny VPN, dzięki któremu SideStore odświeża aplikację bezprzewodowo.",
    wireguardAppStoreBtn: "Pobierz WireGuard z App Store",
    downloadConfBtn: "Pobierz SideStore.conf",
    wireguardNote: "Po pobraniu otwórz WireGuard -> Dodaj tunel -> Importuj z pliku -> Wybierz SideStore.conf i włącz (zielony przełącznik).",

    step12Title: "Włącz Tryb Dewelopera (iOS 16, 17, 18)",
    step12Desc: "Wymagane na nowszych iOS, aby uruchamiać własne aplikacje.",
    devModePath: "Ustawienia → Prywatność i ochrona → Tryb dewelopera",
    devModeNote: "Włącz przełącznik i uruchom ponownie iPhone. Po restarcie kliknij „Włącz” i wpisz kod blokady.",

    step13Title: "Instalacja SideServer na komputerze",
    winTab: "Windows",
    macTab: "macOS",
    winStep1: "1. Zainstaluj <strong>iTunes</strong> i <strong>iCloud</strong> ze strony Apple (nie ze sklepu Microsoft Store!).",
    winStep2: "2. Pobierz i wypakuj <strong>SideServer dla Windows</strong>, a następnie go uruchom.",
    winStep3: "3. Podłącz iPhone kablem USB i kliknij „Ufaj temu komputerowi”.",
    winStep4: "4. W zasobniku systemowym kliknij SideServer -> 'Install SideStore' -> wybierz swój iPhone -> wpisz Apple ID.",
    macStep1: "1. Pobierz <strong>SideServer dla macOS</strong> i przenieś do Aplikacji.",
    macStep2: "2. Otwórz SideServer z paska menu.",
    macStep3: "3. Podłącz iPhone kablem, zaufaj komputerowi w Finderze.",
    macStep4: "4. Kliknij 'Install SideStore' i podaj Apple ID.",

    step14Title: "Zaufaj certyfikatowi na iPhone",
    trustPath: "Ustawienia → Ogólne → VPN i zarządzanie urządzeniami → Aplikacja dewelopera",
    trustNote: "Kliknij swój adres Apple ID i wybierz „Zaufaj”.",

    step15Title: "Pierwsze uruchomienie SideStore",
    step15Desc: "Mając włączony WireGuard VPN, otwórz SideStore. Wybierz plik pairing file i zaloguj się Apple ID.",

    sec3Tag: "KROK 2",
    sec3Title: "Instalacja aplikacji Language Islands (Runner.ipa)",
    sec3Desc: "Gdy SideStore działa, wystarczy wgrać plik aplikacji na iPhone.",
    downloadIpaBtn: "Pobierz Runner.ipa (Aplikacja)",
    appInstallStep1: "1. Kliknij „Pobierz Runner.ipa” powyżej w Safari na iPhone.",
    appInstallStep2: "2. Upewnij się, że <strong>WireGuard</strong> VPN jest <strong>włączony</strong>.",
    appInstallStep3: "3. Otwórz <strong>SideStore</strong> i przejdź do zakładki 'My Apps'.",
    appInstallStep4: "4. Kliknij ikonę <strong>'+'</strong> w lewym górnym rogu i wybierz plik <code>Runner.ipa</code> z Pobranych.",
    appInstallStep5: "5. Aplikacja <strong>Language Islands</strong> pojawi się na Twoim ekranie głównym! 🎉",
    weeklyRefreshTitle: "💡 Odświeżanie co 7 dni (zajmuje 5 sekund)",
    weeklyRefreshDesc: "Darmowe konto Apple ID wymaga odświeżenia aplikacji co 7 dni. Wystarczy raz w tygodniu włączyć WireGuard VPN na telefonie, wejść do SideStore i kliknąć 'Refresh All' (bez użycia komputera!).",

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
    sec5Desc: "Połączenie aplikacji przez Gist pozwala na dwukierunkową wymianę zdań.",

    syncSetupTitle: "1. Połączenie ze wspólnym Gistem",
    syncStep1: "1. Otwórz menu <strong>'︙'</strong> w aplikacji.",
    syncStep2: "2. Kliknij <strong>'Zdalna baza zdań / Synchronizacja'</strong>.",
    syncStep3: "3. Wklej poniższy adres URL wspólnego Gista:",
    copyGistBtn: "Kopiuj adres Gist URL",
    syncStep4: "4. Włącz opcję <strong>'Automatyczna synchronizacja przy starcie'</strong>.",
    syncStep5: "5. Kliknij <strong>'Synchronizuj teraz'</strong>, aby pobrać lekcje polskiego przygotowane przez Jakuba!",

    sendPhraseTitle: "2. Jak wysyłać zdania po japońsku dla Jakuba",
    sendIntro: "Gdy chcesz przekazać Jakubowi przydatny japoński zwrot:",
    sendStep1: "1. Kliknij ikonę serca/wysyłania lub menu '︙' -> <strong>'Dla Przyjaciela / Wyślij zwrot'</strong>.",
    sendStep2: "2. Wybierz zakładkę <strong>'日本語 (Dla Jakuba / 友だちへ)'</strong>.",
    sendStep3: "3. Wypełnij pola:",
    sendF1: "• <strong>1. Japoński (Kanji/Kana)</strong>: np. これ、すごく美味しいよ！",
    sendF2: "• <strong>2. Wymowa w katakanie</strong>: np. コレ、スゴク オイシイ ヨ！",
    sendF3: "• <strong>3. Rōmaji</strong>: np. Kore, sugoku oishii yo!",
    sendF4: "• <strong>4. Znaczenie / Notatki</strong>: np. 'To jest naprawdę pyszne!'",
    sendStep4: "4. Kliknij przycisk <strong>'Wyślij'</strong>!",
    sendResult: "Zdanie trafi do wspólnej bazy, a Jakub zobaczy je w swojej aplikacji do nauki japońskiego! 🌸",

    mockupTitle: "Podgląd ekranów aplikacji",
    mockTab1: "Karta nauki polskiego",
    mockTab2: "Wysyłanie zwrotu do Jakuba",
    mockTab3: "Zdalna synchronizacja",

    faqTitle: "Często zadawane pytania (FAQ)",
    faqQ1: "SideStore zgłasza błąd 'Cannot connect to SideServer / Device'?",
    faqA1: "Otwórz WireGuard i upewnij się, że VPN jest włączony (zielony suwak). SideStore wymaga aktywnego WireGuard.",
    faqQ2: "Komunikat 'Nie zaufano deweloperowi' przy otwieraniu aplikacji?",
    faqA2: "Wejdź w Ustawienia iPhone -> Ogólne -> VPN i zarządzanie urządzeniami -> Wybierz swój Apple ID -> Kliknij „Zaufaj”.",
    faqQ3: "Brak dźwięku w aplikacji?",
    faqA3: "Sprawdź fizyczny przełącznik wyciszenia z boku iPhone'a (czy nie widać pomarańczowego paska) oraz podgłośnij dźwięk multimediów.",
    faqQ4: "Czy po 7 dniach aplikacja zniknie z telefonu?",
    faqA4: "Nie! Wystarczy raz w tygodniu włączyć WireGuard na telefonie i kliknąć 'Refresh All' w SideStore.",
    faqQ5: "Jak zaktualizować aplikację do nowszej wersji?",
    faqA5: "Pobierz nowy plik Runner.ipa i dodaj go przez ikonę '+' w SideStore. Żadne dane nie zostaną utracone!",

    resourceTitle: "Centrum pobierania",
    resWireguardTitle: "WireGuard (iOS)",
    resWireguardDesc: "Oficjalny klient VPN z App Store",
    resConfTitle: "SideStore.conf",
    resConfDesc: "Plik konfiguracji WireGuard",
    resAppTitle: "Language Islands IPA",
    resAppDesc: "Plik instalacyjny Runner.ipa",
    resSideServerWin: "SideServer (Windows)",
    resSideServerWinDesc: "Instalator na Windows",
    resSideServerMac: "SideServer (macOS)",
    resSideServerMacDesc: "Instalator na macOS",

    footerNote: "Aplikacja do wspólnej nauki języków dla Jakuba i Przyjaciółki",
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

  if (paramGist) {
    const gistUrlText = document.getElementById('gistUrlText');
    const copyGistBtn = document.querySelector('[data-i18n="copyGistBtn"]');
    if (gistUrlText) gistUrlText.textContent = paramGist;
    if (copyGistBtn) copyGistBtn.setAttribute('data-copy', paramGist);
  }

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

  langBtn.addEventListener('click', (e) => {
    e.stopPropagation();
    langDropdown.classList.toggle('open');
  });

  document.addEventListener('click', () => {
    langDropdown.classList.remove('open');
  });

  document.querySelectorAll('.lang-opt').forEach((btn) => {
    btn.addEventListener('click', () => {
      const selected = btn.getAttribute('data-lang');
      if (translations[selected]) {
        currentLang = selected;
        localStorage.setItem('lang_islands_lang', currentLang);
        applyLanguage(currentLang);
        langDropdown.classList.remove('open');
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

  themeToggle.addEventListener('click', () => {
    const active = document.documentElement.getAttribute('data-theme') === 'light' ? 'dark' : 'light';
    document.documentElement.setAttribute('data-theme', active);
    localStorage.setItem('lang_islands_theme', active);
    updateThemeIcon(active);
  });
}

function updateThemeIcon(theme) {
  const themeToggle = document.getElementById('themeToggle');
  themeToggle.innerHTML = theme === 'light' ? '🌙' : '☀️';
  themeToggle.setAttribute('title', theme === 'light' ? 'Switch to Dark Mode' : 'Switch to Light Mode');
}

// Checklist & progress calculation
function initChecklist() {
  const checkboxes = document.querySelectorAll('.checklist-item input[type="checkbox"]');
  const progressBar = document.getElementById('progressBar');
  const progressPct = document.getElementById('progressPct');

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
