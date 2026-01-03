-- TableFlow RLS (Row Level Security) Politikaları
-- Bu SQL kodunu Supabase SQL Editor içerisinde çalıştırın.

-- ⚠️ ÖNEMLİ: RLS'yi etkinleştirmeden önce politikaları eklemelisiniz!

-- 1. Companies tablosu için RLS
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;

-- Herkes yeni şirket oluşturabilir (kayıt için gerekli)
CREATE POLICY "Herkes şirket oluşturabilir" ON companies
  FOR INSERT WITH CHECK (true);

-- Kullanıcı sadece kendi şirketini görebilir
CREATE POLICY "Kullanıcı kendi şirketini görebilir" ON companies
  FOR SELECT USING (
    id::text = (auth.jwt() -> 'user_metadata' ->> 'company_id')
  );

-- Kullanıcı sadece kendi şirketini güncelleyebilir
CREATE POLICY "Kullanıcı kendi şirketini güncelleyebilir" ON companies
  FOR UPDATE USING (
    id::text = (auth.jwt() -> 'user_metadata' ->> 'company_id')
  );

-- 2. Categories tablosu için RLS
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Kullanıcı kendi kategorilerini yönetebilir" ON categories
  FOR ALL USING (
    company_id::text = (auth.jwt() -> 'user_metadata' ->> 'company_id')
  );

-- 3. Products tablosu için RLS
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Kullanıcı kendi ürünlerini yönetebilir" ON products
  FOR ALL USING (
    company_id::text = (auth.jwt() -> 'user_metadata' ->> 'company_id')
  );

-- 4. Tables tablosu için RLS
ALTER TABLE tables ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Kullanıcı kendi masalarını yönetebilir" ON tables
  FOR ALL USING (
    company_id::text = (auth.jwt() -> 'user_metadata' ->> 'company_id')
  );

-- 5. Orders tablosu için RLS
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Kullanıcı kendi siparişlerini yönetebilir" ON orders
  FOR ALL USING (
    company_id::text = (auth.jwt() -> 'user_metadata' ->> 'company_id')
  );

-- 6. Order Items tablosu için RLS
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Kullanıcı kendi sipariş kalemlerini yönetebilir" ON order_items
  FOR ALL USING (
    order_id IN (
      SELECT id FROM orders 
      WHERE company_id::text = (auth.jwt() -> 'user_metadata' ->> 'company_id')
    )
  );
