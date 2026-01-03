"use client";

import { useState, useEffect, useRef } from "react";

// Scroll animasyonu için custom hook
function useInView() {
  const ref = useRef<HTMLDivElement>(null);
  const [isInView, setIsInView] = useState(false);

  useEffect(() => {
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setIsInView(true);
        }
      },
      { threshold: 0.1 }
    );

    if (ref.current) {
      observer.observe(ref.current);
    }

    return () => observer.disconnect();
  }, []);

  return { ref, isInView };
}

// Animasyonlu bileşen
function FadeIn({ children, delay = 0 }: { children: React.ReactNode; delay?: number }) {
  const { ref, isInView } = useInView();

  return (
    <div
      ref={ref}
      style={{
        opacity: isInView ? 1 : 0,
        transform: isInView ? 'translateY(0)' : 'translateY(30px)',
        transition: `all 0.6s ease ${delay}s`,
      }}
    >
      {children}
    </div>
  );
}

export default function Home() {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const handleScroll = () => setScrolled(window.scrollY > 50);
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  // Hover state için
  const [hoveredFeature, setHoveredFeature] = useState<number | null>(null);
  const [hoveredPlan, setHoveredPlan] = useState<number | null>(null);

  return (
    <main style={{ background: '#f9fafb', color: '#111827', minHeight: '100vh', fontFamily: "'Inter', system-ui, sans-serif" }}>

      {/* Navigation - scroll'da değişen */}
      <nav style={{
        position: 'fixed',
        width: '100%',
        zIndex: 50,
        background: scrolled ? 'rgba(255,255,255,0.95)' : 'rgba(255,255,255,0.8)',
        backdropFilter: 'blur(12px)',
        borderBottom: '1px solid #f3f4f6',
        boxShadow: scrolled ? '0 4px 20px rgba(0,0,0,0.1)' : 'none',
        transition: 'all 0.3s ease'
      }}>
        <div style={{ maxWidth: '1280px', margin: '0 auto', padding: '0 24px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', height: '64px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <div style={{
              background: '#2563eb',
              padding: '8px',
              borderRadius: '8px',
              color: 'white',
              fontSize: '20px',
              transition: 'transform 0.3s ease'
            }}>🍽️</div>
            <span style={{ fontSize: '20px', fontWeight: 'bold' }}>Resto<span style={{ color: '#2563eb' }}>Sync</span></span>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '32px' }}>
            <a href="#ozellikler" style={{ color: '#4b5563', textDecoration: 'none', fontWeight: 500, transition: 'color 0.2s' }}>Özellikler</a>
            <a href="#fiyatlandirma" style={{ color: '#4b5563', textDecoration: 'none', fontWeight: 500, transition: 'color 0.2s' }}>Fiyatlandırma</a>
            <a href="#iletisim" style={{ color: '#4b5563', textDecoration: 'none', fontWeight: 500, transition: 'color 0.2s' }}>İletişim</a>
            <a href="/login" style={{
              color: '#2563eb',
              textDecoration: 'none',
              fontWeight: 600,
              transition: 'color 0.2s'
            }}>Giriş Yap</a>
            <a href="/register" style={{
              background: '#2563eb',
              color: 'white',
              padding: '10px 20px',
              borderRadius: '50px',
              fontWeight: 600,
              textDecoration: 'none',
              boxShadow: '0 4px 14px rgba(37, 99, 235, 0.3)',
              transition: 'all 0.3s ease'
            }}>Ücretsiz Dene</a>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section style={{ paddingTop: '128px', paddingBottom: '80px', textAlign: 'center', padding: '128px 24px 80px' }}>
        <div style={{ maxWidth: '1280px', margin: '0 auto' }}>
          <FadeIn>
            <div style={{
              display: 'inline-block',
              padding: '6px 16px',
              marginBottom: '24px',
              fontSize: '14px',
              fontWeight: 600,
              color: '#2563eb',
              background: '#eff6ff',
              borderRadius: '50px',
              textTransform: 'uppercase',
              letterSpacing: '0.5px',
              animation: 'pulse 2s infinite'
            }}>
              🚀 Yeni Nesil Restoran Yönetimi
            </div>
          </FadeIn>

          <FadeIn delay={0.1}>
            <h1 style={{ fontSize: '48px', fontWeight: 800, marginBottom: '24px', lineHeight: 1.1 }}>
              Restoranınız İçin <span style={{
                background: 'linear-gradient(90deg, #3b82f6, #8b5cf6)',
                WebkitBackgroundClip: 'text',
                WebkitTextFillColor: 'transparent',
              }}>Akıllı Adisyon</span> Sistemi
            </h1>
          </FadeIn>

          <FadeIn delay={0.2}>
            <p style={{ fontSize: '18px', color: '#4b5563', maxWidth: '800px', margin: '0 auto 40px', lineHeight: 1.7 }}>
              Garson, kasa ve yönetici arasında tek ekrandan, gerçek zamanlı sipariş yönetimi.
              Hızlı, güvenli ve tamamen dijital adisyon sistemiyle restoran operasyonlarınızı kolaylaştırın.
            </p>
          </FadeIn>

          <FadeIn delay={0.3}>
            <div style={{ display: 'flex', gap: '16px', justifyContent: 'center', flexWrap: 'wrap', marginBottom: '24px' }}>
              <a href="/register" style={{
                background: '#2563eb',
                color: 'white',
                padding: '16px 32px',
                borderRadius: '12px',
                fontSize: '18px',
                fontWeight: 700,
                textDecoration: 'none',
                boxShadow: '0 10px 30px rgba(37, 99, 235, 0.3)',
                transition: 'all 0.3s ease'
              }}
                onMouseOver={(e) => { e.currentTarget.style.transform = 'translateY(-3px)'; e.currentTarget.style.boxShadow = '0 15px 40px rgba(37, 99, 235, 0.4)'; }}
                onMouseOut={(e) => { e.currentTarget.style.transform = 'translateY(0)'; e.currentTarget.style.boxShadow = '0 10px 30px rgba(37, 99, 235, 0.3)'; }}
              >
                👉 Ücretsiz Denemeye Başla
              </a>
              <a href="#ozellikler" style={{
                background: 'white',
                color: '#374151',
                padding: '16px 32px',
                borderRadius: '12px',
                fontSize: '18px',
                fontWeight: 700,
                textDecoration: 'none',
                border: '1px solid #e5e7eb',
                transition: 'all 0.3s ease'
              }}
                onMouseOver={(e) => { e.currentTarget.style.transform = 'translateY(-3px)'; e.currentTarget.style.background = '#f9fafb'; }}
                onMouseOut={(e) => { e.currentTarget.style.transform = 'translateY(0)'; e.currentTarget.style.background = 'white'; }}
              >
                Özellikleri Keşfet
              </a>
            </div>
          </FadeIn>

          <FadeIn delay={0.4}>
            <p style={{ fontSize: '14px', color: '#6b7280' }}>
              <span style={{ color: '#22c55e', marginRight: '4px' }}>✓</span>
              Kurulum gerektirmez. Bulut tabanlı. <strong>14 gün ücretsiz deneyin.</strong>
            </p>
          </FadeIn>

          {/* Mockup - floating animation */}
          <FadeIn delay={0.5}>
            <div style={{
              marginTop: '64px',
              maxWidth: '900px',
              margin: '64px auto 0',
              borderRadius: '16px',
              overflow: 'hidden',
              boxShadow: '0 25px 50px rgba(0, 0, 0, 0.15)',
              border: '8px solid #1f2937',
              background: '#1f2937',
              animation: 'float 6s ease-in-out infinite'
            }}>
              <div style={{
                aspectRatio: '16/9',
                background: 'linear-gradient(135deg, #3b82f6, #6366f1)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: 'white',
                textAlign: 'center',
                padding: '32px'
              }}>
                <div>
                  <div style={{ fontSize: '80px', marginBottom: '16px', opacity: 0.5 }}>📱</div>
                  <p style={{ fontSize: '24px', fontWeight: 300, fontStyle: 'italic' }}>Dashboard ve Adisyon Arayüzü Önizlemesi</p>
                </div>
              </div>
            </div>
          </FadeIn>
        </div>
      </section>

      {/* Features Section */}
      <section id="ozellikler" style={{ padding: '80px 24px', background: 'white' }}>
        <div style={{ maxWidth: '1280px', margin: '0 auto' }}>
          <FadeIn>
            <div style={{ textAlign: 'center', marginBottom: '64px' }}>
              <h2 style={{ fontSize: '32px', fontWeight: 700, marginBottom: '16px' }}>🚀 Neden Bu Adisyon Sistemi?</h2>
              <p style={{ color: '#4b5563', maxWidth: '700px', margin: '0 auto' }}>
                Restoranların günlük operasyonlarını hızlandırmak ve hataları minimuma indirmek için tasarlandı.
                Sipariş alma, ödeme, raporlama ve yönetim artık tek bir sistemde.
              </p>
            </div>
          </FadeIn>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(350px, 1fr))', gap: '24px' }}>
            {[
              { icon: '🔄', title: 'Anlık Senkronizasyon', desc: 'Tüm siparişler anında tüm cihazlara yansır. Garson, mutfak ve kasa eş zamanlı güncellenir.' },
              { icon: '📱', title: 'Mobil Uyumlu', desc: 'Tablet, telefon veya bilgisayar — her cihazda kusursuz çalışır. Uygulama veya kurulum gerekmez.' },
              { icon: '📊', title: 'Detaylı Raporlar', desc: 'Günlük–aylık satışlar, en çok satan ürünler, yoğun saatler ve performans analizleri tek ekranda.' },
              { icon: '💳', title: 'Kolay Ödeme', desc: 'Nakit, kredi kartı veya parçalı ödeme seçenekleri. Tek tıkla hesap kapatma ve hızlı masa boşaltma.' },
              { icon: '⚙️', title: 'Tam Özelleştirme', desc: 'Menüler, kategoriler, masalar ve fiyatlar tamamen size özel. Restoranınıza göre şekillenir.' },
              { icon: '🔐', title: 'Güvenli Altyapı', desc: 'Tüm veriler şifreli olarak saklanır. Her restoran izole ve güvenli bir ortamda çalışır.' },
            ].map((feature, i) => (
              <FadeIn key={i} delay={i * 0.1}>
                <div
                  style={{
                    padding: '32px',
                    borderRadius: '16px',
                    background: hoveredFeature === i ? 'white' : '#f9fafb',
                    border: hoveredFeature === i ? '1px solid #dbeafe' : '1px solid transparent',
                    transition: 'all 0.3s ease',
                    transform: hoveredFeature === i ? 'translateY(-8px)' : 'translateY(0)',
                    boxShadow: hoveredFeature === i ? '0 20px 40px rgba(37, 99, 235, 0.1)' : 'none',
                    cursor: 'pointer'
                  }}
                  onMouseEnter={() => setHoveredFeature(i)}
                  onMouseLeave={() => setHoveredFeature(null)}
                >
                  <div style={{
                    width: '56px',
                    height: '56px',
                    background: hoveredFeature === i ? '#2563eb' : '#dbeafe',
                    color: hoveredFeature === i ? 'white' : '#2563eb',
                    borderRadius: '12px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontSize: '24px',
                    marginBottom: '20px',
                    transition: 'all 0.3s ease'
                  }}>
                    {feature.icon}
                  </div>
                  <h3 style={{ fontSize: '20px', fontWeight: 700, marginBottom: '12px' }}>{feature.icon} {feature.title}</h3>
                  <p style={{ color: '#4b5563', lineHeight: 1.6 }}>{feature.desc}</p>
                </div>
              </FadeIn>
            ))}
          </div>
        </div>
      </section>

      {/* Pricing Section */}
      <section id="fiyatlandirma" style={{ padding: '80px 24px', background: '#f9fafb' }}>
        <div style={{ maxWidth: '1280px', margin: '0 auto', textAlign: 'center' }}>
          <FadeIn>
            <h2 style={{ fontSize: '32px', fontWeight: 700, marginBottom: '16px' }}>💼 Paketler & Fiyatlandırma</h2>
            <p style={{ color: '#4b5563', marginBottom: '48px' }}>İhtiyacınıza uygun planı seçin, 14 gün ücretsiz kullanmaya başlayın.</p>
          </FadeIn>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: '24px', maxWidth: '1100px', margin: '0 auto' }}>

            {[
              {
                name: 'Başlangıç Paketi',
                color: '#22c55e',
                price: 'Bütçe Dostu',
                desc: 'Küçük ve orta ölçekli işletmeler için ideal.',
                features: ['Temel adisyon yönetimi', 'Garson & kasa ekranları', 'Mobil uyumlu kullanım', 'Standart raporlar', 'E-posta destek'],
                badge: '🎁 14 gün ücretsiz deneme',
                popular: false
              },
              {
                name: 'Profesyonel Paket',
                color: '#2563eb',
                price: 'Abonelik Modeli',
                desc: 'Yoğun ve büyüyen restoranlar için.',
                features: ['Tüm başlangıç özellikleri', 'Gelişmiş raporlama', 'Yönetici paneli', 'Çoklu kullanıcı yetkilendirme', 'Öncelikli destek'],
                badge: '🎁 14 gün ücretsiz deneme',
                popular: true
              },
              {
                name: 'Kurumsal Paket',
                color: '#9333ea',
                price: 'Özel Fiyat',
                desc: 'Zincir restoranlar ve yüksek hacimli işletmeler.',
                features: ['Tüm profesyonel özellikler', 'Çoklu şube yönetimi', 'Gelişmiş analiz & istatistik', 'Özel destek & danışmanlık', 'API & entegrasyon'],
                badge: '🤝 Kurumsal Çözümler',
                popular: false
              },
            ].map((plan, i) => (
              <FadeIn key={i} delay={i * 0.15}>
                <div
                  style={{
                    background: 'white',
                    padding: '32px',
                    borderRadius: '16px',
                    border: plan.popular ? `2px solid ${plan.color}` : '1px solid #e5e7eb',
                    boxShadow: plan.popular ? `0 10px 40px rgba(37, 99, 235, 0.15)` : '0 4px 20px rgba(0,0,0,0.05)',
                    position: 'relative',
                    display: 'flex',
                    flexDirection: 'column',
                    transition: 'all 0.3s ease',
                    transform: hoveredPlan === i ? 'translateY(-8px)' : 'translateY(0)',
                  }}
                  onMouseEnter={() => setHoveredPlan(i)}
                  onMouseLeave={() => setHoveredPlan(null)}
                >
                  {plan.popular && (
                    <div style={{
                      position: 'absolute',
                      top: '-14px',
                      left: '50%',
                      transform: 'translateX(-50%)',
                      background: plan.color,
                      color: 'white',
                      padding: '4px 16px',
                      borderRadius: '50px',
                      fontSize: '12px',
                      fontWeight: 700,
                      textTransform: 'uppercase'
                    }}>En Popüler</div>
                  )}
                  <div style={{ marginBottom: '24px' }}>
                    <div style={{ color: plan.color, fontWeight: 700, fontSize: '12px', textTransform: 'uppercase', marginBottom: '8px' }}>
                      {plan.name === 'Başlangıç Paketi' ? '🟢' : plan.name === 'Profesyonel Paket' ? '🔵' : '🟣'} {plan.name}
                    </div>
                    <p style={{ color: '#6b7280', fontSize: '14px' }}>{plan.desc}</p>
                  </div>
                  <div style={{ fontSize: '28px', fontWeight: 700, marginBottom: '24px' }}>{plan.price}</div>
                  <ul style={{ listStyle: 'none', padding: 0, marginBottom: '24px', flex: 1, textAlign: 'left' }}>
                    {plan.features.map((item, j) => (
                      <li key={j} style={{ color: '#4b5563', marginBottom: '12px' }}>
                        <span style={{ color: plan.color, marginRight: '8px' }}>✓</span> {item}
                      </li>
                    ))}
                  </ul>
                  <div style={{
                    background: `${plan.color}10`,
                    padding: '8px',
                    borderRadius: '8px',
                    color: plan.color,
                    fontWeight: 600,
                    marginBottom: '24px',
                    fontSize: '14px'
                  }}>
                    {plan.badge}
                  </div>
                  <a href={plan.name === 'Kurumsal Paket' ? '#iletisim' : '/register'} style={{
                    display: 'block',
                    padding: '12px',
                    borderRadius: '12px',
                    background: plan.popular ? plan.color : 'transparent',
                    border: `2px solid ${plan.color}`,
                    color: plan.popular ? 'white' : plan.color,
                    fontWeight: 700,
                    textDecoration: 'none',
                    textAlign: 'center',
                    transition: 'all 0.3s ease'
                  }}>
                    {plan.name === 'Kurumsal Paket' ? 'Bizimle İletişime Geçin' : 'Hemen Başla'}
                  </a>
                </div>
              </FadeIn>
            ))}
          </div>
        </div>
      </section>

      {/* Contact Section */}
      <section id="iletisim" style={{ padding: '80px 24px', background: 'white' }}>
        <div style={{ maxWidth: '800px', margin: '0 auto', textAlign: 'center' }}>
          <FadeIn>
            <h2 style={{ fontSize: '36px', fontWeight: 800, marginBottom: '24px' }}>
              Adisyon sistemimizi <span style={{ color: '#2563eb', textDecoration: 'underline' }}>ücretsiz</span> deneyin
            </h2>
            <p style={{ fontSize: '20px', color: '#4b5563', marginBottom: '40px' }}>
              Restoranınıza uygun olup olmadığını görün. Hiçbir risk yok!
            </p>
          </FadeIn>

          <FadeIn delay={0.2}>
            <div style={{
              background: '#f9fafb',
              borderRadius: '24px',
              padding: '48px',
              border: '1px solid #e5e7eb'
            }}>
              <form style={{ maxWidth: '500px', margin: '0 auto 32px' }}>
                <input
                  type="text"
                  placeholder="Restoran Adı"
                  style={{
                    width: '100%',
                    padding: '14px 20px',
                    borderRadius: '12px',
                    border: '1px solid #e5e7eb',
                    marginBottom: '12px',
                    fontSize: '16px',
                    outline: 'none',
                    transition: 'border-color 0.3s ease'
                  }}
                />
                <input
                  type="email"
                  placeholder="E-posta Adresiniz"
                  style={{
                    width: '100%',
                    padding: '14px 20px',
                    borderRadius: '12px',
                    border: '1px solid #e5e7eb',
                    marginBottom: '12px',
                    fontSize: '16px',
                    outline: 'none',
                    transition: 'border-color 0.3s ease'
                  }}
                />
                <button
                  type="submit"
                  style={{
                    width: '100%',
                    padding: '16px',
                    borderRadius: '12px',
                    background: '#2563eb',
                    color: 'white',
                    fontSize: '18px',
                    fontWeight: 700,
                    border: 'none',
                    cursor: 'pointer',
                    boxShadow: '0 10px 30px rgba(37, 99, 235, 0.3)',
                    transition: 'all 0.3s ease'
                  }}
                >
                  👉 14 Günlük Ücretsiz Denemeye Başla
                </button>
              </form>

              <div style={{ display: 'flex', justifyContent: 'center', gap: '32px', flexWrap: 'wrap', color: '#4b5563' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                  <div style={{ width: '40px', height: '40px', background: 'white', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 2px 8px rgba(0,0,0,0.1)' }}>
                    ✉️
                  </div>
                  <span>info@restosync.com</span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                  <div style={{ width: '40px', height: '40px', background: 'white', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 2px 8px rgba(0,0,0,0.1)' }}>
                    📞
                  </div>
                  <span>+90 5XX XXX XX XX</span>
                </div>
              </div>
            </div>
          </FadeIn>
        </div>
      </section>

      {/* Footer */}
      <footer style={{ padding: '40px 24px', borderTop: '1px solid #e5e7eb', background: 'white', textAlign: 'center' }}>
        <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', gap: '8px', marginBottom: '16px' }}>
          <div style={{ background: '#e5e7eb', padding: '4px 8px', borderRadius: '4px', color: '#4b5563' }}>🍽️</div>
          <span style={{ fontWeight: 700, color: '#1f2937' }}>RestoSync</span>
        </div>
        <p style={{ color: '#6b7280', fontSize: '14px' }}>© 2026 RestoSync Adisyon Sistemleri. Tüm hakları saklıdır.</p>
      </footer>

      {/* CSS Animations */}
      <style jsx global>{`
        @keyframes float {
          0%, 100% { transform: translateY(0px); }
          50% { transform: translateY(-20px); }
        }
        @keyframes pulse {
          0%, 100% { opacity: 1; }
          50% { opacity: 0.7; }
        }
        html {
          scroll-behavior: smooth;
        }
        a:hover {
          color: #2563eb !important;
        }
        input:focus {
          border-color: #2563eb !important;
          box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
        }
        button:hover {
          transform: translateY(-2px);
          box-shadow: 0 15px 40px rgba(37, 99, 235, 0.4) !important;
        }
      `}</style>
    </main>
  );
}
