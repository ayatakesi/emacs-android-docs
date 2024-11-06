# Installation instructions for Android

Copyright (C) 2023-2024 Free Software Foundation, Inc.
See the end of the file for license conditions.

EmacsをAndroidデバイスで実行可能なアプリケーションパッケージとしてビルドする前に、どうかこのファイル全体を読んで欲しい。  

(リリースtarballではなく)ソースレポジトリからビルドする際には、トップレベルにあるINSTALL.REPOも確認して欲しい。  


AndroidはAndroid自体が実行されるコンピューターではプログラムのバイナリファイルを生成できないという点において、通常のオペレーティングシステムとは異なる。そのかわりにプログラムのバイナリファイルは`Android SDK(Android Software Development Kit)`、および`Android NDK(Android Native Development Kit)`と呼ばれる一連のツールセットを用いて別のコンピューターでビルドしなければならない。GNU Emacs をビルドするためにはどちらも適切なバージョンを入手しなければならない。ビルド後に生成されるバイナリは、ほとんどすべてのAndroidデバイスで機能するだろう。このドキュメントではこれら2つのツールセットをどのように入手できるかについての詳細には触れない。ただしあなたの自由のためにも、Debianプロジェクト提供のAndroid SDKを使用するべきだろう。  

Android SDKとAndroid NDKに加えて、EmacsのビルドにはシステムにOpenJDK 1.7.0のJavaコンパイラー、および動作するm4プロセッサーがインストールされていることが必要だ。公式にサポートされているのはGNUシステム上でのビルドだけだ。Mac OSでも動作するし他のUnixシステムでも同様に動作するだろうと言われているが、MS WindowsとCygwinでは動作しないだろう。  

これらのツールが入手できたら、以下のように`configure`スクリプトを呼び出せるだろう:  

```bash
./configure --with-android=/path/to/android.jar \
    ANDROID_CC=/path/to/android/ndk/cc  \
    SDK_BUILD_TOOLS=/path/to/sdk/build/tools
```

上記コマンドラインのパスは以下のように置き換えること:  
  - Android SDK付属の`android.jar`ヘッダーへのパス。Androidバージョン14(API level 34)に対応していなければならない。
  - ビルドしたEmacsを実行するCPU向けの、Android NDKに付属するCコンパイラーへのパス。
  - Android SDKの`aapt`、`apksigner`、`d8`といったバイナリを含むディレクトリーへのパス。アプリケーションパッケージをビルドするために使用する。

CPUの種類は`armeabi`、`armv7*`、`i686`、`x86_64`、`mips`、`mips64`のいずれか。  

configureによる構成プロセスが終われば、以下を実行できるだろう:  

```bash
make all
```

`make`が終われば`java`ディレクトリーに以下のような名前のファイルだできている筈だ:  
```text
emacs-<version>-<api-version>-<abi>.apk
```

ここで<api-version>はそのパッケージが実行可能なAndroidの最低バージョン、<abi>はビルドされたパッケージが対象とするAndroidマシンのタイプ。  

生成されたパッケージをSDカード(または類似メディア)にアップロードして、デバイス上にインストールできる。  


## LOCATING NECESSARY FILES

上で述べたようにAndroid向けにEmacsをビルドするためには、Android SDKとAndroid NDKという個別のコンポーネントが存在する必要がある。これらツールのインストールによって、Android開発ツールのコンテンツは複数のディレクトリーに編成される。これらのうち、Emacsのコンパイルプロセスに関係があるのは以下のとおり:  

```text 
platforms
ndk
build-tools
```

platformsディレクトリーにはAPIレベルごとに1つのサブディレクトリーがあり、そのレベル用のヘッダーがインストールされている。これらのディレクトリーそれぞれには、Emacsのコンパイルにも必要なそのAndroidバージョン用のandroid.jarアーカイブが含まれている。  

Emacsをコンパイルするには正しいAPIレベル向けに記述されたヘッダーを用いることが不可欠である。これは現在のところAPI level 34なので、名前が`android-34`で始まるディレクトリー内に配置されているandroid.jarが正しいアーカイブである。Emacsのコンパイルプロセスにとっては、ヘッダーのマイナーリビジョンは重要ではない。`android-34-extN`(NはAndroid SDKのリビジョンを表す)という名前のディレクトリーがある場合に、`configure`にそのディレクトリーのandroid.jarを指定するか、それとも`android-34`という名前のディレクトリーにあるandroid.jarを指定するかはさほど重要ではないのだ。  

ndkディレクトリーにはインストールされているAndroid NDKのバージョンごとに1つのサブディレクトリーが含まれている。このディレクトリーにはCおよびC++のコンパイルシステムが含まれている。前段で述べたJavaヘッダーとは対照的に使用するNDKのバージョンは、android.jarのバージョンほどにはEmacsに影響しない。とはいえNDKのバージョンはそれぞれ、限られた範囲のAPIレベルだけをサポートしている。lCコンパイラーのバイナリ(あるいは`__ANDROID_API__`)にどれを選択するかは、コンパイルするパッケージがサポート対象とするAndroidの最低バージョンに応じて決まる。  

ほとんどの場合においてサブディレクトリーにはそれぞれ`toolchains`という名前のフォルダーが含まれており、そこには`llvm`というディレクトリーとNDK提供のGCCツールチェーンごとにディレクトリーが保持されている。そのディレクトリー内の`prebuilt/*/bin`の中にCコンパイラーが配置されているだろう。  

build-toolsディレクトリーにJavaコンパイラーが出力するclassファイルから、Androidが用いるDEX形式への変換に使用するユーティリティープログラムが保持されている。ビルドツールごとに1つのサブディレクトリーがあるが、もっとも重要なのはバージョンの選択ではない。選択したバージョンが機能しないとコンパイラーが文句をいうので、新しいバージョンをインストールすること。33.0.xや34.0.xのような最新リリースであれば動作する見込みがある。  


## BUILDING WITH OLD NDK VERSIONS

古いバージョンのAndroid NDKでEmacsをビルドするには特別なセットアップを要する。それらのNDKバージョンには、Androidバージョンごとに個別のCコンパイラーのバイナリが存在しないからだ。  

`configure`を実行する前に、3つの変数決定する必要がある:  

- どのタイプのAndroidシステム向けにEmacsをビルドするか
- ビルドするEmacsが対象とするAndroidの最小APIレベルは
- システムのルート位置、NDKのそのAndroidバージョン用インクルードファイルの位置


この情報をNDKのCコンパイラーの引数として指定しなければならない。たとえば:

```bash
./configure [...] \
    ANDROID_CC="i686-linux-android-gcc \
    --sysroot=/path/to/ndk/platforms/android-14/arch-x86/
	-isystem /path/to/ndk/sysroot/usr/include \
	-isystem /path/to/ndk/sysroot/usr/include/i686-linux-android \
	-D__ANDROID_API__=14"
```

`__ANDROID_API__`と"platforms/android-14"に含まれるバージョン識別によってビルド対象とするAndroidバージョンを定義、インクルードディレクトリーでは関連するAndroidヘッダーへのパスを指定する。加えてAndroid NDKのバグのために、"-gdwarf-2"の指定が必要かもしれない。  

古いバージョンのAndroid SDKであっても、`-isystem`ディレクティブを追加する必要はない。  

EmacsはAndroid 2.2(API バージョン8)以降、NDKのr10b以降で実行できることが判っている。さらに古いバージョンのAndroidでもEmacsを動作させたいと考えているが、EmacsがCコードからテキストを表示するために必要となるJNIグラフィックライブラリーが欠落している。  

NDKAndroid 2.2には非常に厄介なバグがあり、そのために生成されたEmacs内の大容量ファイルをAndroid 2.2用のビルドでは圧縮できないことから、新たなバージョン用のEmacsパッケージよりもおよそ15MBサイズが大きくなる。園山システムにおいては、パッケージマネージャーによって誤認されないパッケージを生成するために、`zip`ユーティリティーも必要になる。  


## BUILDING C++ DEPENDENCIES

普通の状況下であれば、`--with-ndk-path`で指定された依存関係のビルドにNDKに同梱されているC++ライブラリーのいずれか1つが必要であれば、Emacsが自動的に検知してそれを構成するべきだろう。  

そうであってもなおこのプロセスに間違いがない訳ではないし、NDKがC++コンパイラーの検索に失敗しがちな特定バージョンも存在するので、スタンドアローンツールチェーン(standalone toolchain)を生成して通常のコンパイラーツールチェーンと同じものに置き換えるために、NDKディストリビューションに同梱されている`make_standalone_toolchain.py`スクリプトの実行が必要である。詳細についてはhttps://developer.android.com/ndk/guides/standalone_toolchainを参照して欲しい。  

一部のNDKバージョンに同梱されているGCC 4.9.xにはスタンドアローンツールチェーンにコピーされた後に`stddef.h`を見つけられないというバグが発生する。この問題を回避するには:  

```bash
-isystem /path/to/toolchain/include/c++/4.9.x
```

これを`ANDROID_CFLAGS`に追加すればよい。  


## DEBUG AND RELEASE BUILDS

Androidはアプリケーションのビルドにたいして`debug`と`release`の区別を設けている。`release`ビルドではetc/DEBUG記載のステップによるデバッグが不可能という代償を払って、システムがアプリケーションに強力な最適化を施すだろう。  

Emacsはデフォルトではデバッグ可能なしパッケージとしてビルドされるが:  

```bash
./configure --without-android-debug
```

上記のように指定すればかわりにリリースビルドが作成される。リソースが限られたマシンでEmacsを実行する際には役に立つかもしれない。  

再配布用にEmacsパッケージをビルドする場合には、debug版とrelease版の両方を提供するよう強く推奨する。  


## BUILDING WITH A SHARED USER ID

他のプログラムから実行可能ファイルやアプリケーションデータにアクセスできるようにEmacsをビルドしたいと思う場合もあるかもしれない。これを成すためには他のプログラムが`shared user ID`をもっていて、Emacsの署名に用いたのと同じキー(通常は`emacs.keystore`)で署名されていなければならない。  

この署名キーで両方に署名してそのプログラムの`shared user ID`を入手したら、以下のようにconfigureに指定できる:  

```bash
./configure --with-shared-user-id=MY.SHARED.USER.ID
```

たとえば、  

```bash
./configure --with-shared-user-id=com.termux
```

これにより`/data/data/com.termux/files`ディレクトリーに配置されている(Termux)[https://termux.dev]のアプリケーションデータに、Emacsがアクセスできるようになる。インストール後のuser ID変更はシステムが禁止しているので、すでに別のshared user IDでEmacsをインストール済みならこれを行ってはならない。  


## BUILDING WITH THIRD PARTY LIBRARIES

Android NDKは通常の方法によるサードパーティライブラリーの配置は特にサポートしておらず、特に`pkg-config`を通じたライブラリー配置はサポートしない。そのかわりに用いるのが`ndk-build`と呼ばれる独自のシステムだ。このルールの例外の1つ、zlibはAndroid OS自体の一部とみなされているので、Androidを実行するすべてのデバイスで利用可能になっている。  

Androidではどのような特定ライブラリーの存在について保証されていないので、アプリケーションにはそれぞれ自身の依存関係が含まれていることが要求される。  

Emacsは`ndk-build`システムではビルドされず、AutoconfとMakeによってビルドされる。  

とはいえMakeをベースにする点では似ている`ndk-build`システムを使用する、ビルドは依存関係を含めてサポートしている。  

`ndk-build`を通じてビルドされた依存関係を使用するには、以下のようにEmacsが``Android.mk``ファイルが検索するディレクトリーのリストを指定しなければならない:  

```bash
./configure "--with-ndk-path=directory1 directory2"
```

`libc++_shared.so`が見つからないことに関して`configure`が告げるようであれば、NDKのコピーにそのファイルを配置して、以下のように指定しなければならない:  

  ./configure --with-ndk-cxx-shared=/path/to/sysroot/libc++_shared.so

そうすればEmacsはそれぞれのディレクトリーにある`Android.mk`を読み込んで自動的にビルド、それらのモジュールを使用するだろう。  

Intelシステム向けにビルドする際には一部の`ndk-build`モジュール用に、EシステムにNetwideアセンブラーが存在する必要があるが、これは通常だと`nasm`配下にインストールされている筈だ。  

GoogleはEmacsの依存関係いくつかにたいして`ndk-build`システムを使用するよう調整話施したが、その多くはEmacs環境で動作させるためのpatchが必要となる。したがって一般的にはわたしたちが提供するポートを用いるのが賢明な選択ではあるものの、参考用に以下のリストとpatchの提供は継続する。  

libpng	- https://android.googlesource.com/platform/external/libpng  
giflib	- https://android.googlesource.com/platform/external/giflib  
(これのAndroid.mkで`$(BUILD_STATIC_LIBRARY)`をincludeする前に`LOCAL_EXPORT_CFLAGS := -I$(LOCAL_PATH)`を追加しなければならない)  

libjpeg-turbo - https://android.googlesource.com/platform/external/libjpeg-turbo  
(これのAndroid.mkで`$(BUILD_SHARED_LIBRARY)`をincludeする前に`LOCAL_EXPORT_C_INCLUDE_DIRS := $(LOCAL_PATH)`を追加しなければならない)  

libxml2	- https://android.googlesource.com/platform/external/libxml2/  
(`--with-ndk-path`にicu4cの依存関係を追加、さらにこのファイルの最後にあるpatchも適用しなければならない)  

icu4c - https://android.googlesource.com/platform/external/icu/  
(このファイルの最後にあるpatchも適用しなければならない)  

sqlite3	- https://android.googlesource.com/platform/external/sqlite/  
(このファイルの最後にあるpatchを適用、さらに`--with-ndk-path`に`dist`ディレクトリーを追加しなければならない)  

libselinux	- https://android.googlesource.com/platform/external/libselinux  
(このファイルの最後にあるpatchを適用、さらに以下の3つの依存関係を入手しなければならない)  

libpackagelistparser - https://android.googlesource.com/platform/system/core/+/refs/heads/nougat-mr1-dev/libpackagelistparser/  
(これのAndroid.mkで`$(BUILD_SHARED_LIBRARY)`をincludeする前に`LOCAL_EXPORT_C_INCLUDE_DIRS := $(LOCAL_PATH)/include`を追加しなければならない)  

libpcre	- https://android.googlesource.com/platform/external/pcre  
libcrypto	- https://android.googlesource.com/platform/external/boringssl  
(ARMシステム向けにビルドする場合にはこのファイルの最後にあるpatchを適用しなければならない)  

これらの依存関係の多くは、現在Android自体のビルドにも使用されている`Android.bp`にポートされている。しかし古いブランチでは未だに以前の`Android.mk`がMakefileとして提供されているので、新たなバージョンに容易に調整できるだろう。  

さらにEmacsの一部の依存関係には、それ自体が`ndk-build'のサポートを提供するものもある。  

libwebp	- https://android.googlesource.com/platform/external/webp  
(armv7デバイスで動作するバイナリを得るには、このファイルの最後にあるpatchを適用しなければならない)  

Emacs開発者によって以下の依存関係についてはARMのAndroidシステムにポートされている:  

gnutls, gmp	- https://sourceforge.net/projects/android-ports-for-gnu-emacs  
(このファイルの最後の方にあるGNUTLSセクションを参考にして欲しい)  

libtiff    	- https://sourceforge.net/projects/android-ports-for-gnu-emacs  
(tiff-4.5.0-emacs.tar.gzを解凍したらそこを`--with-ndk-path`に指定)  

tree-sitter	- https://sourceforge.net/projects/android-ports-for-gnu-emacs  
(このファイルの最後の方にあるTREE-SITTERセクションを参考にして欲しい)  

harfbuzz  	- https://sourceforge.net/projects/android-ports-for-gnu-emacs  
(このファイルの最後の方にあるARFBUZZセクションを参考にして欲しい)  

libxml2       - https://sourceforge.net/projects/android-ports-for-gnu-emacs  
(このファイルの最後の方にあるLIBXML2セクションを参考にして欲しい)  

libjpeg-turbo - https://sourceforge.net/projects/android-ports-for-gnu-emacs  
giflib        - https://sourceforge.net/projects/android-ports-for-gnu-emacs  
libtiff       - https://sourceforge.net/projects/android-ports-for-gnu-emacs  
libpng        - https://sourceforge.net/projects/android-ports-for-gnu-emacs  
(このファイルの最後の方にあるIMAGE LIBRARIESを参考にして欲しい)  

libselinux - https://sourceforge.net/projects/android-ports-for-gnu-emacs  
(このファイルの最後の方にあるSELINUXセクションを参考にして欲しい)  

さらに他の開発者によって以下の依存関係がAndroid システムにポートされている:  

ImageMagick, lcms2 - https://github.com/MolotovCherry/Android-ImageMagick7  
(このファイルの最後の方にあるIMAGEMAGICKセクションを参考にして欲しい)  

Emacsビルドシステムによるndk-buildのエミュレートは非常に初期段階にあるので、未テストかつ些細な変更とは言えないndk-buildを使った依存関係をEmacsで動作させるためには調整を要することだろう。  


## GNUTLS

ndk-buildシステムでビルドできるGnuTLSとそれの依存関係(libgmp、libtasn1、p11-kitなど)の修正済みのコピーはhttps://sourceforge.net/projects/android-ports-for-gnu-emacs で入手できる。  

これらはAndroid 5.0以降を実行するarm64のAndroidシステム、およびAndroid 13以降を実行するarmv7lシステムでしかテストされていないので、他のタイプのマシン向けにビルドした結果は人それぞれだろう。  

GnuTLSとともにEmacsをビルドするためには、上記サイトの以下のアーカイブそれぞれを解凍しなければならない:  

gmp-6.2.1-emacs.tgz  
gnutls-3.8.5-emacs.tar.gz  
(or gnutls-3.8.5-emacs-armv7a.tar.gz on 32-bit systems)  
libtasn1-4.19.0-emacs.tar.gz  
p11-kit-0.24.1-emacs.tar.gz  
nettle-3.8-emacs.tar.gz  

解凍したらそのフォルダーを`--with-ndk-path`に追加する。フォルダー内の`configure`やMakefileを使ってパッケージの個別ビルドを試みてはならない。  


## LIBXML2

同じビルドシステム用に調整したlibxml2のコピーは以下の名前で提供されている:  

libxml2-2.12.4-emacs.tar.gz  

Googleで配布されているバージョンとは対照的に、icu4c(およびC++コンパイラー拡張)への依存関係を削除するために国際化は無効になっている。  


## IMAGE LIBRARIES

以下のようにEmacsが必要とするndk-buildが有効なバージョンのイメージライブラリーも提供されている:  

giflib-5.2.1-emacs.tar.gz  
libjpeg-turbo-3.0.2-emacs.tar.gz  
libpng-1.6.41-emacs.tar.gz  
tiff-4.5.1-emacs.tar.gz  

サポートされているすべてのAndroidシステムとツールチェーンにおいて、libjpeg-turbo-3.0.2-emacs.tar.gz以外はコンパイルできる筈だ。古いarmabiのツールチェーンのようにツールチェーンが原因でコンパイルできなければ、Googleバージョンがよい代替えとなるだろう。  

残りの3つのイメージ関連の依存関係だがlibwebpはアップストリームにおいてndk-buildをサポートしている。ImageMagickは有志によるサードパーティ開発者によってポートされているし、librsvgについては次に述べる。  


## LIBRSVG

librsvgの2.40.xの最終リリースであるLibrsvg 2.40.21,は、Cで実装された最終リリースでもあり、これは以下の名前で提供されている:  

librsvg-2.40.21-emacs.tar.gz  

Pangoがフォントを提供できない環境にたいする互換性のために若干の修正を施してあるものの、結果として得られるlibrsvgバイナリにはテキストを表示できないというという但し書きがつく。PCRE以外にも多くの依存関係が存在する:  

libiconv-1.17-emacs.tar.gz  
libffi-3.4.5-emacs.tar.gz  
pango-1.38.1-emacs.tar.gz  
glib-2.33.14-emacs.tar.gz  
libcroco-0.6.13-emacs.tar.gz  
pixman-0.38.4-emacs.tar.gz  
libxml2-2.12.4-emacs.tar.gz  
gdk-pixbuf-2.22.1-emacs.tar.gz  
giflib-5.2.1-emacs.tar.gz  
libjpeg-turbo-3.0.2-emacs.tar.gz  
libpng-1.6.41-emacs.tar.gz  
tiff-4.5.1-emacs.tar.gz  
cairo-1.16.0-emacs.tar.gz  

これらは他の依存関係と同じように個別に解凍して、それらが提供する内容をコマンドラインで指定しなければならない。これらは最終的なアプリケーションにおよそ8MBの共有ライブラリーとして編入される。librsvgは異なる言語実装に移行されたので、今後のリリースでポートされる可能性は低い。  

これらの依存関係にたいして最新で素晴らしいものを提供する努力は何も費やされていない。むしろ依存関係を満足するために利用できるバージョンの中でも古いバージョン、一般的にはポートがより容易なもっとも古いバージョンが選ばれているからだ。  


## SELINUX

libselinuxのアップストリーム版は以下の名前で提供されている:  

libselinux-3.6-emacs.tar.gz  

そしてSELinuxをサポートする最古のAndroidであるAndroid 4.3以降向けに構成されたツールチェーンでコンパイルする。Googleバージョンに勝る主な利点として、libpackagelistparserとlibcryptoへの依存関係をもたらすGoogle固有の変更がなくなることである。Googleのpcreにはまだその要件が残ったままだ。そしてSELinuxをサポートする最古のAndroidであるAndroid 4.3以降向けに構成されたツールチェーンでコンパイルする。Googleバージョンに勝る主な利点として、libpackagelistparserとlibcryptoへの依存関係をもたらすGoogle固有の変更がなくなることである。Googleのpcreにはまだその要件が残ったままだ。  


## TREE-SITTER

ndk-buildシステムでビルドできるように修正したtree-sitterのコピーもそのURLで見つけられる。tree-sitterとともにEmacsをビルドするには、そのサイトにある以下のtarアーカイブを解凍しなければならない:  

tree-sitter-0.20.7-emacs.tar.gz  

解凍したフォルダーを`--with-ndk-build`に追加する。


## HARFBUZZ

ndk-buildシステムでビルドできるように修正したHarfBuzzもそのURLで見つけられる。HarfBuzzとともにEmacsをビルドするには、そのサイトにある以下のtarアーカイブを解凍しなければならない:  

harfbuzz-7.1.0-emacs.tar.gz  
(Android >4.3でNDK 21.0.x以降を使ってビルドする場合)  

harfbuzz-1.7.7.tar.gz  
(もっと古いNDKやプラットフォームリリースの場合)  

解凍したフォルダーを`--with-ndk-build`に追加する。


## IMAGEMAGICK

Android向けのImageMagickにはサードパーティ製のポートが存在する。残念ながらこのポートではEmacsで使用されているlibpng、libjpeg、libtiff、libwebpと競合するバージョンのpatchも使用されている。MakefileもMS Windows用に記述されているので、このファイルの最後にあるpatchも適用しなければならない。  



## PATCH FOR LIBXML2

このpatchはEmacsをビルドする前に、Googleバージョンのlibxml2のAndroid.mkに適用しなければならない。さらにコミット`edb5870767fed8712a9b77ef34097209b61ab2db`もrevertしなければならない。

```diff
diff --git a/Android.mk b/Android.mk
index 07c7b372..2494274f 100644
--- a/Android.mk
+++ b/Android.mk
@@ -80,6 +80,7 @@ LOCAL_SHARED_LIBRARIES := libicuuc
 LOCAL_MODULE:= libxml2
 LOCAL_CLANG := true
 LOCAL_ADDITIONAL_DEPENDENCIES += $(LOCAL_PATH)/Android.mk
+LOCAL_EXPORT_C_INCLUDES += $(LOCAL_PATH)/include
 include $(BUILD_SHARED_LIBRARY)
 
 # For the host
@@ -94,3 +95,5 @@ LOCAL_MODULE := libxml2
 LOCAL_CLANG := true
 LOCAL_ADDITIONAL_DEPENDENCIES += $(LOCAL_PATH)/Android.mk
 include $(BUILD_HOST_STATIC_LIBRARY)
+
+$(call import-module,libicuuc)
```

## PATCH FOR ICU

Emacs用にビルド可能にするには、Google版のicuのicu4j/Android.mkにこのpatchを適用しなければならない。  

```diff
diff --git a/icu4j/Android.mk b/icu4j/Android.mk
index d1ab3d5..69eff81 100644
--- a/icu4j/Android.mk
+++ b/icu4j/Android.mk
@@ -69,7 +69,7 @@ include $(BUILD_STATIC_JAVA_LIBRARY)
 # Path to the ICU4C data files in the Android device file system:
 icu4c_data := /system/usr/icu
 icu4j_config_root := $(LOCAL_PATH)/main/classes/core/src
-include external/icu/icu4j/adjust_icudt_path.mk
+include $(LOCAL_PATH)/adjust_icudt_path.mk
 
 include $(CLEAR_VARS)
 LOCAL_SRC_FILES := $(icu4j_src_files)

diff --git a/icu4c/source/common/Android.mk b/icu4c/source/common/Android.mk
index 8e5f757..44bb130 100644
--- a/icu4c/source/common/Android.mk
+++ b/icu4c/source/common/Android.mk
@@ -231,7 +231,7 @@ include $(CLEAR_VARS)
 LOCAL_SRC_FILES += $(src_files)
 LOCAL_C_INCLUDES += $(c_includes) $(optional_android_logging_includes)
 LOCAL_CFLAGS += $(local_cflags) -DPIC -fPIC
-LOCAL_SHARED_LIBRARIES += libdl $(optional_android_logging_libraries)
+LOCAL_SHARED_LIBRARIES += libdl libstdc++ $(optional_android_logging_libraries)
 LOCAL_MODULE_TAGS := optional
 LOCAL_MODULE := libicuuc
 LOCAL_RTTI_FLAG := -frtti
```

## PATCH FOR SQLITE3

```diff
diff --git a/dist/Android.mk b/dist/Android.mk
index bf277d2..36734d9 100644
--- a/dist/Android.mk
+++ b/dist/Android.mk
@@ -141,6 +141,7 @@ include $(BUILD_HOST_EXECUTABLE)
 include $(CLEAR_VARS)
 LOCAL_SRC_FILES := $(common_src_files)
 LOCAL_CFLAGS += $(minimal_sqlite_flags)
+LOCAL_EXPORT_C_INCLUDES += $(LOCAL_PATH)
 LOCAL_MODULE:= libsqlite_static_minimal
 LOCAL_SDK_VERSION := 23
 include $(BUILD_STATIC_LIBRARY)

diff --git a/dist/sqlite3.c b/dist/sqlite3.c
index b0536a4..8fa1ee9 100644
--- a/dist/sqlite3.c
+++ b/dist/sqlite3.c
@@ -26474,7 +26474,7 @@ SQLITE_PRIVATE const char *sqlite3OpcodeName(int i){
 */
 #if !defined(HAVE_POSIX_FALLOCATE) \
       && (_XOPEN_SOURCE >= 600 || _POSIX_C_SOURCE >= 200112L)
-# define HAVE_POSIX_FALLOCATE 1
+/* # define HAVE_POSIX_FALLOCATE 1 */
 #endif
 
 /*
```

## PATCH FOR WEBP

```diff
diff --git a/Android.mk b/Android.mk
index c7bcb0f5..d4da1704 100644
--- a/Android.mk
+++ b/Android.mk
@@ -28,9 +28,10 @@ ifneq ($(findstring armeabi-v7a, $(TARGET_ARCH_ABI)),)
   # Setting LOCAL_ARM_NEON will enable -mfpu=neon which may cause illegal
   # instructions to be generated for armv7a code. Instead target the neon code
   # specifically.
-  NEON := c.neon
-  USE_CPUFEATURES := yes
-  WEBP_CFLAGS += -DHAVE_CPU_FEATURES_H
+  # NEON := c.neon
+  # USE_CPUFEATURES := yes
+  # WEBP_CFLAGS += -DHAVE_CPU_FEATURES_H
+  NEON := c
 else
   NEON := c
 endif
```

## PATCHES FOR SELINUX

```diff
diff --git a/Android.mk b/Android.mk
index 659232e..1e64fd6 100644
--- a/Android.mk
+++ b/Android.mk
@@ -116,3 +116,7 @@ LOCAL_STATIC_LIBRARIES := libselinux
 LOCAL_WHOLE_STATIC_LIBRARIES := libpcre
 LOCAL_C_INCLUDES := external/pcre
 include $(BUILD_HOST_EXECUTABLE)
+
+$(call import-module,libpcre)
+$(call import-module,libpackagelistparser)
+$(call import-module,libcrypto)

diff --git a/src/android.c b/src/android.c
index 5206a9f..b351ffc 100644
--- a/src/android.c
+++ b/src/android.c
@@ -21,8 +21,7 @@
 #include <selinux/label.h>
 #include <selinux/avc.h>
 #include <openssl/sha.h>
-#include <private/android_filesystem_config.h>
-#include <log/log.h>
+#include <android/log.h>
 #include "policy.h"
 #include "callbacks.h"
 #include "selinux_internal.h"
@@ -686,6 +685,7 @@ static int seapp_context_lookup(enum seapp_kind kind,
 		seinfo = parsedseinfo;
 	}
 
+#if 0
 	userid = uid / AID_USER;
 	isOwner = (userid == 0);
 	appid = uid % AID_USER;
@@ -702,9 +702,13 @@ static int seapp_context_lookup(enum seapp_kind kind,
 		username = "_app";
 		appid -= AID_APP;
 	} else {
+#endif
 		username = "_isolated";
+		appid = 0;
+#if 0
 		appid -= AID_ISOLATED_START;
 	}
+#endif
 
 	if (appid >= CAT_MAPPING_MAX_ID || userid >= CAT_MAPPING_MAX_ID)
 		goto err;
@@ -1662,8 +1666,10 @@ int selinux_log_callback(int type, const char *fmt, ...)
 
     va_start(ap, fmt);
     if (vasprintf(&strp, fmt, ap) != -1) {
+#if 0
         LOG_PRI(priority, "SELinux", "%s", strp);
         LOG_EVENT_STRING(AUDITD_LOG_TAG, strp);
+#endif
         free(strp);
     }
     va_end(ap);
```

## PATCH FOR BORINGSSL

```diff
diff --git a/Android.mk b/Android.mk
index 3e3ef2a..277d4a9 100644
--- a/Android.mk
+++ b/Android.mk
@@ -27,7 +27,9 @@ LOCAL_MODULE := libcrypto
 LOCAL_EXPORT_C_INCLUDE_DIRS := $(LOCAL_PATH)/src/include
 LOCAL_ADDITIONAL_DEPENDENCIES := $(LOCAL_PATH)/Android.mk $(LOCAL_PATH)/crypto-sources.mk
 LOCAL_CFLAGS += -fvisibility=hidden -DBORINGSSL_SHARED_LIBRARY -DBORINGSSL_IMPLEMENTATION -DOPENSSL_SMALL -Wno-unused-parameter
+LOCAL_CFLAGS_arm = -DOPENSSL_STATIC_ARMCAP -DOPENSSL_NO_ASM
 LOCAL_SDK_VERSION := 9
+LOCAL_LDFLAGS = --no-undefined
 # sha256-armv4.S does not compile with clang.
 LOCAL_CLANG_ASFLAGS_arm += -no-integrated-as
 LOCAL_CLANG_ASFLAGS_arm64 += -march=armv8-a+crypto
diff --git a/sources.mk b/sources.mk
index e82f3d5..be3a3c4 100644
--- a/sources.mk
+++ b/sources.mk
@@ -337,20 +337,20 @@ linux_aarch64_sources := \
   linux-aarch64/crypto/sha/sha256-armv8.S\
   linux-aarch64/crypto/sha/sha512-armv8.S\
 
-linux_arm_sources := \
-  linux-arm/crypto/aes/aes-armv4.S\
-  linux-arm/crypto/aes/aesv8-armx32.S\
-  linux-arm/crypto/aes/bsaes-armv7.S\
-  linux-arm/crypto/bn/armv4-mont.S\
-  linux-arm/crypto/modes/ghash-armv4.S\
-  linux-arm/crypto/modes/ghashv8-armx32.S\
-  linux-arm/crypto/sha/sha1-armv4-large.S\
-  linux-arm/crypto/sha/sha256-armv4.S\
-  linux-arm/crypto/sha/sha512-armv4.S\
-  src/crypto/chacha/chacha_vec_arm.S\
-  src/crypto/cpu-arm-asm.S\
-  src/crypto/curve25519/asm/x25519-asm-arm.S\
-  src/crypto/poly1305/poly1305_arm_asm.S\
+# linux_arm_sources := \
+#   linux-arm/crypto/aes/aes-armv4.S\
+#   linux-arm/crypto/aes/aesv8-armx32.S\
+#   linux-arm/crypto/aes/bsaes-armv7.S\
+#   linux-arm/crypto/bn/armv4-mont.S\
+#   linux-arm/crypto/modes/ghash-armv4.S\
+#   linux-arm/crypto/modes/ghashv8-armx32.S\
+#   linux-arm/crypto/sha/sha1-armv4-large.S\
+#   linux-arm/crypto/sha/sha256-armv4.S\
+#   linux-arm/crypto/sha/sha512-armv4.S\
+#   src/crypto/chacha/chacha_vec_arm.S\
+#   src/crypto/cpu-arm-asm.S\
+#   src/crypto/curve25519/asm/x25519-asm-arm.S\
+#   src/crypto/poly1305/poly1305_arm_asm.S\
 
 linux_x86_sources := \
   linux-x86/crypto/aes/aes-586.S\
```

## PATCH FOR IMAGEMAGICK

```diff
diff --git a/Android.mk b/Android.mk
index 5ab6699..4441417 100644
--- a/Android.mk
+++ b/Android.mk
@@ -52,6 +52,20 @@ LZMA_LIB_PATH                   := $(LOCAL_PATH)/xz-5.2.4
 BZLIB_LIB_PATH                  := $(LOCAL_PATH)/bzip-1.0.8
 LCMS_LIB_PATH                   := $(LOCAL_PATH)/liblcms2-2.9
 
+LIBBZ2_ENABLED        := true
+LIBFFTW_ENABLED       := true
+LIBFREETYPE2_ENABLED  := true
+LIBJPEG_TURBO_ENABLED := true
+LIBLZMA_ENABLED       := true
+LIBOPENJPEG_ENABLED   := true
+LIBPNG_ENABLED        := true
+LIBTIFF_ENABLED       := true
+LIBWEBP_ENABLED       := true
+LIBXML2_ENABLED       := true
+LIBZLIB_ENABLED       := true
+LIBLCMS2_ENABLED      := true
+BUILD_MAGICKWAND      := true
+
 #-------------------------------------------------------------
 # Include all modules
 #-------------------------------------------------------------
@@ -68,6 +82,9 @@ include $(MAKE_PATH)/libjpeg-turbo.mk
 # libopenjpeg
 include $(MAKE_PATH)/libopenjpeg.mk
 
+# libwebp
+include $(MAKE_PATH)/libwebp.mk
+
 # libtiff
 include $(MAKE_PATH)/libtiff.mk
 
@@ -77,9 +94,6 @@ include $(MAKE_PATH)/libpng.mk
 # libfreetype2
 include $(MAKE_PATH)/libfreetype2.mk
 
-# libwebp
-include $(MAKE_PATH)/libwebp.mk
-
 # libfftw
 include $(MAKE_PATH)/libfftw.mk
 
diff --git a/libjpeg-turbo-2.0.2/jconfig.h b/libjpeg-turbo-2.0.2/jconfig.h
index 47d14c9..5c6f8ee 100644
--- a/libjpeg-turbo-2.0.2/jconfig.h
+++ b/libjpeg-turbo-2.0.2/jconfig.h
@@ -1,57 +1,43 @@
-/* autogenerated jconfig.h based on Android.mk var JCONFIG_FLAGS */ 
+/* autogenerated jconfig.h based on Android.mk var JCONFIG_FLAGS */
 #ifndef JPEG_LIB_VERSION
 #define JPEG_LIB_VERSION 62
 #endif
-
 #ifndef LIBJPEG_TURBO_VERSION
 #define LIBJPEG_TURBO_VERSION 2.0.2
 #endif
-
 #ifndef LIBJPEG_TURBO_VERSION_NUMBER
 #define LIBJPEG_TURBO_VERSION_NUMBER 202
 #endif
-
 #ifndef C_ARITH_CODING_SUPPORTED
 #define C_ARITH_CODING_SUPPORTED
 #endif
-
 #ifndef D_ARITH_CODING_SUPPORTED
 #define D_ARITH_CODING_SUPPORTED
 #endif
-
 #ifndef MEM_SRCDST_SUPPORTED
 #define MEM_SRCDST_SUPPORTED
 #endif
-
 #ifndef WITH_SIMD
 #define WITH_SIMD
 #endif
-
 #ifndef BITS_IN_JSAMPLE
 #define BITS_IN_JSAMPLE 8
 #endif
-
 #ifndef HAVE_LOCALE_H
 #define HAVE_LOCALE_H
 #endif
-
 #ifndef HAVE_STDDEF_H
 #define HAVE_STDDEF_H
 #endif
-
 #ifndef HAVE_STDLIB_H
 #define HAVE_STDLIB_H
 #endif
-
 #ifndef NEED_SYS_TYPES_H
 #define NEED_SYS_TYPES_H
 #endif
-
 #ifndef HAVE_UNSIGNED_CHAR
 #define HAVE_UNSIGNED_CHAR
 #endif
-
 #ifndef HAVE_UNSIGNED_SHORT
 #define HAVE_UNSIGNED_SHORT
 #endif
-
diff --git a/libxml2-2.9.9/encoding.c b/libxml2-2.9.9/encoding.c
index a3aaf10..60f165b 100644
--- a/libxml2-2.9.9/encoding.c
+++ b/libxml2-2.9.9/encoding.c
@@ -2394,7 +2394,6 @@ xmlCharEncOutput(xmlOutputBufferPtr output, int init)
 {
     int ret;
     size_t written;
-    size_t writtentot = 0;
     size_t toconv;
     int c_in;
     int c_out;
@@ -2451,7 +2450,6 @@ retry:
                             xmlBufContent(in), &c_in);
     xmlBufShrink(in, c_in);
     xmlBufAddLen(out, c_out);
-    writtentot += c_out;
     if (ret == -1) {
         if (c_out > 0) {
             /* Can be a limitation of iconv or uconv */
@@ -2536,7 +2534,6 @@ retry:
 	    }
 
             xmlBufAddLen(out, c_out);
-            writtentot += c_out;
             goto retry;
 	}
     }
@@ -2567,9 +2564,7 @@ xmlCharEncOutFunc(xmlCharEncodingHandler *handler, xmlBufferPtr out,
                   xmlBufferPtr in) {
     int ret;
     int written;
-    int writtentot = 0;
     int toconv;
-    int output = 0;
 
     if (handler == NULL) return(-1);
     if (out == NULL) return(-1);
@@ -2612,7 +2607,6 @@ retry:
                             in->content, &toconv);
     xmlBufferShrink(in, toconv);
     out->use += written;
-    writtentot += written;
     out->content[out->use] = 0;
     if (ret == -1) {
         if (written > 0) {
@@ -2622,8 +2616,6 @@ retry:
         ret = -3;
     }
 
-    if (ret >= 0) output += ret;
-
     /*
      * Attempt to handle error cases
      */
@@ -2700,7 +2692,6 @@ retry:
 	    }
 
             out->use += written;
-            writtentot += written;
             out->content[out->use] = 0;
             goto retry;
 	}
diff --git a/libxml2-2.9.9/xpath.c b/libxml2-2.9.9/xpath.c
index 5e3bb9f..505ec82 100644
--- a/libxml2-2.9.9/xpath.c
+++ b/libxml2-2.9.9/xpath.c
@@ -10547,7 +10547,7 @@ xmlXPathCompFilterExpr(xmlXPathParserContextPtr ctxt) {
 
 static xmlChar *
 xmlXPathScanName(xmlXPathParserContextPtr ctxt) {
-    int len = 0, l;+    int l;
     int c;
     const xmlChar *cur;
     xmlChar *ret;
@@ -10567,7 +10567,6 @@ xmlXPathScanName(xmlXPathParserContextPtr ctxt) {
 	    (c == '_') || (c == ':') ||
 	    (IS_COMBINING(c)) ||
 	    (IS_EXTENDER(c)))) {
-	len += l;
 	NEXTL(l);
 	c = CUR_CHAR(l);
     }
diff --git a/make/libicu4c.mk b/make/libicu4c.mk
index 21ec121..8b77865 100644
--- a/make/libicu4c.mk
+++ b/make/libicu4c.mk
@@ -250,7 +250,7 @@ LOCAL_MODULE    := libicuuc
 LOCAL_SRC_FILES := $(src_files)
 
 # when built in android, they require uconfig_local (because of android project), but we don't need this
-$(shell > $(ICU_COMMON_PATH)/unicode/uconfig_local.h echo /* Autogenerated stub file to make libicuuc build happy */) \
+$(shell > $(ICU_COMMON_PATH)/unicode/uconfig_local.h echo /\* Autogenerated stub file to make libicuuc build happy \*/) \
 
 ifeq ($(LIBXML2_ENABLED),true)
     include $(BUILD_STATIC_LIBRARY)
diff --git a/make/libjpeg-turbo.mk b/make/libjpeg-turbo.mk
index d39dd41..fdebcf3 100644
--- a/make/libjpeg-turbo.mk
+++ b/make/libjpeg-turbo.mk
@@ -230,30 +230,30 @@ JCONFIG_FLAGS += \
     HAVE_UNSIGNED_SHORT
 
 JCONFIGINT_FLAGS += \
-    BUILD="20190814" \
-    PACKAGE_NAME="libjpeg-turbo" \
-    VERSION="2.0.2"
+    BUILD=\"20190814\" \
+    PACKAGE_NAME=\"libjpeg-turbo\" \
+    VERSION=\"2.0.2\"
 
 # originally defined in jconfigint.h, but the substitution has problems with spaces
 LOCAL_CFLAGS := \
     -DINLINE="inline __attribute__((always_inline))"
 
 # create definition file jconfig.h, needed in order to build
-$(shell echo /* autogenerated jconfig.h based on Android.mk var JCONFIG_FLAGS */ > $(JPEG_LIB_PATH)/jconfig.h)
+$(shell echo \/\* autogenerated jconfig.h based on Android.mk var JCONFIG_FLAGS \*\/ > $(JPEG_LIB_PATH)/jconfig.h)
 $(foreach name,$(JCONFIG_FLAGS), \
     $(if $(findstring =,$(name)), \
-        $(shell >>$(JPEG_LIB_PATH)/jconfig.h echo #ifndef $(firstword $(subst =, ,$(name)))) \
+        $(shell >>$(JPEG_LIB_PATH)/jconfig.h echo \#ifndef $(firstword $(subst =, ,$(name)))) \
     , \
-        $(shell >>$(JPEG_LIB_PATH)/jconfig.h echo #ifndef $(name)) \
+        $(shell >>$(JPEG_LIB_PATH)/jconfig.h echo \#ifndef $(name)) \
     ) \
-    $(shell >>$(JPEG_LIB_PATH)/jconfig.h echo #define $(subst =, ,$(name))) \
-    $(shell >>$(JPEG_LIB_PATH)/jconfig.h echo #endif) \
+    $(shell >>$(JPEG_LIB_PATH)/jconfig.h echo \#define $(subst =, ,$(name))) \
+    $(shell >>$(JPEG_LIB_PATH)/jconfig.h echo \#endif) \
     $(shell >> $(JPEG_LIB_PATH)/jconfig.h echo.) \
 )
 
 # create definition file jconfigint.h, needed in order to build
-$(shell >$(JPEG_LIB_PATH)/jconfigint.h echo /* autogenerated jconfigint.h based on Android.mk vars JCONFIGINT_FLAGS */)
-$(foreach name,$(JCONFIGINT_FLAGS),$(shell >>$(JPEG_LIB_PATH)/jconfigint.h echo #define $(subst =, ,$(name))))
+$(shell >$(JPEG_LIB_PATH)/jconfigint.h echo /\* autogenerated jconfigint.h based on Android.mk vars JCONFIGINT_FLAGS \*/)
+$(foreach name,$(JCONFIGINT_FLAGS),$(shell >>$(JPEG_LIB_PATH)/jconfigint.h echo \#define $(subst =, ,$(name))))
 
 ifeq ($(LIBJPEG_TURBO_ENABLED),true)
     include $(BUILD_STATIC_LIBRARY)
diff --git a/make/liblcms2.mk b/make/liblcms2.mk
index e1fd3b9..29ca791 100644
--- a/make/liblcms2.mk
+++ b/make/liblcms2.mk
@@ -10,6 +10,10 @@ LOCAL_C_INCLUDES := \
     $(LCMS_LIB_PATH)/include \
     $(LCMS_LIB_PATH)/src
 
+LOCAL_EXPORT_C_INCLUDES := \
+    $(LCMS_LIB_PATH) \
+    $(LCMS_LIB_PATH)/include \
+    $(LCMS_LIB_PATH)/src
 
 LOCAL_CFLAGS := \
     -DHAVE_FUNC_ATTRIBUTE_VISIBILITY=1 \
diff --git a/make/libmagick++-7.mk b/make/libmagick++-7.mk
index 5352ccb..929396d 100644
--- a/make/libmagick++-7.mk
+++ b/make/libmagick++-7.mk
@@ -12,7 +12,7 @@ LOCAL_C_INCLUDES  :=  \
 
 ifneq ($(STATIC_BUILD),true)
     LOCAL_LDFLAGS += -fexceptions
-    LOCAL_LDLIBS    := -L$(SYSROOT)/usr/lib -llog -lz
+    LOCAL_LDLIBS    := -llog -lz
 endif
 
 LOCAL_SRC_FILES := \
diff --git a/make/libmagickcore-7.mk b/make/libmagickcore-7.mk
index 81293b2..d51fced 100644
--- a/make/libmagickcore-7.mk
+++ b/make/libmagickcore-7.mk
@@ -25,6 +25,7 @@ else ifeq ($(TARGET_ARCH_ABI),x86_64)
     
 endif
 
+LOCAL_EXPORT_C_INCLUDES += $(IMAGE_MAGICK)
 
 LOCAL_C_INCLUDES  += \
     $(IMAGE_MAGICK) \
@@ -45,10 +46,9 @@ LOCAL_C_INCLUDES  += \
     $(BZLIB_LIB_PATH) \
     $(LCMS_LIB_PATH)/include
 
-
 ifneq ($(STATIC_BUILD),true)
 # ignored in static library builds
-    LOCAL_LDLIBS    := -L$(SYSROOT)/usr/lib -llog -lz
+    LOCAL_LDLIBS    := -llog -lz
 endif
 
 
diff --git a/make/libmagickwand-7.mk b/make/libmagickwand-7.mk
index 7be2fb6..0bbcca5 100644
--- a/make/libmagickwand-7.mk
+++ b/make/libmagickwand-7.mk
@@ -14,7 +14,7 @@ LOCAL_C_INCLUDES  :=  \
 
 # always ignored in static builds
 ifneq ($(STATIC_BUILD),true)
-    LOCAL_LDLIBS    := -L$(SYSROOT)/usr/lib -llog -lz
+    LOCAL_LDLIBS    := -llog -lz
 endif
 
 LOCAL_SRC_FILES := \
@@ -54,6 +54,29 @@ ifeq ($(OPENCL_BUILD),true)
     LOCAL_SHARED_LIBRARIES += libopencl
 endif
 
+LOCAL_SHARED_LIBRARIES += libstdc++
+
+ifeq ($(TARGET_ARCH_ABI),arm64-v8a)
+    LOCAL_EXPORT_C_INCLUDES += $(IMAGE_MAGICK)/configs/arm64
+    LOCAL_C_INCLUDES += $(IMAGE_MAGICK)/configs/arm64
+else ifeq ($(TARGET_ARCH_ABI),armeabi-v7a)  
+    LOCAL_EXPORT_C_INCLUDES += $(IMAGE_MAGICK)/configs/arm
+    LOCAL_C_INCLUDES += $(IMAGE_MAGICK)/configs/arm
+else ifeq ($(TARGET_ARCH_ABI),x86)
+    LOCAL_EXPORT_C_INCLUDES += $(IMAGE_MAGICK)/configs/x86
+    LOCAL_C_INCLUDES += $(IMAGE_MAGICK)/configs/x86
+else ifeq ($(TARGET_ARCH_ABI),x86_64)
+    LOCAL_EXPORT_C_INCLUDES += $(IMAGE_MAGICK)/configs/x86-64
+    LOCAL_C_INCLUDES += $(IMAGE_MAGICK)/configs/x86-64
+    
+    ifneq ($(STATIC_BUILD),true)
+        LOCAL_LDFLAGS += -latomic
+    endif
+    
+endif
+
+LOCAL_EXPORT_C_INCLUDES += $(IMAGE_MAGICK)
+
 ifeq ($(BUILD_MAGICKWAND),true)
     ifeq ($(STATIC_BUILD),true)
         LOCAL_STATIC_LIBRARIES := \
diff --git a/make/libpng.mk b/make/libpng.mk
index 24fb8ac..dda05fd 100644
--- a/make/libpng.mk
+++ b/make/libpng.mk
@@ -30,6 +30,7 @@ ifeq ($(TARGET_ARCH_ABI), arm64-v8a)
 endif # TARGET_ARCH_ABI == arm64-v8a
 
 
+LOCAL_EXPORT_C_INCLUDES := $(PNG_LIB_PATH)
 LOCAL_C_INCLUDES := $(PNG_LIB_PATH)
 
 LOCAL_SRC_FILES += \
diff --git a/make/libtiff.mk b/make/libtiff.mk
index ca43f25..2b17508 100644
--- a/make/libtiff.mk
+++ b/make/libtiff.mk
@@ -12,6 +12,9 @@ LOCAL_C_INCLUDES :=  \
     $(LZMA_LIB_PATH)/liblzma/api \
     $(WEBP_LIB_PATH)/src
 
+LOCAL_EXPORT_C_INCLUDES :=  \
+    $(TIFF_LIB_PATH)
+
 ifeq ($(LIBLZMA_ENABLED),true)
     LOCAL_CFLAGS += -DLZMA_SUPPORT=1
 endif
diff --git a/make/magick.mk b/make/magick.mk
index 3ba4b1d..5471608 100644
--- a/make/magick.mk
+++ b/make/magick.mk
@@ -18,7 +18,7 @@ LOCAL_C_INCLUDES  :=  \
     $(FREETYPE_LIB_PATH)/include
 
 
-LOCAL_LDLIBS    := -L$(SYSROOT)/usr/lib -llog -lz
+LOCAL_LDLIBS    := -llog -lz
 LOCAL_SRC_FILES := \
     $(IMAGE_MAGICK)/utilities/magick.c \
``` 


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
