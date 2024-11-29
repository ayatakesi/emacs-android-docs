# Debugging GNU Emacs

```text
Copyright (C) 1985, 2000-2024 Free Software Foundation, Inc.
See the end of the file for license conditions.
```

## まえがき

あなたがすでにdebug情報つきEmacsのビルド、GDBの設定と開始、GDBによる簡単なデバッグテクニックに親しんでいる場合には、このセクションはスキップしてもよい。

### デバッグ用のEmacsのconfigure

デバッグを容易にする特別なオプションでEmacsをconfigure、ビルドするのが最善だ。以下にconfigure時にわたしたちが推薦しているオプションを示す(--prefixのようにあなたにとって必要なオプションに追加して指定する):

```shell
  ./configure --enable-checking='yes,glyphs' --enable-check-lisp-object-type \
    CFLAGS='-O0 -g3'
```

`-O0`フラグの指定は重要だ。最適化されたコードのデバッグは困難な場合が多いからだ。しかし最適化されたコードでのみ問題が発生する場合には、最適化を有効にする必要があるかもしれない。このようなケースに遭遇した場合には`-O2`ではなくまずは`-Og`の使用を試みて欲しい。`-Og`ならある種のコードのデバッグを著しく困難にする一部の最適化が無効になるからだ。

古いバージョンのGCCには`-g3`フラグだけでは足りないかもしれない。詳細は後述の"analyze failed
assertions"を参照して欲しい。

2つの`--enable-*`フラグは必須ではない。これらのフラグはGDBでのデバッグには何も影響を与えないが、あなたがデバッグしている問題をassert違反という形で、より早い段階で検知できるかもしれない追加のコードをコンパイルする。`--enable-checking`オプションは、ディスプレイに起因する問題のデバッグに有用な追加機能の有効化も行う。これについては後述の"Debugging
Emacs redisplay problems"を参照して欲しい。

デバッグ用のEmacsをインストールする必要はない。`src`ディレクトリーに作成されるバイナリをデバッグできるからだ。

### GDBの設定

EmacsをデバッグするためにGDBを開始するには、シェルプロンプトで単に`gdb ./emacs
RET`とタイプすればよい(Emacsの実行可能ファイルがあるディレクトリー、通常はEmacsソースツリーのサブディレクトリー`src`からデバッグを行う場合)。しかしわたしたちが推奨するのは、以下のようにEmacsからGDBを開始する方法だ。

GDBでEmacsをデバッグする際には、Emacsの実行可能形式が作成されたディレクトリー(Emacsソースツリーの`src`ディレクトリー)でGDBを開始すること。このディレクトリーにある`.gdbinit`ファイルには、Emacsのデバッグ用にさまざまな"ユーザー定義"コマンドが定義されている(これらのコマンドについては"Examining
Lisp object values"や"Debugging Emacs Redisplay problems"で後述する)。

Emacsからのデバッガの開始は`M-x
gdb`コマンド(後述)通じて行う。カレントバッファーでEmacsのCソースファイルをvisitしていれば、`src`ディレクトリーで自動的にGDBが開始される筈だ。デフォルトディレクトリーが別のディレクトリーであるようなバッファー、たとえば"*scratch*"バッファーから`M-x
gdb`を呼び出した場合には、デバッガを開始する前に`M-x cd`コマンドでデフォルトディレクトリーを変更できる。

l最近のバージョンのGDBでは、GDBを呼び出したディレクトリーにある`.gdbinit`を自動的にロードすることはない。そのようなバージョンのGDBでは、GDBの開始時に以下のような警告を目にするかもしれない:

```shell
  warning: File ".../src/.gdbinit" auto-loading has been declined by your `auto-load safe-path' set to "$debugdir:$datadir/auto-load".
  # 訳注: あなたの`auto-loadできる安全なパス'が"$debugdir:$datadir/auto-load"に
  # セットされているので"..."のオートロードは拒否する
```

これを解決する一番簡単な方法は、あなたの`~/.gdbinit`ファイルに(そんなファイルがなければ作成して)、以下の行を追加すればよい:

```shell
  add-auto-load-safe-path /path/to/emacs/src/.gdbinit
```

これらの困難を克服する他の手段については、GDBユーザーマニュアルのノード"Auto-loading safe
path"にすべて記されている。他に手立てがなければ、GDBプロンプトで`source /path/to/.gdbinit
RET`とタイプして、GDBのinitファイルを無条件でロードできる。

macOSでGDBを実行すると、以下のようなエラーメッセージが表示されることがあるかもしれない:

```text
  Unable to find Mach task port for process-id NNN: (os/kern) failure (0x5).
  # 訳注: process-id NNNのMachタスクポートが見つからない: (os/kern) failure (0x5).
```

これを解決するためにはインターネットで"Unable to find Mach task port for
process-id"というフレーズを検索すれば、したがうべき手順の記述を見つけられるだろう。。

### EmacsのGDB用のUIフロントエンドの使用

わたしたちが推薦するのはEmacsが提供するGDB用のGUIフロントエンドの使用だ。これを使えば、`M-x gdb
RET`とタイプしてGDBを開始できる。このコマンドはデバッグするバイナリファイルのデフォルトの名前を提案する。デバッグしたいEmacsバイナリ以外のデフォルトが提案された場合には、必要に応じてファイル名を変更すればよい。すでに実行中のEmacsプロセスにアタッチしたい場合には、ミニバッファーに表示されているGDBコマンドを以下のように修正しよう:

```shell
    gdb -i=mi -p PID
```

ここでPIDはPosixホストの`top`や`ps`、MS-Windowsのタスクマネージャーのようなシステムユーティリティーが表示する実行中のEmacsのプロセスID(数値)だ。

デバッガが開始されたら、`M-x gdb-many-windows
RET`とタイプしてGDBのUIが提供する追加のウィンドウをオープンしよう(メニューバーの`Gud->GDB-MI->Display Other
Windows`をクリックしてもよい)。この段階で水平スクロールせずとも内容が表示されるように、オープンしたばかりのウィンドウのスペースを充分大きく拡げておこう(フルスクリーンにするという手もある)。

変更したウィンドウ構成はお馴染みのウィンドウ構成コマンド`M-x gdb-restore-windows
RET`、あるいはメニューバーの`Display Other Windows`を選択解除すれば、後からリストアできる。

### 最初のブレークポイントの設定

Emacsを実行する前の今こそ、デバッグしたいコードにブレークポイントをすべきときだ。そうすればそこでEmacsは停止して、GDBが制御を得られるのだ。何らかの非常に稀な特殊な状況下で実行されるコード、あるいは特定のEmacsコマンドを手作業で呼び出した場合のみ実行されるコードをデバッグしたい場合には、そこにブレークポイントをセットしてEmacsを実行して後はそのコマンドを呼び出すか、あるいはその稀な状況やらを再現すればブレークポイントがトリガーされるだろう。

あなたにそれほどツキがなく問題となっているのがとても頻繁に実行されるコードの場合には、バグのある動作が起こるまであなたのブレークポイントがトリガーされないように回避する手段を見つける必要があるだろう。これには単一の処方せんは存在しない。あなたはより創造力を発揮するとともに、適切なのは何なのかを見い出すためにコードをより深く学ぶことが必要になるだろう。有用なトリックをいくつか挙げておこう:

- 特定のバッファーや文字列の位置にブレークポイント条件を作成する。たとえば:

```text
      (gdb) break foo.c:1234 if PT >= 9876
```

- 滅多に呼び出されない関数を何か選んでからバグが発生する条件をセットアップして、その滅多に呼び出されない関数を呼び出す。このタイミングなら疑わしいコードが呼び出されればバグが発生するであろうこと予見できるのでGDBに制御が渡り次第、バグの疑いがあるコードにブレークポイントをセットすればよい。

- バグ自体がエラーメッセージとして顕現するのであれば、Fsignalにブレークポイントをセットして、ブレークポイントで実行が止まってからバックトレースを調べれば何でエラーが発生したのか確認できる。

他にも追加のテクニックについては、"Getting control to the debugger"で後述する。

これであなたのデバッグセッションを始められるだろう。

### GDBからのEmacs起動

新たにEmacsセッションを開始する場合には"*gud-emacs*"バッファーで`run`、その後にコマンドライン引数(`-Q`とか)をタイプしてから`RET`を押下する。Emacs外部でGDBを実行している場合には、GDBプロンプトでは`run`、その後にコマンドライン引数をタイプすればよい。

実行中のEmacsにデバッガをアタッチした場合には、"*gud-emacs*"バッファーで`continue`をタイプして`RET`を押下する。

デバッグ中に目にするであろう多くの変数はLispオブジェクトだ。通常は正体がはっきりしないポインターや解釈が困難な整数が表示されるだろう。それが長いリストして表されている場合にはなおさら不可解なものとなる(`--enable-check-lisp-object-type`が有効な場合にはこれら不可解な値を含む構造体として表示される)。これらをLisp形式で表示するために`pp`コマンドが使用できる。このコマンドは出力をエラーストリームに表示するので、`M-x
redirect-debugging-output`を使えばファイルにリダイレクトできる。もしあなたがGDBでデスクトップアイコンから呼び出された実行中のEmacsにアタッチした場合には、出力をまったく目にしなかったり、どこかの見知らぬ場所に吐き出される公算が強いことを意味している(あなたのデスクトップ環境のドキュメントをチェックしよう)。

"Examining Lisp object values"で、Lispオブジェクトの表示に関する追加情報を入手できるだろう。

このドキュメントの残りの部分では、Emacsのデバッグで特に役に立つテクニックを説明する。Emacsをデバッグしようと思ったらまず全体に目を通して、必要に応じて特定の問題を調べることをお勧めする。

幸運を祈る!

## 失敗したassertやバックトレースの分析を試みる場合
デバッグに適したフラグでEmacsをコンパイルすることが肝だ。最近のコンパイラーでは`CFLAGS="-O0 -g3"`で充分な場合が多いものの、`CFLAGS="-O0 -g3 -gdwarf-4"`を使うことでさらなる恩恵を得られるかもしれない。あなたのコンパイラーがもっと上のバージョンのDWARFをサポートしているようなら、そのバージョンで`4`を置き換えよう。これは4.8より前のバージョンのGCCでは、特に重要だ。GCCともっと高い`-O2`のような最適化レベルでは、オプション`-fno-omit-frame-pointer`や`-fno-crossjumping`が必須なことが多い。後者のオプションは与えられた関数のすべてのassertにたいして、GCCが同一のabort呼び出しを使う(特定のassert失敗を特定するスタックバックトレース出力が使い物にならない)ことが抑止される。

## GDB(や他の適切なデバッガ)配下でEmacsを実行するのは、 __如何なるときでも__ 悪くないアイデアだ
そうしておけばEmacsがクラッシュした際にcoreダンプだけではなく、生きたプロセスをデバッグできるだろう(coreファイルをサポートしていないシステムや、単にレジスターや一部のスタックアドレスのプリントできないシステムでは、これが特に重要になる)。

## Emacsが固まったときや何らかの無限ループに嵌っているように見える場合
`kill -TSTP PID`とタイプする。ここでPIDはEmacsのプロセスID。GDB配下で実行していれば、これによりGDBに制御が渡るだろう。

## デバッガに制御を渡すには 

デバッガにEmacsをロードした後、実行する前にブレークポイントを戦略的な位置にセットすること。制御権が必要なタイミングで、制御権が確実にデバッガにリターンされるようにすることがもっとも重要なのだ。

ブレークポイントを配置する場所として、`Fsignal`はとても役に立つ場所だ。すべてのLispエラーがそこにたどり着く。Lispデバッガを起動するエラーだけに興味がある場合には、ブレークポイントを`maybe_call_debugger`にすれば役に立つだろう。

デバッガに制御を渡す別のテクニックとして、稀にしか使用されない関数へのブレークポイントの配置が挙げられる。この類の便利な関数の1つがFredraw_displayだ。この関数は呼び出そうと思ったら、`M-x
redraw-display RET`でインタラクティブに呼び出すことができる。

任意のタイミングで確実にデバッガに戻れる手段をもっていれば、それも役に立つだろう。Xを使っていれば簡単だ。GDBと対話中のウィンドウで`C-z`とタイプすれば、普通のプログラムと同じようにEmacsも停止するだろう(実行中のEmacsプロセスにアタッチしたGDBでは機能しない;
この場合にはEmacsを開始したシェルウィンドウで`C-z`をタイプするか、以下で述べる`kill -TSTP`を用いる手法が必要になるだろう)。

テキスト端末上でEmacsを表示している際には、そう簡単にはいかない。そこで以下にさまざまな代替え案記しておいた(ただしシグナルを使用する方法が機能するのはPosixシステムだけだが)。

Emacsディストリビューションにある`src/.gdbinit`ファイルは、Emacsに`SIGINT`
(テキストモードのフレー厶のEmacsではC-gに相当する)を送信するようアレンジされている。この場合にはGDBに制御は戻らない。最近のシステムでは、以下のコマンドでこれをオーバーライドできる:

```text
    handle SIGINT stop nopass
```

この`handle`コマンド以降は、`SIGINT`でGDBに制御が戻るようになる筈だ。通常のEmacs使用時と同じように`C-g`でquitしたければ、`nopass`を省略する。シグナルハンドリングと`handle`コマンドの詳細については、GDBマニュアルを参照のこと。

何か文字コードを変数`stop_character`に格納しておくというテクニックは、`handle
SIGINT`が機能しなくても上手く動作するだろう。つまり、

```text
    set stop_character = 29
```

とすることで、`Control-]`
(10進では文字コード29)が一時停止文字にするのだ。これで`Control-]`とタイプすれば即座に停止できるようになる。内部プロセスを開始するまでは`set`コマンドは使用できないので、上述の`set`コマンドを使えるようにするためには、`start`コマンドでEmacsを開始すること。

Posixホストであれば、以下のようにシェルプロンプトから、`kill `コマンドでシグナルを送信することも可能だ:

```shell
    kill -TSTP Emacs-PID
```

ここで`Emacs-PID`は、デバッグするEmacsのプロセスIDのこと。送信するシグナルとして、他にも`SIGUSR1`と`SIGUSR2`が役に立つ。これらのシグナルの使い方については、ELispマニュアルの"Error
Debugging"を参照して欲しい。

テキスト端末上にEmacsが表示されている際には、デバッグセッション用に別個に端末があると便利だ。これは通常通りEmacsを開始して、GDBから`attach`コマンド(GDBマニュアルのノード"Attach"を参照)でアタッチすることで実現できる。

MS-Windowsの場合にはGDB配下でEmacsを実行する前にnew-consoleオプションをセットすれば、別個のコンソールからEmacsを開始できる:

```text
  (gdb) set new-console 1
  (gdb) run
```

この方法を使えばEmacsが表示されているのがGUIフレームか、あるいはテキストモード端末かに関わらず、GDBとの対話に使用しているコンソールウィンドウ経由で`C-c`か`C-BREAK`をタイプすることにより、Emacsが停止して制御がデバッガに戻されるだろう。これは13.1より前のバージョンのGDBを使用するMS-Windowsでは、あらかじめブレークポイントをセットする方法にかわる信頼性のある唯一の選択肢であった。GDB
13.1ではWindowsにおける`C-c`と`C-BREAK`の扱いが変更されたので、Emacsを開始したGDBの対話に使用するコンソールウィンドウで`set
new-console 1`を実行せずとも、新しいバージョンのGDBなら`C-c`や`C-BREAK`でEmacsに割り込めるようになったのだ。

## Lispオブジェクトの値の調べ方

デバッグするのが生きたプロセスで、致命的なエラーにはまだ遭遇していなければ、GDBの`pr`コマンドを使うことができる。まずは通常のように`p`コマンドで値をプリントしよう。それから引数なしで`pr`をタイプするのだ。これはLispプリンターを使用するサブルーチンを呼び出す。

emacsの値を直接プリントする`pp value`を使うことも可能だ。

Lisp変数のカレント値を確認する場合には`pv variable'`を使う。

これらのコマンドは出力をstderrに送信する。stderrがクローズされていたり、何処か知らない場所にリダイレクトされている場合には、出力は確認できないだろう。これは特にMS-WindowsでデスクトップのショートカットからEmacsを呼び出した場合が該当する。stderrをファイルにリダイレクトするためには、コマンド`redirect-debugging-output`を使うことができる。

注意:
Emacsが深刻なトラブルの最中にあると判っているのに`pr`、`pp`、`pv`といったコマンドを使うのはよいアイデアではない。これによりスタック(たとえばスタックオーバーフローによるSIGSEGVの発生)がめちゃくちゃになったり、あるいは`obarray`のような非常に重要なデータ構造が壊れてしまうかもしれないからだ。このような状況下では`pr`によって呼び出されるEmacsサブルーチンが、たとえば元の原因のデバッグにとって重要な何らかのデータを上書きしてしまうかもしれない。

`select`の呼び出し中にEmacsを停止すると、`pr`の使用が不可能なシステムもある。実際のところ、Emacsがwaitを行っている間にEmacsを停止するとこの現象が発生する。このような状況において`pr`を使ってはならない。かわりにそのシステムコールから抜け出すために`s`を使うこと。そうすればEmacsが命令と命令の間に移って、`pr`を処理することが可能になるだろう。

何らかの理由により`pr`コマンドが使用できない場合には、`xpr`コマンドが使用できる。これはデータタイプとそのデータの最後の値をプリントするコマンドだ。たとえば:

```text
    p it->object
    xpr
```

低レベルコマンドを用いたデータ値の分析もできるかもしれない。最後のデータ値のデータタイプをプリントするのは`xtype`コマンドだ。データタイプが判ってしまえば、そのタイプに応じたコマンドを使用すればよい。以下にその種のコマンドを挙げておこう:

```text
    xint xptr xwindow xmarker xoverlay xmiscfree xintfwd xboolfwd xobjfwd
    xbufobjfwd xkbobjfwd xbuflocal xbuffer xsymbol xstring xvector xframe
    xwinconfig xcompiled xcons xcar xcdr xsubr xprocess xfloat xscrollbar
    xchartable xsubchartable xboolvector xhashtable xlist xcoding
    xcharset xfontset xfont
```

これらのコマンドはそれぞれ特定のタイプ、あるいはタイプクラスに適用できる(いくつかのタイプは内部的にしか存在しないのでLispでは目にしないタイプだろう)。

これらの`x...`コマンドはいずれも値に関する情報、およびGDB値を生成する。このGDB値は以後`$`で使用できるので、これで残りの内容を取得できる筈だ。

残りの内容のほとんどは、一般的には順繰りに`x...`コマンドを使って調べることができるLispオブジェクトの筈だ。

たとえ生きたプロセスの場合であってもバッファー、ウィンドウ、プロセス、マーカーのフィールドを調べるのにも`x...`コマンドは役に立つだろう。以下にフレームと呼ばれる変数に割り当てられた値のプリントに、GDBマニュアルのノード"Value
History"で説明されている概念を用いた例を示す。最初は以下のコマンドを使う:

```shell
  cd src
  gdb emacs
  b set_frame_buffer_list
  r -q
```

その後にEmacsがブレークポイントに到達するので:

```shell
  (gdb) p frame
  $1 = 139854428
  (gdb) xpr
  Lisp_Vectorlike
  PVEC_FRAME
  $2 = (struct frame *) 0x8560258
  "emacs@localhost"
  (gdb) p *$
  $3 = {
    size = 1073742931,
    next = 0x85dfe58,
    name = 140615219,
    [...]
  }
```

これで`pp`コマンドでフレームパラメーターをプリントできる:

```shell
  (gdb) pp $->param_alist
  ((background-mode . light) (display-type . color) [...])
```

EmacsのCコードでは、`lisp.h`で定義されているマクロが頻繁に使用されている。ここでたとえば`keyboard.c`の終盤付近にある`add_command_key`の左辺値アドレスが知りたいとする:

```shell
  XVECTOR (this_command_keys)->contents[this_command_key_count++] = key;
```

XVECTORはマクロなので、それに関してGDBが知ることができるのは、Emacsがプリプロセッサマクロ情報とともにコンパイルされた場合だけだ。オプション`-gdwarf-N`(`N`は2以上)、および`-g3`オプションを指定するとGCCがその情報を提供する。この場合には`p
XVECTOR (this_command_keys)`のような式でもGDBが評価できるだろう。

この情報が利用できない場合には、GDBの`xvector`コマンドを使って同じ結果を得ることができる。以下に手順を示そう:

```shell
  (gdb) p this_command_keys
  $1 = 1078005760
  (gdb) xvector
  $2 = (struct Lisp_Vector *) 0x411000
  0
  (gdb) p $->contents[this_command_key_count]
  $3 = 1077872640
  (gdb) p &$
  $4 = (int *) 0x411008
```

以下はマクロおよびGDBの`define`コマンドに関する例だ。`recent_keys`(直近3000回分のキーストロークが記録されている)のように多くのLispベクターが存在する。以下のようにすればこのLispベクターをプリントできる

```shell
  p recent_keys
  pr
```

しかしこれでは少々使いにくいかもしれない、`C-h l`(訳注:
`view-lossage`)に比べて`recent_keys`の出力は冗長だからだ。わたしたちがプリントしたいのは、このベクターの最後の10要素だけだとしよう。以下のコマンドで`keyboard.c`の`recent_keys`を変更できる

```shell
  XVECTOR (recent_keys)->contents[recent_keys_index] = c;
```

では最後の10回分のキーストロークがプリントできるように、GDBコマンド`xvector-elts`コマンドを定義しよう

```shell
  xvector-elts recent_keys recent_keys_index 10
```

`xvector-elts`は以下のように定義できる:

```shell 
  define xvector-elts
  set $i = 0
  p $arg0
  xvector
  set $foo = $
  while $i < $arg2
  p $foo->contents[$arg1-($i++)]
  pr
  end
  document xvector-elts
  Prints a range of elements of a Lisp vector.
  xvector-elts  v n i
  prints 'i' elements of the vector 'v' ending at the index 'n'.
  end
```

## GDBでLispレベルのバックトレース情報を得るには

もっとも役に立つのが`xbacktrace`コマンドを使う方法だろう。これはカレントでアクティブなLisp関数の名前www表示するコマンドだ。

これが(たとえば構造体`backtrace_list`が壊れている等の理由で)機能しない場合には、GDBプロンプトで`bt`をタイプしてCレベルのバックトレースを生成して、Ffuncallを呼び出しているスタックフレームを調べることになる。`up
N`をタイプして順繰りにスタックフレームを選択する。何個上のフレームを選択するかは、適切な数値を`N`に指定する。そしてFfuncallを呼び出しているフレームそれぞれにおいて以下をタイプするのだ:

```shell
  p *args
   pr
```

これによりそのレベルにおける関数呼び出しによって呼び出された、Lisp関数の名前がプリントされるだろう。

`arg`の残りの要素をプリントすることによって、引数の値を確認できる。1つ目ｎ９引数をプリントするには、以下のようにする:

```shell
  p args[1]
  pr
```

生きたプロセスがなければ、(若干便利さで劣るものの`xsymbol`のようなその種の情報を得られる別の`x...`コマンドを使うことができる。たとえば:

```shell
  p *args
  xtype
```

`xtype`は`arg[0]`がシンボルだと判断したようだ:

```shell
  xsymbol
```

## Emacsの再表示にまつわる問題のデバッグ

Emacsのディスプレイに関するコードには特別なデバッグ用コードが含まれているが、通常だと無効になっている。`--enable-checking='yes,glyphs'`を指定してconfigureすることで、これを有効にできる。

このようにEmacsをビルドすることで、ディスプレイコード処理精査のためのassertが通常のビルドよりも多くアクティブになる(`eassert`マクロの呼び出しを検索すれば、コードでこれらのassertをどのようにテストするのか確認できる)。失敗したassertはすべて調査するべきだ。正式版としてビルドされたEmacsでabortやsegfaultを発生させるような問題の多くは、クラッシュに至る前にこれらのassertによって捕獲されるだろう。

`--enable-checking='glyphs'`を指定してconfigureされたEmacsであれば、実行中のEmacsセッションから再表示のトレース機能を使うことができる。

コマンド`M-x trace-redisplay
RET`は、再表示が何を行ったかについてのトレースを標準エラーストリームに出力する。これはさまざまな条件において、ディスプレイエンジンが採用するコードパスの理解にとても役に立つだろう(`M-x
redraw-display
RET`の呼び出し、あるいは単に`M-x`とタイプするだけでも、Emacsが不正な表示を修正ための再表示最適化が関係するかもしれないことが判るだろう)。点滅カーソル機能およびEldocは定期的な再表示サイクルをトリガーするので、トレースの雑音を減少させるために、`trace-redisplay`呼び出しの前に`blink-cursor-mode`と`global-eldoc-mode`は無効にすることをお勧めする。dump-redisplay-historyコマンドを呼び出せば、直近のトレースメッセージを最大30個まで標準エラーにダンプすることもできる。

あなたが目にしたトレースメッセージを`xdisp.c`で検索すれば、ディスプレイエンジンが採用しあコードパスを調べることができるだろう。

標準エラーストリームに選択されたウィンドウのグリフマトリクスを出力するには、コマンド`dump-glyph-matrix`が役に立つ。詳細についてはこの関数のdoc文字列を参照のこと。

GDB配下でEmacsを実行している場合には、引数にマトリクスを指定してこの関数を呼び出すだけで、任意のグリフマトリクスの内容をプリントできる。例として以下は、ポインター`w`が示すウィンドウのカレントマトリクスの内容をプリントするコマンドだ:

```shell
  (gdb) p dump_glyph_matrix (w->current_matrix, 2)
```

(2つ目の引数の`2`は長い形式でグリフをプリントするよう`dump_glyph_matrix`に指示している。)

テキストモード端末で再表示問題をデバッグすれば、dump-frame-glyph-matrix``の有用性に気付くかもしれない。

再表示のデバッグに役立つ他のコマンドとしては、`dump-glyph-row`と`dump-tool-bar-row`が挙げられる。

X配下で実行中のEmacsにたいして再表示問題をデバッグする際には、`ff`コマンドを使用できる。これは保留されているすべてのディスプレイ更新をフラッシュするコマンドだ。

`src/.gdbinit`には再表示に関するデータ構造を、簡潔かつユーザーフレンドリーなフォーマットでダンプする多くのコマンドが定義されている:

- `ppt` :: カレントバッファーのPT、ナローイング、gapの値をプリント
- `pit` :: カレントディスプレイイテレータ`it`をダンプ
- `pwin` :: カレントウィンドウ`win`をダンプ
- `prow` :: glyph_row型のカレントの`row`をダンプ
- `pg` :: カレントグリフ`glyph`をダンプ
- `pgi` :: 次のグリフをダンプ
- `pgrow` :: glyph_row型のカレント`row`のすべてのグリフをダンプ
- `pcursor` :: カレントの`output_cursor`をダンプ

上記コマンドのについては、`x`を後置したバージョンのコマンドもある。関連するオブジェクトを引数として受け取るコマンドだ。たとえば`pgrowx`は`struct
glyph_row`型の引数オブジェクトについて、すべてのグリフをダンプするコマンドだ。

再表示はEmacsによって非常に頻繁に行われるので、デバッグ中の問題が(まだ)発生していないのに、再表示の度に停止しないよう、ブレークポイントの配置には考慮が要される。これに関する役に立つテクニックを挙げておこう:

- Emacsを実行する前に`Frecenter`か`Fredraw_display`にブレークポイントを配置する。それから表示バグの再現に必要なことを行い、バグ再現のための最後のアクションを呼び出す直前に`C-l`や`M-x redraw-display`を呼び出すのだ。デバッガに制御が渡るので、表示バグが間もなく発生すると判っている上で、戦略的な位置へのブレークポイントのセットや有効化が可能になる。`Fredraw_display`にブレークポイントを張っておけばバグの再現だけではなく、`M-x redraw-display`を呼び出すことによって表示バグが再描画される様を一から確認できるだろう。

- 不正なカーソル位置をデバッグする際のブレークポイントの位置として相応しいのが`set_cursor_from_row`だ。この関数が`redraw-display`の一部として最初に呼び出される際には、ミニバッファーウィンドウが再描画されるがこれは多分あなたが欲する再描画ではないので、目的としている呼び出しに到達するために、`continue`をタイプしよう。一般的なデバッグ方法としては`w->contents`の値を調べる。`set_cursor_from_row`が正しいウィンドウおよびバッファーにたいして呼び出されているか調べるのだ。そのバッファーの表示は、デバッグしている再表示呼び出しによって行われている筈だからだ。

- `set_cursor_from_row`はGDBコマンド`pgrow`でスクリーン行(またの名を`glyph row`という)の内容を調べる場所としても適している。最初はもちろん調査したいスクリーン行にカーソルがあるか確認しよう。上記アドバイスにある`Fredraw_display`か`Frecenter`にブレークポイントをセットした場合には、これらのコマンドが呼び出される前にその行にカーソルを移動しておくこと。

- 特定のバッファー位置や滅多に使用されない特定の文字でのみ問題が発生する場合には、それらの値をブレークポイントのブレーク条件にセットできる。ディスプレイエンジンははバッファーや文字列の位置を`it->current`、バッファーでの文字位置を`it->current.pos.charpos`で保守している。ほとんどの再表示関数は`struct it`オブジェクトのポインターを引数として受け取るので、これらの関数のブレークポイントに以下のような条件を設定すればよい:

```text
    (gdb) break x_produce_glyphs if it->current.pos.charpos == 1234
```

表示される文字に条件を設定する場合には`it->c`か`it->char_to_display`を使おう。

- 表示用のグリフ生成に使用されるオブジェクトに条件を設けることもできる。`it->method`はバッファーコンテンツの表示では`GET_FROM_BUFFER`、Lisp文字列(`display`プロパティやオーバーレイ文字列のこと)の表示は`GET_FROM_STRING`、イメージの表示なら`GET_FROM_IMAGE`といった値となる。これらの値の完全なリストについては、`dispextern.h`の`enum it_method`を参照のこと。

- ディスプレイエンジンがテキストプロパティ`display`やオーバーレイ文字列を処理する際には、バッファーテキストのイテレーションを記述する状態変数をイテレータ(反復)のスタックにpushしてから、プロパティやオーバーレイを処理するためにイテレータオブジェクトの再初期化を行う。`it->sp` (spは"スタックポインター")が0より大きければ、少なくとも1回はイテレータスタックにpush されたことを意味している。したがってブレークポイントの条件として`it->sp`の値が正、あるいは特定の正の値を設定すれば、`display`プロパティやオーバーレイでのみ発生する表示問題がデバッグできる。

## ネイティブコンパイルされたLispのデバッグにまつわる問題

ネイティブコンパイルされたLisp固有の問題に遭遇したときには、以下の手順にしたがって原因の特定を試みることを推奨する:

- 二分探索を用いて問題のある".el"ファイルのコード範囲を最小化して、問題の原因となっている関数の特定を試みる。

`native-comp-speed`を1、何なら0にセットして、問題のあるファイルのネイティブコンパイルを試みる。これで問題が解決するようなら、以下を使用できるだろう

```text
    (declare (speed 1))
```

疑わしい関数(複数可)のbody先頭に上記宣言を追加して、それらの関数にたいしてのみ`native-comp-speed`を変更するのだ。どの関数が問題の原因となっているか特定する助けとなるかもしれない。

- 問題のある関数にたいして、依然として問題が発生する最小限のコードになるまで絞り込む。

- 問題にたいしてLispやCのバックトレースのような資料を調べて、問題の原因特定を試みる。

上記手段を使用しても問題の原因を特定できない場合には、変数`comp-libgccjit-reproducer`に非`nil`値をセットした後に問題のあるファイルをネイティブコンパイルしてみる。これにより`ELNFILENAME_libgccjit_repro.c`という名前のファイルが生成される筈だ。ここで`ELNFILENAME`は問題のある".eln"と同じ名前であり".eln"ファイルが生成されるのと同じディレクトリー、あるいは"~/.emacs.d/eln-cache"というディレクトリーの配下に生成される(どちらのディレクトリーになるかはネイティブコンパイルがどのように呼び出されたかに依存する)。再生成するファイルを`subr--trampoline-XXXXXXX_FUNCTION_libgccjit_repro.c`
(`XXXXXXX`は16進文字からなるながい文字列、`FUNCTION`はコンパイルされた".el"ファイルの中の関数)のような名前にすることも可能だ。この再生成したCファイルをバグレポートに添付して欲しい。

## `longjmp`呼び出しの後を追う

glibcの最近のバージョン(2.4以上か?)は`setjmp`および`longjmp`のための値を暗号化して保存するが、これによりGDBから`next`呼び出しで`longjmp`を追うのが不可能になった。この保護を無効にするには、環境変数`LD_POINTER_GUARD`に`0`をセットする必要がある。

## EmacsからGDBを使うには

EmacsでのGDBを用いたデバッグには、コマンドラインから行う場合に比べていくつかの利点がある(Emacsマニュアルの"GDB Graphical
Interface"ノードを参照)。Emacsのデバッグだけに利用可能な機能もいくつか存在する:

1) ツールバーのコマンド`gud-print` ("p"アイコン)を使えば、ポイント位置にある変数のS式をGUDバッファーにプリントできる。

2) lispオブジェクトにたいするスピードバー上のwatch式のコンポーネントの上で"p"を押下すると、GUDバッファーにそれのS式をプリントする。

3) ツールバーの`STOP`ボタンおよびメニューバーのメニューアイテム`Signals->STOP`は通常だと`SIGINT`を送信するが、かわりにSIGTSTPを送信するように調整されている。

4) コマンド`gud-pv`は`C-x C-a C-v`にグローバルにバインドされており、これを使えばポイント位置のlisp変数の値をプリントできる。

## ロード前のEmacsやダンプ中のEmacsで起こっていることをデバッグする

アンダンプされたEmacsで問題が発生しているかどうか確認したい場合には、`temacs`をデバッグすると役に立つかもしれない。`gdb
temacs`とタイプしてから`r -batch -l loadup`で開始すれば、デバッガ配下で`temacs`を実行できる(訳注:
実行中のプロセスをメモリからディスクに書き出すのがダンプなので、アンダンプはその反対; 前にダンプしたファイルをメモリに読み込んで実行することを指す)。

ダンプ中に何が起きているかをデバッグする必要がある場合には、かわりに`r -batch -l loadup
dump`で開始する。bootstrapでのダンプをデバッグする場合には、`loadup dump`ではなく`loadup
bootstrap`を使えばよい。

この方法で実際にGDBから`temacs`を実行できた場合には、ダンプしたEmacsの実行を試みてはならない。GDBのブレークポイントが張られた状態でダンプされているからだ。

## Xプロトコルエラーに出くわしたら

Xサーバーは通常だとプロトコルエラーを非同期に報告するので、エラー原因のプリミティブがリターンされてからかなり経った後にエラーに気づくことになる。

エラー原因に関して明解な情報を得るためには、`(x-synchronize
t)`を評価してみる。これによりEmacsはXlib呼び出しそれぞれが、リターンする前にエラーチェックを同期モードに移行する。これは非常に低速なモードだがエラー発生時には、どの呼び出しが本当のエラー原因なのかを正確に確認できるだろう。

以下のように`-xrm`オプションとともに呼び出すことで、同期モードでEmacsを開始することもできる:

```shell
    emacs -xrm "emacs.synchronous: true"
```

関数`x_error_quitter`にブレークポイントをセットして、Emacsがこの関数内部で停止した際にバックトレースを調べれば、どのコードがXプロトコルエラーを起こしたのか確認できるだろう。

`emacsclient`呼び出しによって作成されたGUIフレームのXプロトコルエラーをトレースしたくても、コマンドラインオプションに`-nw`を指定して開始したEmacsセッションのサーバーでは、`-xrm`オプションの効果がないかもしれないことに注意。そのような場合には以下のようにしてEmacsを開始すること

```shell
  emacs -nw --eval '(setq x-command-line-resources "emacs.synchronous: true")'
```

こうすればより確度の高い結果が得られる筈だ。

通常使用しない文字の表示や、フォント関連のカスタマイズでのXプロトコルエラーにたいしては、以下のようにしてEmacsを呼び出してみよう:

```shell
  XFT_DEBUG=16 emacs -xrm "emacs.synchronous: true"
```

これによりlibXftライブラリーでのフォントに関する問題について有益な情報が生成される筈だ。

Emacsを同期モードで実行すると、Xプロトコル関連の一部のバグが発生しなくなる。このようなバグを追跡する場合には、以下の手順を推奨している:

- デバッガからEmacsを実行して、Lispから呼び出されるとXプロトコルエラートリガーするプリミティブ関数の内部にブレークポイントを配置する。たとえばフレームの削除時にエラーが発生する場合には、`Fdelete_frame`の中にブレークポイントを配置する。

- ブレークポイントで停止したらコードをステップ実行してX関数の呼び出しを探す(名前が"X"、"Xt"、"Xm"で始まる関数だ)。

- 以下のようにX関数の呼び出しそれぞれにたいして、前後に`XSync`呼び出しを挿入する:

```c
      XSync (f->output_data.x->display_info->display, 0);
```

ここで`f`は選択されたフレーム`struct frame` (通常は`XFRAME (selected_frame)`を介して利用可能)へのポインターだ(Xを呼び出すほとんどの関数はフレームへのポインターを保持するために、多分`f`や`sf`のような名前の変数をすでにもっているので、改めて計算する必要はない筈だ)。

デバッグ中のプログラムの中から関数を呼び出せるデバッガであれば、Emacsをリコンパイルせずに`XSync`呼び出しを行える筈だ。たとえばGDBなら:

```text
      call XSync (f->output_data.x->display_info->display, 0)
```

上記のように疑わしいX呼び出しの前と直後で呼び出せばよい。
before and immediately after the suspect X calls.
デバッガがこれをサポートしていなければ、ソースコードに呼び出しのペアーを追加して、Emacsをリビルドする必要があるだろう。

どちらの方法でも計画的にコードをステップで追跡、Emacsが呼び出すX関数それぞれにたいしてこれらの呼び出しを行っていく。そして`XSync`呼び出しが関数`x_error_quitter`内で終了するような最初のX関数を突き止めよう。これが発生する最初のX関数呼び出しこそが、Xプロトコルエラーを生成している関数だ。

- これでこの忌々しいX呼び出しを調べて、何が問題なのか見つけだせる筈だ。

## Xサーバー上でのEmacsのエラーやメモリーリーク

`xmon`のようなツールを使えば、EmacsとXサーバーの間のトラフィックをトレースできる。

`xmon`を使えばlXプロトコルエラーの発生時に、実際にEmacsが何を送信したか調べることができる。Xサーバーのメモリー使用量増加の原因がEmacsの場合には、xmonを使ってEmacsがサーバー上で何のアイテム(ウィンドウ、グラフィカルコンテキスト、pixmap)を作成したか、何を削除したか調べることができる。作成の方が削除より一貫して多い場合には、そのアイテムのタイプ、アイテム作成時にあなたが行っていたアクティビティがデバッグ開始点のヒントを与えてくれるだろう。

## Emacsが応答に失敗するという症状のバグについて

Emacsが`hung`、つまり固まっていると判断を下すのは早計だ。無限ループのせいかもしれないのだから。どちらなのかを調べるためにはGDB配下で問題を再現して、応答しなくなったらEmacsを一度停止してみよう。(Emacsが直接Xウィンドウを使用している場合には、GDB上で`C-z`をタイプすればEmacsを停止できる。MS-Windowsの場合には通常通りEmacsを実行してからGDBをアタッチすれば、通常だとEmacsが何を行っていたとしても割り込むことができるので、以下に示すステップを実行できるだろう。)

Emacsが停止したら`step`でステップ実行してみる。Emacsがhungしていた場合には`step`コマンドはリターンしないが、無限ループしていたのなら`step`がリターンして制御が戻る筈だ。

これによりEmacsが何らかのシステムコールでhungしている場合には、もう一度Emacsを停止してその呼び出しの引数を調べてみよう。あなたがバグレポートを送る際にはそのシステムコールがソースの何処にあるのか、引数が何なのかを正確に伝えることが非常に重要になるだろう。

Emacsが無限ループしていたら、そのループの懐紙と終了を見つけ出そう。これをもっとも簡単に行うには、GDBコマンドの`finish`コマンドを使えばよい。このコマンドを使用する度に、Emacsは実行を再開して1階層分のスタックフレームを抜け出すと再び停止する。`finish`がリターンしなくなるまでこれを繰り返すのだ(`finish`を試してリターンしなければ、今試したスタックフレームに無限ループがあることを意味している)。

Emacsをもう一度停止して、そのフレームに戻るまで繰り返し`finish`を実行する。戻ったらそのフレームをステップで追うために`next`を使用しよう。ステップ実行することによりループの開始と終了の位置が確認できるだろう。そのループで使用されているデータも調べて、終了すべきループから何故抜け出せないのかを特定するのだ。

GNUおよびUnixシステムでは、EmacsへのSIGUSR2の送信を試みることも可能だ。`debug-on-event`がデフォルト値のままなら、このシグナルによってEmacsはカレントループからの脱出を試みて、Lispデバッガにエンターする筈だ(Lispデバッガに関する詳細については、ELispマニュアルのノード"Debugging"を参照)。この機能はCレベルのデバッガが簡単に利用できないときに役に立つだろう。

## Emacsで特定の操作が前より遅くなった原因を調べるためのアドバイス

その遅い処理の間に繰り返しEmacsを停止して、その都度バックトレースを取得する。パターンを見い出すためにバックトレースを比較しよう。あなたの予想よりも頻繁に出現する関数を見つけるのだ。

Cのバックトレースで特徴的なパターンが見つからなかったら`xbacktrace`をタイプするか、あるいは`Ffuncall`を呼び出すフレーム(上記参照)を調べて、もう一度パターンの発見を試みるのだ。

Xを使用していれば、GDBから`C-z`をタイプしていつでもEmacsを停止できる。X以外の場合には`C-g`でこれを行うことができる。Unix以外のプラットフォーム(MS-DOSとか)の場合には、かわりに`C-BREAK`を押下する必要があるかもしれない。

## GDBが実行できずEmacsのロードもできないデバッガの場合

シンボルテーブルとともにEmacsをロードできるデバッガがないシステムも一部に存在する(多分シンボル数に固定値の制限があり、Emacsのシンボル数がその制限を超過するからだろう。そのような極限環境において用いることができる手法を紹介しておく。

```shell
    nm -n temacs > nmout
    strip temacs
    adb temacs
    0xd:i
    0xe:i
    14:i
    17:i
    :r -l loadup   (または何でもよい)
```

数値アドレスとシンボルの間の変換や逆変換を行うために、ファイル"nmout"の参照が必要になる。

実行する環境は、何らかのウィンドウシステム配下だと便利だ。見込みのない状況でEmacsが立ち往生してしまった場合でも、別ウィンドウを作成して`kill
-9`を実行できるからだ。`kill -ILL`も役に立つことが多い。これによりEmacsがcoreダンプするか、あるいはadbに制御が戻るだろう。

## テキスト端末における不正なスクリーン更新のデバッグ

Emacsが間違ってスクリーンを更新する問題をデバッグする際には何をタイプ入力したか、Emacsがスクリーンに何を送信したかを記録できれば役に立つだろう。これらを記録するには以下のようにする

```lisp
(open-dribble-file "~/.dribble")  (open-termscript "~/.termscript")
```

このdribbleファイルにはEmacsが端末から読み取ったすべての文字、termscriptファイルには端末に送信したすべての文字が記録される。ディレクトリー"~/"を使うのは、他のユーザーとの干渉を防ぐためだ。

思うように再現できない表示問題にたいしては、これら2つの式を"~/.emacs"ファイルに配置して、問題が発生したら実行中のEmacsをexitしてkill。その後これら2つのファイルの名前を変更する。ファイルが上書きされないようにしたら別のEmacsを起動して、そのEmacsを使って調査を行うのだ。

## Lesstifのデバッグ

LesstifとともにビルドしたEmacsにおいて、Lesstifがマウスとキーボードのイベントをすべて奪ったり、Lesstifのメニューの動作がおかしいといったバグに遭遇した場合には、環境変数`DEBUGSOURCES`と`DEBUG_FILE`をセットすればその時点でLesstifが何を行っていたか確認できるので助けになるだろう。たとえば

```shell
  export DEBUGSOURCES="RowColumn.c:MenuShell.c:MenuUtil.c"
  export DEBUG_FILE=/usr/tmp/LESSTIF_TRACE
  emacs &
```

これにより名前を指定された3つのソースファイルからのトレースを、Lesstifが`/usr/tmp`のファイルにプリントするようになる(非常にサイズが大きくなるかもしれない)。上記で示したように、Emacsを呼び出す前にシェルプロンプトにコマンドをタイプすること。

この種の問題のデバッグには、別の端末からGDBを実行することも助けとなるかもしれない。あるマシンでGDBを実行するよう手配しておいて、Emacsのディスプレイは別の端末に表示させるのだ。そうすればバグが発生した際にGDBを開始した端末に戻って、そこからデバッガを使用する。

## GCで発生する問題のデバッグ

配列`last_marked`
("alloc.c"で定義されている)を使えば、ガベージコレクションのプロセスによってもっとも最近マークされた、最大で512個のオブジェクトを確認できる。ガベージコレクタがLispオブジェクトをマークする際には、常にそのオブジェクトへのポインターが配列`last_marked`に記録される(循環バッファーとして保守されている)。変数`last_marked_index`には`last_marked`配列のインデックスが格納されており、このインデックスにはもっとも最近格納されたばかりのオブジェクトの1つ先を指す値がセットされている。

GC問題のデバッグにおけるもっとも重要な単一のゴールが、破壊されてしまったLispデータ構造の発見である。これは容易なことではない。GCはタグビットを変更して文字列を再配置する。それが`pr`のようなコマンドによる、Lispオブジェクトの調査を困難にしているのだ。Lisp_Object変数からC構造体のポインターへの変換に手作業が必要になることも間々ある。

マークされたオブジェクトの順序の再構築には、`last_marked`配列とソースを用いる。バックトレースから`last_marked`配列に記録された値に相当するスタックフレームを結びつけるためには、一般的にはもっとも内側のフレームから調べる必要がある。`mark_object`のサブルーチンには再帰的に呼び出されるもの、あるいはデータ構造の一部範囲をマークしながらループするものがある。これらのルーチンのコードを調べるとともに、バックトレース内のフレームと`last_marked`の値を比較することによって、`last_marked`の中の値同士の関連性を発見することが可能になるのである。たとえばGCがコンスセルを発見した際には、そのコンスセルの`car`と`cdr再帰的にマークするだろう。`同じことがシンボルのプロパティやベクターの要素等に発生するのである。マークされたデータ構造の再構築には、これらの関連性を使用する。遭遇する文字列やシンボルの名前に特別な注意を払いつつ行っていこう。これらの文字列やシンボル名は、ソースを"grep"して、クラッシュに関係がある高レベルのシンボルやグローバル変数を特定するのに役立つだろう。

破壊されたLispオブジェクトやデータ構造を発見したら、ソースを"grep"してそれが何に使用されているのか、そして何が破壊を引き起こす原因となったかを解決していこう。ソースの調査で手掛かりが見つからなかった場合には、破壊されたデータにウォッチポイントをセットして、無効な方法でそれを変更するコードがどれか確認することができるかもしれない(当然ながらこのテクニックは滅多に変更されないデータでなければ役に立たないだろう)。

破壊されたオブジェクトやデータ構造を手つかずの新鮮なEmacsセッションで調べたり、デバッグ中のセッションと中身を比較することも役に立つかもしれない。これは実行中の実行可能ファイルのアドレスをランダム化(ASLR:Address
Space Layout
Randomization、すなわちアドレス空間配置のランダム化)を行う現代的なシステムでは幾分困難かもしれない。この問題に遭遇してしまったら、"How
to disable ASLR"を参照して欲しい。

## (ウィンドウ化されていない)TTYバージョンのデバッグ

文字端末のディスプレイでデバッグする際にもっとも便利な方法は、Xのようなウィンドウシステムでデバッグする方法だろう。xtermウィンドウを開始してそのウィンドウで以下のコマンドをタイプしよう:

```shell
  $ tty
  $ echo $TERM
```

これらのコマンドがそれぞれ`/dev/ttyp4`および`xterm`と応えたとしよう。

ここでEmacsを開始して(通常のようにウィンドウで表示されるセッション、つまり`-nw`オプションを指定せずに開始する。そして今度はGDBのプロンプトから以下のコマンドをタイプしよう:

```text
  (gdb) set args -nw -t /dev/ttyp4
  (gdb) set environment TERM xterm
  (gdb) run
```

デバッグされることになるEmacsが上記でオープンしたxtermに直接表示されるように、今度は非ウィンドウモードで開始すること。

`screen`パッケージを使用すれば、文字端末の場合と同じようなアレンジが可能になる。

MS-Windowsの場合にはGDB配下でEmacsを実行する前に`new-console`オプションをセットすることで、別個に独自のコンソールでEmacsを開始できる:

```text
  (gdb) set new-console 1
  (gdb) run
```

## 振る舞いが未定義のサニタイザとともにEmacsを実行する

挙動が未定義なサニタイザとともにEmacsをビルドすることによって、Cコードに存在する低レベルな問題の何種類かが見つかる助けになることがある。これらの問題には以下が含まれる:

- (すべてではないが)多くの配列の境界外アクセス
- 符号付き整数のオーバーフロー(`INT_MAX + 1`とか)
- 整数の負の値やwordより大きい量のシフト演算
- アライメントがおかしいポインターやポインターのオーバーフロー
- 型の範囲を超えたbool値やenum値のロード
- NULLを許容しない関数へlにたいするNULLの受け渡し
- 対応するサイズより大きい配列をmemcmp等に渡す
- `__builtin_clz (0)`のようにビルトイン関数に無効な値を渡す
- `__builtin_unreachable`呼び出しに届いてしまう(Emacsでは`eassume`に相当する)

GCCの`UndefinedBehaviorSanitizer`を使用するには`configure`か`make`を実行する際に、`CFLAGS`に`-fsanitize=undefined`を指定する。サポートされていれば`bound-strict`と`float-cast-overflow`も指定できる。たとえば:

```shell
  ./configure \
    CFLAGS='-O0 -g3 -fsanitize=undefined,bounds-strict,float-cast-overflow'
```

あなたのGCCが普通の場所以外にインストールされたバージョンの場合には、`CFLAGS`に-static-libubsan`の追加が必要かもしれない。

Clangのサニタイザも使用できるが、カバレッジに問題がある。NULLポインターへの0の追加に関する見当違いの警告を抑止するために、`-fsanitize=undefined
-fno-sanitize=pointer-overflow`を追加する必要があるだろう。とはいえこれによりポインターのオーバーフローに関する、他の有効な警告もすべて抑止されてしまう訳だが。

GDBを使用して挙動が未定義なサニタイザでとともに実行可能ファイルをデバッグする際には:

```text
  (gdb) rbreak ^__ubsan_handle_
```

上記GDBコマンドによりエラーが検出されて`UndefinedBehaviorSanitizer`が`stderr`に出力したり、プログラムが終了する前に制御が得られるようになった。

## アドレスサニタイザとともにEmacsを実行する

アドレスサニタイジングとともにEmacsをビルドすることにより、同一オブジェクトを2回freeするといったような、不正なメモリー使用をデバッグする助けになるかもしれない。GCCやこの類のコンパイラーとともにAddressSanitizerを使用するためには、`configure`や`make`のいずれかを実行する際に`CFLAGS`に`-fsanitize=address`を追加する。`configure`してビルドしたらEmacs実行できる。実行時に環境変数に`ASAN_OPTIONS='detect_leaks=0`を設定してあれば、マイナーなメモリーリークに関する冗長な診断を抑止できる。たとえば:

```shell
  export ASAN_OPTIONS='detect_leaks=0'
  ./configure CFLAGS='-O0 -g3 -fsanitize=address'
  make
  src/emacs
```

普通とは違う場所にインストールされたバージョンのGCCでは、`CFLAGS`に`-static-libasan`を追加する必要があるかもしれない。

アドレスサニタイジングされた実行可能ファイルのデバッグにGDBを用いる際には、以下のGDBコマンド:

```text
  (gdb) rbreak ^__asan_report_
```

上記GDBコマンドによりエラーが検出されて`UndefinedBehaviorSanitizer`が`stderr`に出力したり、プログラムが終了する前に制御が得られるようになった。

残念なことにアドレスサニタイジングは動作が未定義のサニタイザとの互換性はなく、`configure`の`--with-dumping=unexec`オプションとも互換性がない。

### アドレスポイズニング(address poisoning)とその無毒化

アドレスサニタイジングとともにコンパイルしたEmacsだと、dead/freeのlispオブジェクトをまず"poisoned"とマークしようと試みるので、最初にその"poisoned"を解除しなければアクセスが禁じられる。これはフリーな内部リストの中のオブジェクトにたいするチェックを行う余計なレイヤーを追加するが、伝統的な"使用後にフリー"のチェックによって回避できるかもしれない。これを無効にするためには`ASAN_OPTIONS`に`allow_user_poisoning=0`を追加するか、あるいは`CFLAGS`に`-DGC_ASAN_POISON_OBJECTS=0`を指定してEmacsをビルドすること。

GDB使用中のメモリーアドレスの検証は、ASanライブラリーが追加で提供するヘルパー関数を用いて行っている:

```text
  (gdb) call __asan_describe_address(ptr)
```

あるアドレス範囲が"poisoned"かどうかをチェックするには以下のように行う:

```text
  (gdb) call __asan_region_is_poisoned(ptr, 8)
```

他の追加関数についても、あなたのコンピューター用のヘッダーディレクトリーにあるヘッダー"sanitizer/asan_interface.h"で見つけることができる。

## Valgrind配下でのEmacsの実行

[Valgrind](https://valgrind.org/)とは低レベルな問題をEmacsでデバッグする際に役に立つフリーソフトウェアのことだ。GCCサニタイザとは異なり、ValgrindとともにEmacsをコンパイルするために特別なデバッグ用のフラグは必要ない。したがってデバッグを有効にしてリコンパイルしたら消滅してしまうような問題の調査に便利だ。ただしデフォルトのValgrindはにたいして大量の誤検出を生成するので、Valgrindを効果的に使用するためにはこれらの誤検出を抑制するための抑止ファイルを保守する必要があるだろう。たとえば以下のようにValgrindを呼び出すのだ:

```shell
    valgrind --suppressions=valgrind.supp ./emacs
```

ここで"valgrind.supp"は、以下のような行のグループを含んだファイルだ(以下の例はEmacsのガベージコレクションの間に生成されるValgrindの誤検出の一部を抑止するための設定):

```text
    {
      Fgarbage_collect Cond - 抑止的なガベージコレクション
      Memcheck:Cond
      ...
      fun:Fgarbage_collect
    }
```

残念なことにValgrindの抑止ファイルはシステムに依存する傾向があるので、あなたのシステムに合致するファイルを維持する必要があるだろう。

## ASLRを無効にする方法

現代的なシステムではASLR(Address Space Layout Randomization:
アドレス空間配置のランダム化)という機能を使用している。これは実行中のプログラムのベースアドレスをランダム化する。この機能によって、怪しげなソフトウェアやハッカーが実行可能ファイルを調べて実行中のプログラムの関数や変数のアドレスを見つけることが難しくなるのだ。これにより同じプログラムを再実行しても、同じ変数に異なるアドレスが割り振られることになる。しかしたとえば2つの異なるEmacsセッションでオブジェクトを比較したい場合などは、ASLRを無効にすることが役に立つときもあるかもしれない。

GNU/Linuxシステムであれば、以下のシェルコマンドでASLRを一時的に無効化できる:

```shell
  echo 0 > /proc/sys/kernel/randomize_va_space
```

またはASLRを一時的に無効にした環境でEmacsを実行する:

```text
  setarch -R emacs [args...]
```

MS-WindowsのEmacsでASLRを無効にするためには、"src/Makefile"で定義されている変数`LD_SWITCH_SYSTEM_TEMACS`に`-Wl,-disable-dynamicbase`を追加してEmacsをリビルドする必要があるだろう。代替えとしてEmacsの実行可能ファイルのPEヘッダーを編集するツールなどを使用して、PEヘッダーに記録されている`DllCharacteristics`フラグを`DYNAMIC_BASE
(0x40)`にリセットする手もある。

macOSでASLRを無効にする方法は公式には存在しないが、インターネットを検索すれば色々なハックの存在を確認できる筈だ。

## Emacsのcoreダンプファイルからバッファー内容を復旧する方法

ファイル"etc/emacs-buffer.gdb"にはcoreダンプファイルからEmacsのバッファー内容を復旧するために、一連のGDBコマンドが定義されている。それらのコマンドを使えば、デバッガから人間が読めるフォーマットで、バッファーのリストを表示できることにも気付くかもしれない。

## LLDBを使ったデバッグ

GDBが利用できないM1チップのmacOS等では、EmacsのデバッグにLLDBを使うこともできる。

LLDBによるEmacsのデバッグを開始するには、Emacsの実行可能ファイルがあるディレクトリー(通常はEmacsディストリビューションツリーのサブディレクトリー"src")で、シェルプロンプトから単に`lldb
./emacs RET`ちタイプすればよい。

LLDBでEmacsをデバッグする際には、EmacsをビルドしたディレクトリーでLLDBを開始するべきだ。このディレクトリーにあるファイル".lldbinit"は、Emacsソースツリーの"etc"ディレクトリーにあるPythonモジュール"emacs_lldb.py"をロードする。このPythonモジュールにはEmacsのデバッグ用のコマンド`user-defined`が定義されている。

LLDBはデフォルトではカレントディレクトリーにある".lldbinit"ファイルを自動的にロードしない。あなたの"~/.lldbinit"ファイル(なければ作成する)に、以下の行を追加するのがもっとも簡単な方法だろう:

```text
  settings set target.load-cwd-lldbinit true
```

かわりに`lldb --local-lldbinit ./emacs RET`とタイプしてもよい。

ここまで上手くいけば、LLDBの開始後に"Emacs debugging support has been
installed"のようなメッセージを目にする筈だ。どのようなEmacs固有コマンドが定義されているかは、以下のようにして確認できる

```text
  (lldb) help
```

"x"で始まるのがEmacs用にユーザー定義されたコマンドだ。

LLDBに関する情報については、ウェブにあるLLDBリファレンスを参照して欲しい。すでにGDBに関する知識がある場合には、ウェブでGDBコマンドに相当するLLDBコマンドのマッピングも見つけられるだろう。

## OpenBSDでのEmacsのデバッグ

OpenBSDでEmacsをデバッグするには、"gdb"パッケージの`egdb`コマンドを使用する。GCCおよびclangどちらでコンパイルしたEmacsでも機能すると報告されている。

## AndroidでのEmacsのデバッグ

"java/"ディレクトリーには、USBを使ってコンピューターに接続されたAndroidデバイスにおいて、EmacsをGDBセッション配下で実行するために必要な手順を自動化するためのスクリプトがある。

必要なユーティリティーは`adb` (Android Debug
Bridge)、デバッガのアタッチ後にEmacsが再開するようにAndroidシステムに合図を起こるように調整されたJavaデバッガ("jdb")だ。

これら3つのツールがあれば、(Emacsのソースディレクトリーから)単に以下を実行するだけでよい:

```shell
  ../java/debug.sh -- [gdbに渡したい追加の引数があれば追加]
```

デバッグ情報が何行かプリントされた後に、GDBプロンプトが表示される筈だ。

そのデバイスにGdbserverが存在しない場合には、以下のようにしてアップロードしよう:

```shell
  ../java/debug.sh --gdbserver /path/to/gdbserver
```

このGdbserverはAndroid
NDKを使って静的にリンク、あるいはコンパイルされている筈なので、デバッグするEmacsバイナリと同じアーキテクチャを対象としたものでなければならない。古いバージョンのAndroid
NDK(r24とか)に相当するGdbserverバイナリは、普通は以下の場所にあるだろう

```text
  prebuilt/android-<arch>/gdbserver/gdbserver
```

これはNDKディストリビューションのルートからの相対ディレクトリーだ。

ターゲットdeviceの既存のEmacsプロセスにアタッチするためには、"debug.sh"の引数に`--attach-existing`を指定する:

```shell
  ../java/debug.sh --attach-existing [other arguments]
```

Emacsプロセス複数実行中の場合には、"debug.sh"が実行中のプロセスそれぞれについて名前とPIDを表示して、どのプロセスにアタッチするべきか入力を求めるだろう。

Emacsが開始されたら、以下のようにタイプしよう:

```text
  (gdb) handle SIGUSR1 noprint pass
```

これはAndroidポートの`select`エミュレーションが送信する`SIGUSR1`シグナルを無視するためだ。これを失念すると、ウィンドウイベントを受信する度にEmacsが停止するが、それは恐らくあなたがやりたいことではないだろう。

上述のデバッグ手順に加えて、Androidにはクラッシュの最中およびクラッシュ後に毎回バックトレースをプリントする`logcat`バッファーも保守している。このバッファーの内容はクラッシュ後の検死デバッグ(post-mortem
debug: 事後デバッグ)を行う際には役に立つだろう。これは以下のように`adb`ツールを通じて取得することも可能だ:

```shell
  $ adb logcat
```

Androidによってプリントされるクラッシュメッセージには3つの形式がある。1つ目はJavaコード内でクラッシュが発生した際の形式で、logcatバッファーには以下のようにプリントされる筈だ:

```text
E AndroidRuntime: FATAL EXCEPTION: main
E AndroidRuntime: Process: org.gnu.emacs, PID: 18057
E AndroidRuntime: java.lang.RuntimeException: sample crash
E AndroidRuntime: 	at
org.gnu.emacs.EmacsService.onCreate(EmacsService.java:308)
E AndroidRuntime: 	at
android.app.ActivityThread.handleCreateService(ActivityThread.java:4485)
E AndroidRuntime: 	... 9 more<
```

2つ目は致命的なシグナル("abort"や"segmentation
fault"など)を受信して、Cコード内でクラッシュが発生した際の形式。この種のクラッシュでは以下のようにプリントされるだろう:

```text
F libc    : Fatal signal 11 (SIGSEGV), code 1 (SEGV_MAPERR), fault addr 0x3 in tid 32644
 (Emacs main thre), pid 32619 (org.gnu.emacs)
F DEBUG   : Cmdline: org.gnu.emacs
F DEBUG   : pid: 32619, tid: 32644, name: Emacs main thre  >>> org.gnu.emacs <<<
F DEBUG   :       #00 pc 002b27b0  /.../lib/arm64/libemacs.so (sfnt_read_cmap_table+32)
F DEBUG   :       #01 pc 002c4ee8  /.../lib/arm64/libemacs.so (sfntfont_read_cmap+84)
F DEBUG   :       #02 pc 002c4dc4  /.../lib/arm64/libemacs.so (sfntfont_lookup_char+396)
F DEBUG   :       #03 pc 002c23d8  /.../lib/arm64/libemacs.so (sfntfont_list+1688)
F DEBUG   :       #04 pc 0021112c  /.../lib/arm64/libemacs.so (font_list_entities+864)
F DEBUG   :       #05 pc 002138d8  /.../lib/arm64/libemacs.so (font_find_for_lface+1532)
F DEBUG   :       #06 pc 00280c50  /.../lib/arm64/libemacs.so (fontset_find_font+2760)
F DEBUG   :       #07 pc 0027cadc  /.../lib/arm64/libemacs.so (fontset_font+792)
F DEBUG   :       #08 pc 0027c710  /.../lib/arm64/libemacs.so (face_for_char+412)
F DEBUG   :       #09 pc 00217314  /.../lib/arm64/libemacs.so (Finternal_char_font+324)
F DEBUG   :       #10 pc 00240d78  /.../lib/arm64/libemacs.so (exec_byte_code+3112)
F DEBUG   :       #11 pc 001f5ff8  /.../lib/arm64/libemacs.so (Ffuncall+392)
F DEBUG   :       #12 pc 001f3cf0  /.../lib/arm64/libemacs.so (eval_sub+2260)
F DEBUG   :       #13 pc 001f853c  /.../lib/arm64/libemacs.so (Feval+80)
F DEBUG   :       #14 pc 00240d78  /.../lib/arm64/libemacs.so (exec_byte_code+3112)
F DEBUG   :       #15 pc 00240130  /.../lib/arm64/libemacs.so (Fbyte_code+120)
F DEBUG   :       #16 pc 001f3d84  /.../lib/arm64/libemacs.so (eval_sub+2408)
F DEBUG   :       #17 pc 00221d7c  /.../lib/arm64/libemacs.so (readevalloop+1748)
F DEBUG   :       #18 pc 002201a0  /.../lib/arm64/libemacs.so (Fload+2544)
F DEBUG   :       #19 pc 00221f3c  /.../lib/arm64/libemacs.so (save_match_data_load+88)
F DEBUG   :       #20 pc 001f8414  /.../lib/arm64/libemacs.so (load_with_autoload_queue+252)
F DEBUG   :       #21 pc 001f6550  /.../lib/arm64/libemacs.so (Fautoload_do_load+608)
F DEBUG   :       #22 pc 00240d78  /.../lib/arm64/libemacs.so (exec_byte_code+3112)
F DEBUG   :       #23 pc 001f5ff8  /.../lib/arm64/libemacs.so (Ffuncall+392)
F DEBUG   :       #24 pc 001f1120  /.../lib/arm64/libemacs.so (Ffuncall_interactively+64)
F DEBUG   :       #25 pc 001f5ff8  /.../lib/arm64/libemacs.so (Ffuncall+392)
F DEBUG   :       #26 pc 001f8b8c  /.../lib/arm64/libemacs.so (Fapply+916)
F DEBUG   :       #27 pc 001f137c  /.../lib/arm64/libemacs.so (Fcall_interactively+576)
F DEBUG   :       #28 pc 00240d78  /.../lib/arm64/libemacs.so (exec_byte_code+3112)
F DEBUG   :       #29 pc 001f5ff8  /.../lib/arm64/libemacs.so (Ffuncall+392)
F DEBUG   :       #30 pc 0016d054  /.../lib/arm64/libemacs.so (command_loop_1+1344)
F DEBUG   :       #31 pc 001f6d90  /.../lib/arm64/libemacs.so (internal_condition_case+92)
F DEBUG   :       #32 pc 0016cafc  /.../lib/arm64/libemacs.so (command_loop_2+48)
F DEBUG   :       #33 pc 001f6660  /.../lib/arm64/libemacs.so (internal_catch+84)
F DEBUG   :       #34 pc 0016c288  /.../lib/arm64/libemacs.so (command_loop+264)
F DEBUG   :       #35 pc 0016c0d8  /.../lib/arm64/libemacs.so (recursive_edit_1+144)
F DEBUG   :       #36 pc 0016c4fc  /.../lib/arm64/libemacs.so (Frecursive_edit+348)
F DEBUG   :       #37 pc 0016af9c  /.../lib/arm64/libemacs.so (android_emacs_init+7132)
F DEBUG   :       #38 pc 002ab8d4  /.../lib/arm64/libemacs.so (Java_org_gnu_emacs_...+3816)
```

1行目("libc"を含む行)には致命的なシグナルの番号、シグナルが発生したVMのアドレス、クラッシュしたスレッドの名前とIDがプリントされている。以降の行にはクラッシュに至るまでのコールスタック含まれる関数それぞれを物語るバックトレースが含まれている。

3つ目はAndroidのCheckJNI機能によって検知された、EmacsによるJVMの誤用についてプリントされた形式だ。以下のようにプリントされるだろう:

```text
A/art: art/runtime/check_jni.cc:65] JNI DETECTED ERROR IN APPLICATION: ...
A/art: art/runtime/check_jni.cc:65]     in call to CallVoidMethodV
A/art: art/runtime/check_jni.cc:65]     from void android.os.MessageQueue.nativePollOnce(long, int)
A/art: art/runtime/check_jni.cc:65] "main" prio=5 tid=1 Runnable
A/art: art/runtime/check_jni.cc:65]   | group="main" sCount=0 dsCount=0 obj=0x87d30ef0 self=0xb4f07800
A/art: art/runtime/check_jni.cc:65]   | sysTid=18828 nice=-11 cgrp=apps sched=0/0 handle=0xb6fdeec8
A/art: art/runtime/check_jni.cc:65]   | state=R schedstat=( 2249126546 506089308 3210 ) utm=183 stm=41 core=3 HZ=100
A/art: art/runtime/check_jni.cc:65]   | stack=0xbe0c8000-0xbe0ca000 stackSize=8MB
A/art: art/runtime/check_jni.cc:65]   | held mutexes= "mutator lock"(shared held)
A/art: art/runtime/check_jni.cc:65]   native: #00 pc 00004640  /system/lib/libbacktrace_libc++.so (UnwindCurrent::Unwind(unsigned int, ucontext*)+23)
A/art: art/runtime/check_jni.cc:65]   native: #01 pc 00002e8d  /system/lib/libbacktrace_libc++.so (Backtrace::Unwind(unsigned int, ucontext*)+8)
A/art: art/runtime/check_jni.cc:65]   native: #02 pc 00248381  /system/lib/libart.so (art::DumpNativeStack(std::__1::basic_ostream<char, std::__1::char_traits<char> >&, int, char const*, art::mirror::ArtMethod*)+68)
A/art: art/runtime/check_jni.cc:65]   native: #03 pc 0022cd0b  /system/lib/libart.so (art::Thread::Dump(std::__1::basic_ostream<char, std::__1::char_traits<char> >&) const+146)
A/art: art/runtime/check_jni.cc:65]   native: #04 pc 000b189b  /system/lib/libart.so (art::JniAbort(char const*, char const*)+582)
A/art: art/runtime/check_jni.cc:65]   native: #05 pc 000b1fd5  /system/lib/libart.so (art::JniAbortF(char const*, char const*, ...)+60)
A/art: art/runtime/check_jni.cc:65]   native: #06 pc 000b50e5  /system/lib/libart.so (art::ScopedCheck::ScopedCheck(_JNIEnv*, int, char const*)+1284)
A/art: art/runtime/check_jni.cc:65]   native: #07 pc 000bc59f  /system/lib/libart.so (art::CheckJNI::CallVoidMethodV(_JNIEnv*, _jobject*, _jmethodID*, std::__va_list)+30)
A/art: art/runtime/check_jni.cc:65]   native: #08 pc 00063803  /system/lib/libandroid_runtime.so (???)
A/art: art/runtime/check_jni.cc:65]   native: #09 pc 000776bd  /system/lib/libandroid_runtime.so (android::NativeDisplayEventReceiver::dispatchVsync(long long, int, unsigned int)+40)
A/art: art/runtime/check_jni.cc:65]   native: #10 pc 00077885  /system/lib/libandroid_runtime.so (android::NativeDisplayEventReceiver::handleEvent(int, int, void*)+80)
A/art: art/runtime/check_jni.cc:65]   native: #11 pc 00010f6f  /system/lib/libutils.so (android::Looper::pollInner(int)+482)
A/art: art/runtime/check_jni.cc:65]   native: #12 pc 00011019  /system/lib/libutils.so (android::Looper::pollOnce(int, int*, int*, void**)+92)
A/art: art/runtime/check_jni.cc:65]   native: #13 pc 000830c1  /system/lib/libandroid_runtime.so (android::NativeMessageQueue::pollOnce(_JNIEnv*, int)+22)
A/art: art/runtime/check_jni.cc:65]   native: #14 pc 000b22d7  /system/framework/arm/boot.oat (Java_android_os_MessageQueue_nativePollOnce__JI+102)
A/art: art/runtime/check_jni.cc:65]   at android.os.MessageQueue.nativePollOnce(Native method)
A/art: art/runtime/check_jni.cc:65]   at android.os.MessageQueue.next(MessageQueue.java:143)
A/art: art/runtime/check_jni.cc:65]   at android.os.Looper.loop(Looper.java:130)
A/art: art/runtime/check_jni.cc:65]   at android.app.ActivityThread.main(ActivityThread.java:5832)
A/art: art/runtime/check_jni.cc:65]   at java.lang.reflect.Method.invoke!(Native method)
A/art: art/runtime/check_jni.cc:65]   at java.lang.reflect.Method.invoke(Method.java:372)
A/art: art/runtime/check_jni.cc:65]   at com.android.internal.os.ZygoteInit$MethodAndArgsCaller.run(ZygoteInit.java:1399)
A/art: art/runtime/check_jni.cc:65]   at com.android.internal.os.ZygoteInit.main(ZygoteInit.java:1194)
A/art: art/runtime/check_jni.cc:65]
```

このような状況では最初の行にまずEmacsが犯した罪状、それ以降の行にはエラー発生時に実行中だったスレッドそれぞれについてバックトレースがプリントされる。

Android 5.0以上でEmacsを実行している場合には、以下にブレークポイントを置くとよい

```text
  (gdb) break art::JavaVMExt::JniAbort
```

ここにブレークポイントを張っておけば、上記のようなエラー検出時に毎回ブレークする筈だ。

"logcat"出力は常に高速に更新されるので、ファイルやシェルコマンドバッファーにpipeしてから"AndroidRuntime"、"Fatal
signal"、"JNI DETECTED ERROR IN APPLICATION"といったキーワードを検索する方がよいだろう。

滅多にないことだが、CではなくJavaコードのデバッグ必要なことが判るだろう。gdbserverではなくJavaデバッガにアタッチする場合はオプション`--jdb`を指定する。遺憾ながらCとJavaのコードを同時にデバッグするのは不可能だと思われる。

EmacsのCコードではout-of-memoryエラー(メモリー不足)をシグナルするかもしれないJVM関数にたいしては、呼び出し後にJava例外を徹底的にチェックしている。このチェックのための関数が`android_exception_check(_N)`であり、"android.c"で定義されている。これらの関数は前述のJavaコード自身が例外をシグナルしない前提で動作するとともに、メモリー不足以外のすべての種類の例外にたいしてメモリー不足エラーと報告するだろう。

空き容量がかなり残っているにも関わらずEmacsがメモリーの不足を訴えるようなら、ログバッファーから以下の文字列を含む行を検索して欲しい:

```text
  "Possible out of memory error.  The Java exception follows:"
```

そうすれば偽りのメモリー不足エラーに隠れていた例外を改めて発見できるかもしれない。このような例外はいつでも、修正すべきバグがEmacsにあることを示している。


```text
This file is part of GNU Emacs.


GNU Emacs is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.


GNU Emacs is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.


You should have received a copy of the GNU General Public License
along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.
```


Local variables: mode: outline paragraph-separate: "[ 	]*$" end:
