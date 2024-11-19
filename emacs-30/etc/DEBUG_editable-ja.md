# Debugging GNU Emacs

```text
Copyright (C) 1985, 2000-2024 Free Software Foundation, Inc.
See the end of the file for license conditions.
```

## Preliminaries

あなたがすでにdebug情報つきEmacsのビルド、GDBの設定と開始、GDBによる簡単なデバッグテクニックに親しんでいる場合には、このセクションはスキップしてもよい。

### Configuring Emacs for debugging

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

### Configuring GDB

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

### Use the Emacs GDB UI front-end

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

### Setting initial breakpoints

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

### Running Emacs from GDB

新たにEmacsセッションを開始する場合には"*gud-emacs*"バッファーで`run`、その後にコマンドライン引数(`-Q`とか)をタイプしてから`RET`を押下する。Emacs外部でGDBを実行している場合には、GDBプロンプトでは`run`、その後にコマンドライン引数をタイプすればよい。

実行中のEmacsにデバッガをアタッチした場合には、"*gud-emacs*"バッファーで`continue`をタイプして`RET`を押下する。

デバッグ中に目にするであろう多くの変数はLispオブジェクトだ。通常は正体がはっきりしないポインターや解釈が困難な整数が表示されるだろう。それが長いリストして表されている場合にはなおさら不可解なものとなる(`--enable-check-lisp-object-type`が有効な場合にはこれら不可解な値を含む構造体として表示される)。これらをLisp形式で表示するために`pp`コマンドが使用できる。このコマンドは出力をエラーストリームに表示するので、`M-x
redirect-debugging-output`を使えばファイルにリダイレクトできる。もしあなたがGDBでデスクトップアイコンから呼び出された実行中のEmacsにアタッチした場合には、出力をまったく目にしなかったり、どこかの見知らぬ場所に吐き出される公算が強いことを意味している(あなたのデスクトップ環境のドキュメントをチェックしよう)。

"Examining Lisp object values"で、Lispオブジェクトの表示に関する追加情報を入手できるだろう。

このドキュメントの残りの部分では、Emacsのデバッグで特に役に立つテクニックを説明する。Emacsをデバッグしようと思ったらまず全体に目を通して、必要に応じて特定の問題を調べることをお勧めする。

幸運を祈る!

** When you are trying to analyze failed assertions or backtraces, it
is essential to compile Emacs with flags suitable for debugging.
Although CFLAGS="-O0 -g3" often suffices with modern compilers,
you may benefit further by using CFLAGS="-O0 -g3 -gdwarf-4", replacing
"4" by the highest version of DWARF that your compiler supports;
this is especially important for GCC versions older than 4.8.
With GCC and higher optimization levels such as -O2, the
-fno-omit-frame-pointer and -fno-crossjumping options are often
essential.  The latter prevents GCC from using the same abort call for
all assertions in a given function, rendering the stack backtrace
useless for identifying the specific failed assertion.

** It is a good idea to run Emacs under GDB (or some other suitable
debugger) *all the time*.  Then, when Emacs crashes, you will be able
to debug the live process, not just a core dump.  (This is especially
important on systems which don't support core files, and instead print
just the registers and some stack addresses.)

** If Emacs hangs, or seems to be stuck in some infinite loop, typing
"kill -TSTP PID", where PID is the Emacs process ID, will cause GDB to
kick in, provided that you run under GDB.

** Getting control to the debugger

Setting a breakpoint in a strategic place, after loading Emacs into the
debugger, but before running it, is the most efficient way of making sure
control will be returned to the debugger when you need that.

'Fsignal' is a very useful place to put a breakpoint in.  All Lisp errors go
through there.  If you are only interested in errors that would fire the
Lisp debugger, breaking at 'maybe_call_debugger' is useful.

Another technique for getting control to the debugger is to put a breakpoint
in some rarely used function.  One such convenient function is
Fredraw_display, which you can invoke at will interactively with "M-x
redraw-display RET".

It is also useful to have a guaranteed way to return to the debugger at any
arbitrary time.  When using X, this is easy: type C-z at the window where
you are interacting with GDB, and it will stop Emacs just as it would stop
any ordinary program.  (This doesn't work if GDB was attached to a running
Emacs process; in that case, you will need to type C-z to the shell window
from which Emacs was started, or use the "kill -TSTP" method described
below.)

When Emacs is displaying on a text terminal, things are not so easy, so we
describe the various alternatives below (however, those of them that use
signals only work on Posix systems).

The src/.gdbinit file in the Emacs distribution arranges for SIGINT (C-g in
Emacs on a text-mode frame) to be passed to Emacs and not give control back
to GDB.  On modern systems, you can override that with this command:

   handle SIGINT stop nopass

After this 'handle' command, SIGINT will return control to GDB.  If you want
the C-g to cause a quit within Emacs as well, omit the 'nopass'.  See the
GDB manual for more details about signal handling and the 'handle' command.

A technique that can work when 'handle SIGINT' does not is to store the code
for some character into the variable stop_character.  Thus,

    set stop_character = 29

makes Control-] (decimal code 29) the stop character.  Typing Control-] will
cause immediate stop.  You cannot use the set command until the inferior
process has been started, so start Emacs with the 'start' command, to get an
opportunity to do the above 'set' command.

On a Posix host, you can also send a signal using the 'kill' command from a
shell prompt, like this:

   kill -TSTP Emacs-PID

where Emacs-PID is the process ID of Emacs being debugged.  Other useful
signals to send are SIGUSR1 and SIGUSR2; see "Error Debugging" in the ELisp
manual for how to use those.

When Emacs is displaying on a text terminal, it is useful to have a separate
terminal for the debug session.  This can be done by starting Emacs as
usual, then attaching to it from gdb with the 'attach' command which is
explained in the node "Attach" of the GDB manual.

On MS-Windows, you can alternatively start Emacs from its own separate
console by setting the new-console option before running Emacs under GDB:

  (gdb) set new-console 1
  (gdb) run

If you do this, then typing C-c or C-BREAK into the console window through
which you interact with GDB will stop Emacs and return control to the
debugger, no matter if Emacs displays GUI or text-mode frames.  With GDB
versions before 13.1, this is the only reliable alternative on MS-Windows to
get control to the debugger, besides setting breakpoints in advance.  GDB
13.1 changed the way C-c and C-BREAK are handled on Windows, so with those
newer versions, you don't need the "set new-console 1" setting to be able to
interrupt Emacs by typing C-c or C-BREAK into the console window from which
you started Emacs and where you interact with GDB.

** Examining Lisp object values.

When you have a live process to debug, and it has not encountered a fatal
error, you can use the GDB command 'pr'.  First print the value in the
ordinary way, with the 'p' command.  Then type 'pr' with no arguments.  This
calls a subroutine which uses the Lisp printer.

You can also use 'pp value' to print the emacs value directly.

To see the current value of a Lisp Variable, use 'pv variable'.

These commands send their output to stderr; if that is closed or redirected
to some file you don't know, you won't see their output.  This is
particularly so for Emacs invoked on MS-Windows from the desktop shortcut.
You can use the command 'redirect-debugging-output' to redirect stderr to a
file.

Note: It is not a good idea to try 'pr', 'pp', or 'pv' if you know that
Emacs is in deep trouble: its stack smashed (e.g., if it encountered SIGSEGV
due to stack overflow), or crucial data structures, such as 'obarray',
corrupted, etc.  In such cases, the Emacs subroutine called by 'pr' might
make more damage, like overwrite some data that is important for debugging
the original problem.

Also, on some systems it is impossible to use 'pr' if you stopped Emacs
while it was inside 'select'.  This is in fact what happens if you stop
Emacs while it is waiting.  In such a situation, don't try to use 'pr'.
Instead, use 's' to step out of the system call.  Then Emacs will be between
instructions and capable of handling 'pr'.

If you can't use 'pr' command, for whatever reason, you can use the 'xpr'
command to print out the data type and value of the last data value, For
example:

    p it->object
    xpr

You may also analyze data values using lower-level commands.  Use the
'xtype' command to print out the data type of the last data value.  Once you
know the data type, use the command that corresponds to that type.  Here are
these commands:

    xint xptr xwindow xmarker xoverlay xmiscfree xintfwd xboolfwd xobjfwd
    xbufobjfwd xkbobjfwd xbuflocal xbuffer xsymbol xstring xvector xframe
    xwinconfig xcompiled xcons xcar xcdr xsubr xprocess xfloat xscrollbar
    xchartable xsubchartable xboolvector xhashtable xlist xcoding
    xcharset xfontset xfont

Each one of them applies to a certain type or class of types.  (Some of
these types are not visible in Lisp, because they exist only internally.)

Each x... command prints some information about the value, and produces a
GDB value (subsequently available in $) through which you can get at the
rest of the contents.

In general, most of the rest of the contents will be additional Lisp objects
which you can examine in turn with the x... commands.

Even with a live process, these x...  commands are useful for examining the
fields in a buffer, window, process, frame or marker.  Here's an example
using concepts explained in the node "Value History" of the GDB manual to
print values associated with the variable called frame.  First, use these
commands:

  cd src
  gdb emacs
  b set_frame_buffer_list
  r -q

Then Emacs hits the breakpoint:

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

Now we can use 'pp' to print the frame parameters:

  (gdb) pp $->param_alist
  ((background-mode . light) (display-type . color) [...])

The Emacs C code heavily uses macros defined in lisp.h.  So suppose we want
the address of the l-value expression near the bottom of 'add_command_key'
from keyboard.c:

  XVECTOR (this_command_keys)->contents[this_command_key_count++] = key;

XVECTOR is a macro, so GDB only knows about it if Emacs has been compiled
with preprocessor macro information.  GCC provides this if you specify the
options '-gdwarf-N' (where N is 2 or higher) and '-g3'.  In this case, GDB
can evaluate expressions like "p XVECTOR (this_command_keys)".

When this information isn't available, you can use the xvector command in
GDB to get the same result.  Here is how:

  (gdb) p this_command_keys
  $1 = 1078005760
  (gdb) xvector
  $2 = (struct Lisp_Vector *) 0x411000
  0
  (gdb) p $->contents[this_command_key_count]
  $3 = 1077872640
  (gdb) p &$
  $4 = (int *) 0x411008

Here's a related example of macros and the GDB 'define' command.  There are
many Lisp vectors such as 'recent_keys', which contains the last 300
keystrokes.  We can print this Lisp vector

  p recent_keys
  pr

But this may be inconvenient, since 'recent_keys' is much more verbose than
'C-h l'.  We might want to print only the last 10 elements of this vector.
'recent_keys' is updated in keyboard.c by the command

  XVECTOR (recent_keys)->contents[recent_keys_index] = c;

So we define a GDB command 'xvector-elts', so the last 10 keystrokes are
printed by

  xvector-elts recent_keys recent_keys_index 10

where you can define xvector-elts as follows:

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

** Getting Lisp-level backtrace information within GDB

The most convenient way is to use the 'xbacktrace' command.  This shows the
names of the Lisp functions that are currently active.

If that doesn't work (e.g., because the 'backtrace_list' structure is
corrupted), type "bt" at the GDB prompt, to produce the C-level backtrace,
and look for stack frames that call Ffuncall.  Select them one by one in
GDB, by typing "up N", where N is the appropriate number of frames to go up,
and in each frame that calls Ffuncall type this:

   p *args
   pr

This will print the name of the Lisp function called by that level of
function calling.

By printing the remaining elements of args, you can see the argument
values.  Here's how to print the first argument:

   p args[1]
   pr

If you do not have a live process, you can use xtype and the other x...
commands such as xsymbol to get such information, albeit less conveniently.
For example:

   p *args
   xtype

and, assuming that "xtype" says that args[0] is a symbol:

   xsymbol

** Debugging Emacs redisplay problems

The Emacs display code includes special debugging code, but it is normally
disabled.  Configuring Emacs with --enable-checking='yes,glyphs' enables it.

Building Emacs like that activates many assertions which scrutinize display
code operation more than Emacs does normally.  (To see the code which tests
these assertions, look for calls to the 'eassert' macros.)  Any assertion
that is reported to fail should be investigated.  Redisplay problems that
cause aborts or segfaults in production builds of Emacs will many times be
caught by these assertions before they cause a crash.

If you configured Emacs with --enable-checking='glyphs', you can use
redisplay tracing facilities from a running Emacs session.

The command "M-x trace-redisplay RET" will produce a trace of what redisplay
does on the standard error stream.  This is very useful for understanding
the code paths taken by the display engine under various conditions,
especially if some redisplay optimizations produce wrong results.  (You know
that redisplay optimizations might be involved if "M-x redraw-display RET",
or even just typing "M-x", causes Emacs to correct the bad display.)  Since
the cursor blinking feature and ElDoc trigger periodic redisplay cycles, we
recommend disabling 'blink-cursor-mode' and 'global-eldoc-mode' before
invoking 'trace-redisplay', so that you have less clutter in the trace.  You
can also have up to 30 last trace messages dumped to standard error by
invoking the 'dump-redisplay-history' command.

To find the code paths which were taken by the display engine, search
xdisp.c for the trace messages you see.

The command 'dump-glyph-matrix' is useful for producing on standard error
stream a full dump of the selected window's glyph matrix.  See the
function's doc string for more details.

If you run Emacs under GDB, you can print the contents of any glyph matrix
by just calling that function with the matrix as its argument.  For example,
the following command will print the contents of the current matrix of the
window whose pointer is in 'w':

  (gdb) p dump_glyph_matrix (w->current_matrix, 2)

(The second argument 2 tells dump_glyph_matrix to print the glyphs in a long
form.)

If you are debugging redisplay issues in text-mode frames, you may find the
command 'dump-frame-glyph-matrix' useful.

Other commands useful for debugging redisplay are 'dump-glyph-row' and
'dump-tool-bar-row'.

When you debug display problems running emacs under X, you can use the 'ff'
command to flush all pending display updates to the screen.

The src/.gdbinit file defines many useful commands for dumping redisplay
related data structures in a terse and user-friendly format:

 'ppt' prints value of PT, narrowing, and gap in current buffer.
 'pit' dumps the current display iterator 'it'.
 'pwin' dumps the current window 'win'.
 'prow' dumps the current glyph_row 'row'.
 'pg' dumps the current glyph 'glyph'.
 'pgi' dumps the next glyph.
 'pgrow' dumps all glyphs in current glyph_row 'row'.
 'pcursor' dumps current output_cursor.

The above commands also exist in a version with an 'x' suffix which takes an
object of the relevant type as argument.  For example, 'pgrowx' dumps all
glyphs in its argument, which must be of type 'struct glyph_row'.

Since redisplay is performed by Emacs very frequently, you need to place
your breakpoints cleverly to avoid hitting them all the time, when the issue
you are debugging did not (yet) happen.  Here are some useful techniques for
that:

 . Put a breakpoint at 'Frecenter' or 'Fredraw_display' before running Emacs.
   Then do whatever is required to reproduce the bad display, and type C-l or
   "M-x redraw-display" just before invoking the last action that reproduces
   the bug.  The debugger will kick in, and you can set or enable breakpoints
   in strategic places, knowing that the bad display will happen soon.  With a
   breakpoint at 'Fredraw_display', you can even reproduce the bug and invoke
   "M-x redraw-display" afterwards, knowing that the bad display will be
   redrawn from scratch.

 . For debugging incorrect cursor position, a good place to put a breakpoint
   is in 'set_cursor_from_row'.  The first time this function is called as
   part of 'redraw-display', Emacs is redrawing the minibuffer window, which
   is usually not what you want; type "continue" to get to the call you want.
   In general, always make sure 'set_cursor_from_row' is called for the right
   window and buffer by examining the value of w->contents: it should be the
   buffer whose display you are debugging.

 . 'set_cursor_from_row' is also a good place to look at the contents of a
   screen line (a.k.a. "glyph row"), by means of the 'pgrow' GDB command.  Of
   course, you need first to make sure the cursor is on the screen line which
   you want to investigate.  If you have set a breakpoint in 'Fredraw_display'
   or 'Frecenter', as advised above, move cursor to that line before invoking
   these commands.

 . If the problem happens only at some specific buffer position or for some
   specific rarely-used character, you can make your breakpoints conditional
   on those values.  The display engine maintains the buffer and string
   position it is processing in the it->current member; for example, the
   buffer character position is in it->current.pos.charpos.  Most redisplay
   functions accept a pointer to a 'struct it' object as their argument, so
   you can make conditional breakpoints in those functions, like this:

    (gdb) break x_produce_glyphs if it->current.pos.charpos == 1234

   For conditioning on the character being displayed, use it->c or
   it->char_to_display.

 . You can also make the breakpoints conditional on what object is being used
   for producing glyphs for display.  The it->method member has the value
   GET_FROM_BUFFER for displaying buffer contents, GET_FROM_STRING for
   displaying a Lisp string (e.g., a 'display' property or an overlay string),
   GET_FROM_IMAGE for displaying an image, etc.  See 'enum it_method' in
   dispextern.h for the full list of values.

 . When the display engine is processing a 'display' text property or an
   overlay string, it pushes on the iterator stack the state variables
   describing its iteration of buffer text, then reinitializes the iterator
   object for processing the property or overlay.  The it->sp ("stack
   pointer") member, if it is greater than zero, means the iterator's stack
   was pushed at least once.  You can therefore condition your breakpoints on
   the value of it->sp being positive or being of a certain positive value, to
   debug display problems that happen only with display properties or
   overlays.

** Debugging problems with native-compiled Lisp.

When you encounter problems specific to native-compilation of Lisp, we
recommend to follow the procedure below to try to identify the cause:

 . Reduce the problematic .el file to the minimum by bisection, and
   try identifying the function that causes the problem.

 . Try natively compiling the problematic file with
   'native-comp-speed' set to 1 or even zero.  If doing that solves
   the problem, you can use

     (declare (speed 1))

   at the beginning of the body of suspected function(s) to change
   'native-comp-speed' only for those functions -- this could help you
   identify the function(s) which cause(s) the problem.

 . Reduce the problematic function(s) to the minimal code that still
   reproduces the problem.

 . Study the problem's artifacts, like Lisp or C backtraces, to try
   identifying the cause of the problem.

If you cannot figure out the cause for the problem using the above,
native-compile the problematic file after setting the variable
'comp-libgccjit-reproducer' to a non-nil value.  That should produce a file
named ELNFILENAME_libgccjit_repro.c, where ELNFILENAME is the name of the
problematic .eln file, either in the same directory where the .eln file is
produced, or under your ~/.emacs.d/eln-cache (which one depends on how the
native-compilation is invoked).  It is also possible that the reproducer
file's name will be something like
subr--trampoline-XXXXXXX_FUNCTION_libgccjit_repro.c, where XXXXXXX is a long
string of hex digits and FUNCTION is some function from the compiled .el
file.  Attach that reproducer C file to your bug report.

** Following longjmp call.

Recent versions of glibc (2.4+?) encrypt stored values for setjmp/longjmp
which prevents GDB from being able to follow a longjmp call using 'next'.
To disable this protection you need to set the environment variable
LD_POINTER_GUARD to 0.

** Using GDB in Emacs

Debugging with GDB in Emacs offers some advantages over the command line
(See the GDB Graphical Interface node of the Emacs manual).  There are also
some features available just for debugging Emacs:

1) The command gud-print is available on the tool bar (the 'p' icon) and
   allows the user to print the s-expression of the variable at point,
   in the GUD buffer.

2) Pressing 'p' on a component of a watch expression that is a lisp object
   in the speedbar prints its s-expression in the GUD buffer.

3) The STOP button on the tool bar and the Signals->STOP menu-bar menu
   item are adjusted so that they send SIGTSTP instead of the usual
   SIGINT.

4) The command gud-pv has the global binding 'C-x C-a C-v' and prints the
   value of the lisp variable at point.

** Debugging what happens while preloading and dumping Emacs

Debugging 'temacs' is useful when you want to establish whether a problem
happens in an undumped Emacs.  To run 'temacs' under a debugger, type "gdb
temacs", then start it with 'r -batch -l loadup'.

If you need to debug what happens during dumping, start it with 'r -batch -l
loadup dump' instead.  For debugging the bootstrap dumping, use "loadup
bootstrap" instead of "loadup dump".

If temacs actually succeeds when running under GDB in this way, do not try
to run the dumped Emacs, because it was dumped with the GDB breakpoints in
it.

** If you encounter X protocol errors

The X server normally reports protocol errors asynchronously, so you find
out about them long after the primitive which caused the error has returned.

To get clear information about the cause of an error, try evaluating
(x-synchronize t).  That puts Emacs into synchronous mode, where each Xlib
call checks for errors before it returns.  This mode is much slower, but
when you get an error, you will see exactly which call really caused the
error.

You can start Emacs in a synchronous mode by invoking it with the -xrm
option, like this:

    emacs -xrm "emacs.synchronous: true"

Setting a breakpoint in the function 'x_error_quitter' and looking at the
backtrace when Emacs stops inside that function will show what code causes
the X protocol errors.

Note that the -xrm option may have no effect when you start a server in an
Emacs session invoked with the -nw command-line option, and want to trace X
protocol errors from GUI frames created by subsequent invocations of
emacsclient.  In that case starting Emacs via

  emacs -nw --eval '(setq x-command-line-resources "emacs.synchronous: true")'

should give more reliable results.

For X protocol errors related to displaying unusual characters or to
font-related customizations, try invoking Emacs like this:

  XFT_DEBUG=16 emacs -xrm "emacs.synchronous: true"

This should produce information from the libXft library which could give
useful hints regarding font-related problems in that library.

Some bugs related to the X protocol disappear when Emacs runs in a
synchronous mode.  To track down those bugs, we suggest the following
procedure:

  - Run Emacs under a debugger and put a breakpoint inside the
    primitive function which, when called from Lisp, triggers the X
    protocol errors.  For example, if the errors happen when you
    delete a frame, put a breakpoint inside 'Fdelete_frame'.

  - When the breakpoint breaks, step through the code, looking for
    calls to X functions (the ones whose names begin with "X" or
    "Xt" or "Xm").

  - Insert calls to 'XSync' before and after each call to the X
    functions, like this:

       XSync (f->output_data.x->display_info->display, 0);

    where 'f' is the pointer to the 'struct frame' of the selected
    frame, normally available via XFRAME (selected_frame).  (Most
    functions which call X already have some variable that holds the
    pointer to the frame, perhaps called 'f' or 'sf', so you shouldn't
    need to compute it.)

    If your debugger can call functions in the program being debugged,
    you should be able to issue the calls to 'XSync' without recompiling
    Emacs.  For example, with GDB, just type:

       call XSync (f->output_data.x->display_info->display, 0)

    before and immediately after the suspect X calls.  If your
    debugger does not support this, you will need to add these pairs
    of calls in the source and rebuild Emacs.

    Either way, systematically step through the code and issue these
    calls until you find the first X function called by Emacs after
    which a call to 'XSync' winds up in the function
    'x_error_quitter'.  The first X function call for which this
    happens is the one that generated the X protocol error.

  - You should now look around this offending X call and try to figure
    out what is wrong with it.

** If Emacs causes errors or memory leaks in your X server

You can trace the traffic between Emacs and your X server with a tool like
xmon.

Xmon can be used to see exactly what Emacs sends when X protocol errors
happen.  If Emacs causes the X server memory usage to increase you can use
xmon to see what items Emacs creates in the server (windows, graphical
contexts, pixmaps) and what items Emacs delete.  If there are consistently
more creations than deletions, the type of item and the activity you do when
the items get created can give a hint where to start debugging.

** If the symptom of the bug is that Emacs fails to respond

Don't assume Emacs is 'hung'--it may instead be in an infinite loop.  To
find out which, make the problem happen under GDB and stop Emacs once it is
not responding.  (If Emacs is using X Windows directly, you can stop Emacs
by typing C-z at the GDB job.  On MS-Windows, run Emacs as usual, and then
attach GDB to it -- that will usually interrupt whatever Emacs is doing and
let you perform the steps described below.)

Then try stepping with 'step'.  If Emacs is hung, the 'step' command won't
return.  If it is looping, 'step' will return.

If this shows Emacs is hung in a system call, stop it again and examine the
arguments of the call.  If you report the bug, it is very important to state
exactly where in the source the system call is, and what the arguments are.

If Emacs is in an infinite loop, try to determine where the loop starts and
ends.  The easiest way to do this is to use the GDB command 'finish'.  Each
time you use it, Emacs resumes execution until it exits one stack frame.
Keep typing 'finish' until it doesn't return--that means the infinite loop
is in the stack frame which you just tried to finish.

Stop Emacs again, and use 'finish' repeatedly again until you get back to
that frame.  Then use 'next' to step through that frame.  By stepping, you
will see where the loop starts and ends.  Also, examine the data being used
in the loop and try to determine why the loop does not exit when it should.

On GNU and Unix systems, you can also try sending Emacs SIGUSR2, which, if
'debug-on-event' has its default value, will cause Emacs to attempt to break
out of its current loop and enter the Lisp debugger.  (See the node
"Debugging" in the ELisp manual for the details about the Lisp debugger.)
This feature is useful when a C-level debugger is not conveniently
available.

** If certain operations in Emacs are slower than they used to be, here
is some advice for how to find out why.

Stop Emacs repeatedly during the slow operation, and make a backtrace each
time.  Compare the backtraces looking for a pattern--a specific function
that shows up more often than you'd expect.

If you don't see a pattern in the C backtraces, get some Lisp backtrace
information by typing "xbacktrace" or by looking at Ffuncall frames (see
above), and again look for a pattern.

When using X, you can stop Emacs at any time by typing C-z at GDB.  When not
using X, you can do this with C-g.  On non-Unix platforms, such as MS-DOS,
you might need to press C-BREAK instead.

** If GDB does not run and your debuggers can't load Emacs.

On some systems, no debugger can load Emacs with a symbol table, perhaps
because they all have fixed limits on the number of symbols and Emacs
exceeds the limits.  Here is a method that can be used in such an
extremity.  Do

    nm -n temacs > nmout
    strip temacs
    adb temacs
    0xd:i
    0xe:i
    14:i
    17:i
    :r -l loadup   (or whatever)

It is necessary to refer to the file 'nmout' to convert numeric addresses
into symbols and vice versa.

It is useful to be running under a window system.  Then, if Emacs becomes
hopelessly wedged, you can create another window to do kill -9 in.  kill
-ILL is often useful too, since that may make Emacs dump core or return to
adb.

** Debugging incorrect screen updating on a text terminal.

To debug Emacs problems that update the screen wrong, it is useful to have a
record of what input you typed and what Emacs sent to the screen.  To make
these records, do

(open-dribble-file "~/.dribble")  (open-termscript "~/.termscript")

The dribble file contains all characters read by Emacs from the terminal,
and the termscript file contains all characters it sent to the terminal.
The use of the directory '~/' prevents interference with any other user.

If you have irreproducible display problems, put those two expressions in
your ~/.emacs file.  When the problem happens, exit the Emacs that you were
running, kill it, and rename the two files.  Then you can start another
Emacs without clobbering those files, and use it to examine them.

** Debugging LessTif

If you encounter bugs whereby Emacs built with LessTif grabs all mouse and
keyboard events, or LessTif menus behave weirdly, it might be helpful to set
the 'DEBUGSOURCES' and 'DEBUG_FILE' environment variables, so that one can
see what LessTif was doing at this point.  For instance

  export DEBUGSOURCES="RowColumn.c:MenuShell.c:MenuUtil.c"
  export DEBUG_FILE=/usr/tmp/LESSTIF_TRACE
  emacs &

causes LessTif to print traces from the three named source files to a file
in '/usr/tmp' (that file can get pretty large).  The above should be typed
at the shell prompt before invoking Emacs, as shown by the last line above.

Running GDB from another terminal could also help with such problems.  You
can arrange for GDB to run on one machine, with the Emacs display appearing
on another.  Then, when the bug happens, you can go back to the machine
where you started GDB and use the debugger from there.

** Debugging problems which happen in GC

The array 'last_marked' (defined on alloc.c) can be used to display up to
the 512 most-recent objects marked by the garbage collection process.
Whenever the garbage collector marks a Lisp object, it records the pointer
to that object in the 'last_marked' array, which is maintained as a circular
buffer.  The variable 'last_marked_index' holds the index into the
'last_marked' array one place beyond where the pointer to the very last
marked object is stored.

The single most important goal in debugging GC problems is to find the Lisp
data structure that got corrupted.  This is not easy since GC changes the
tag bits and relocates strings which make it hard to look at Lisp objects
with commands such as 'pr'.  It is sometimes necessary to convert
Lisp_Object variables into pointers to C struct's manually.

Use the 'last_marked' array and the source to reconstruct the sequence that
objects were marked.  In general, you need to correlate the values recorded
in the 'last_marked' array with the corresponding stack frames in the
backtrace, beginning with the innermost frame.  Some subroutines of
'mark_object' are invoked recursively, others loop over portions of the data
structure and mark them as they go.  By looking at the code of those
routines and comparing the frames in the backtrace with the values in
'last_marked', you will be able to find connections between the values in
'last_marked'.  E.g., when GC finds a cons cell, it recursively marks its
car and its cdr.  Similar things happen with properties of symbols, elements
of vectors, etc.  Use these connections to reconstruct the data structure
that was being marked, paying special attention to the strings and names of
symbols that you encounter: these strings and symbol names can be used to
grep the sources to find out what high-level symbols and global variables
are involved in the crash.

Once you discover the corrupted Lisp object or data structure, grep the
sources for its uses and try to figure out what could cause the corruption.
If looking at the sources doesn't help, you could try setting a watchpoint
on the corrupted data, and see what code modifies it in some invalid way.
(Obviously, this technique is only useful for data that is modified only
very rarely.)

It is also useful to look at the corrupted object or data structure in a
fresh Emacs session and compare its contents with a session that you are
debugging.  This might be somewhat harder on modern systems which randomize
addresses of running executables (the so-called Address Space Layout
Randomization, or ASLR, feature).  If you have this problem, see below under
"How to disable ASLR".

** Debugging the TTY (non-windowed) version

The most convenient method of debugging the character-terminal display is to
do that on a window system such as X.  Begin by starting an xterm window,
then type these commands inside that window:

  $ tty
  $ echo $TERM

Let's say these commands print "/dev/ttyp4" and "xterm", respectively.

Now start Emacs (the normal, windowed-display session, i.e. without the
'-nw' option), and invoke "M-x gdb RET emacs RET" from there.  Now type
these commands at GDB's prompt:

  (gdb) set args -nw -t /dev/ttyp4
  (gdb) set environment TERM xterm
  (gdb) run

The debugged Emacs should now start in no-window mode with its display
directed to the xterm window you opened above.

Similar arrangement is possible on a character terminal by using the
'screen' package.

On MS-Windows, you can start Emacs in its own separate console by setting
the new-console option before running Emacs under GDB:

  (gdb) set new-console 1
  (gdb) run

** Running Emacs with undefined-behavior sanitization

Building Emacs with undefined-behavior sanitization can help find several
kinds of low-level problems in C code, including:

  * Out-of-bounds access of many (but not all) arrays.
  * Signed integer overflow, e.g., (INT_MAX + 1).
  * Integer shifts by a negative or wider-than-word value.
  * Misaligned pointers and pointer overflow.
  * Loading a bool or enum value that is out of range for its type.
  * Passing NULL to or returning NULL from a function requiring nonnull.
  * Passing a size larger than the corresponding array to memcmp etc.
  * Passing invalid values to some builtin functions, e.g., __builtin_clz (0).
  * Reaching __builtin_unreachable calls (in Emacs, 'eassume' failure).

To use GCC's UndefinedBehaviorSanitizer, append '-fsanitize=undefined' to
CFLAGS, either when running 'configure' or running 'make'.  When supported,
you can also specify 'bound-strict' and 'float-cast-overflow'.  For example:

  ./configure \
    CFLAGS='-O0 -g3 -fsanitize=undefined,bounds-strict,float-cast-overflow'

You may need to append '-static-libubsan' to CFLAGS if your version of GCC
is installed in an unusual location.

Clang's UB sanitizer can also be used, but has coverage problems.  You'll
need '-fsanitize=undefined -fno-sanitize=pointer-overflow' to suppress
misguided warnings about adding zero to a null pointer, although this also
suppresses any valid pointer overflow warnings.

When using GDB to debug an executable with undefined-behavior sanitization,
the GDB command:

  (gdb) rbreak ^__ubsan_handle_

will let you gain control when an error is detected and before
UndefinedBehaviorSanitizer outputs to stderr or terminates the program.

** Running Emacs with address sanitization

Building Emacs with address sanitization can help debug memory-use problems,
such as freeing the same object twice.  To use AddressSanitizer with GCC and
similar compilers, append '-fsanitize=address' to CFLAGS, either when
running 'configure' or running 'make'.  Configure, build and run Emacs with
ASAN_OPTIONS='detect_leaks=0' in the environment to suppress diagnostics of
minor memory leaks in Emacs.  For example:

  export ASAN_OPTIONS='detect_leaks=0'
  ./configure CFLAGS='-O0 -g3 -fsanitize=address'
  make
  src/emacs

You may need to append '-static-libasan' to CFLAGS if your version of GCC is
installed in an unusual location.

When using GDB to debug an executable with address sanitization, the GDB
command:

  (gdb) rbreak ^__asan_report_

will let you gain control when an error is detected and before
AddressSanitizer outputs to stderr or terminates the program.

Address sanitization is incompatible with undefined-behavior sanitization,
unfortunately.  Address sanitization is also incompatible with the
--with-dumping=unexec option of 'configure'.

*** Address poisoning/unpoisoning

When compiled with address sanitization, Emacs will also try to mark
dead/free lisp objects as poisoned, forbidding them from being accessed
without being unpoisoned first.  This adds an extra layer of checking with
objects in internal free lists, which may otherwise evade traditional
use-after-free checks. To disable this, add 'allow_user_poisoning=0' to
ASAN_OPTIONS, or build Emacs with '-DGC_ASAN_POISON_OBJECTS=0' in CFLAGS.

While using GDB, memory addresses can be inspected by using helper functions
additionally provided by the ASan library:

  (gdb) call __asan_describe_address(ptr)

To check whether an address range is poisoned or not, use:

  (gdb) call __asan_region_is_poisoned(ptr, 8)

Additional functions can be found in the header 'sanitizer/asan_interface.h'
in your compiler's headers directory.

** Running Emacs under Valgrind

Valgrind <https://valgrind.org/> is free software that can be useful when
debugging low-level Emacs problems.  Unlike GCC sanitizers, Valgrind does
not need you to compile Emacs with special debugging flags, so it can be
helpful in investigating problems that vanish when Emacs is recompiled with
debugging enabled.  However, by default Valgrind generates many false alarms
with Emacs, and you will need to maintain a suppressions file to suppress
these false alarms and use Valgrind effectively.  For example, you might
invoke Valgrind this way:

   valgrind --suppressions=valgrind.supp ./emacs

where valgrind.supp contains groups of lines like the following, which
suppresses some Valgrind false alarms during Emacs garbage collection:

   {
     Fgarbage_collect Cond - conservative garbage collection
     Memcheck:Cond
     ...
     fun:Fgarbage_collect
   }

Unfortunately Valgrind suppression files tend to be system-dependent, so you
will need to keep one around that matches your system.

** How to disable ASLR

Modern systems use the so-called Address Space Layout Randomization, (ASLR)
feature, which randomizes the base address of running programs, making it
harder for malicious software or hackers to find the address of some
function or variable in a running program by looking at its executable
file.  This causes the address of the same symbol to be different across
rerunning of the same program.  Sometimes, it can be useful to disable ASLR,
for example, if you want to compare objects in two different Emacs sessions.

On GNU/Linux, you can disable ASLR temporarily with the following shell
command:

  echo 0 > /proc/sys/kernel/randomize_va_space

or by running Emacs in an environment where ASLR is temporarily disabled:

  setarch -R emacs [args...]

To disable ASLR in Emacs on MS-Windows, you will have to rebuild Emacs while
adding '-Wl,-disable-dynamicbase' to LD_SWITCH_SYSTEM_TEMACS variable
defined in src/Makefile.  Alternatively, use some tool to edit the PE header
of the Emacs executable file and reset the DYNAMIC_BASE (0x40) flag in the
DllCharacteristics flags recorded by the PE header.

On macOS, there's no official way for disabling ASLR, but there are various
hacks that can be found by searching the Internet.

** How to recover buffer contents from an Emacs core dump file

The file etc/emacs-buffer.gdb defines a set of GDB commands for recovering
the contents of Emacs buffers from a core dump file.  You might also find
those commands useful for displaying the list of buffers in human-readable
format from within the debugger.

** Debugging Emacs with LLDB

On systems where GDB is not available, like macOS with M1 chip, you can also
use LLDB for Emacs debugging.

To start LLDB to debug Emacs, you can simply type "lldb ./emacs RET" at the
shell prompt in directory of the Emacs executable, usually the 'src'
sub-directory of the Emacs tree).

When you debug Emacs with LLDB, you should start LLDB in the directory where
the Emacs executable was built.  That directory has an .lldbinit file that
loads a Python module emacs_lldb.py from the 'etc' directory of the Emacs
source tree.  The Python module defines "user-defined" commands for
debugging Emacs.

LLDB by default does not automatically load .lldbinit files in the current
directory.  The simplest way to fix this is to add the following line to
your ~/.lldbinit file (creating such a file if it doesn't already exist):

  settings set target.load-cwd-lldbinit true

Alternatively, you can type "lldb --local-lldbinit ./emacs RET".

If everything worked, you should see something like "Emacs debugging support
has been installed" after starting LLDB.  You can see which Emacs-specific
commands are defined with

  (lldb) help

User-defined commands for Emacs debugging start with an "x".

Please refer to the LLDB reference on the web for more information about
LLDB.  If you already know GDB, you will also find a mapping from GDB
commands to corresponding LLDB commands there.

** Debugging Emacs on OpenBSD

To debug Emacs on OpenBSD, use the 'egdb' command from the 'gdb' package.
This reportedly works both if Emacs was compiled with GCC and if it was
compiled with clang.

** Debugging Emacs on Android.

A script located in the java/ directory automates the procedures necessary
run Emacs under a Gdb session on an Android device connected to a computer
using USB.

Its requirements are the `adb' (Android Debug Bridge) utility and the Java
debugger (jdb), utilized to cue the Android system to resume the Emacs
process after the debugger attaches.

If all three of those tools are present, simply run (from the Emacs source
directory):

  ../java/debug.sh -- [any extra arguments you wish to pass to gdb]

Several lines of debug information will be printed, after which the Gdb
prompt should be displayed.

If there is no Gdbserver binary present on the device, then specify one to
upload, like so:

  ../java/debug.sh --gdbserver /path/to/gdbserver

This Gdbserver should be statically linked or compiled using the Android
NDK, and must target the same architecture as the debugged Emacs binary.
Older versions of the Android NDK (such as r24)  distribute suitable
Gdbserver binaries, usually located within

  prebuilt/android-<arch>/gdbserver/gdbserver

relative to the root of the NDK distribution.

To attach Emacs to an existing process on a target device, use the
`--attach-existing' argument to debug.sh:

  ../java/debug.sh --attach-existing [other arguments]

If multiple Emacs processes are running, debug.sh will display the names and
PIDs of each running process, and prompt for the process that it should
attach to.

After Emacs starts, type:

  (gdb) handle SIGUSR1 noprint pass

to ignore the SIGUSR1 signal that is sent by the Android port's `select'
emulation.  If this is overlooked, Emacs will stop each time a windowing
event is received, which is probably unwanted.

On top of the debugging procedure described above, Android also maintains a
"logcat" buffer, where it prints backtraces during or after each crash.  Its
contents are of interest when performing post-mortem debugging after a
crash, and can also be retrieved through the `adb' tool, like so:

  $ adb logcat

There are three forms of crash messages printed by Android.  The first form
is printed when a crash arises within Java code, and should resemble the
following when printed in the logcat buffer:

E AndroidRuntime: FATAL EXCEPTION: main E AndroidRuntime: Process:
org.gnu.emacs, PID: 18057 E AndroidRuntime: java.lang.RuntimeException:
sample crash E AndroidRuntime: 	at
org.gnu.emacs.EmacsService.onCreate(EmacsService.java:308)  E
AndroidRuntime: 	at
android.app.ActivityThread.handleCreateService(ActivityThread.java:4485)  E
AndroidRuntime: 	... 9 more

The second form is printed when a fatal signal (such as an abort, or
segmentation fault) is raised within C code.  Here is an example of such a
crash:

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

Where the first line (the one containing "libc") mentions the number of the
fatal signal, the address of any VM fault, and the name and ID of the thread
which crashed.  Subsequent lines then contain a backtrace, recounting each
function in the call stack culminating in the crash.

The third form is printed when Emacs misuses the JVM in some fashion that is
detected by the Android CheckJNI facility.  It looks like:

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

In such situations, the first line explains what infraction Emacs committed,
while the ensuing ones print backtraces for each running Java thread at the
time of the error.

If Emacs is executing on Android 5.0 and later, placing a breakpoint on

  (gdb) break art::JavaVMExt::JniAbort

will set a breakpoint that is hit each time such an error is detected.

Since the logcat output is always rapidly being amended, it is worth piping
it to a file or shell command buffer, and then searching for keywords such
as "AndroidRuntime", "Fatal signal", or "JNI DETECTED ERROR IN APPLICATION".

Once in a blue moon, it proves necessary to debug Java rather than C code.
To this end, the `--jdb' option will attach the Java debugger instead of
gdbserver.  Lametably, it seems impossible to debug both C and Java code in
concert.

C code within Emacs rigorously checks for Java exceptions after calling any
JVM function that may signal an out-of-memory error, employing one of the
android_exception_check(_N) functions defined within android.c for this
purpose.  These functions operate presuming the preceding Java code does not
signal exceptions of its own, and report out-of-memory errors upon any type
of exception, not just OOM errors.

If Emacs protests that it is out of memory, yet you witness a substantial
amount of free space remaining, search the log buffer for a string
containing:

  "Possible out of memory error.  The Java exception follows:"

subsequent to which a reproduction of the exception precipitating the
spurious OOM error should be located.  This exception is invariably
indicative of a bug within Emacs that should be fixed.


This file is part of GNU Emacs.

GNU Emacs is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option)
any later version.

GNU Emacs is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.


Local variables: mode: outline paragraph-separate: "[ 	]*$" end: