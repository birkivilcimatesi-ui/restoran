# 🛡️ Güvenlik ve Kod Analiz Raporu

**Tarih:** 3 Ocak 2026
**Durum:** Kritik Hatalar Tespit Edildi

Aşağıda projenin mevcut durumunda tespit edilen güvenlik açıkları, mantıksal hatalar ve yapısal sorunlar listelenmiştir.

---

## 🚨 1. Kritik Güvenlik Açıkları

### A. Hardcoded API Anahtarları
**Dosya:** `lib/core/constants/api_constants.dart` ve `landing/middleware.ts`
*   **Sorun:** `supabaseAnonKey` ve özellikle `geminiApiKey` kod içine gömülü (hardcoded) olarak saklanmış.
*   **Risk:**
    *   `geminiApiKey`: Kötü niyetli kişiler tarafından kotanızı tüketmek veya ücretli modelleri kullanmak için çalınabilir.
    *   `supabaseAnonKey`: Genelde public olsa da, RLS politikaları zayıfsa veritabanına erişim riski oluşturur.
*   **Çözüm:** Bu anahtarlar `.env` dosyasında saklanmalı ve derleme zamanında (flutter_dotenv, --dart-define) veya sunucu tarafında (middleware için Environment Variables) kullanılmalıdır.

### B. Zayıf RLS (Row Level Security) Politikaları
**Dosya:** `rls_policies.sql`
*   **Sorun:** `CREATE POLICY "Herkes şirket oluşturabilir" ON companies FOR INSERT WITH CHECK (true);`
*   **Risk:** Herhangi bir doğrulanmış kullanıcı, `companies` tablosuna sınırsız sayıda şirket ekleyebilir. `owner_id` gibi bir sahiplik sütunu olmadığı için, bu şirketler sahipsiz kalabilir veya sistem çöp veriyle dolabilir.

---

## 🐛 2. Mantıksal Hatalar ve Kırık Akışlar

### A. Kayıt Akışı (Registration Flow) Çalışmıyor
**Dosya:** `lib/providers/auth_provider.dart` ve `rls_policies.sql`
*   **Analiz:**
    1.  Kullanıcı `signUp` fonksiyonunu çağırır.
    2.  `CompanyService.createCompany` çağrılır. Bu fonksiyon şirketi `INSERT` eder ve hemen ardından `SELECT` ile dönen veriyi almaya çalışır.
    3.  **HATA:** RLS politikası (`SELECT`) şu kurala bakar: `auth.jwt() -> 'user_metadata' ->> 'company_id'`.
    4.  Kullanıcı henüz yeni kayıt olduğu için `user_metadata` içinde `company_id` **YOKTUR**.
    5.  Sonuç olarak veritabanı boş döner, uygulama hata verir veya donar. Kayıt işlemi tamamlanamaz.
*   **Çözüm:** `companies` tablosuna `owner_id` sütunu eklenmeli ve RLS politikası "Kullanıcı kendi oluşturduğu (owner_id kendisi olan) şirketi görebilir" şeklinde güncellenmelidir.

### B. Subdomain Yönlendirmesi Çalışmıyor
**Dosya:** `landing/middleware.ts`
*   **Analiz:** Middleware, `supabase` istemcisini `anon` (anonim) anahtarla başlatır. `companies` tablosunda `subdomain` araması yapar.
*   **HATA:** RLS politikası sadece şirket sahibinin (`company_id` eşleşen kullanıcının) okumasına izin verir. Anonim kullanıcının (middleware) hiçbir satırı okuma yetkisi yoktur.
*   **Sonuç:** `firma.restosync.com` adresine giden herkes "Şirket bulunamadı" hatası alır.
*   **Çözüm:** `security definer` yetkisine sahip bir PostgreSQL fonksiyonu (RPC) yazılarak, sadece gerekli bilgilerin (id, subdomain) dışarıya açılması sağlanmalıdır.

---

## 📱 3. Platform Uyumluluğu Sorunları

### A. `dart:html` Kullanımı
**Dosya:** `lib/services/menu_ocr_service.dart`
*   **Sorun:** Dosyada `import 'dart:html' as html;` kullanılmış.
*   **Risk:** Bu kod sadece Web'de çalışır. Android veya iOS için derleme yapılmaya çalışıldığında **derleme hatası (compile error)** verecektir.
*   **Çözüm:** `image_picker` paketi kullanılarak platformdan bağımsız (cross-platform) resim seçme yapısı kurulmalıdır.

---

## 📋 Önerilen Aksiyon Planı

1.  **Veritabanı Güncellemesi:**
    *   `companies` tablosuna `owner_id` ekle.
    *   RLS politikalarını güncelle.
    *   Middleware için güvenli bir RPC fonksiyonu oluştur.
2.  **Kod Düzeltmeleri:**
    *   `MenuOcrService`'i mobil uyumlu hale getir.
    *   `AuthProvider` ve `CompanyService` mantığını yeni veritabanı yapısına göre güncelle.
3.  **Güvenlik:**
    *   API anahtarlarını güvenli hale getir.

Bu düzeltmeler yapılmadan projenin canlıya alınması veya mobilde çalıştırılması mümkün değildir.
