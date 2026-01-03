"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase";

export default function LoginPage() {
    const router = useRouter();
    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);

    const handleLogin = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        setError(null);

        try {
            const { error } = await supabase.auth.signInWithPassword({
                email,
                password,
            });

            if (error) throw error;

            // Başarılı giriş - dashboard'a yönlendir
            router.push("/dashboard");
        } catch (err: unknown) {
            setError(err instanceof Error ? err.message : "Giriş yapılırken bir hata oluştu");
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
                maxWidth: '440px',
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
                        Tekrar Hoş Geldiniz
                    </h1>
                    <p style={{ color: '#6b7280', fontSize: '16px' }}>
                        Hesabınıza giriş yapın
                    </p>
                </div>

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
                <form onSubmit={handleLogin}>
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

                    <div style={{ marginBottom: '24px' }}>
                        <label style={{ display: 'block', marginBottom: '8px', fontWeight: 500, color: '#374151' }}>
                            Şifre
                        </label>
                        <input
                            type="password"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            placeholder="••••••••"
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
                            background: loading ? '#93c5fd' : '#2563eb',
                            color: 'white',
                            fontSize: '16px',
                            fontWeight: 600,
                            border: 'none',
                            cursor: loading ? 'not-allowed' : 'pointer',
                            boxShadow: '0 10px 25px rgba(37, 99, 235, 0.25)',
                            transition: 'all 0.2s'
                        }}
                    >
                        {loading ? '⏳ Giriş yapılıyor...' : '🚀 Giriş Yap'}
                    </button>
                </form>

                {/* Kayıt Linki */}
                <p style={{ textAlign: 'center', marginTop: '24px', color: '#6b7280' }}>
                    Hesabınız yok mu?{' '}
                    <Link href="/register" style={{ color: '#2563eb', fontWeight: 600, textDecoration: 'none' }}>
                        Kayıt Ol
                    </Link>
                </p>
            </div>
        </main>
    );
}
