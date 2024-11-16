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
``

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

```java
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



DRAWABLES, CURSORS AND HANDLES

Each widget created by Emacs corresponds to a single ``window'', which has
its own backing store.  This arrangement is quite similar to X.

C code does not directly refer to the EmacsView widgets that implement the
UI logic behind windows.  Instead, its handles refer to EmacsWindow
structures, which contain the state necessary to interact with the widgets
in an orderly and synchronized manner.

Like X, both pixmaps and windows are drawable resources, and the same
graphics operations can be applied to both.  Thus, a separate EmacsPixmap
structure is used to wrap around Android Bitmap resources, and the
Java-level graphics operation functions are capable of operating on them
both.

Finally, graphics contexts are maintained on both the C and Java levels; the
C state recorded in `struct android_gc' is kept in sync with the Java state
in the GContext handle's corresponding EmacsGC structure, and cursors are
used through handles that refer to EmacsCursor structures that hold system
PointerIcons.

In all cases, the interfaces provided are identical to X.



EVENT LOOP

In a typical Android application, the event loop is managed by the operating
system, and callbacks (implemented through overriding separate functions in
widgets) are run by the event loop wherever necessary.  The thread which
runs the event loop is also the only thread capable of creating and
manipulating widgets and activities, and is referred to as the ``UI
thread''.

These callbacks are used by Emacs to write representations of X-like events
to a separate event queue, which are then read from Emacs's own event loop
running in a separate thread.  This is accomplished through replacing
`select' by a function which waits for the event queue to be occupied, in
addition to any file descriptors that `select' would normally wait for.

Conversely, Emacs's event loop sometimes needs to send events to the UI
thread.  These events are implemented as tiny fragments of code, which are
run as they are received by the main thread.

A typical example is `displayToast', which is implemented in
EmacsService.java:

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

Here, the variable `string' is used by a nested function.  This nested
function contains a copy of that variable, and is run on the main thread
using the function `runOnUiThread', in order to display a short status
message on the display.

When Emacs needs to wait for the nested function to finish, it uses a
mechanism implemented in `syncRunnable'.  This mechanism first calls a
deadlock avoidance mechanism, then runs a nested function on the UI thread,
which is expected to signal itself as a condition variable upon completion.
It is typically used to allocate resources that can only be allocated from
the UI thread, or to obtain non-thread-safe information.  The following
function is an example; it returns a new EmacsView widget corresponding to
the provided window:

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

As no value can be directly returned from the nested function, a separate
container object is used to hold the result after the function finishes
execution.  Note the type name inside the angle brackets: this type is
substituted into the class definition as it is used; a definition such as:

public class Foo<T>
{
  T bar;
};

can not be used alone:

  Foo holder; /* Error! */

but must have a type specified:

  Foo<Object> holder;

in which case the effective definition is:

public class Foo
{
  Object bar;
};



COMPATIBILITY

There are three variables set within every Android application that extert
influence over the set of Android systems it supports, and the measures it
must take to function faithfully on each of those systems: the minimum API
level, compile SDK version and target API level.

The minimum API level is the earliest version of Android that is permitted
to install and run the application.  For Emacs, this is established by
detecting the __ANDROID_API__ preprocessor macro defined within the Android
C compiler.

Before Java code executes any Android API calls that are not present within
Android 2.2 (API level 8), the lowest API level supported by Emacs as a
whole, it must first check the value of the:

  Build.VERSION.SDK_INT

variable, which is always set to the API level of the system Emacs is
presently installed within.  For example, before calling
`dispatchKeyEventFromInputMethod', a function absent from Android 6.0 (API
level 23) or earlier, check:

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N)
      view.imManager.dispatchKeyEventFromInputMethod (view, key);
    else
      {

where `N' is a constant defined to 24.

The compile SDK version is the version of the Android SDK headers Java code
is compiled against.  Because Java does not provide conditional compilation
constructs, Emacs can't be compiled with any version of these headers other
than the version mentioned in `java/INSTALL', but the headers used do not
affect the set of supported systems provided that the version checks
illustrated above are performed where necessary.

The target API level is a number within java/AndroidManifest.xml.in the
system refers to when deciding whether to enable backwards-incompatible
modifications to the behavior of various system APIs.  For any given Android
version, backwards incompatible changes in that version will be disabled for
applications whose target API levels don't exceed its own.

The target API should nevertheless be updated to match every major Android
update, as Google has stated their intentions to prohibit users from
installing applications targeting ``out-of-date'' versions of Android,
though this threat has hitherto been made good on.



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
