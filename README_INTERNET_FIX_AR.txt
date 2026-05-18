تم إضافة صلاحيات الإنترنت إلى نسخة Flutter:

- android.permission.INTERNET
- android.permission.ACCESS_NETWORK_STATE

هذه الصلاحيات تساعد التطبيق على الاتصال بـ:
https://api.telegram.org

بعد فك الضغط شغّل:
flutter clean
flutter pub get
flutter build apk --release

ثم ثبت APK الجديد.

إذا بقي خطأ Failed host lookup:
- جرّب فتح https://api.telegram.org من متصفح الهاتف.
- جرّب شبكة أخرى أو VPN أو DNS مختلف.
