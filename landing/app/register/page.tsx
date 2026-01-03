"use client";

import { useState } from "react";
import Link from "next/link";
import { supabase } from "@/lib/supabase";

export default function RegisterPage() {
    const [companyName, setCompanyName] = useState("");
    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");
    const [confirmPassword, setConfirmPassword] = useState("");
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [success, setSuccess] = useState(false);

    const handleRegister = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        setError(null);

        // Şifre kontrolü
        if (password !== confirmPassword) {
            setError("Şifreler eşleşmiyor");
            setLoading(false);
            return;
        }

        if (password.length < 6) {
            setError("Şifre en az 6 karakter olmalıdır");
            setLoading(false);
            return;
        }

        try {
            const { error } = await supabase.auth.signUp({
                email,
                password,
                options: {
                    data: {
                        company_name: companyName,
                    },
                },
            });

            if (error) throw error;

            setSuccess(true);
        } catch (err: unknown) {
            setError(err instanceof Error ? err.message : "Kayıt olurken bir hata oluştu");
        } finally {
            setLoading(false);
        }
    };

    return (
        <main style={{
            background: 'linear-gradient(135deg, #f9fafb 0%, #eff6ff 100%)',
            minHeight: '100vh',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontFamily: "'Inter', system-ui, sans-serif",
            padding: '24px'
        }}>
            <div style={{
                background: 'white',
                borderRadius: '24px',
                padding: '48px',
                width: '100%',
                maxWidth: '480px',
                boxShadow: '0 25px 50px rgba(0, 0, 0, 0.1)',
                border: '1px solid #e5e7eb'
            }}>
                {/* Logo */}
                <div style={{ textAlign: 'center', marginBottom: '32px' }}>
                    <Link href="/" style={{ textDecoration: 'none', display: 'inline-flex', alignItems: 'center', gap: '8px' }}>
                        <div style={{
                            background: '#2563eb',
                            padding: '10px',
                            borderRadius: '12px',
                            color: 'white',
                            fontSize: '24px'
                        }}>🍽️</div>
                        <span style={{ fontSize: '24px', fontWeight: 'bold', color: '#111827' }}>
                            Resto<span style={{ color: '#2563eb' }}>Sync</span>
                        </span>
                    </Link>
                </div>

                {/* Başlık */}
                <div style={{ textAlign: 'center', marginBottom: '32px' }}>
                    <h1 style={{ fontSize: '28px', fontWeight: 700, color: '#111827', marginBottom: '8px' }}>
                        Restoranınızı Kaydedin
                    </h1>
                    <p style={{ color: '#6b7280', fontSize: '16px' }}>
                        14 gün ücretsiz deneme • Kredi kartı gerekmez
                    </p>
                </div>

                {/* Başarı Mesajı */}
                {success && (
                    <div style={{
                        background: '#ecfdf5',
                        border: '1px solid #10b981',
                        borderRadius: '12px',
                        padding: '20px',
                        marginBottom: '24px',
                        color: '#065f46',
                        textAlign: 'center'
                    }}>
                        <div style={{ fontSize: '32px', marginBottom: '8px' }}>🎉</div>
                        <p style={{ fontWeight: 600, marginBottom: '8px' }}>Kayıt başarılı!</p>
                        <p style={{ fontSize: '14px' }}>
                            E-posta adresinize doğrulama linki gönderildi.
                            <br />Lütfen e-postanızı kontrol edin.
                        </p>
                    </div>
                )}

                {/* Hata Mesajı */}
                {error && (
                    <div style={{
                        background: '#fef2f2',
                        border: '1px solid #ef4444',
                        borderRadius: '12px',
                        padding: '16px',
                        marginBottom: '24px',
                        color: '#dc2626',
                        textAlign: 'center'
                    }}>
                        ⚠️ {error}
                    </div>
                )}

                {/* Form */}
                {!success && (
                    <form onSubmit={handleRegister}>
                        <div style={{ marginBottom: '20px' }}>
                            <label style={{ display: 'block', marginBottom: '8px', fontWeight: 500, color: '#374151' }}>
                                Restoran Adı
                            </label>
                            <input
                                type="text"
                                value={companyName}
                                onChange={(e) => setCompanyName(e.target.value)}
                                placeholder="Örn: Lezzet Durağı"
                                required
                                style={{
                                    width: '100%',
                                    padding: '14px 16px',
                                    borderRadius: '12px',
                                    border: '1px solid #e5e7eb',
                                    fontSize: '16px',
                                    outline: 'none',
                                    transition: 'border-color 0.2s, box-shadow 0.2s',
                                    boxSizing: 'border-box'
                                }}
                                onFocus={(e) => {
                                    e.target.style.borderColor = '#2563eb';
                                    e.target.style.boxShadow = '0 0 0 3px rgba(37, 99, 235, 0.1)';
                                }}
                                onBlur={(e) => {
                                    e.target.style.borderColor = '#e5e7eb';
                                    e.target.style.boxShadow = 'none';
                                }}
                            />
                        </div>

                        <div style={{ marginBottom: '20px' }}>
                            <label style={{ display: 'block', marginBottom: '8px', fontWeight: 500, color: '#374151' }}>
                                E-posta
                            </label>
                            <input
                                type="email"
                                value={email}
                                onChange={(e) => setEmail(e.target.value)}
                                placeholder="ornek@restoran.com"
                                required
                                style={{
                                    width: '100%',
                                    padding: '14px 16px',
                                    borderRadius: '12px',
                                    border: '1px solid #e5e7eb',
                                    fontSize: '16px',
                                    outline: 'none',
                                    transition: 'border-color 0.2s, box-shadow 0.2s',
                                    boxSizing: 'border-box'
                                }}
                                onFocus={(e) => {
                                    e.target.style.borderColor = '#2563eb';
                                    e.target.style.boxShadow = '0 0 0 3px rgba(37, 99, 235, 0.1)';
                                }}
                                onBlur={(e) => {
                                    e.target.style.borderColor = '#e5e7eb';
                                    e.target.style.boxShadow = 'none';
                                }}
                            />
                        </div>

                        <div style={{ marginBottom: '20px' }}>
                            <label style={{ display: 'block', marginBottom: '8px', fontWeight: 500, color: '#374151' }}>
                                Şifre
                            </label>
                            <input
                                type="password"
                                value={password}
                                onChange={(e) => setPassword(e.target.value)}
                                placeholder="En az 6 karakter"
                                required
                                style={{
                                    width: '100%',
                                    padding: '14px 16px',
                                    borderRadius: '12px',
                                    border: '1px solid #e5e7eb',
                                    fontSize: '16px',
                                    outline: 'none',
                                    transition: 'border-color 0.2s, box-shadow 0.2s',
                                    boxSizing: 'border-box'
                                }}
                                onFocus={(e) => {
                                    e.target.style.borderColor = '#2563eb';
                                    e.target.style.boxShadow = '0 0 0 3px rgba(37, 99, 235, 0.1)';
                                }}
                                onBlur={(e) => {
                                    e.target.style.borderColor = '#e5e7eb';
                                    e.target.style.boxShadow = 'none';
                                }}
                            />
                        </div>

                        <div style={{ marginBottom: '24px' }}>
                            <label style={{ display: 'block', marginBottom: '8px', fontWeight: 500, color: '#374151' }}>
                                Şifre Tekrar
                            </label>
                            <input
                                type="password"
                                value={confirmPassword}
                                onChange={(e) => setConfirmPassword(e.target.value)}
                                placeholder="Şifrenizi tekrar girin"
                                required
                                style={{
                                    width: '100%',
                                    padding: '14px 16px',
                                    borderRadius: '12px',
                                    border: '1px solid #e5e7eb',
                                    fontSize: '16px',
                                    outline: 'none',
                                    transition: 'border-color 0.2s, box-shadow 0.2s',
                                    boxSizing: 'border-box'
                                }}
                                onFocus={(e) => {
                                    e.target.style.borderColor = '#2563eb';
                                    e.target.style.boxShadow = '0 0 0 3px rgba(37, 99, 235, 0.1)';
                                }}
                                onBlur={(e) => {
                                    e.target.style.borderColor = '#e5e7eb';
                                    e.target.style.boxShadow = 'none';
                                }}
                            />
                        </div>

                        <button
                            type="submit"
                            disabled={loading}
                            style={{
                                width: '100%',
                                padding: '16px',
                                borderRadius: '12px',
                                background: loading ? '#93c5fd' : 'linear-gradient(90deg, #2563eb, #7c3aed)',
                                color: 'white',
                                fontSize: '16px',
                                fontWeight: 600,
                                border: 'none',
                                cursor: loading ? 'not-allowed' : 'pointer',
                                boxShadow: '0 10px 25px rgba(37, 99, 235, 0.25)',
                                transition: 'all 0.2s'
                            }}
                        >
                            {loading ? '⏳ Kayıt yapılıyor...' : '🚀 Ücretsiz Denemeye Başla'}
                        </button>
                    </form>
                )}

                {/* Giriş Linki */}
                <p style={{ textAlign: 'center', marginTop: '24px', color: '#6b7280' }}>
                    Zaten hesabınız var mı?{' '}
                    <Link href="/login" style={{ color: '#2563eb', fontWeight: 600, textDecoration: 'none' }}>
                        Giriş Yap
                    </Link>
                </p>

                {/* Özellikler */}
                {!success && (
                    <div style={{
                        marginTop: '32px',
                        paddingTop: '24px',
                        borderTop: '1px solid #e5e7eb',
                        display: 'grid',
                        gridTemplateColumns: 'repeat(2, 1fr)',
                        gap: '12px'
                    }}>
                        {[
                            '✓ 14 gün ücretsiz deneme',
                            '✓ Kredi kartı gerekmez',
                            '✓ Anında kurulum',
                            '✓ 7/24 destek'
                        ].map((item, i) => (
                            <div key={i} style={{ color: '#6b7280', fontSize: '13px' }}>{item}</div>
                        ))}
                    </div>
                )}
            </div>
        </main>
    );
}
