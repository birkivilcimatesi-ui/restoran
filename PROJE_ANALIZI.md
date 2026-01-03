# 📘 RestoSync - Proje Analizi ve Ürün Tanımı

**Versiyon:** 1.0  
**Tarih:** 3 Ocak 2026

---

## 1. Proje Nedir?
**RestoSync**, restoran ve kafe işletmecilerinin tüm süreçlerini dijitalleştiren, bulut tabanlı bir **akıllı adisyon ve restoran yönetim sistemidir**.

Geleneksel, kurulum gerektiren, pahalı ve hantal yazılımların aksine; RestoSync internet tarayıcısı üzerinden her yerden erişilebilen, kurulum gerektirmeyen ve modern bir çözümdür. İşletme sahipleri tek bir hesaptan birden fazla şubeyi yönetebilir.

**Temel Felsefe:** "Karmaşıklığı yok et, hızı artır."

---

## 2. Hedef Kitle
*   **Küçük ve Orta Ölçekli İşletmeler:** Kafeler, butik restoranlar, pastaneler.
*   **Zincir Restoranlar:** Birden fazla şubesi olan ve merkezi yönetim isteyen işletmeler.
*   **Girişimciler:** Hızlıca restoran açıp teknolojik altyapı kurmak isteyenler.

---

## 3. Sistem Neler Yapar? (Temel Yetenekler)

### 🏢 Çoklu Şube Yönetimi
Bir patron, İstanbul'daki kafesini ve Ankara'daki restoranını aynı panelden yönetebilir. Her restoranın kendine özel bir web adresi (örn: `kahvediyari.restosync.com`) olur.

### ⚡ Hızlı Sipariş (Adisyon)
Garsonlar, tablet veya telefonlarından masaları seçip saniyeler içinde sipariş girebilir. Mutfak ile salon arasındaki iletişim tamamen dijitalleşir.

### 🌐 Her Yerden Erişim
Bilgisayar, tablet veya telefon... İnternetin olduğu her yer ofisinizdir. Windows, Mac, Android veya iOS fark etmeksizin çalışır.

### 🔄 Canlı Takip (Real-Time)
Bir garson siparişi girdiği anda, diğer garsonun ekranına anında düşer. Kasada ödeme alındığında masa anında "boş" olarak işaretlenir. Sayfa yenilemeye gerek yoktur.

---

## 4. Kullanıcı Akışı (User Flow)

### 👨‍💼 İşletme Sahibi (Patron) Akışı
1.  **Tanışma:** `restosync.com` ana sayfasına gelir, özellikleri inceler.
2.  **Kayıt:** E-posta ile saniyeler içinde kayıt olur.
3.  **Restoran Oluşturma:**
    *   Restoran ismini yazar (örn: "Lezzet Durağı").
    *   Sistem otomatik olarak özel bir adres oluşturur: `lezzet-duragi.restosync.com`.
4.  **Yönetim:** Dashboard (Panel) ekranında restoranlarını kartlar halinde görür. "Adisyonu Aç" diyerek dükkanını yönetmeye başlar.

### 🧑‍🍳 Personel (Garson) Akışı
1.  **Giriş:** İşletmenin özel adresine (örn: `lezzet-duragi.restosync.com`) girer.
2.  **Masa Seçimi:** Krokiden sipariş alacağı masayı seçer.
3.  **Sipariş:** Menüden ürünlere tıklar (örn: 2 Çay, 1 Tost) ve siparişi onaylar.
4.  **Sonuç:** Sipariş anında mutfağa/kasaya iletilir.

---

## 5. Ekranlar ve İşlevleri

### A. Karşılama Ekranı (Landing Page)
*   **Amaç:** Ürünü satmak ve tanıtmak.
*   **İçerik:** Büyük, etkileyici başlıklar, özellik tanıtımları, fiyatlandırma tabloları ve "Hemen Başla" butonları.
*   **Havası:** Güven verici, profesyonel ve modern.

### B. Yönetim Paneli (Dashboard)
*   **Amaç:** İşletmecinin şubelerini yönettiği merkez.
*   **İçerik:**
    *   Şube Kartları: Her restoran için şık bir kart.
    *   Durum Göstergeleri: Hangi restoran aktif, hangisinin web adresi (subdomain) ne?
    *   Hızlı İşlemler: Restoran ekle, sil, düzenle.

### C. Adisyon Sistemi (Uygulama)
*   **Amaç:** Operasyonu yönetmek.
*   **İçerik:**
    *   **Masa Görünümü:** Dolu, boş, rezerve masaların renkli kuş bakışı görünümü.
    *   **Menü:** Kategorilere ayrılmış (İçecekler, Tatlılar vb.) fotoğraflı ürün listesi.
    *   **Sepet:** O an girilen siparişlerin özeti.
    *   **Ödeme:** Nakit, kredi kartı ile tahsilat ve masa kapatma.

---

## 6. Tasarım Dili
*   **Renkler:** Güven veren kurumsal **Mavi** tonları (`#2563eb`), temiz **Beyaz** arka planlar ve uyarılar için canlı renkler (Yeşil: Başarılı, Kırmızı: Hata/Dolu Masa).
*   **Form:** Köşeleri yuvarlatılmış kartlar, yumuşak gölgeler, ferah boşluklar. "Basık" veya "sıkışık" değil, "nefes alan" bir arayüz.
*   **Hissiyat:** Modern, akıcı ve kullanışlı.

---

## 7. Gelecek Vizyonu (Roadmap)
Sistem şu an temel operasyonu mükemmel yapıyor. İleride şunlar eklenecek:

1.  **patron.restosync.com:** İşletme sahipleri için detaylı grafikler, ciro raporları, en çok satan ürün analizleri.
2.  **Kredi Kartı ile Ödeme:** İşletmelerin sistem üzerinden abonelik satın alabilmesi.
3.  **Stok Takibi:** Satılan her tostun peynirden, ekmekten düşmesi.
4.  **QR Menü:** Müşterilerin masadaki QR'ı okutup kendi telefonundan sipariş vermesi.

---
*Bu doküman, teknik detaylardan arındırılmış, projenin vizyonunu ve işleyişini anlatan canlı bir belgedir.*
