```text
Installation instructions for Android
Copyright (C) 2023-2024 Free Software Foundation, Inc.
See the end of the file for license conditions.
```



# OVERVIEW OF JAVA

Emacs開発者はJavaを知らないし、知ることが必要だという理由も存在しない。故にこのディレクトリーにあるコードはEmacsのサポートに必要なコードに厳選されており、Cプログラマーにとって理解しやすい方法で記述されたJavaのサブセットだけを使用している。

Androidのランタイム全体がJavaを基本としていること、そしてJavaなしで実行されるAndroidプログラムを記述する方法がないことによりJavaは必須である。

これはすでにCに精通している他のEmacs開発者にたいして、Androidポートの基本的アーキテクチャを説明するために、そしてこのディレクトリーにあるJavaコードの読み方、記述する方法を説明するために存在するディレクトリーである。

Java    自動的なうメモリー管理を備えたオブジェクト指向言語であり、バイトコードにコンパイルされてからJava仮想マシン(JVM: Java
Virtual Machine)によって解釈される。

これが何を意味するかというと:

```c
struct emacs_window
{
  int some_fields;
  int of_emacs_window;
};
```

```c
static void
do_something_with_emacs_window (struct emacs_window *a, int n)
{
  a->some_fields = a->of_emacs_window + n;
}
```

上記は以下のように記述できる:

```java
public class EmacsWindow
{
  public int someFields;
  public int ofEmacsWindow;
```

```java
  public void
  doSomething (int n)
  {
    someFields = ofEmacsWindow + n;
  }
}
```

Cの以下のような記述は:

```c
do_something_with_emacs_window (my_window, 1);
```

javaでは以下のようになるのだ:

```java
myWindow.doSomething (1);
```

(`EmacsWindow`のように)与えられたクラスオブジェクトに関連付けられる関数に加えて、Javaには他に2種類の関数がある。

1つ目は`static`な関数だ(JavaのstaticはCの場合とはまったく異なるものを意味する)。

static関数はクラスの内部定義する必要があるものの、オブジェクトなしで呼び出すことができる。オブジェクトのかわりにオブジェクトが定義されているJavaクラスの名前を記述する。たとえば以下のようなCコードなら:

```c
int
multiply_a_with_b_and_then_add_c (int a, int b, int c)
{
  return a * b + c;
}
```

以下のようになるだろう:

```java
public class EmacsSomething
{
  public static int
  multiplyAWithBAndThenAddC (int a, int b, int c)
  {
    return a * b + c;
  }
};
```

以下のようなCの呼び出しは:

```c_or_java
int foo;

foo = multiply_a_with_b_then_add_c (1, 2, 3);
```

javaでは以下のようになるのだ:

```c_or_java
int foo;

```java
foo = EmacsSomething.multiplyAWithBAndThenAddC (1, 2, 3);
```

Javaでの`static`はその関数が関数のコンパイル単位でのみ使用されるという意味にはならない!
ほぼ同じことを表すためには、かわりに`private`が使用される。

```c
static void
this_procedure_is_only_used_within_this_file (void)
{
  do_something ();
}
```

上記は以下のようになるだろう

```java
public class EmacsSomething
{
  private static void
  thisProcedureIsOnlyUsedWithinThisClass ()
  {

  }
}
```

他にも`constructor`
(コンストラクター)と呼ばれるものがある。これはクラスをメモリー上に割り当てるために呼び出さなければならない関数のことだ:

```java
public class EmacsFoo
{
  int bar;

  public
  EmacsFoo (int tokenA, int tokenB)
  {
    bar = tokenA + tokenB;
  }
}
```

そして以下のような文として呼び出される:

```java
EmacsFoo foo;

foo = new EmacsFoo (1, 2);
```

以下はほぼ同じことを行うCコード:

```C
struct emacs_foo
{
  int bar;
};

struct emacs_foo *
make_emacs_foo (int token_a, int token_b)
{
  struct emacs_foo *foo;

  foo = xmalloc (sizeof *foo);
  foo->bar = token_a + token_b;

  return foo;
}

/* ... */

struct emacs_foo *foo;

foo = make_emacs_foo (1, 2);
```

クラスは任意の個数のconstructorをもったり、constructorなしでもよい(コンパイラーが空のconstructorを挿入する)。



以下のようなJavaコードを目にすることもあるだろう:

```java
      allFiles = filesDirectory.listFiles (new FileFilter () {
	@Override
	public boolean
	accept (File file)
	{
	  return (!file.isDirectory ()
		  && file.getName ().endsWith (".pdmp"));
	}
      });
```

これ程GCCの関数内関数拡張(nested function
extension)のJavaバージョンだ。関数内関数はスコープ外からも呼び出せるかもしれないし、呼び出された前後のクラスやlocal変数への参照を常に保持する点が主な違い。

Javaはオブジェクト指向言語なので、あるクラスが他のクラスを"拡張"することもできる。以下のCコードは:

```C
struct a
{
  long thirty_two;
};

struct b
{
  struct a a;
  long long sixty_four;
};

extern void do_something (struct a *);

void
my_function (struct b *b)
{
  do_something (&b->a);
}
```

これは以下の2ファイルに分割されたJavaコードとおおよそ同じだ:

```java
  A.java

public class A
{
  int thirtyTwo;

  public void
  doSomething ()
  {
    etcEtcEtc ();
  }
};

  B.java

public class B extends A
{
  long sixty_four;

  public static void
  myFunction (B b)
  {
    b.doSomething ();
  }
}
```

Javaランタイムが呼び出し`b.doSomething`を`((A) b).doSomething`の変換したのだ。

ただしJavaでは@Overrideキーワードを指定して、動作をオーバーライドすることもできる:

public class B extends A
{
  long sixty_four;

```java
  @Override
  public void
  doSomething ()
  {
    Something.doSomethingTwo ();
    super.doSomething ();
  }
}
```

これで`new B
()`を用いて作成した`B`の`doSomething`にたいするすべての呼び出しは、`A.doSomething`をコールバックする前に`Something.doSomethingTwo`呼び出しを終えるようになった。このオーバーライドは反対方向にたいしても適用される。つまりたとえ以下のように記述したとしても:

```java
  ((A) b).doSomething ();
```

たとえ`new B ()`で`b`を作成した場合でも、BバージョンのdoSomethingは依然として呼び出されるのだ。

これはJava言語およびAndroidのウィンドウ化API全般を通じて、広範囲で使用されているメカニズムである。

どこかで配列を定義するJavaコード出会うかもしれない:

```java
public class EmacsFrobinicator
{
  public static void
  emacsFrobinicate (int something)
  {
    int[] primesFromSomething;

    primesFromSomething = new int[numberOfPrimes];
    /* ... */
  }
}
```

拡張できないという点においては、Javaの配列とCの配列は似ている。しかし(ある状況下においてのみポインタに変化するのではなく)常にリファレンス(reference:
参照)であること、長さの情報を含んでいる点では、Cの配列とは大きく異なる。

``frobinicate1''という引数として配列を受け取る別の関数の場合には、配列の長さを受け取る必要はない。

以下のように配列にたいして単に繰り返し処理することができるからだ:

```java
int i, k;

for (i = 0; i < array.length; ++i)
  {
    k = array[i];

    Whatever.doSomethingWithK (k);
  }
```

配列の定義に用いる構文も若干異なる。配列は常にリファレンスなので、structure(やclass)にサイズNの配列を割り当てるようランタイムに指示する。

配列のサイズが必要な場合とはその配列のタイプでフィールドを宣言して、以下のようにクラスのconstructor内部で配列を割り当てなければならない:

```java
public class EmacsArrayContainer
{
  public int[] myArray;

  public
  EmacsArrayContainer ()
  {
    myArray = new array[10];
  }
}
```

Cでは以下のように記述するか:

```C
struct emacs_array_container
{
  int my_array[10];
};
```

こちらのほうがよいかもしれない

```C
typedef int emacs_array_container[10];
```

悲しいかな、Javaには`typedef`の等価物が存在しないのだ。

Javaの文字列リテラルは、Cの場合と同じようにダブルクォートで区切る。ただしCと異なるのは文字列がNULL終端された文字の配列ではなく、`String`と呼ばれる別個のタイプだという点だ。これは独自に長さを保持しておりJavaの16ビット`char`タイプ、それにNULLバイトを保持することもできる。

以下のように:

```C
wchar_t character; extern char *s; size_t s;

  for (/* determine n, s in a loop.  */)
    s += mbstowc (&character, s, n);
```

あるいは:

```C
const char *byte;

for (byte = my_string; *byte; ++byte)
  /* do something with *byte.  */;
```

あるいは以下もありかもしれない:

```C
size_t length, i; char foo;

length = strlen (my_string);

for (i = 0; i < length; ++i)
  foo = my_string[i];
```

これらを以下のように記述できるのだ:

```java
char foo; int i;

for (i = 0; i < myString.length (); ++i)
  foo = myString.charAt (0);
```

Javaには条件判定において何を真値として使用できるかについての厳格なルールもある。Cでのtrueは任意の非0値だが、Javaにおける真値はすべてブーリアン型``boolean''であることが要求される。

これは何を意味するのか?
たとえばfooは1か0、barはNULLあるいは何かへのポインターであるような場合には、以下のようにシンプルに記述するかわりに:

```
  if (foo || bar)
```

Javaでは:

```java
  if (foo != 0 || bar != null)
```

のように明示的に記述しなければならないことを意味する:

# JAVA NATIVE INTERFACE

JavaはJavaとインターフェイスするためのCコード用のインターフェイスも提供している。

共有ライブラリーからエクスポートされるC関数は、、以下のようなJavaのクラスのstatic関数になります:

```java
public class EmacsNative
{
  /* このビルドのEmacsのfingerprintを取得
     fingerprintはダンプファイル名取得に用いられる */
  public static native String getFingerprint ();

  /* Emacs初期化前に特定のパラメーターをセット

     assetManagerはEmacsロードのコンテキストで割り当てられたアセット
     マネージャーでなければならない。これは保存されてEmacsプロセスの
     ライフタイムのリマインダーとして残留する

     filesDirはAndroidのカレントユーザーのパッケージ用データストレージ
     でなければならない

     libDirはパッケージのネイティブライブラリー用データストレージ
     でなければならない。これがPATHとして用いられる

     cacheDirパッケージのキャッシュディレクトリーでなければならない
     これが`temporary-file-directory`として使用される

     pixelDensityXとpixelDensityYはEmacsが用いるDPI値

     classPathはこのapp_processプロセスのclasspath、またはNULL

     emacsServiceはEmacsServiceシングルトン、またはNULL */
  public static native void setEmacsParams (AssetManager assetManager,
					    String filesDir,
					    String libDir,
					    String cacheDir,
					    float pixelDensityX,
					    float pixelDensityY,
					    String classPath,
					    EmacsService emacsService);
}
```

これに対応するC関数をandroid.cに配置、それが特別な呼び出しによってロードされる:

```C
  static
  {
    System.loadLibrary ("emacs");
  };
```

ここで`static`はオブジェクト(classも含む)のロード時に実行されるコードのセクションを定義する。共有オブジェクトのconstructorをサポートするシステムであれば:

```C
  __attribute__ ((constructor))
```

のようになるだろう。

詳細についてはhttp://docs.oracle.com/en/java/javase/19/docs/specs/jni/intro.htmlを参照のこと。



# OVERVIEW OF ANDROID

Androidシステムがアプリケーションを開始する際には、実際にそのアプリケーションの`main`を呼び出す訳ではない。もしもすでに実行中であれば、アプリケーションプロセスの開始すら行わないかもしれない。

そのかわりにAndroidはコンポーネントを中心に構成されている。ユーザーが`Emacs`のアイコンをオープンすると、`Emacs`アイコンに関連付けられたコンポーネントをAndroidシステムが検索して開始処理を行う。この場合にはコンポーネントはactivityと呼ばれる。これはこのディレクトリーのAndroidManifest.xmlで宣言されている。

```xml
    <activity android:name="org.gnu.emacs.EmacsActivity"
	      android:launchMode="singleTop"
	      android:windowSoftInputMode="adjustResize"
	      android:exported="true"
	      android:configChanges="orientation|screenSize|screenLayout|keyboardHidden">
      <intent-filter>
	<action android:name="android.intent.action.MAIN" />
	<category android:name="android.intent.category.DEFAULT" />
	<category android:name="android.intent.category.LAUNCHER" />
      </intent-filter>
    </activity>
```

これはAndroidにたいして`EmacsActivity`
(org/gnu/emacs/EmacsActivity.java)で定義されているactivity
(Androidのクラス`Activity``を拡張するクラス)を開始するように指示する。

これによりAndroidシステムが`EmacsActivity`のインスタンスを作成、それにウィンドウシステムがウィンドウを関連付けて最終的には以下を呼び出す:

```java
  Activity activity;

  activity.onCreate (...);
```

しかし実際には、どの`onCreate`が呼び出されるのだろうか?
というのも実際に`onCreate`はEmacsActivity.javaで定義されているが、これはAndroid自身のActivity内で定義されている`onCreate`をオーバーライドしたものだからだ:

```java
  @Override
  public void
  onCreate (Bundle savedInstanceState)
  {
    FrameLayout.LayoutParams params;
    Intent intent;
```

この`onCreate`関数で何が行われていくのかをステップバイステップで追ってみよう:

```java
    /* Emacsが-Qで開始されたのか確認    */
    intent = getIntent ();
    EmacsService.needDashQ
      = intent.getBooleanExtra ("org.gnu.emacs.START_DASH_Q",
				false);
```

ここでEmacsは自身の開始に使用されたintent(コンポーネントを開始するためのリクエスト)を入手して、コマンドライン引数`-Q`でEmacsを開始するリクエストが含まれていたら、特別なフラグをセットする。

```java
    /* タイトルバーなしのテーマをセット */

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.ICE_CREAM_SANDWICH)
      setTheme (android.R.style.Theme_DeviceDefault_NoActionBar);
    else
      setTheme (android.R.style.Theme_NoTitleBar);
```

次にEmacsはこのactivityにたいして関連付けられたウィンドウ装飾(window decoration)にたいして、適切なテーマをセットする。

```java
    params = new FrameLayout.LayoutParams (LayoutParams.MATCH_PARENT,
					   LayoutParams.MATCH_PARENT);

    /* フレームのレイアウトを作成       */
    layout = new FrameLayout (this);
    layout.setLayoutParams (params);

    /* content viewにそれをセット       */
    setContentView (layout);
```

それからEmacsは`FrameLayout` (別の単一のwidgetを保持するwidget)を作成して、そのactivityの`content
view`にする。

activity自体が`FrameLayout`なので、ここで適用する`layout`パラメーターは子ではなくこのFrameLayout自体に適用される。

```java
    /* 必要ならEmacsサービスを開始するかもしれない      */
    EmacsService.startEmacsService (this);
```

この後にEmacsはクラス`EmacsService`で定義されているstatic関数`startEmacsService`を呼び出す。これは必要ならEmacsサービスのコンポーネントを開始する部分だ。

```java
    /* 利用可能なactivityリストにこのactivityを追加     */
    EmacsWindowAttachmentManager.MANAGER.registerWindowConsumer (this);

    super.onCreate (savedInstanceState);
```

そしてついにこのactivityが、Lispから作成されたトップレベルのフレーム(ウィンドウ)を受け取る準備が整ったことをEmacsが登録するのだ。

activityは来たり去りゆくが、その間はEmacsが実行し続けている必要がある。したがってEmacsはバックグラウンドでの実行をAndroidシステムが許可するような、長時間実行される`service`としても定義する必要がある。

では戻って`startEmacsService`の定義をレビューしよう:

```java
  public static void
  startEmacsService (Context context)
  {
    if (EmacsService.SERVICE == null)
      {
	if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O)
	  /* Emacsサービスを開始  */
	  context.startService (new Intent (context,
					    EmacsService.class));
	else
	  /* 永続的な通知を表示して、フォアグラウンドサービスとして
	     Emacsを開始する    */
	  context.startForegroundService (new Intent (context,
						      EmacsService.class));
      }
  }
```

これが行うのは`EmacsService.SERVICE`がまだ存在しなければ、`context`(`Xlib Display
*`と等価)にたいしてクラス`EmacsService`で定義されたサービスの開始を伝えることだ:

```java
  @Override
  public void
  onCreate ()
  {
    AssetManager manager;
    Context app_context;
    String filesDir, libDir, cacheDir, classPath;
    double pixelDensityX;
    double pixelDensityY;
```

ここでは関数が何を行うかステップバイステップで追ってみよう:

```java
    SERVICE = this;
```

まず最初に`this`
(作成された`EmacsServic`オブジェクトへのポインター)にたいして、特別なstatic変数`SERVICE`をセットしている。

```java
    handler = new Handler (Looper.getMainLooper ());
```

次に`main looper`にたいして`Handler`オブジェクトを作成した。これはAndroid
のユーザーインターフェイススレッドでコードを実行できるようにするためのヘルパーstructureだ。

```java
    manager = getAssets ();
    app_context = getApplicationContext ();
    metrics = getResources ().getDisplayMetrics ();
    pixelDensityX = metrics.xdpi;
    pixelDensityY = metrics.ydpi;
```

最後に入手したのは:

- アセットマネージャー :: Emacsアプリケーションパッケージにパッケージされたアセットの取得に使用

- application context ：： アプリケーション固有の情報用に使用

- ディスプレイメトリクス :: ドット単位で表したXおよびYの密度

では`try`ブロックの内側だ:

```java
      try
      {
	/* アセットマネージャー他必要なパラメーターとともに
	   Emacsを構成する      */
	filesDir = app_context.getFilesDir ().getCanonicalPath ();
	libDir = getLibraryDirectory ();
	cacheDir = app_context.getCacheDir ().getCanonicalPath ();
```

これがEmacsのホーム、共有ライブラリー、一時ファイル用のディレクトリー名を取得する。

```java
        /* では(android-emacsを介して)app_processを再帰的に呼び出す
           ことによってEmacsNoninteractiveを見つけられるように、この
           アプリケーションのapkファイルを提供する      */
	classPath = getApkFile ();
```

以下はEmacsのアプリケーションパッケージ名。

```java
        Log.d (TAG, "Initializing Emacs, where filesDir = " + filesDir
	       + ", libDir = " + libDir + ", and classPath = " + classPath);
```

そしてこの情報とともにデバッグメッセージをAndroidシステムのログにプリントする。

```java
        EmacsNative.setEmacsParams (manager, filesDir, libDir,
				    cacheDir, (float) pixelDensityX,
				    (float) pixelDensityY,
				    classPath, this);
```

次にこの情報でEmacsを構成するために、(android.cで定義されている)ネイティブ関数`setEmacsParams`を呼び出す。

```java
        /* Emacsを実行するスレッドを開始        */
	thread = new EmacsThread (this, needDashQ);
	thread.start ();
```

その後は`EmacsThread`オブジェクトのアロケートを行う。このスレッドの内側こそが、EmacsのCコードが実行される場所なのだ。

```java
      }
    catch (IOException exception)
      {
	EmacsNative.emacsAbort ();
	return;
```

そしてここに`try`ブロックの目的がある。Javaのファイル名に関する関数は、失敗の際にはさまざまなタイプのエラーをシグナルすることになるだろう。

この`catch`ブロックは`IOException`タイプのエラーに遭遇次第、Java仮想マシンが`try`ブロック内のコード実行をabortさせて、`catch`ブロック内のコードの実行を開始することを意味する。

上記タイプの任意の失敗によってcrashした場合には、有益なバックトレースが得られるように速やかに`EmacsNative.emacsAbort`を呼び出してプロセスをabortさせる。
```java
      }
  }
```

今度はorg/gnu/emacs/EmacsThread.javaの`EmacsThread`の定義の番だ:

```java
public class EmacsThread extends Thread
{
  /* Emacsは-Qで開始されたのか  */
  private boolean startDashQ;

  public
  EmacsThread (EmacsService service, boolean startDashQ)
  {
    super ("Emacs main thread");
    this.startDashQ = startDashQ;
  }

  @Override
  public void
  run ()
  {
    String args[];

    if (!startDashQ)
      args = new String[] { "libandroid-emacs.so", };
    else
      args = new String[] { "libandroid-emacs.so", "-Q", };

    /* ここでネイティブコードを実行する */
    EmacsNative.initEmacs (args, EmacsApplication.dumpFileName);
  }
};
```

このクラス自体は1つのフィールド`startDashQ`、使用されないタイプ``EmacsService`の引数(デバッグ中は便利)およびフラグ`startDashQ`を受け取るlconstructor、それに`Thread`クラスの同名の関数をオーバーライドする関数`run`を1つ定義している。

`thread.start`が呼び出されるとJava仮想マシンは新たにスレッドを作成してから、そのスレッド内で関数`run`を呼び出す。

次にこの関数は適切なvector引数を算出して、(android.cで定義されている)`EmacsNative.initEmacs`、それにEmacsの通常の`main`関数の修正版を呼び出す。

この時点で通常のlEmacs初期化処理が行われる。Vinitial_window_systemをセット、loadup.elが`normal-top-level`呼び出し、これが`command-line'を呼び出して、最終的には通常の`android`端末を初期化する`window-system-initialization`が呼び出されるのだ。

ここでは他のプラットフォームで行われるのと同様なことが起こっている。デフォルト初期フレーム作成時に何が起こっているのだろうか?
まずトップレベルのウィンドウを作成するためにFx_create_frameが`android_create_frame_window`を呼び出す:

```java
static void
android_create_frame_window (struct frame *f)
{
  struct android_set_window_attributes attributes;
  enum android_window_value_mask attribute_mask;

  attributes.background_pixel = FRAME_BACKGROUND_PIXEL (f);
  attribute_mask = ANDROID_CW_BACK_PIXEL;

  block_input ();
  FRAME_ANDROID_WINDOW (f)
    = android_create_window (FRAME_DISPLAY_INFO (f)->root_window,
			     f->left_pos,
			     f->top_pos,
			     FRAME_PIXEL_WIDTH (f),
			     FRAME_PIXEL_HEIGHT (f),
			     attribute_mask, &attributes);
  unblock_input ();
}
```

これが同じ引数で関数`android_create_window`を呼び出す。引数の意味は`XCreateWindow`の場合と同じだ。

以下はandroid.cにおける`android_create_window`の定義:

```java
android_window
android_create_window (android_window parent, int x, int y,
		       int width, int height,
		       enum android_window_value_mask value_mask,
		       struct android_set_window_attributes *attrs)
{
  static jclass class;
  static jmethodID constructor;
  jobject object, parent_object, old;
  android_window window;
  android_handle prev_max_handle;
  bool override_redirect;
```

何を行うのだろうか? コンテキストを少々説明しよう:

任意の時点において最大で65535のJavaオブジェクトが、Javaのネイティブインターフェイスを通じてEmacsの残りの部分から参照され得る。そのようなオブジェクトにはそれぞれ`handle`
(XでのXIDのようなもの)が割り当てられて、一意なタイプが付与される。`android_resolve_handle`は、そのhandleに関連付けられたJNIの`jobject`をリターンする関数だ。

```java
  parent_object = android_resolve_handle (parent, ANDROID_HANDLE_WINDOW);
```

ここでは`parent`というhandleに関連付けられている`jobject`を検索するために使用されている。

```java
  prev_max_handle = max_handle;
  window = android_alloc_id ();
```

`max_handle`が保存されて、今度は`window`にたいして新たなhandleが割り当てられる。

```java
  if (!window)
    error ("Out of window handles!");
```

Emacsが利用可能なlhandleを使い切ったときは、エラーがシグナルされる。

```java
  if (!class)
    {
      class = (*android_java_env)->FindClass (android_java_env,
					      "org/gnu/emacs/EmacsWindow");
      assert (class != NULL);
```

この初期化がまだ完了していない場合には、Emacsは`EmacsWindow`という名前のJavaクラスの検索を実行する。

```java
      constructor
	= (*android_java_env)->GetMethodID (android_java_env, class, "<init>",
					    "(SLorg/gnu/emacs/EmacsWindow;"
					    "IIIIZ)V");
      assert (constructor != NULL);
```

そしてconstructorを見つける、引数は7つの筈だ:

- S :: データはshort(lhandleのID)
- Lorg/gnu/Emacs/EmacsWindow; :: EmacsWindowクラスのインスタンス(親)
- IIII :: 4つの整数(ウィンドウジオメトリ)
- Z :: ブール値(そのウィンドウがoverride-redirectかどうか; XChangeWindowAttributesを参照)

```java
      old = class;
      class = (*android_java_env)->NewGlobalRef (android_java_env, class);
      (*android_java_env)->ExceptionClear (android_java_env);
      ANDROID_DELETE_LOCAL_REF (old);
```

次にクラスへのグローバルリファレンスを保存、ローカルリファレンスを削除する。グローバルリファレンスは、存在し続けるかぎりはJava仮想マシンによって割り当て開放されることはない。

```java
      if (!class)
	memory_full (0);
    }

  /* 注意: ANDROID_CW_OVERRIDE_REDIRECTはウィンドウ作成時しか
     セットできない     */
  override_redirect = ((value_mask
			& ANDROID_CW_OVERRIDE_REDIRECT)
		       && attrs->override_redirect);

  object = (*android_java_env)->NewObject (android_java_env, class,
					   constructor, (jshort) window,
					   parent_object, (jint) x, (jint) y,
					   (jint) width, (jint) height,
					   (jboolean) override_redirect);
```

そして適切な引数と前に見つけたconstructorで、`EmacsWindow`のインスタンスを作成する。

```java
  if (!object)
    {
      (*android_java_env)->ExceptionClear (android_java_env);

      max_handle = prev_max_handle;
      memory_full (0);
```

オブジェクトの作成に失敗した場合には、Emacsは"保留中の例外"をクリアーしてから"out of memory(メモリ不足)"をシグナルする。
```java
    }

  android_handles[window].type = ANDROID_HANDLE_WINDOW;
  android_handles[window].handle
    = (*android_java_env)->NewGlobalRef (android_java_env,
					 object);
  (*android_java_env)->ExceptionClear (android_java_env);
  ANDROID_DELETE_LOCAL_REF (object);
```

成功した場合にはそのオブジェクトにhandleと新たなグローバルリファレンスが割り当てられて、JNIのNewObject関数からリターンされたローカルリファレンスは削除する。

```java
  if (!android_handles[window].handle)
    memory_full (0);
```

グローバルリファレンスの割り当てに失敗した場合にも、Emacsは"out of memory"をシグナルする。

```java
  android_change_window_attributes (window, value_mask, attrs);
  return window;
```

成功した場合には指定されたウィンドウ属性を適用して、新たなウィンドウのhandleをリターンする。
```java
}
```



## DRAWABLES, CURSORS AND HANDLES

Emacsが作成したwidgetはそれぞれ、独自のバッキングストアをもった単一の`window`に対応する。これはXと非常に似た采配といえよう。

ウィンドウ背後にあるUIロジックを実装するEmacsViewのwidgetそれぞれを、Cコードが直接参照することはない。Cコードは順序よく同期してwidgetと相互作用を行うために必要となる、state(状態)を含んだEmacsWindowをかわりに参照して処理を行う。

Xと同じようにpixmapとwindowはどちらもドローワブル(drawable:
描画可能)なリソースであり、いずれも同じグラフィック操作を適用できる。したがってEmacsPixmapのstructureはそれぞれ個別にAndroidのBitmapリソースをラップできるし、Javaレベルのグラフィック操作関数はどちらも処理する能力がある。

最後にグラフィックコンテキストはCとJavaの両方のレベルで保守されている。Cのstate(`struct
android_gc`の中に記録されている)とJavaのstate(EmacsGC構造体に相当するGContextのhandleにある)との同期を保つとともに、カーソルもシステムのPointerIconsを保持しているEmacsCursor構造体を参照するhandleを介して使用される。

すべての状況において、提供されているインターフェイスはXの場合と同じだ。



## EVENT LOOP

典型的なAndroidアプリケーションではイベントループはオペレーティングシステムによって管理されており、必要であれば常にイベントループによってコールバック(widgetの個々の関数をオーバーライドすることにより実装する)が実行される。イベントループが実行するスレッドは、widgetやactivityの作成と操作ができる唯一のスレッドでもあり、`UI
thread`と呼ばれている。

これらのコールバックはEmacsがXに似たイベント表現を、個々のイベントキューに書き込むために使用される。そして書き込まれたイベントキューは、別スレッドで実行中のEmacs独自のイベントループによって読み取られることになる。これは`select`、および`select`が待機するであろうすべてのファイル記述子をイベントキューの占有を待機する関数で置き換えることによって実現している。

これとは反対にEmacsのイベントループの方はUIスレッドにイベントを送信する必要が間々ある。これらの少量のコードによって実装されるイベントは、メインスレッドによってこれらのイベントが受信されると実行されることになる。

典型的な例は`displayToast`だ。これはEmacsService.javaに実装されている:

```java
  public void
  displayToast (final String string)
  {
    runOnUiThread (new Runnable () {
	@Override
	public void
	run ()
	{
	  Toast toast;

	  toast = Toast.makeText (getApplicationContext (),
				  string, Toast.LENGTH_SHORT);
	  toast.show ();
	}
      });
  }
```

ここで`string`はネストされた関数(入れ子関数)で使用される変数だ。ディスプレイ上に短いstatusメッセージを表示するために、関数`runOnUiThread`を用いてメインスレッドで実行されるこのネストされた関数には、この変数のコピーが含まれることになる。

ネストされた関数の完了を待機する必要がある場合には、Emacsは`syncRunnable`で実装されているメカニズムを使用する。これは最初にデッドロック回避メカニズムを呼び出して、その後に完了時にはコンディション変数を自身にシグナルするネスト関数をUIスレッドで実行するというメカニズムだ。これは通常だとUIスレッドからしか割り当てられないリソースの割り当てや、スレッドセーフではない情報の取得に用いられるメカニズムだ。以下は提供されたウィンドウに相当するEmacsViewの新たなwidgetをリターンする関数の例だ:

```java
  public EmacsView
  getEmacsView (final EmacsWindow window, final int visibility,
		final boolean isFocusedByDefault)
  {
    Runnable runnable;
    final EmacsHolder<EmacsView> view;

    view = new EmacsHolder<EmacsView> ();

    runnable = new Runnable () {
	public void
	run ()
	{
	  synchronized (this)
	    {
	      view.thing = new EmacsView (window);
	      view.thing.setVisibility (visibility);

	      /* The following function is only present on Android 26
		 or later.  */
	      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
		view.thing.setFocusedByDefault (isFocusedByDefault);

	      notify ();
	    }
	}
      };

    syncRunnable (runnable);
    return view.thing;
  }
```

ネストされた関数から値は直接リターンされないので、関数が実行を完了した後の結果を保持するためのコンテナオブジェクト別途使用する。山カッコ(angle
bracket)の内側のタイプ名に注目。このタイプ名は使用するクラスの定義に置き換えられるのだ。以下のような定義は:

```java
public class Foo<T>
{
  T bar;
};
```

これ単独では使用できない:

```java
  Foo holder; /* エラーになるよ! */
```

タイプを指定しなければならない:

```java
  Foo<Object> holder;
```

この場合に効果がある定義は:

```java
public class Foo
{
  Object bar;
};
```



## COMPATIBILITY

すべてのAndroidアプリケーションには、サポート対象のAndroidシステムにたいして影響を与えるために、そしてこれらのシステムそれぞれにたいして正確に機能するために必要な対策を講じるためにセットする3つの変数がある。それは最小APIレベル(minimum
API level)、コンパイルSDKバージョン(compile SDK version)、ターゲットAPIレベル(target API
level)という3つの変数だ。

最小APIレベルとは、そのアプリケーションのインストールと実行が許されるもっとも古いAndroidのバージョンのことだ。EmacsではAndroidのCコンパイラーで定義されているプリプロセッサマクロ__ANDROID_API__を調べて確認している。

JavaコードがAndroid 2.2(API level 8; Emacs
がサポートする最小のAPIレベルだ)では提供されていないAndroidのAPI呼び出しを実行する前に、まずは以下の値をチェックしなければならない:

```text
  Build.VERSION.SDK_INT
```

この変数には常にその時点でEmacsがインストールされているシステムのAPIレベルがセットされる。たとえば`dispatchKeyEventFromInputMethod`(Android
6.0: API level 23では提供されていない)を呼び出す前に以下のようなチェックを行う:

```java
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N)
      view.imManager.dispatchKeyEventFromInputMethod (view, key);
    else
      {
```

ここで`N`は定数24に定義されている。

コンパイルSDKバージョンとは、JavaコードがコンパイルされるAndroid
SDKのヘッダーのバージョンのこと。Javaは条件付きコンパイル構造を提供していないので、`java/INSTALL`記載のバージョン以外のヘッダーではEmacsをコンパイルできないが、必要に応じて上述したバージョンチェックが行われるかぎり、サポート対象となるシステムの範囲には影響しない。

ターゲットAPIレベルとは、さまざまなシステムAPIの動作にたいする後方互換性のない変更を有効にするかどうか判断する際に、システムが参照するjava/AndroidManifest.xml.inで定義されている数値のこと。どのAndroidバージョンにおいても、そのアプリケーションのターゲットAPIレベル以下のバージョンにおける後方互換性のない変更は無効になる。

GoogleがAndroidの"時代遅れ"のバージョンをターゲットとするアプリケーションをユーザーがインストールことを禁止する意向を表明しているので、Androidのメジャーバージョンアップに合わせてターゲットAPIを更新する必要があるものの、これまでのところこの脅威にたいしては上手く対処できている。



```text
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
```
