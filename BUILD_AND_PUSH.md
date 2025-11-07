scripts\build-apk.bat

flutter build apk --release

scripts\git-push.bat

git add .
git commit -m "Your commit message here"
git push

scripts\build-apk.bat
scripts\git-push.bat
