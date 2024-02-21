@echo off
echo Building SUAI LeetCode Bot

md build
md build\config
md build\libs
md build\db
md build\logs

dart pub get
dart pub run build_runner build --delete-conflicting-outputs
dart compile exe bin/suai_leetcode_bot.dart -o build/suai_leetcode_bot.exe

copy bin\config\example.env.config.json build\config\env.config.json
copy bin\libs\sqlite3.dll build\libs\sqlite3.dll

echo Build complete
