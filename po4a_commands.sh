po4a-gettextize -o neverwrap=1 -o nobullets=1 -f text -m README -p README.pot
perl -l -000 -pe s/^|$/\n/g if 2 != s/\n/ /g -- README
