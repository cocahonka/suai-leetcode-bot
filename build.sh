#!/bin/bash

echo "Building SUAI LeetCode Bot"

mkdir -p build/config
mkdir -p build/libs
mkdir -p build/db
mkdir -p build/logs

dart pub get
dart pub run build_runner build --delete-conflicting-outputs
dart compile exe bin/suai_leetcode_bot.dart -o build/suai_leetcode_bot

cp bin/config/example.env.config.json build/config/env.config.json
cp bin/libs/sqlite3.so build/libs/sqlite3.so

echo "Build complete"
