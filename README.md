# 📚 Yazım Kuralları Mobil Eğitim Uygulaması

Türkçe yazım kurallarını eğlenceli ve etkileşimli bir şekilde öğretmek amacıyla geliştirilen oyunlaştırma destekli mobil eğitim uygulamasıdır.

Bu proje, Necmettin Erbakan Üniversitesi Bilgisayar Mühendisliği Bölümü Bitirme Projesi kapsamında geliştirilmiştir.

---

## 🚀 Özellikler

### 👤 Kullanıcı Sistemi
- E-posta ile kayıt olma
- E-posta doğrulama sistemi
- Kullanıcı adı ile giriş yapabilme
- Güvenli Firebase Authentication altyapısı
- Her kullanıcı için ayrı veri saklama

### 📖 Eğitim Modülleri
- Yazım kuralları dersleri
- Konu bazlı içerikler
- Öğrenme odaklı tasarım
- Kolay ve anlaşılır arayüz

### 📝 Test Sistemi
- Çoktan seçmeli sorular
- Anlık doğru/yanlış geri bildirimi
- Konu bazlı quizler
- Yanlış yapılan soruları tekrar çözebilme

### 🎮 Oyunlaştırma
- XP (Deneyim Puanı) sistemi
- Seviye sistemi
- Rozet kazanımları
- Başarı ekranı
- Günlük görevler
- Motivasyonu artıran ödül mekanizmaları

### 🔔 Bildirim Sistemi
- Günlük hatırlatma bildirimleri
- Görev tamamlama bildirimleri
- Bildirim açma/kapama ayarları

### ⚙️ Kullanıcı Ayarları
- Açık/Koyu tema desteği
- Ses efektleri
- Titreşim desteği
- Bildirim yönetimi

### ☁️ Bulut Senkronizasyonu
- Firebase Realtime Database
- Kullanıcı verilerinin güvenli saklanması
- Cihaz değişiminde veri kaybının önlenmesi

---

## 🛠️ Kullanılan Teknolojiler

### Frontend
- Flutter
- Dart

### Backend & Cloud
- Firebase Authentication
- Firebase Realtime Database
- Firebase Core

### Diğer Paketler

- shared_preferences
- flutter_local_notifications
- audioplayers
- image_picker
- fl_chart
- timezone

---

## 📱 Ekranlar

- Splash Screen
- Giriş Yap
- Kayıt Ol
- Ana Sayfa
- Dersler
- Quiz Ekranı
- Yanlışlarım
- Başarılar
- Profil
- Ayarlar

---

## 🎯 Projenin Amacı

Bu proje, Türkçe yazım kurallarının mobil platformlar üzerinden daha etkili öğretilmesini amaçlamaktadır.

Geleneksel öğrenme yöntemlerinden farklı olarak;

- Mobil öğrenme
- Oyunlaştırma
- Etkileşimli testler
- Kullanıcı motivasyonu

yaklaşımları birlikte kullanılmıştır.

---

## 📊 Oyunlaştırma Yapısı

Kullanıcılar:

- Soru çözdükçe XP kazanır
- Seviye atlar
- Rozetler kazanır
- Günlük görevleri tamamlar
- İlerlemelerini takip eder

Bu sayede öğrenme süreci daha eğlenceli ve sürdürülebilir hale getirilmiştir.

---

## 🔒 Güvenlik

- Firebase Authentication kullanılmıştır.
- E-posta doğrulama sistemi bulunmaktadır.
- Her kullanıcının verileri ayrı tutulmaktadır.
- Kullanıcı ilerlemeleri bulut ortamında saklanmaktadır.

---



## ⚡ Kurulum

### 1. Projeyi Klonlayın

```bash
git clone https://github.com/KULLANICI_ADIN/YazimKurallari.git
```

### 2. Proje Klasörüne Girin

```bash
cd YazimKurallari
```

### 3. Paketleri Yükleyin

```bash
flutter pub get
```

### 4. Firebase Yapılandırmasını Ekleyin

- google-services.json
- firebase_options.dart

dosyalarını projeye ekleyin.

### 5. Uygulamayı Çalıştırın

```bash
flutter run
```

---

## 👨‍💻 Geliştirici

**Süleyman Şahin**

Bilgisayar Mühendisliği Öğrencisi

Necmettin Erbakan Üniversitesi

GitHub:
https://github.com/suleymansahinn

---

## 📄 Lisans

Bu proje eğitim ve akademik amaçlarla geliştirilmiştir.
