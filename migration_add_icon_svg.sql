-- Categories tablosuna icon_svg kolonu ekle
ALTER TABLE public.categories 
ADD COLUMN IF NOT EXISTS icon_svg TEXT;

-- Yorum ekle
COMMENT ON COLUMN public.categories.icon_svg IS 'AI tarafından üretilen SVG ikon kodu';
