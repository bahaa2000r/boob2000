@echo off
chcp 65001 >nul
echo تجهيز مشروع الدود ماركت Flutter Android Final...
flutter create --platforms=android .
flutter pub get
echo.
echo لتشغيل التطبيق:
echo flutter run
pause
