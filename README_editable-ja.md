このディレクトリーにはさまざまな異なる種類のAndroidマシンを意図した、複数のインストール用パッケージがある。  

```text
emacs-3*.0.*0-16-armeabi-v7a.apk - armv7 devices running Android 4.1 or later.
emacs-3*.0.*0-24-armeabi-v7a.apk - armv7 devices running Android 7.0 or later.
emacs-3*.0.*0-21-arm64-v8a.apk - aarch64 devices running Android 5.0 or later.
emacs-3*.0.*0-29-arm64-v8a.apk - aarch64 devices running Android 10.0 or later.
emacs-3*.0.*0-21-mips64.apk - mips64 devices running Android 5.0 or later.
emacs-3*.0.*0-21-x86_64.apk - x86_64 devices running Android 5.0 or later.
emacs-3*.0.*0-29-x86_64.apk - x86_64 devices running Android 10.0 or later.
emacs-3*.0.*0-9-armeabi.apk - armeabi devices running Android 2.3 or later.
emacs-3*.0.*0-9-mips.apk - mips devices running Android 2.3 or later.
emacs-3*.0.*0-9-x86.apk	- x86 devices running Android 2.3 or later.
emacs-3*.0.*0-8-armeabi.apk - armeabi devices running Android 2.2.
```

如何なる時もあなたのAndroidシステムが使用しているCPU向けパッケージをインストールすること。他のシステムと互換性のあるパッケージ(たとえばx86_64システムにx86パッケージをインストールするなど)をインストールすると、サブプロセスの実行に失敗するだろう。  

上記に加えてディレクトリー`termux`には`shared user ID`を`com.termux`にセットしてビルド、さらにEmacsの署名キーで署名したバージョンのTermux端末エミュレータのインストール様パッケージのコピーが含まれている。これらのパッケージを合わせるとTermuxのパッケージレポジトリ使用できるEmacsが利用可能になる。  

Termuxサポート付きEmacsをインストールするためには、署名やユーザーIDの競合を防ぐためにまず既存のEmacsとTermuxのコピーをすべて削除する必要がある(Emacsのホームディレクトリー内のすべてのデータが削除されるので事前にバックアップすること!)。次は **まず最初に** Termux、その後にEmacs話インストールする。一度これらのパッケージを両方インストールしたらTermuxをオープンして、表示されたシェルプロンプトで以下をタイプする:  

```bash
$ pkg update && pkg upgrade
```

dpkgパッケージマネージャーが求める確認には同意していく。すべてのアプリケーションがインストールされて更新されたら、Emacsをオープンして以下のコードを`early-init.el`に記述する:  

```lisp
(setenv "PATH" (format "%s:%s" "/data/data/com.termux/files/usr/bin"
               (getenv "PATH")))
(push "/data/data/com.termux/files/usr/bin" exec-path)
```

Termuxでプログラムがインストールされれば、それらにEmacsがアクセスできるようになる。  

FAQのこのセクションでは、以前はTermuxからバイナリを実行するために環境変数`LD_LIBRARY_PATH`をセットするという誤った解説が提供されていた。実際にはTermuxの実行可能バイナリにはTermuxの共有ライブラリーのパスが埋め込まれており、Termuxのバイナリが実行される際のリンクプロセス中にインポートされる一連のライブラリーにたいして(逆も発生し得る)、別個に提供される`LD_LIBRARY_PATH`によるシステムライブラリー名の競合による干渉が原因の数多の奇妙なエラーが発生するのだ。  

Termux(とそれを使用するようにビルドしたEmacs)はAndroid 7.0以降にしかインストールできないことをどうか忘れないで欲しい。  

# FREQUENTLY ANSWERED QUESTIONS

このEmacsポートのユーザーから寄せられるFAQにたいする解答のほとんどは、同時に配布されているEmacsおよびLispのリファレンスマニュアルに答えを見い出すことができるだろう。にも関わらず前述したドキュメントの存在を知らない人の利益のために、さまざまなFAQのリストここにまとめておいた。  

## 1. どのパッケージをダウンロードすればいいの?  
おそらく`emacs-3*.0.*0-29-arm64-v8a.apk`か`termux`ディレクトリーの同等パッケージだろう。あなたのスマホやタブレットが32ビットOSを実行している場合は、多分`emacs-3*.0.*0-16-armeabi-v7a.apk`。

## 2. どのパッケージをインストールすると、どのバージョンのEmacsがインストールされるの?  

`emacs-30.0.90`という名前のパッケージは`emacs-30`ブランチから生成されており、最終的にはEmacs 30.1としてリリースされる。一方`emacs-31.0.50`という名前のパッケージは、すぐにはリリースされない開発ブランチから生成したパッケージ。  

パッケージ名のバージョンと変数emacs-versionによってプリントされるバージョンは、プレテスト(訳注: pretest、いわゆるベータ版のようなもの)のいずれかに相当するバージョンではあるがGitレポジトリのソースからビルドされており、プレテストのバージョンが同じであっても厳密にそのバージョンのソースからビルドされている保証はない。  

## 3. どこで助けを得られるだろうか?  

help-gnu-emacs@gnu.orgだ。  

## 4. バグレポやpatchはどこに送付すれば?  

bug-gnu-emacs@gnu.orgだ。  

## 5. どうやってドキュメントやソースコード等にアクセスするの?  

Androidアプリには3つの異なる種類のストレージにアクセスする権限を付与できる。  

1つ目はアプリのデータディレクトリー。これはアプリにとってUnixホームディレクトリーに相当する役目をもっており、アクセスできるのはEmacs自身だけ。  

2つ目は外部ストレージディレクトリー(/sdcardにある)。ここにアクセスするには、Emacsが明示的にアクセス権限を要求しなければならない。ファイルマネージャーアプリでは"内部ストレージ"として表示されるディレクトリー。  

Android 11より前は、このディレクトリーへのアクセス権限をEmacsに与えるためにApp Info設定メニューのPermissionsメニューからStorageという名前のオプションを有効にして行うことができた。Android 11では設定へのアクセス経路が変更されたので、SettingsにあるSpecial App Accessメニューから権限を与えなければならない。  

オンラインに出回っている口上とは異なり、外部ストレージにアクセスするためにTermuxの変種をインストールする必要はない。とはいえ2つのアプリケーションでユーザーIDを共有した結果として、一方のアプリケーションにアクセス権限(外部ストレージへのアクセス権限もそのうちの1つ)が付与されれば、もう一方のアプリケーションもその権限を取得する。  

3つ目は他のアプリケーションたとえばNextcloud)によって提供されるストレージ。これはStorage Access Frameworkを通じて提供される、/content/storageのサブディレクトリー配下にあるとてつもなく低速なストレージだ(Googleのドキュメントプロバイダー実装の失敗に祝福あれ)。これらのディレクトリーいずれかが利用可能になる前に`M-x android-request-directory-access`を実行して、表示されたファイル選択パネルから権限を付与したいディレクトリーを選択しなければならない。  

/contentディレクトリーはEmacs独自のファイル入出力プリミティブによって完全に実装されているので、サブプロセスがそのディレクトリーに含まれるファイルにアクセスすることはできない。そのディレクトリー内でサブプロセス生成を試みると、そのプロセスの実際の作業ディレクトリーは、実際にはEmacsのホームディレクトリーにセットされるだろう。これはEmacsとともに配布されるLispおよび補助ファイルを補助する/assetsディレクトリーにも適用される。  

詳細についてはEmacsマニュアルの(emacs)Android Filesystem、および(emacs)Android Document Providersを参照のこと。  

## 6. わたしの.emacs、.emacs.d、init.elはどこにいった?  

もちろん~/.emacsにある。  

Emacsの構成をスマホ上のいわゆる内部ストレージにコピーして、すぐにEmacsから利用可能にすることはできない。なぜならこれはAndroidのセキュリティーモデルに起因する問題であり、Emacsのホームディレクトリーにアクセス可能な唯一のアプリがEmacsだけであるという理由による。  

Emacsに内部ストレージへのアクセス権限を付与する方法に関する解答で示した手順にしたがい、それからそのディレクトリーにある構成ファイルをホームディレクトリーにコピーすればよい。  

AndroidはEmacsのホームディレクトリーがあらかじめ決められた場所に配置されることを保証しないが、通常は/data/data/org.gnu.emacs/filesになるだろう。複数ユーザー(Unixユーザーではない; Androidユーザーだ)のシステムでは、デバイスのオーナー以外のユーザーによってEmacsがインストールされた場合には、/data/user/配下のどこかに配置される可能性がある。  

## 7. emacs、emacsclient、movemailといったバイナリはどこ?  

簡単に言うと~/../lib。  

長いバージョンで答えるとAndroidは実行可能ファイルをロードできる場所、それにインストールパッケージから抽出される実行可能ファイルの名前の両方に制限を課すので、Emacsは補助的な実行可能ファイルを共有ライブラリーに習った名前にしている。Emacsがインストールされると、AndroidはEmacsが起動時にホームディレクトリーの親ディレクトリーにある`lib`としてシンボリックリンクするプライベートディレクトリーにこれらの実行可能バイナリを抽出する。詳細については(elisp)Subprocess Creation、および(emacs)Android Environmentを参照のこと。  

これの実行可能バイナリの名前は比較的に安定しているので(近い将来においても)、`libemacsclient.so`、`libmovemail.so`等のようなハードコードされた名前ではなく`emacsclient-program-name`、`movemail-program-name`等といった名前を提供するために特に定義した変数を用いるほうがよい。このアドバイスにしたがっていれば将来、そして非Androidデバイスでもあなたのコードが実行され続けることが保証されるだろう。  

`emacs`の場所についてはさらに複雑になる。実際には共有ライブラリーの`libemacs.so`こそが、EmacsのCコードすべてを含んでいるからだ。このコードはAndroidのファイルシステムおよびGUIインターフェイスを実装する一連のJava-コードにリンクされるまでは機能しない。これはアプリケーションからEmacsをオープンした実行時に、Android JVMによって自動的に実行されるのだ。  

`libandroid-emacs.so`はコマンドラインでのEmacsの開始において、正しい引数でJVMの呼び出しを試みるバイナリだ。Emacsがこの方法で開始された場合にはディスプレイ接続を作成できないというのは事実だが、予告なしに変更されるAndroid内部に依存する点こそがこのアプローチの最大の難点である。すべてのバージョンのAndroidで確実には動作しないこと、そしてOSにメジャーな変更が行われる度に後から修正する必要があるのは、この不適切な依存関係が理由なのだ。  

そもそもEmacs内部でEmacsを実行するのではなく、このバイナリの必要性の排除こそがこの難問にたいする真の解決策だろう。  

## 8. どこでソフトウェアを入手できるの?  (clang、git、pythonとか)  

(emacs)Android Softwareを参照のこと。`termux`ディレクトリーにはどちらも同じ共有ユーザーID、署名キーをもったバージョンのTermuxとEmacsがある。  

## 9. オンスクリーンキーボードが表示されない! 物理キーボードでしかEmacsを使っていないんだね!  

このポートの作成者は、Androidでは物理キーボードを使っていない。彼が使っているのは英語入力にはAnySoftKeyboard、CJK入力には以下のFcitxを使っている。  
```text
https://github.com/fcitx5-android/fcitx5-android/
```

疑いは晴れたとして、このような誤解が生じたのには、少なくとも2つの理由が考えられる。  

1つ目の理由として考えられるのはオンラインで手に入れた入門テキストの記述にしたがい、意味を吟味することなくメニューバーやツールバーを無効にして、その後にキーボードがなくては行うことが不可能な操作を行いたい場合だろう。これはAndroidにおいてはとんでもなく愚かな判断だ。キーボードから行うすべての操作はメニューバーやツールバーからも行うことができるので、キーボードを使う必要はなくなる(M-xを含む; Edit -> Executeがそれだ)。  

上記を念頭に置いて考えると、カレントウィンドウが読み取り専用バッファーを選択した際には、画面スペースを確保するためにキーボードが非表示になるからだろう。2つ目の理由として考えられるのは、オンスクリーンキーボードを常時表示しておきたいという理由だろう。これは単にオプション`touch-screen-display-keyboard`を非nil値にカスタマイズするだけで行うことができる(ヒント: Options -> Customize Emacs)。  

Emacsがタッチスクリーンおよびオンスクリーンキーボード入力を扱う方法に関する詳細については(emacs)On-Screen Keyboards、(elisp)Misc Events、(elisp)Touchscreen Eventsを参照のこと。  

## 10. 生のキーイベント/キーバインドに依存するわたしのパッケージXは、オンスクリーンキーボードでは概ね動作しないのだが!  

Androidの入力メソッドが、Emacsのバッファー編集プリミティブ(テキスト変換と呼ばれている)の直接呼び出しに依存しているのが理由だ。Emacsは編集後の経過を分析することによってelectric-indentやelectric-pair、Auto-Fillなどを実装している。  

その結果、Emacsは入力メソッドにタイプしたキーの内の押下イベントを受け取らず、あなたのパッケージは機能せず、あなたがタイプして送信しようと意図したイベントのかわりに、タイプしたテキストが直接バッファーに挿入されることと相なる訳だ。  

変数`overriding-text-conversion-style`、またはバッファーローカル変数`text-conversion-style`のいずれかを通じてこれらのパッケージのテキスト変換を無効にすれば解決するだろう(テキスト変換をグローバルに無効にするなら前者の変数)。  

テキスト変換の詳細については、(elisp)Misc Eventsを参照のこと。  

## 11. 開きカッコをタイプするとポイントがテキスト先頭にジャンプした! (TextモードやProgモードでのIMEにまつわる問題も含む)  

あなたが使っているIMEのバグだ、多分。EmacsはAndroidの入力メソッドのインターフェイスを厳守して実装しているが、Androidの独自実装にはまだ多くの点が残されている。  

入力メソッドが頻繁に犯すありがちな違反というものがある。その1つがIMEがリクエストした文字数に関わらず、IMEの`getExtractedText`リクエストが常にバッファーのコンテンツ全体を応答すると仮定することだ(確かにAndroidのTextViewを使ったエディターならそのとおり)。そのようなエディターとは反対に、Emacsはリクエストに指定されたサイズにしたがう。これはリクエストの文書化された趣旨に沿った動作だ。  

このリクエストにたいする応答が常にバッファーテキストの内容全体ならば、入力メソッドがリターンするcaretオフセット(訳注: テキストが挿入された相対位置)が挿入ポイントの位置だと仮定することにより、さらに違反を犯すことになる。このオフセットとは、実際にはリターンされるテキストの先頭からのオフセットだからだ。  

問題を抱える多くの入力メソッドにおいてこれら2つの実装上の誤りが合体すると、ポイントがバッファーの先頭にあるという誤解が生じる。このような入力メソッドはelectric-pairに類似した独自機能の一部として、閉じカッコの前の最後の文字のポイント位置の取得を試みがちだ。しかし彼ら最後の文字だと思っている位置は、実際にはまさにバッファーの先頭に他ならないのだ。  

あなたのIMEで目撃した挙動が上述した状況に該当しなければ、どうか使用しているIMEの名前とバージョン番号を明記して、(M-x report-emacs-bugで)バグレポートを送信して欲しい。  

## 12. fundamentalモードやCustomバージョンでタイプすると、入力メソッドが発狂しますが!  

そのIMEのバグ。入力メソッドが誤ったテキスト変換を実装するに留まらず、素のキーボードデバイスとして振る舞うことを要求する`TYPE_NULL`入力モードの実装をも失念する場合もあるのだ。  

これらのバグは(テキスト変換が無効だとEmacsは入力コネクションを提供しないので)何もテキストが挿入されない、Deleteキーが機能しない、その他さまざまな症状として顕在化しがちだ。もっとましな入力メソッドを入手すること。友人にもそうするよう勧めること。  

## 13. どうやってツールバーに修飾キーを表示するの?  

`modifier-bar-mode`と`tool-bar-mode`を有効にする。ツールバーとともに、Emacsが認識する各修飾キーによって後続イベントを読み取り変更するボタンをもった第2の小さなツールバーが表示されるだろう。  

これらのボタンのいずれかをタップするとEmacsはオンスクリーンキーボードを表示して、テキスト変換を一時的に無効にする。これによりテキスト変換が有効なTextモードやProgモードのバッファーであっても、修飾キーを含んだキーシーケンスのタイプが有効になる。  

## 14. ツールバーをフレーム下端に表示するには? タイプするとき指の近くにボタンと修飾バーを配置したいんだ。  

Androidポートに限られた話しではないが、非GTKシステムにおけるこの機能の実装モチベーションはAndroidポートのユーザーのリクエストにある。  

`tool-bar-position`を`bottom`にカスタマイズする。  

## 15. 閉じ方は?  C-gをタイプできないんだ。  

ボリュームダウンボタンを素早く連続クリック。通常のC-gとして機能する。  

## 16. Emacsで他のファイルを開く方法は?  

`M-x server-start`を実行する(何なら初期化ファイルに記述してしまう)。  

あなたがテキストファイルのオープンを試みると、実行するプログラムを尋ねるダイアログをシステムが表示するだろう。Emacsを選択するとそのファイルをオープンするためにemacsclientが呼び出されるか、Emacsがまだ実行中でなければそのファイルを引数としてEmacsが開始されることになる。  

## 17. このアプリとTermuxのEmacs、何が違うの?  

このアプリはAndroidのネイティブGUIプログラムとして実行される。入力メソッド、ドキュメントプロバイダープログラムなどを利用できる利点があり、タッチスクリーンサポート入力に優れているし、一般的なジェスチャーのほとんどを認識するし、それをマウスイベントに透過的に変換できたりもする。  

Emacsのアップデートをインストールするために別個のパッケージマネージャーを使う必要がないように、Lispおよび補助的なファイルはすべてアプリのケージ自体に含めて配布される。これらのファイルはアプリのパッケージから直接ロードされるので使用前、Emacsがアップデートされるたびに毎回時間のかかる抽出手順を行う必要がない。  

このアプリはTermuxのポート済みUnixソフトウェアを使うこともできる。このファイルの冒頭部分を参照のこと。さらにTermuxがサポートしていない7.0より前の古いAndroidリリースもサポートしている。  

## 18. ここで提供しているビルド、F-Droid版のビルド、何が違うの?  

F-Droid版は2月のAndroidポートの古いスナップショットであり、その前の2月に配布されたバージョンと比較すると大幅に改善されてはいるものの、依然として不完全なままである。ここで提供しているパッケージには適用済みのバグフィックスや新機能は含まれていない。  

GnuTLS、イメージ用のライブラリー、tree-sitterのようなここでパッケージして提供している多くの依存関係のビルドも含まれていないバージョンなのだ。  

## 19. F-Droid版のビルドからここのビルドにアップデートできない、何で?  

Androidでのアップデートで、既存のインストールで署名したのと同じキーで署名したパッケージが要求される。F-DroidはEmacsレポジトリに含まれている署名キーとは違う署名キーを使用しているからだ。  

設定をバックアップしたら、このディレクトリーにあるいずれかのパッケージをインストールする前にF-Droid版をアンインストールすればよい。  

## 20. Optionsメニューの`Set Default Font`で表示されるリストににインストール済みのフォントがない。  

このメニューは実はフォントの"バックエンド"がXだけであった頃、プログラムはほとんどのXサーバーで共通なフォントを常にリストするだけでよかった、Emacsのグラフィカルサポート黎明期の名残りである。Androidで呼び出すと、Androidには実際にはほとんど存在しないフォントの長ったらしいリストが生成される。フォントはCustomizeか`set-frame-font`コマンドで構成する必要がある。  

## 21. Microsoftのコアフォント(Arial、Tahomaなど)のグリフ(glyph: 字形、字体)が崩れるぼやける。  

これらのフォントの旧バージョンは、Emacsが提供していないMicrosoft Windows固有のフォントスケーラーの拡張機能と実装固有の動作を利用している。このためにグリフをピクセルグリッドに適合させるために、これらのフォントが定義しているさまざまなグリフプログラムを実行しても上手く機能しないのだ。解決策はMS Windowsの最新リリースに同梱されているこれらのフォントの最新版にアップデートすること。  

そのようなフォントは存在しないグリフポイントをアドレス指定する権限をインタープリターに期待する。MSスケーラーは無効な命令は無視するが、Emacsはプログラムを完全に終了する。  

## 22. ツールバーのボタンが小さい。  

ツールバーのボタンのマージン(余白)は画面解像度に合わせて拡大しない。今日ではほとんどのAndroidスマホに搭載されている高解像度出力デバイスでは、予想よりも小さく表示されるだろう。変数`tool-bar-button-margin`を調整して補正できる。  

## 23. モノクロあるいはグレースケールのディスプレイが検出されないすぃで、フォントロックなどが適用する色がコントラスト不足になる。  

これは"電子ペーパーディスプレイ(digital paper display)"以外ではほとんど知られていない、モノクロ/グレースケールのディスプレイを搭載するタブレットに関連する質問だ。  

そのようなアプリケーション向けにAndroidはデザインされていないので、ディスプレイのビジュアルクラスはそれをプログラムに報告しない。という訳で変数`android-display-depth`を使用してEmacsにディスプレイの色深度(color depth)を通知する役目はユーザーたるあなたが担うことになる。グレースケールに最適な値は2から8の間だろう。値が大きくなるほどサポートされるグレー値が多くなる。モノクロディスプレイの適切な値は1。  

たとえこの値が色割り当ての選択がLispに報告されるディスプレイ機能、フェイスの実現中に選択される色を制御するとしても、Emacsに提供される基礎となるサーフェス(surface)は依然として色のままなので、フォントのアンチエイリアスやイメージ表示には効果がなく、かわりにドライバーがアンチエイリアスされたテキストやカラーグラフィックを、スクリーン向けにグレースケールやモノクロのデータに変換している。これはむしろ色空間や色深度を必要とするディスプレイ用に慎重に厳選したパレットを、ユーザーがアクティブにできるようにすることを意図した変数なのだ。  

## 24. このアプリのGNU GPLの条件に基づく権利を有するソースコードはどこでどうやって入手できるの?  

Emacsで以下をタイプすればよい:  

```text
M-x describe-variable RET emacs-repository-version RET
```

そして以下のEmacsのGitレポジトリからそのリビジョンをダウンロードする:  

```text
https://git.savannah.gnu.org/git/emacs.git
```

このレポジトリから現在SourceForgeにあるバイナリ用に取得したソースコードのtarアーカイブは残してある。これが必要なら連絡して欲しい。  

## 25. TermuxやTermuxのアドオン、(あるいはEmacs)がインストールされない。  

このサイトからTermuxが有効なEmacsやTermux自体をダウンロードしてインストールしている場合には、アップストリームのTermuxのアプリパッケージのインストールは何の特徴もないエラーメッセージを表示して失敗するだろう。これはアプリパッケージの署名がインストール済みのパッケージの署名と一致しないからだ。  

インストールするには以下のEmacsのアップストリームの署名キーでインストールしたいパッケージに再署名する:  

```text
https://git.savannah.gnu.org/cgit/emacs.git/tree/java/emacs.keystore
```

あるいは以下のようなXPosedモジュールでAndroidを変更して、厳格な署名検証を無効化しなければならない:  

```text
https://github.com/LSPosed/CorePatch
```

## 26. このFAQには何かが足りない!  

EmacsマニュアルのAndroidやInputに関する章、あるいはLispリファレンスマニュアルの関連する部分でカバーされていない問題の場合には、どうかバグを報告して欲しい。必要と判断したらこのFAQとマニュアルを更新する。  

