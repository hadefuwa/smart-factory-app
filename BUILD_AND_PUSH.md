scripts\build-apk.bat

Copy-Item "build\app\outputs\flutter-apk\app-release.apk" "releases\smart-factory-v1.0.6.apk" -Force

scripts\git-push.bat
