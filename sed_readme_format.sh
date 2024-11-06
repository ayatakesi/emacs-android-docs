#!/bin/sh

for ORIGINAL in README emacs-30/java/INSTALL emacs-30/admin/notes/java emacs-30/cross/ndk-build/README
do
    EDITABLE_FILE=${ORIGINAL}_editable;
    PERL_OUT=$(mktemp);
    PO4A_OUT=$(mktemp);
    MSGCAT_OUT=$(mktemp);
    RM_FILES="$RM_FILES $PERL_OUT $PO4A_OUT $MSGCAT_OUT";
    cat $ORIGINAL >$PERL_OUT;
    cp -p $PERL_OUT $EDITABLE_FILE;
    po4a-gettextize -o nobullets=1 -f text -m $EDITABLE_FILE -p $PO4A_OUT;
    msgcat --no-wrap $PO4A_OUT >$MSGCAT_OUT;
    cp -pf $MSGCAT_OUT ${EDITABLE_FILE}.pot;
done

rm -fr "$RM_FILES";


