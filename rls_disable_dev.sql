-- HIZLI ÇÖZÜM: Companies tablosunda RLS'yi düzelt
-- Bu SQL'i Supabase SQL Editor'da çalıştır

-- Önce mevcut politikaları sil
DROP POLICY IF EXISTS "Herkes şirket oluşturabilir" ON companies;
DROP POLICY IF EXISTS "Kullanıcı kendi şirketini görebilir" ON companies;
DROP POLICY IF EXISTS "Kullanıcı kendi şirketini güncelleyebilir" ON companies;

-- RLS'yi devre dışı bırak (geliştirme aşamasında)
ALTER TABLE companies DISABLE ROW LEVEL SECURITY;

-- Diğer tablolar için de RLS kapat (geliştirme kolaylığı için)
ALTER TABLE categories DISABLE ROW LEVEL SECURITY;
ALTER TABLE products DISABLE ROW LEVEL SECURITY;
ALTER TABLE tables DISABLE ROW LEVEL SECURITY;
ALTER TABLE orders DISABLE ROW LEVEL SECURITY;
ALTER TABLE order_items DISABLE ROW LEVEL SECURITY;

-- NOT: Production'a geçmeden önce RLS tekrar aktif edilecek ve
-- doğru politikalar uygulanacak. Şu an geliştirme aşamasındayız.
