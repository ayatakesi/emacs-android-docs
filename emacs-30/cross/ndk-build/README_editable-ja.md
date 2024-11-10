# NDK BUILD SYSTEM IMPLEMENTATION

```text
Copyright (C) 2023-2024 Free Software Foundation, Inc.  See the end of the
file for license conditions.
```

Emacsは`ndk-build`を独自に実装する。他の`Makefile`から使うAndroid NDK同梱バージョンを使うのは容易ではなく、互換性のない変更が加え続けられるからである。  

Emacsにおける`ndk-build`は1つの`m4`ファイル:  

```text
m4/ndk-build.m4
```

`configure`中に実行される`build-aux`の4つ`Makefile`:  

```text
build-aux/ndk-build-helper-1.mk
build-aux/ndk-build-helper-2.mk
build-aux/ndk-build-helper-3.mk
build-aux/ndk-build-helper.mk
```

`configure`中に実行される`build-aux`の1つのawkスクリプト:  

```text
build-aux/ndk-module-extract.awk
```

`cross/ndk-build`の7つの`Makefile`:  

```text
cross/ndk-build/ndk-build-shared-library.mk
cross/ndk-build/ndk-build-static-library.mk
cross/ndk-build/ndk-build-executable.mk
cross/ndk-build/ndk-clear-vars.mk
cross/ndk-build/ndk-prebuilt-shared-library.mk
cross/ndk-build/ndk-prebuilt-static-library.mk
cross/ndk-build/ndk-resolve.mk
```

さらに`configure`が生成する`cross/ndk-build`の2つの`Makefile`:  

```text
cross/ndk-build/Makefile     (cross/ndk-build/Makefile.inより生成)
cross/ndk-build/ndk-build.mk (cross/ndk-build/ndk-build.mk.inより生成)
```

`m4/ndk-build.m4`は`configure`スクリプトが用いるマクロコレクションであり`ndk-build`システムのセットアップ、モジュール検索、`LIBS`と`CFLAGS`に適切なオプションをセットしたり、Emacsの残りの部分のビルドに必要な`Makefile`を生成するために使用される。  

`configure`は`Android.mk`ファイルを検索するディレクトリー、およびビルド対象となるAndroidシステムのバージョンとタイプを決定した直後に以下を呼び出す:  

```shell
ndk_INIT([$android_abi], [$ANDROID_SDK], [cross/ndk-build])
```

これは`$with_ndk_path`に指定された`Android.mk`ファイルすべてを列挙する一連のシェルスクリプトに展開されて、`configure`スクリプトが実行する残りの`ndk-build`コードの実行に使用されるいくつかのシェル関数をセットアップ、`ndk-build`に生成された`Makefile`が`cross/ndk-build/Makefile`にあることを伝える。  

`configure`はAndroid用のクロスコンパイルの際には、マクロ`EMACS_CHECK_MODULES`を`pkg-config.m4`の`PKG_CHECK_MODULES`ではなく、マクロ`ndk_CHECK_MODULES`に展開する。したがって以下のコードは:  

```shell
EMACS_CHECK_MODULES([PNG], [libpng >= 1.0.0])
```

実際には以下のように展開される:  

```shell
ndk_CHECK_MODULES([PNG], [libpng >= 1.0.0], [HAVE_PNG=yes],
               [HAVE_PNG=no])
```

これは最初に以下を呼び出す一連のシェルスクリプトに順次展開される:  

```shell
make -f build-aux/ndk-build-helper.mk
```

`ndk_INIT`が見つけた`Android.mk`それぞれにたいして、Makeに以下の変数が与えられる:  

```make
EMACS_SRCDIR=.  # (configureが実行される)ソースディレクトリー
BUILD_AUXDIR=$ndk_AUX_DIR # build-auxディレクトリー
EMACS_ABI=$ndk_ABI # ndk_INITに与えられた$android_abi
ANDROID_MAKEFILE="/opt/android/libpng/Android.mk"
ANDROID_MODULE_DIRECTORY="/opt/android/libpng"
NDK_BUILD_DIR="$ndk_DIR" # ndk_INITに与えられたディレクトリー
```

ここで初めて`build-aux/ndk-build-helper.mk`は`$(ANDROID_MAKEFILE)`、すなわち`Android.mk`の内容を評価する。`Android.mk`によって提供されるパッケージ(あるいはモジュール)のリスト、それらに対応する`Makefile`のターゲット、ターゲットのビルドとリンクに必要なコンパイラーフラグ、リンカーフラグを確立することがこの評価の目的である。  

これを行う前に`build-aux/ndk-build-helper.mk`は、すべての`Android.mk`ファイルにとって必要ないくつかの変数および関数を定義する:  

```make
my-dir # Android.mkファイルがあるディレクトリー
BUILD_SHARED_LIBRARY # build-aux/ndk-build-helper-1.mk
BUILD_STATIC_LIBRARY # build-aux/ndk-build-helper-2.mk
BUILD_EXECUTABLE # build-aux/ndk-build-helper-3.mk
CLEAR_VARS # build-aux/ndk-build-helper-4.mk
```

次に`Android.mk`は`$(CLEAN_VARS)`をインクルード、もしかしたら別の`Android.mk`をインクルード(前にセットされた変数をクリアーするために)、そしてそれぞれのモジュールを`ndk-build`システムにたいして記述するための変数をいくつかセットしてから`$(BUILD_SHARED_LIBRARY)`、`$(BUILD_STATIC_LIBRARY)`、`$(BUILD_EXECUTABLE)`のいずれかをインクルードする。  

これら3つのスクリプトはそれぞれ`Android.mk`がセットした変数を読み込み、依存関係を解決してからEmacsにモジュールを記述するテキストをプリントする。たとえば共有ライブラリーのモジュール`libpng`の場合には、以下のようなテキストがプリントされるだろう:  

```text
Building shared
libpng
/opt/android/libpng/png.c /opt/android/libpng/pngerror.c
/opt/android/libpng/pngget.c /opt/android/libpng/pngmem.c
/opt/android/libpng/pngpread.c /opt/android/libpng/pngread.c
/opt/android/libpng/pngrio.c /opt/android/libpng/pngrtran.c
/opt/android/libpng/pngrutil.c /opt/android/libpng/pngset.c
/opt/android/libpng/pngtrans.c /opt/android/libpng/pngwio.c
/opt/android/libpng/pngwrite.c /opt/android/libpng/pngwtran.c
/opt/android/libpng/pngwutil.c
-I/opt/android/libpng

  -L/opt/emacs/cross/ndk-build -l:libpng_emacs.so
libpng_emacs.so
End
```

この出力は以下のような配置になっている:  

- 1行目は単語`Building`、その後に`shared`、`static`、`executable`のいずれかが続く(ビルドするモジュールのタイプに依存する)。

- 2行目は現在ビルドしているモジュールの名前。

- 3行目はそのモジュールに含まれているすべてのソースコードファイル。

- 4行目はそのモジュールに関連するインクルードを見つけるために、`CFLAGS`に追加する必要があるテキスト。

- 5行目はそのモジュールと依存関係すべてをリンクするために、`LIBS`に追加する必要があるテキスト。

- 6行目はこのモジュールの最終的な共有オブジェクトまたはライブラリーアーカイブとすべての依存関係をビルドするMakeのターゲット(後述)。

- 7行目は空行、またはC++標準ライブラリー依存関係の名前。これはEmacsのアプリケーションパッケージにC++標準ライブラリーをインクルードするかどうかを判断するために使用される。

このMakeからの出力は`build-aux/ndk-module-extract.awk`というawkスクリプトに与えられる。このawkスクリプトには出力を解析して、ビルドするモジュール以外のモジュールをフィルタリングする役目がある:  

```shell
awk -f build-aux/ndk-module-extract.awk MODULE=libpng
```

最終的にはシェルスクリプトの以下のセクションが生成される:  

```shell
module_name=libpng
module_kind=shared
module_src="/opt/android/libpng/png.c /opt/android/libpng/pngerror.c
/opt/android/libpng/pngget.c /opt/android/libpng/pngmem.c
/opt/android/libpng/pngpread.c /opt/android/libpng/pngread.c
/opt/android/libpng/pngrio.c /opt/android/libpng/pngrtran.c
/opt/android/libpng/pngrutil.c /opt/android/libpng/pngset.c
/opt/android/libpng/pngtrans.c /opt/android/libpng/pngwio.c
/opt/android/libpng/pngwrite.c /opt/android/libpng/pngwtran.c
/opt/android/libpng/pngwutil.c"
module_includes="-I/opt/android/libpng"
module_cflags=""
module_ldflags="  -L/opt/emacs/cross/ndk-build -l:libpng_emacs.so"
module_target="libpng_emacs.so"
module_cxx_deps=""
module_imports=""
```

これはその後に`configure`によって評価される。変数`module_name`がセットされたら、`configure`はモジュールの変数`CFLAGS`と`LIBS`に残りの`$(module_includes)`、`$(module_cflags)`、`$(module_ldflags)`を追加、変数`NDK_BUILD_MODULES`に指定されている`Makefile`のターゲットのリストを追加する。  

自身の`Android.mk`ファイルの中では定義されていないにも関わらず、`--with-ndk-path`で定義されているモジュール定義のインポートを`Android.mk`が選択するかもしれない。`build-aux/ndk-build-helper.mk`はインポートするモジュールを変数に追加するために`import-module`関数を定義する。この変数は`ndk-build-helper.mk`の終了後にプリントされる。たとえば`libicucc`モジュールをインポートする`libxml2`では、以下のようなテキストがプリントされるだろう:  

```text
Building shared
libxml2
/home/oldosfan/libxml2/SAX.c /home/oldosfan/libxml2/entities.c
/home/oldosfan/libxml2/encoding.c /home/oldosfan/libxml2/error.c
/home/oldosfan/libxml2/parserInternals.c /home/oldosfan/libxml2/parser.c
/home/oldosfan/libxml2/tree.c /home/oldosfan/libxml2/hash.c
/home/oldosfan/libxml2/list.c /home/oldosfan/libxml2/xmlIO.c
/home/oldosfan/libxml2/xmlmemory.c /home/oldosfan/libxml2/uri.c
/home/oldosfan/libxml2/valid.c /home/oldosfan/libxml2/xlink.c
/home/oldosfan/libxml2/debugXML.c /home/oldosfan/libxml2/xpath.c
/home/oldosfan/libxml2/xpointer.c /home/oldosfan/libxml2/xinclude.c
/home/oldosfan/libxml2/DOCBparser.c /home/oldosfan/libxml2/catalog.c
/home/oldosfan/libxml2/globals.c /home/oldosfan/libxml2/threads.c
/home/oldosfan/libxml2/c14n.c /home/oldosfan/libxml2/xmlstring.c
/home/oldosfan/libxml2/buf.c /home/oldosfan/libxml2/xmlregexp.c
/home/oldosfan/libxml2/xmlschemas.c /home/oldosfan/libxml2/xmlschemastypes.c
/home/oldosfan/libxml2/xmlunicode.c /home/oldosfan/libxml2/xmlreader.c
/home/oldosfan/libxml2/relaxng.c /home/oldosfan/libxml2/dict.c
/home/oldosfan/libxml2/SAX2.c /home/oldosfan/libxml2/xmlwriter.c
/home/oldosfan/libxml2/legacy.c /home/oldosfan/libxml2/chvalid.c
/home/oldosfan/libxml2/pattern.c /home/oldosfan/libxml2/xmlsave.c
/home/oldosfan/libxml2/xmlmodule.c /home/oldosfan/libxml2/schematron.c
/home/oldosfan/libxml2/SAX.c /home/oldosfan/libxml2/entities.c
/home/oldosfan/libxml2/encoding.c /home/oldosfan/libxml2/error.c
/home/oldosfan/libxml2/parserInternals.c /home/oldosfan/libxml2/parser.c
/home/oldosfan/libxml2/tree.c /home/oldosfan/libxml2/hash.c
/home/oldosfan/libxml2/list.c /home/oldosfan/libxml2/xmlIO.c
/home/oldosfan/libxml2/xmlmemory.c /home/oldosfan/libxml2/uri.c
/home/oldosfan/libxml2/valid.c /home/oldosfan/libxml2/xlink.c
/home/oldosfan/libxml2/debugXML.c /home/oldosfan/libxml2/xpath.c
/home/oldosfan/libxml2/xpointer.c /home/oldosfan/libxml2/xinclude.c
/home/oldosfan/libxml2/DOCBparser.c /home/oldosfan/libxml2/catalog.c
/home/oldosfan/libxml2/globals.c /home/oldosfan/libxml2/threads.c
/home/oldosfan/libxml2/c14n.c /home/oldosfan/libxml2/xmlstring.c
/home/oldosfan/libxml2/buf.c /home/oldosfan/libxml2/xmlregexp.c
/home/oldosfan/libxml2/xmlschemas.c /home/oldosfan/libxml2/xmlschemastypes.c
/home/oldosfan/libxml2/xmlunicode.c /home/oldosfan/libxml2/xmlreader.c
/home/oldosfan/libxml2/relaxng.c /home/oldosfan/libxml2/dict.c
/home/oldosfan/libxml2/SAX2.c /home/oldosfan/libxml2/xmlwriter.c
/home/oldosfan/libxml2/legacy.c /home/oldosfan/libxml2/chvalid.c
/home/oldosfan/libxml2/pattern.c /home/oldosfan/libxml2/xmlsave.c
/home/oldosfan/libxml2/xmlmodule.c /home/oldosfan/libxml2/schematron.c

  -L/home/oldosfan/emacs-dev/emacs-android/cross/ndk-build -l:libxml2_emacs.so -l:libicuuc_emacs.so
libxml2_emacs.so libicuuc_emacs.so
End
Start Imports
libicuuc
End Imports
```

`Start Imports`セクションに到達すると、`build-aux/ndk-module-extract.awk`は`End Imports`がある行まですべてのインポートを収集する。この時点では以下のようにプリントされている筈だ:  

```text
module_imports="libicuuc"
```

インポートのリストが空でなければ、`ndk_CHECK_MODULES`は自身の`Android.mk`を追加する前に、追加でインポートそれぞれにたいして自分を呼び出す。`$ndk_DIR/Makefile`にそのモジュールをインクルードする前に、モジュールにインポートされている依存関係を確実にインクルードするためである。  

そして最後、`src/Makefile.android`の生成直前に`configure`が以下を展開する:  

```text
ndk_CONFIG_FILES
```

これにより`$ndk_DIR/Makefile`と`$ndk_DIR/ndk-build.mk`が生成される。  

これで依存するすべてのモジュールをビルドするように`$ndk_DIR`ディレクトリーがセットアップされて、モジュールをビルドするために`$ndk_DIR`に`chdir`するルールとともにEmacsをリンクするために必要なファイルのリストが`$ndk_DIR/ndk-build.mk`にインクルードされた。  

`$ndk_DIR/ndk-build.mk`は`cross/src/Makefile`(`Makefile.android`)および`java/Makefile`にインクルードされる。これは3つの異なり変数を定義している:  

```text
NDK_BUILD_MODULES ビルドするすべてのモジュールのファイル名
NDK_BUILD_STATIC  ビルドするすべてのライブラリーアーカイブの絶対ファイル名
NDK_BUILD_SHARED  ビルドするすべての共有ライブラリーの絶対ファイル名
```

次は`$(NDK_BUILD_MODULES)`で定義されているモジュールそれぞれをビルドするルールの定義に進む。  

`libemacs.so`と依存関係をリンクする前に、まだビルドされていないEmacsの依存関係をビルドするように`cross/src/Makefile`を手配する。  

さらにアプリケーションパッケージのビルド前にすべての共有オブジェクト依存関係がビルドされるように`java/Makefile`を手配する。これらの依存関係は`libemacs.so`のリンク前にビルドされている筈なので、通常は冗長である。  

モジュールのビルドは、`ndk-build`ビルドシステムの実際の実装を含む`$ndk_DIR/Makefile`を介して実行される。これはまず`ndk-build`ビルドシステム内の特定の定数(共有ライブラリーや静的ライブラリーをビルドするために`Android.mk`にインクルードされるファイルや`CLEAR_VARS`など)を定義する。これらの定数でもっとも重要な定数は:  

```text
CLEAR_VARS              cross/ndk-build/ndk-clear-vars.mk
BUILD_EXECUTABLE        cross/ndk-build/ndk-build-executable.mk
BUILD_SHARED_LIBRARY    cross/ndk-build/ndk-build-shared-library.mk
BUILD_STATIC_LIBRARY    cross/ndk-build/ndk-build-static-library.mk
PREBUILT_SHARED_LIBRARY cross/ndk-build/ndk-prebuilt-shared-library.mk
PREBUILT_STATIC_LIBRARY	 cross/ndk-build/ndk-prebuilt-static-library.mk
```

次にEmacsの依存関係それぞれにたいして`Android.mk`ファイルをロードする。`Android.mk`はそこで定義されているモジュールごとに各モジュールに固有なすべての変数の設定を解除する`$(CLEAR_VARS)`、共有ライブラリーあるいは静的ライブラリーのモジュールそれぞれについては`$(BUILD_SHARED_LIBRARY)`あるいは`$(BUILD_STATIC_LIBRARY)`をインクルードする。  

これにより`configure`スクリプト内部にある`build-aux`の`Makefile`と同じように、`cross/ndk-build/ndk-build-shared-library.mk`や`cross/ndk-build/ndk-build-static-library`がインクルードされるのだ。  

これら2つのスクリプトはそれぞれモジュールに関連付けられたすべてのオブジェクトファイルをビルドするためのルールを定義して、それらのリンクあるいはアーカイブを行う。モジュールは`build-aux/ndk-build-helper.mk`出力の6行目にある`Make`のターゲットと同じ名前にリンクされる。  

これを行う間にどちらもファイル`ndk-resolve.mk`をインクルードする。`ndk-resolve.mk`にはビルドするモジュールのコンパイラーおよびリンカーのコマンドラインにエクスポートされたすべての`CFLAGS`を再帰的に追加すること、およびすべての依存関係をインクルードする役目がある。  

共有ライブラリーモジュールをビルドする際には、すべての静的ライブラリー依存関係のアーカイブファイルを含んだ変数`NDK_LOCAL_A_NAMES_$(LOCAL_MODULE)`および`NDK_WHOLE_A_NAMES_$(LOCAL_MODULE)`の定義も`ndk-resolve.mk`の役目となる。これらのアーカイブファイルは共有オブジェクトファイルにリンクされることになる。  

これらの処理は共有ライブラリーあるいは静的ライブラリーのモジュールがビルドされる度に毎回`cross/ndk-build/ndk-resolve.mk`をインクルードすることによって行われる。ではどうやって?  

まず`ndk-resolve.mk`はモジュールの`LOCAL_PATH`、`LOCAL_STATIC_LIBRARIES`、`LOCAL_SHARED_LIBRARIES`、`LOCAL_EXPORT_CFLAGS`、`LOCAL_EXPORT_C_INCLUDES`を保存する。  

次に`ndk-resolve`はモジュールが指定した依存関係をループして、依存関係の`CFLAGS`とインクルードを、カレントモジュールのコマンドラインに追加する。  

その後はすべての依存関係が解決されるまで、未解決の依存関係それぞれにたいしてこのプロセスを繰り返すのだ。  

`libpng`はただ1つの共有ライブラリーモジュールを提供する非常にシンプルなモジュールだ。このモジュールの名前は`libpng_emacs.so`、最終的にはEmacsアプリケーションパッケージのライブラリーディレクトリーにビルドされてパッケージングされることになる。今度はもっと複雑なモジュール`libwebp`を見てみよう:  



`libwebp`とともにビルドする場合には、Emacsは単一のライブラリー`libwebpdemux`に依存することになる。Unixシステムではこのライブラリーの名前は`libwebpdemux`であり、`pkg-config`で検索するのもこの名前だ。  

しかしAndroidではライブラリーのモジュール名は`webpdemux`だけである。`ndk_CHECK_MODULES`がモジュールの検索を開始する際には、まずこの名前が変数`ndk_package_map`(`ndk_INIT`内部でセットされる)にあるか確認する。この場合には以下の単語が見つかるだろう:  

```text
libwebpdemux:webpdemux
```

そして`libwebpdemux`は即`webpdemux`に置き換えられる。  

`webpdemux`という静的ライブラリーモジュールを含んだ`Android.mk`ファイルを探して、`build-aux/ndk-build-helper.mk`の出力をawkスクリプトに与える。結果は以下のようになるだろう:  

```make
module_name=webpdemux
module_kind=static
module_src="/opt/android/webp/src/demux/anim_decode.c
/opt/android/webp/src/demux/demux.c"
module_includes="-I/opt/android/webp/src"
module_cflags=""
module_ldflags=" cross/ndk-build/libwebpdemux.a cross/ndk-build/libwebp.a
cross/ndk-build/libwebpdecoder_static.a "
module_target="libwebpdemux.a libwebp.a libwebpdecoder_static.a"
```

注意深い読者は`webpdemux`ライブラリーに関連付けられた`libwebpdemux.a`アーカイブに加えて、Emacsが追加で2つのライブラリーとリンクすることになっていることに気づいたかもしれない。これは`webpdemux`モジュールが`webp`モジュールへの依存関係を指定しているためだ(同じ`Android.mk`内で定義されている)。`build-aux/ndk-build-helper.mk`がこの依存関係を解決して、`webpdecoder_static`に別の依存関係が指定されていることに気づき、リンカーのコマンドラインとビルドするターゲットのリストに追加したのだ。  

そのようにして指定されたたった1つの依存関係`webpdemux`ではなく、3つの依存関係すべてがEmacsにリンクされる。  



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
