#!/bin/sh
mv clucene/src/shared/CLucene/util/dirent.h clucene/src/shared/CLucene/util/_dirent.h
sed -i '' 's/\([/"]\)dirent.h"/\1_dirent.h"/g' ./clucene/src/shared/CLucene/util/*.cpp
