# Housekeeping App – Kurulum Dokümanı

Flutter tabanlı otel housekeeping yönetim uygulaması.
- **Supervisor**: Web/Tablet panel (personel, CSV import, görev atama, dashboard)
- **Maid**: Mobil (iOS/Android) görev listesi ve durum güncelleme

---

## Gereksinimler

| Araç | Sürüm |
|------|-------|
| Flutter | >= 3.19 |
| Dart | >= 3.0 |
| Supabase CLI | >= 1.170 |
| Firebase CLI | >= 13 |
| Node.js (Edge Fn) | >= 18 |

---

## 1. Supabase Kurulumu

### 1.1 Proje Oluştur
Supabase Dashboard → New Project → proje bilgilerini not al.

### 1.2 SQL Migration Çalıştır
Supabase Dashboard → SQL Editor:
```
hk_app/supabase/migrations/001_schema.sql   -- Tablo oluşturma
hk_app/supabase/migrations/002_rls.sql      -- RLS politikaları
```

### 1.3 Test Verisi
**Önce** Supabase Dashboard → Authentication → Users'dan şu kullanıcıları oluştur:

| E-posta | Şifre | Rol |
|---------|-------|-----|
| supervisor@hotel.com | Test1234! | supervisor |
| maid1@hotel.com | Test1234! | maid |
| maid2@hotel.com | Test1234! | maid |
| maid3@hotel.com | Test1234! | maid |

Kullanıcıları oluşturduktan sonra her birinin UUID'sini kopyalayıp
`003_test_data.sql` içindeki placeholder UUID'leri güncelle.
Sonra SQL Editor'de çalıştır.

### 1.4 Service Role Key
Dashboard → Settings → API → service_role key'i kopyala.
Bu key sadece Edge Function için kullanılacak (Flutter'a verilmez).

---

## 2. Firebase Kurulumu (FCM)

```bash
# FlutterFire CLI kur
dart pub global activate flutterfire_cli

# Flutter proje klasöründe çalıştır
cd hk_app
flutterfire configure
```

Bu komut `google-services.json` (Android) ve `GoogleService-Info.plist` (iOS) dosyalarını oluşturur.

Android: `android/app/google-services.json`
iOS: `ios/Runner/GoogleService-Info.plist`

### 2.1 FCM Server Key
Firebase Console → Project Settings → Cloud Messaging → Server key kopyala.

---

## 3. Ortam Değişkenleri

`hk_app/assets/env.txt` dosyasını düzenle:

```
SUPABASE_URL=https://PROJE_ID.supabase.co
SUPABASE_ANON_KEY=eyJ...
```

---

## 4. Supabase Edge Function Deploy

```bash
cd hk_app

# Supabase CLI ile login
supabase login

# Projeyi bağla
supabase link --project-ref PROJE_ID

# FCM key sırrını ayarla
supabase secrets set FCM_SERVER_KEY=AAAA...FCM_KEY
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=eyJ...

# Edge function deploy et
supabase functions deploy send-push
```

---

## 5. Flutter Uygulamasını Çalıştır

```bash
cd hk_app
flutter pub get

# Android
flutter run -d android

# iOS
flutter run -d ios

# Web (Supervisor panel)
flutter run -d chrome
```

---

## 6. Android Ek Yapılandırma

`android/app/build.gradle`:
```gradle
android {
    compileSdkVersion 34
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

`android/build.gradle` (proje seviyesi):
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.4.1'
}
```

`android/app/build.gradle` (en alta ekle):
```gradle
apply plugin: 'com.google.gms.google-services'
```

---

## 7. iOS Ek Yapılandırma

`ios/Runner/Info.plist` içine ekle:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

Xcode → Signing & Capabilities → + Capability → Push Notifications

---

## 8. CSV Import Formatı

Supervisor panelinden oda listesi yüklemek için CSV şablonu:

```csv
room_no,floor,task_type
101,1,checkout
102,1,stayover
201,2,arrival
```

`task_type` değerleri: `checkout`, `stayover`, `arrival`

---

## 9. Test Verisi Özeti

- **1 Supervisor**: Ali Yılmaz (supervisor@hotel.com)
- **3 Maid**: Fatma Kaya, Zeynep Demir, Ayşe Çelik
- **10 Oda**: 101–104 (Kat 1), 201–202 (Kat 2), 203, 301–303 (Kat 3)

---

## 10. Proje Yapısı

```
hk_app/
├── lib/
│   ├── main.dart                    # Uygulama giriş noktası
│   ├── app.dart                     # Router (supervisor/maid yönlendirme)
│   ├── core/
│   │   ├── constants.dart
│   │   └── supabase_client.dart
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── task_model.dart
│   │   └── audit_log_model.dart
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── auth_provider.dart       # ChangeNotifier
│   │   ├── task_service.dart
│   │   ├── audit_service.dart
│   │   └── fcm_service.dart
│   └── screens/
│       ├── login_screen.dart
│       ├── supervisor/
│       │   ├── supervisor_home.dart
│       │   ├── dashboard_screen.dart
│       │   ├── task_assign.dart     # Filtrele + toplu atama
│       │   ├── room_import.dart     # CSV upload
│       │   └── staff_management.dart
│       └── maid/
│           ├── maid_home.dart
│           └── task_detail_screen.dart
├── assets/
│   └── env.txt                      # Ortam değişkenleri
├── supabase/
│   ├── migrations/
│   │   ├── 001_schema.sql
│   │   ├── 002_rls.sql
│   │   └── 003_test_data.sql
│   └── functions/
│       └── send-push/
│           └── index.ts             # FCM Edge Function
├── env.example                      # Örnek .env dosyası
└── pubspec.yaml
```
