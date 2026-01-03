"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase";

interface Restaurant {
    id: string;
    name: string;
    subdomain?: string;
    address?: string;
    phone?: string;
    created_at: string;
}

export default function DashboardPage() {
    const router = useRouter();
    const [user, setUser] = useState<{ email?: string; user_metadata?: { company_name?: string } } | null>(null);
    const [restaurants, setRestaurants] = useState<Restaurant[]>([]);
    const [loading, setLoading] = useState(true);
    const [showAddModal, setShowAddModal] = useState(false);
    const [newRestaurantName, setNewRestaurantName] = useState("");
    const [newRestaurantSubdomain, setNewRestaurantSubdomain] = useState("");
    const [addingRestaurant, setAddingRestaurant] = useState(false);

    // Subdomain düzenleme state'leri
    const [editingRestaurant, setEditingRestaurant] = useState<Restaurant | null>(null);
    const [editSubdomain, setEditSubdomain] = useState("");
    const [savingSubdomain, setSavingSubdomain] = useState(false);

    // Hata mesajı state'i
    const [errorMessage, setErrorMessage] = useState("");

    // 3 nokta menüsü state'i
    const [openMenuId, setOpenMenuId] = useState<string | null>(null);
    const [deletingId, setDeletingId] = useState<string | null>(null);

    useEffect(() => {
        checkSession();
    }, []);

    const checkSession = async () => {
        const { data: { session } } = await supabase.auth.getSession();

        if (!session) {
            router.push("/login");
            return;
        }

        setUser(session.user);
        await fetchRestaurants(session.user.id);
        setLoading(false);
    };

    const fetchRestaurants = async (userId: string) => {
        // Kullanıcıya ait restoranları getir
        const { data, error } = await supabase
            .from('companies')
            .select('*')
            .eq('owner_id', userId)
            .order('created_at', { ascending: false });

        if (!error && data) {
            setRestaurants(data);
        }
    };

    const handleAddRestaurant = async () => {
        if (!newRestaurantName.trim() || !user) return;

        setAddingRestaurant(true);

        const { data: { session } } = await supabase.auth.getSession();

        // Subdomain boşsa, restoran isminden otomatik oluştur
        let subdomain = newRestaurantSubdomain.trim().toLowerCase();
        if (!subdomain) {
            // Türkçe karakterleri dönüştür ve sadece harf/rakam/tire bırak
            subdomain = newRestaurantName.trim().toLowerCase()
                .replace(/ğ/g, 'g').replace(/ü/g, 'u').replace(/ş/g, 's')
                .replace(/ı/g, 'i').replace(/ö/g, 'o').replace(/ç/g, 'c')
                .replace(/[^a-z0-9]/g, '-')
                .replace(/-+/g, '-')
                .replace(/^-|-$/g, '');
        }

        const { data, error } = await supabase
            .from('companies')
            .insert({
                name: newRestaurantName.trim(),
                subdomain: subdomain || null,
                owner_id: session?.user.id,
            })
            .select()
            .single();

        if (!error && data) {
            setRestaurants(prev => [data, ...prev]);
            setNewRestaurantName("");
            setNewRestaurantSubdomain("");
            setShowAddModal(false);
            setErrorMessage("");
        } else if (error) {
            // Subdomain çakışması kontrolü
            if (error.message.includes('duplicate') || error.message.includes('unique')) {
                setErrorMessage('Bu subdomain zaten kullanılıyor. Lütfen başka bir subdomain seçin.');
            } else {
                setErrorMessage('Bir hata oluştu: ' + error.message);
            }
        }

        setAddingRestaurant(false);
    };

    const handleOpenRestaurant = (restaurant: Restaurant) => {
        // Flutter uygulamasına yönlendirme - yeni sekmede aç
        window.open(`/app?company_id=${restaurant.id}`, '_blank');
    };

    const handleLogout = async () => {
        await supabase.auth.signOut();
        router.push("/login");
    };

    // Restoran silme
    const handleDeleteRestaurant = async (restaurantId: string) => {
        if (!confirm('Bu restoranı silmek istediğinizden emin misiniz?')) return;

        setDeletingId(restaurantId);

        const { error } = await supabase
            .from('companies')
            .delete()
            .eq('id', restaurantId);

        if (!error) {
            setRestaurants(prev => prev.filter(r => r.id !== restaurantId));
        }

        setDeletingId(null);
        setOpenMenuId(null);
    };

    // Subdomain kopyalama
    const handleCopySubdomain = (subdomain: string) => {
        const url = `https://${subdomain}.restosync.com`;
        navigator.clipboard.writeText(url);
        alert('Subdomain URL kopyalandı: ' + url);
        setOpenMenuId(null);
    };

    // Subdomain düzenleme
    const handleEditSubdomain = (restaurant: Restaurant) => {
        setEditingRestaurant(restaurant);
        setEditSubdomain(restaurant.subdomain || "");
        setOpenMenuId(null);
    };

    const handleSaveSubdomain = async () => {
        if (!editingRestaurant) return;
        setSavingSubdomain(true);

        const { error } = await supabase
            .from('companies')
            .update({ subdomain: editSubdomain.trim().toLowerCase() || null })
            .eq('id', editingRestaurant.id);

        if (!error) {
            setRestaurants(prev => prev.map(r =>
                r.id === editingRestaurant.id
                    ? { ...r, subdomain: editSubdomain.trim().toLowerCase() || undefined }
                    : r
            ));
            setEditingRestaurant(null);
            setEditSubdomain("");
        }

        setSavingSubdomain(false);
    };

    if (loading) {
        return (
            <main style={{
                background: 'linear-gradient(135deg, #f9fafb 0%, #eff6ff 100%)',
                minHeight: '100vh',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontFamily: "'Inter', system-ui, sans-serif"
            }}>
                <div style={{ textAlign: 'center' }}>
                    <div style={{ fontSize: '48px', marginBottom: '16px' }}>🍽️</div>
                    <p style={{ color: '#6b7280' }}>Yükleniyor...</p>
                </div>
            </main>
        );
    }

    return (
        <main style={{
            background: 'linear-gradient(135deg, #f9fafb 0%, #eff6ff 100%)',
            minHeight: '100vh',
            fontFamily: "'Inter', system-ui, sans-serif"
        }}>
            {/* Header */}
            <header style={{
                background: 'white',
                borderBottom: '1px solid #e5e7eb',
                padding: '16px 24px',
                position: 'sticky',
                top: 0,
                zIndex: 10
            }}>
                <div style={{
                    maxWidth: '1280px',
                    margin: '0 auto',
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center'
                }}>
                    <Link href="/" style={{ textDecoration: 'none', display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <div style={{
                            background: '#2563eb',
                            padding: '8px',
                            borderRadius: '8px',
                            color: 'white',
                            fontSize: '20px'
                        }}>🍽️</div>
                        <span style={{ fontSize: '20px', fontWeight: 'bold', color: '#111827' }}>
                            Resto<span style={{ color: '#2563eb' }}>Sync</span>
                        </span>
                    </Link>

                    <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
                        <span style={{ color: '#6b7280', fontSize: '14px' }}>
                            {user?.email}
                        </span>
                        <button
                            onClick={handleLogout}
                            style={{
                                background: 'transparent',
                                border: '1px solid #e5e7eb',
                                padding: '8px 16px',
                                borderRadius: '8px',
                                color: '#374151',
                                cursor: 'pointer',
                                fontSize: '14px',
                                fontWeight: 500
                            }}
                        >
                            Çıkış Yap
                        </button>
                    </div>
                </div>
            </header>

            {/* Content */}
            <div style={{ maxWidth: '1280px', margin: '0 auto', padding: '32px 24px' }}>
                {/* Title */}
                <div style={{ marginBottom: '32px' }}>
                    <h1 style={{ fontSize: '28px', fontWeight: 700, color: '#111827', marginBottom: '8px' }}>
                        🏪 Restoranlarım
                    </h1>
                    <p style={{ color: '#6b7280' }}>
                        Yönetmek istediğiniz restoranı seçin veya yeni bir restoran ekleyin.
                    </p>
                </div>

                {/* Restaurant Grid */}
                <div style={{
                    display: 'grid',
                    gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))',
                    gap: '24px'
                }}>
                    {/* Add New Restaurant Card */}
                    <div
                        onClick={() => setShowAddModal(true)}
                        style={{
                            background: 'white',
                            borderRadius: '16px',
                            padding: '32px',
                            border: '2px dashed #e5e7eb',
                            cursor: 'pointer',
                            display: 'flex',
                            flexDirection: 'column',
                            alignItems: 'center',
                            justifyContent: 'center',
                            minHeight: '200px',
                            transition: 'all 0.2s ease'
                        }}
                        onMouseOver={(e) => {
                            e.currentTarget.style.borderColor = '#2563eb';
                            e.currentTarget.style.background = '#f0f9ff';
                        }}
                        onMouseOut={(e) => {
                            e.currentTarget.style.borderColor = '#e5e7eb';
                            e.currentTarget.style.background = 'white';
                        }}
                    >
                        <div style={{
                            width: '64px',
                            height: '64px',
                            background: '#eff6ff',
                            borderRadius: '50%',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            marginBottom: '16px',
                            fontSize: '28px',
                            color: '#2563eb'
                        }}>
                            +
                        </div>
                        <span style={{ color: '#2563eb', fontWeight: 600, fontSize: '16px' }}>
                            Yeni Restoran Ekle
                        </span>
                    </div>

                    {/* Restaurant Cards */}
                    {restaurants.map((restaurant) => (
                        <div
                            key={restaurant.id}
                            style={{
                                background: 'white',
                                borderRadius: '16px',
                                padding: '24px', // Increased padding for cleaner look
                                boxShadow: '0 4px 20px rgba(0, 0, 0, 0.05)',
                                transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)', // Smooth animation
                                border: '1px solid #e5e7eb',
                                position: 'relative',
                                display: 'flex',
                                flexDirection: 'column',
                                flex: 1, // Allow flex growth
                                minHeight: '320px', // Taller card as requested
                                justifyContent: 'space-between' // Space out content
                            }}
                            onMouseOver={(e) => {
                                e.currentTarget.style.transform = 'translateY(-8px)'; // More pronounced lift
                                e.currentTarget.style.boxShadow = '0 20px 40px rgba(37, 99, 235, 0.12)';
                                e.currentTarget.style.borderColor = '#2563eb';
                            }}
                            onMouseOut={(e) => {
                                e.currentTarget.style.transform = 'translateY(0)';
                                e.currentTarget.style.boxShadow = '0 4px 20px rgba(0, 0, 0, 0.05)';
                                e.currentTarget.style.borderColor = '#e5e7eb';
                            }}
                        >
                            {/* Top Section: Header & Menu */}
                            <div>
                                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '20px' }}>
                                    {/* Icon */}
                                    <div style={{
                                        width: '72px', // Larger icon
                                        height: '72px',
                                        background: 'linear-gradient(135deg, #eff6ff, #dbeafe)',
                                        borderRadius: '20px',
                                        display: 'flex',
                                        alignItems: 'center',
                                        justifyContent: 'center',
                                        fontSize: '32px',
                                        boxShadow: 'inset 0 2px 4px rgba(255,255,255,0.5)',
                                        border: '1px solid #dbeafe'
                                    }}>
                                        🍽️
                                    </div>

                                    {/* 3 Dots Menu Button */}
                                    <div style={{ position: 'relative' }}>
                                        <button
                                            onClick={(e) => { e.stopPropagation(); setOpenMenuId(openMenuId === restaurant.id ? null : restaurant.id); }}
                                            style={{
                                                background: openMenuId === restaurant.id ? '#f3f4f6' : 'white',
                                                border: '1px solid',
                                                borderColor: openMenuId === restaurant.id ? '#e5e7eb' : '#f3f4f6',
                                                cursor: 'pointer',
                                                width: '36px',
                                                height: '36px',
                                                borderRadius: '10px',
                                                fontSize: '20px',
                                                display: 'flex',
                                                alignItems: 'center',
                                                justifyContent: 'center',
                                                color: '#6b7280',
                                                transition: 'all 0.2s',
                                                boxShadow: '0 2px 4px rgba(0,0,0,0.02)'
                                            }}
                                            onMouseOver={(e) => { e.currentTarget.style.borderColor = '#d1d5db'; e.currentTarget.style.color = '#111827'; }}
                                            onMouseOut={(e) => {
                                                if (openMenuId !== restaurant.id) {
                                                    e.currentTarget.style.borderColor = '#f3f4f6';
                                                    e.currentTarget.style.color = '#6b7280';
                                                }
                                            }}
                                        >
                                            ⋮
                                        </button>

                                        {/* Menu Dropdown */}
                                        {openMenuId === restaurant.id && (
                                            <div style={{
                                                position: 'absolute',
                                                top: '120%',
                                                right: 0,
                                                background: 'white',
                                                borderRadius: '16px',
                                                boxShadow: '0 10px 40px rgba(0,0,0,0.15)',
                                                border: '1px solid #e5e7eb',
                                                zIndex: 50,
                                                minWidth: '200px',
                                                overflow: 'hidden',
                                                padding: '6px'
                                            }}
                                                onClick={(e) => e.stopPropagation()} // Prevent card click
                                            >
                                                <button
                                                    onClick={() => handleEditSubdomain(restaurant)}
                                                    style={{
                                                        width: '100%',
                                                        padding: '10px 12px',
                                                        background: 'transparent',
                                                        border: 'none',
                                                        textAlign: 'left',
                                                        cursor: 'pointer',
                                                        fontSize: '14px',
                                                        color: '#374151',
                                                        display: 'flex',
                                                        alignItems: 'center',
                                                        gap: '10px',
                                                        borderRadius: '8px',
                                                        fontWeight: 500
                                                    }}
                                                    onMouseOver={(e) => e.currentTarget.style.background = '#f3f4f6'}
                                                    onMouseOut={(e) => e.currentTarget.style.background = 'transparent'}
                                                >
                                                    ⚙️ Ayarlar
                                                </button>
                                                {restaurant.subdomain && (
                                                    <button
                                                        onClick={() => handleCopySubdomain(restaurant.subdomain!)}
                                                        style={{
                                                            width: '100%',
                                                            padding: '10px 12px',
                                                            background: 'transparent',
                                                            border: 'none',
                                                            textAlign: 'left',
                                                            cursor: 'pointer',
                                                            fontSize: '14px',
                                                            color: '#374151',
                                                            display: 'flex',
                                                            alignItems: 'center',
                                                            gap: '10px',
                                                            borderRadius: '8px',
                                                            fontWeight: 500
                                                        }}
                                                        onMouseOver={(e) => e.currentTarget.style.background = '#f3f4f6'}
                                                        onMouseOut={(e) => e.currentTarget.style.background = 'transparent'}
                                                    >
                                                        📋 Kopyala
                                                    </button>
                                                )}
                                                <div style={{ height: '1px', background: '#e5e7eb', margin: '4px 0' }} />
                                                <button
                                                    onClick={() => handleDeleteRestaurant(restaurant.id)}
                                                    disabled={deletingId === restaurant.id}
                                                    style={{
                                                        width: '100%',
                                                        padding: '10px 12px',
                                                        background: 'transparent',
                                                        border: 'none',
                                                        textAlign: 'left',
                                                        cursor: deletingId === restaurant.id ? 'not-allowed' : 'pointer',
                                                        fontSize: '14px',
                                                        color: '#ef4444',
                                                        display: 'flex',
                                                        alignItems: 'center',
                                                        gap: '10px',
                                                        borderRadius: '8px',
                                                        fontWeight: 500
                                                    }}
                                                    onMouseOver={(e) => e.currentTarget.style.background = '#fef2f2'}
                                                    onMouseOut={(e) => e.currentTarget.style.background = 'transparent'}
                                                >
                                                    🗑️ {deletingId === restaurant.id ? 'Siliniyor...' : 'Sil'}
                                                </button>
                                            </div>
                                        )}
                                    </div>
                                </div>

                                {/* Restaurant Info */}
                                <div style={{ marginBottom: '24px' }}>
                                    <h3 style={{ fontSize: '22px', fontWeight: 700, color: '#111827', margin: '0 0 8px 0', lineHeight: 1.3 }}>
                                        {restaurant.name}
                                    </h3>

                                    {/* Subdomain Status Icons */}
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '8px' }}>
                                        <div style={{
                                            display: 'flex',
                                            alignItems: 'center',
                                            justifyContent: 'center',
                                            width: '24px',
                                            height: '24px',
                                            borderRadius: '50%',
                                            background: restaurant.subdomain ? '#ecfdf5' : '#fef2f2',
                                            color: restaurant.subdomain ? '#10b981' : '#ef4444',
                                            fontSize: '14px'
                                        }} title={restaurant.subdomain ? `Subdomain: ${restaurant.subdomain}` : "Subdomain yok"}>
                                            🌐
                                        </div>
                                        {restaurant.subdomain ? (
                                            <div style={{
                                                display: 'flex',
                                                alignItems: 'center',
                                                gap: '6px',
                                                background: '#ecfdf5',
                                                padding: '4px 10px',
                                                borderRadius: '20px',
                                                border: '1px solid #d1fae5'
                                            }}>
                                                <span style={{ fontSize: '14px' }}>✅</span>
                                                <span style={{ color: '#059669', fontSize: '13px', fontWeight: 600 }}>Aktif</span>
                                            </div>
                                        ) : (
                                            <div style={{
                                                display: 'flex',
                                                alignItems: 'center',
                                                gap: '6px',
                                                background: '#fef2f2',
                                                padding: '4px 10px',
                                                borderRadius: '20px',
                                                border: '1px solid #fee2e2'
                                            }}>
                                                <span style={{ fontSize: '14px' }}>❌</span>
                                                <span style={{ color: '#dc2626', fontSize: '13px', fontWeight: 600 }}>Pasif</span>
                                            </div>
                                        )}
                                    </div>

                                    <p style={{ color: '#9ca3af', fontSize: '13px', display: 'flex', alignItems: 'center', gap: '6px' }}>
                                        📅 {new Date(restaurant.created_at).toLocaleDateString('tr-TR', { day: 'numeric', month: 'long', year: 'numeric' })}
                                    </p>
                                </div>
                            </div>

                            {/* Action Button */}
                            <button
                                onClick={() => handleOpenRestaurant(restaurant)}
                                style={{
                                    width: '100%',
                                    padding: '16px',
                                    borderRadius: '14px',
                                    border: 'none',
                                    background: 'linear-gradient(135deg, #2563eb, #1d4ed8)',
                                    color: 'white',
                                    fontSize: '15px',
                                    fontWeight: 600,
                                    cursor: 'pointer',
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    gap: '10px',
                                    boxShadow: '0 4px 12px rgba(37, 99, 235, 0.2)',
                                    transition: 'all 0.2s',
                                    marginTop: 'auto'
                                }}
                                onMouseOver={(e) => {
                                    e.currentTarget.style.transform = 'translateY(-2px)';
                                    e.currentTarget.style.boxShadow = '0 8px 20px rgba(37, 99, 235, 0.3)';
                                }}
                                onMouseOut={(e) => {
                                    e.currentTarget.style.transform = 'translateY(0)';
                                    e.currentTarget.style.boxShadow = '0 4px 12px rgba(37, 99, 235, 0.2)';
                                }}
                            >
                                🚀 Adisyon Sistemini Aç
                            </button>
                        </div>
                    ))}
                </div>

                {/* Empty State */}
                {restaurants.length === 0 && (
                    <div style={{
                        textAlign: 'center',
                        padding: '48px',
                        color: '#6b7280'
                    }}>
                        <div style={{ fontSize: '64px', marginBottom: '16px', opacity: 0.5 }}>🏪</div>
                        <p>Henüz bir restoranınız yok. Yeni bir restoran ekleyerek başlayın.</p>
                    </div>
                )}
            </div>

            {/* Add Restaurant Modal */}
            {showAddModal && (
                <div style={{
                    position: 'fixed',
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    background: 'rgba(0, 0, 0, 0.5)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    zIndex: 100,
                    padding: '24px'
                }}>
                    <div style={{
                        background: 'white',
                        borderRadius: '24px',
                        padding: '32px',
                        width: '100%',
                        maxWidth: '440px',
                        boxShadow: '0 25px 50px rgba(0, 0, 0, 0.25)'
                    }}>
                        <h2 style={{ fontSize: '24px', fontWeight: 700, marginBottom: '8px', color: '#111827' }}>
                            🏪 Yeni Restoran Ekle
                        </h2>
                        <p style={{ color: '#6b7280', marginBottom: '24px' }}>
                            Restoranınızın adını ve subdomain'ini girin.
                        </p>

                        <input
                            type="text"
                            value={newRestaurantName}
                            onChange={(e) => { setNewRestaurantName(e.target.value); setErrorMessage(""); }}
                            placeholder="Restoran Adı (Örn: Lezzet Durağı)"
                            autoFocus
                            style={{
                                width: '100%',
                                padding: '14px 16px',
                                borderRadius: '12px',
                                border: '1px solid #e5e7eb',
                                fontSize: '16px',
                                outline: 'none',
                                marginBottom: '16px',
                                boxSizing: 'border-box',
                                color: '#111827',
                                background: 'white'
                            }}
                            onFocus={(e) => e.target.style.borderColor = '#2563eb'}
                            onBlur={(e) => e.target.style.borderColor = '#e5e7eb'}
                        />

                        <div style={{ position: 'relative', marginBottom: '16px' }}>
                            <input
                                type="text"
                                value={newRestaurantSubdomain}
                                onChange={(e) => { setNewRestaurantSubdomain(e.target.value.toLowerCase().replace(/[^a-z0-9-]/g, '')); setErrorMessage(""); }}
                                placeholder="subdomain (boş bırakılırsa otomatik oluşur)"
                                style={{
                                    width: '100%',
                                    padding: '14px 16px',
                                    paddingRight: '140px',
                                    borderRadius: '12px',
                                    border: '1px solid #e5e7eb',
                                    fontSize: '16px',
                                    outline: 'none',
                                    boxSizing: 'border-box',
                                    color: '#111827',
                                    background: 'white'
                                }}
                                onFocus={(e) => e.target.style.borderColor = '#2563eb'}
                                onBlur={(e) => e.target.style.borderColor = '#e5e7eb'}
                            />
                            <span style={{
                                position: 'absolute',
                                right: '16px',
                                top: '50%',
                                transform: 'translateY(-50%)',
                                color: '#9ca3af',
                                fontSize: '14px'
                            }}>
                                .restosync.com
                            </span>
                        </div>

                        {/* Hata Mesajı */}
                        {errorMessage && (
                            <div style={{
                                background: '#fef2f2',
                                border: '1px solid #fee2e2',
                                borderRadius: '8px',
                                padding: '12px',
                                marginBottom: '16px',
                                color: '#dc2626',
                                fontSize: '14px'
                            }}>
                                ⚠️ {errorMessage}
                            </div>
                        )}

                        <div style={{ display: 'flex', gap: '12px' }}>
                            <button
                                onClick={() => setShowAddModal(false)}
                                style={{
                                    flex: 1,
                                    padding: '14px',
                                    borderRadius: '12px',
                                    border: '1px solid #e5e7eb',
                                    background: 'white',
                                    color: '#374151',
                                    fontSize: '16px',
                                    fontWeight: 500,
                                    cursor: 'pointer'
                                }}
                            >
                                İptal
                            </button>
                            <button
                                onClick={handleAddRestaurant}
                                disabled={addingRestaurant || !newRestaurantName.trim()}
                                style={{
                                    flex: 1,
                                    padding: '14px',
                                    borderRadius: '12px',
                                    border: 'none',
                                    background: addingRestaurant || !newRestaurantName.trim() ? '#93c5fd' : '#2563eb',
                                    color: 'white',
                                    fontSize: '16px',
                                    fontWeight: 600,
                                    cursor: addingRestaurant || !newRestaurantName.trim() ? 'not-allowed' : 'pointer'
                                }}
                            >
                                {addingRestaurant ? '⏳ Ekleniyor...' : '✓ Ekle'}
                            </button>
                        </div>
                    </div>
                </div >
            )
            }

            {/* Subdomain Düzenleme Modalı */}
            {
                editingRestaurant && (
                    <div style={{
                        position: 'fixed',
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        background: 'rgba(0, 0, 0, 0.5)',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        zIndex: 100,
                        padding: '24px'
                    }}>
                        <div style={{
                            background: 'white',
                            borderRadius: '24px',
                            padding: '32px',
                            width: '100%',
                            maxWidth: '440px',
                            boxShadow: '0 25px 50px rgba(0, 0, 0, 0.25)'
                        }}>
                            <h2 style={{ fontSize: '24px', fontWeight: 700, marginBottom: '8px', color: '#111827' }}>
                                🌐 Subdomain Ayarla
                            </h2>
                            <p style={{ color: '#6b7280', marginBottom: '8px' }}>
                                <strong>{editingRestaurant.name}</strong> için subdomain belirleyin.
                            </p>
                            <p style={{ color: '#9ca3af', fontSize: '14px', marginBottom: '24px' }}>
                                Bu subdomain ile doğrudan adisyon sistemine erişilebilir.
                            </p>

                            <div style={{ position: 'relative', marginBottom: '24px' }}>
                                <input
                                    type="text"
                                    value={editSubdomain}
                                    onChange={(e) => setEditSubdomain(e.target.value.toLowerCase().replace(/[^a-z0-9-]/g, ''))}
                                    placeholder="subdomain"
                                    autoFocus
                                    style={{
                                        width: '100%',
                                        padding: '14px 16px',
                                        paddingRight: '140px',
                                        borderRadius: '12px',
                                        border: '1px solid #e5e7eb',
                                        fontSize: '16px',
                                        outline: 'none',
                                        boxSizing: 'border-box',
                                        color: '#111827',
                                        background: 'white'
                                    }}
                                    onFocus={(e) => e.target.style.borderColor = '#2563eb'}
                                    onBlur={(e) => e.target.style.borderColor = '#e5e7eb'}
                                />
                                <span style={{
                                    position: 'absolute',
                                    right: '16px',
                                    top: '50%',
                                    transform: 'translateY(-50%)',
                                    color: '#9ca3af',
                                    fontSize: '14px'
                                }}>
                                    .restosync.com
                                </span>
                            </div>

                            <div style={{ display: 'flex', gap: '12px' }}>
                                <button
                                    onClick={() => { setEditingRestaurant(null); setEditSubdomain(""); }}
                                    style={{
                                        flex: 1,
                                        padding: '14px',
                                        borderRadius: '12px',
                                        border: '1px solid #e5e7eb',
                                        background: 'white',
                                        color: '#374151',
                                        fontSize: '16px',
                                        fontWeight: 500,
                                        cursor: 'pointer'
                                    }}
                                >
                                    İptal
                                </button>
                                <button
                                    onClick={handleSaveSubdomain}
                                    disabled={savingSubdomain}
                                    style={{
                                        flex: 1,
                                        padding: '14px',
                                        borderRadius: '12px',
                                        border: 'none',
                                        background: savingSubdomain ? '#93c5fd' : '#2563eb',
                                        color: 'white',
                                        fontSize: '16px',
                                        fontWeight: 600,
                                        cursor: savingSubdomain ? 'not-allowed' : 'pointer'
                                    }}
                                >
                                    {savingSubdomain ? '⏳ Kaydediliyor...' : '✓ Kaydet'}
                                </button>
                            </div>
                        </div>
                    </div>
                )
            }
        </main >
    );
}
