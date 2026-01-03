# RestoSync: Uçtan Uca Geliştirme Yol Haritası (Roadmap)

Bu doküman, RestoSync SaaS platformunun sıfırdan canlıya alınma sürecindeki tüm adımları içerir.

---

## 🟢 Faz 1: Temel Altyapı ve Veritabanı ✅ TAMAMLANDI
- [x] Flutter Projesinin Oluşturulması (Web, iOS, Android)
- [x] Supabase Entegrasyonu ve Proje Yapılandırması
- [x] Multi-tenancy Destekli Veritabanı Şeması
- [x] Merkezi Kayıt ve Giriş Sistemi (Authentication)

---

## 🔵 Faz 2: Admin Paneli ve Onboarding ✅ TAMAMLANDI
- [x] Restoran Kayıt ve Profil Oluşturma Akışı
- [x] Masa Yönetim Ekranı
- [x] Manuel Ürün Yönetimi (CRUD)
- [x] Excel/CSV ile Toplu Ürün İçe Aktarma
- [x] AI/OCR ile Menü Okuma (Gemini Vision)
- [x] AI ile Kategori İkonu Önerisi

---

## 🟠 Faz 3: Sipariş ve Ödeme (Adisyon Sistemi) ✅ TAMAMLANDI
- [x] Veritabanı "orders" ve "order_items" tabloları
- [x] Masa Detay Ekranı tasarımı
- [x] Ürün seçimi ve sepete ekleme
- [x] Ödeme sistemi (Nakit/Kart, Parçalı Ödeme)
- [x] Supabase Realtime ile Masa Durumu Senkronizasyonu

---

## 🟣 Faz 4: Real-Time ve Senkronizasyon ✅ TAMAMLANDI
- [x] Supabase Realtime ile Cihazlar Arası Anlık Senkronizasyon
- [x] "Always-On" Yapısı ve Bağlantı Durumu Kontrolü

---

## 🔴 Faz 5: SaaS Platformu ve Landing Page (DEVAM EDİYOR)

### 5.1 Landing Page ✅
- [x] Tanıtım Sitesi Tasarımı (Next.js)
- [x] Animasyonlar ve Premium Tasarım
- [x] Responsive Mobil Uyum

### 5.2 Merkezi Auth Sistemi (YENİ ⭐)
> **Açıklama:** Tüm giriş/kayıt işlemleri Landing Page (Next.js) üzerinden yapılacak.
> Flutter tarafında ayrı login ekranı olmayacak. Kullanıcı web'den giriş yapınca
> restoranlarını görecek ve seçtiği restoran için Flutter adisyon sistemine yönlendirilecek.

#### 5.2.1 Next.js Auth Sayfaları ✅
- [x] `/login` - Giriş sayfası
- [x] `/register` - Kayıt sayfası (company_name metadata ile)
- [x] Supabase Auth entegrasyonu

#### 5.2.2 Next.js Dashboard (Restoranlarım) ✅


- [x] `/dashboard` - Kullanıcının restoranlarını listele
- [x] Yeni restoran ekleme butonu ve modal
- [x] Restoran kartına tıklayınca Flutter'a yönlendirme

#### 5.2.3 Flutter Entegrasyonu (Aynı Domain) ✅
> **Çözüm:** Flutter web build'i Next.js public klasörüne yerleştirildi.
> Aynı domain'de çalıştığı için cookie paylaşılıyor, session otomatik aktarılıyor.

- [x] Flutter web build al (`flutter build web --base-href "/app/"`)
- [x] Build'i `landing/public/app` klasörüne kopyala
- [x] Next.js config'e rewrite ekle
- [x] Dashboard'dan `/app?company_id=xxx` yönlendirmesi

### 5.3 Subdomain Sistemi ✅
- [x] Benzersiz URL Yapılandırması (firma.restosync.com)
- [x] Subdomain'den company_id Tespiti
- [x] Dinamik Routing ve Yönlendirme
- [x] Otomatik Subdomain Oluşturma ve Dashboard UI


### 5.4 Çoklu Restoran Desteği
- [ ] Bir hesap = Birden fazla restoran (Kurumsal paket)
- [ ] Restoran Seçici Ekran (Dashboard)
- [ ] Restoran Bazlı Yetkilendirme

---

## 💎 Faz 6: Abonelik ve Ödeme Sistemi
- [ ] Paket Tanımlamaları (Başlangıç, Pro, Kurumsal)
- [ ] Stripe/iyzico Entegrasyonu
- [ ] Abonelik Durumu Kontrolü (Paywall)
- [ ] Deneme Süresi (14 gün) Yönetimi
- [ ] Fatura ve Ödeme Geçmişi

---

## 💼 Faz 7: Dashboard ve Raporlama
> **Açıklama:** Bu raporlama özellikleri, Faz 5.2'de oluşturulan Web Dashboard (`/dashboard`) üzerine inşa edilecek.
> Login sonrası kullanıcı hem restoranlarına girip Flutter adisyon sistemini kullanabilecek,
> hem de aynı dashboard üzerinden satış raporlarını, grafikleri ve analitik verileri inceleyebilecek.

- [ ] İşletme Sahibi Dashboard (Satış özeti, grafikler)
- [ ] Restoran Seçmeden Genel Özet Görüntüleme
- [ ] Günlük/Haftalık/Aylık Raporlar
- [ ] En Çok Satan Ürünler Analizi
- [ ] Personel Performans Takibi
- [ ] Export (PDF/Excel)

---

## 🚀 Faz 8: Go-Live ve Optimizasyon
- [ ] QR Kod ile Cihaz Eşleştirme
- [ ] Kiosk Modu ve Tam Ekran Desteği
- [ ] UX/UI Final İyileştirmeleri
- [ ] Performance Optimizasyonu
- [ ] Production Deployment
- [ ] Domain ve SSL Yapılandırması

---

## 📝 Paket Limitleri

| Özellik | Başlangıç | Profesyonel | Kurumsal |
|---------|-----------|-------------|----------|
| Restoran Sayısı | 1 | 3 | 10+ |
| Masa Sayısı | 15 | Sınırsız | Sınırsız |
| Cihaz Sayısı | 2 | 10 | Sınırsız |
| Raporlama | Temel | Gelişmiş | Tam |
| Destek | E-posta | Öncelikli | 7/24 |
| Subdomain | ❌ | ✅ | ✅ |
| API Erişimi | ❌ | ❌ | ✅ |

---

## 📝 Notlar
- **Tek Auth:** Landing page ve Adisyon sistemi aynı Supabase Auth kullanır
- **Multi-tenancy:** Her restoran `company_id` ile izole
- Tasarımda "Modern" ve "Premium" estetik ön planda
