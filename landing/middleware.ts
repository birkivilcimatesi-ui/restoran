import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'
import { createClient } from '@supabase/supabase-js'

// Supabase client (middleware'de kullanım için)
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://gilzmsjcdzptuwiwnfuy.supabase.co'
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdpbHptc2pjZHpwdHV3aXduZnV5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjcxNzE2MDMsImV4cCI6MjA4Mjc0NzYwM30.--2L7OpaOx2uh7GhAZUczx-OEZhTjUSY33xEZbjFEmk'

const supabase = createClient(supabaseUrl, supabaseAnonKey)

// Ana domain (production'da değiştirilecek)
const MAIN_DOMAIN = process.env.MAIN_DOMAIN || 'restosync.com'
const LOCALHOST_PORTS = ['localhost', '127.0.0.1']

export async function middleware(request: NextRequest) {
    const { pathname } = request.nextUrl
    const host = request.headers.get('host') || ''

    // Subdomain kontrolü
    // Örnek: kahvediyari.restosync.com veya test.localhost:3000
    let subdomain: string | null = null

    if (LOCALHOST_PORTS.some(lh => host.includes(lh))) {
        // Localhost'ta: test.localhost:3000 formatı
        const parts = host.split('.')[0]
        if (parts !== 'localhost' && parts !== '127') {
            subdomain = parts
        }
    } else {
        // Production'da: kahvediyari.restosync.com formatı
        const hostWithoutPort = host.split(':')[0]
        if (hostWithoutPort.endsWith(MAIN_DOMAIN)) {
            const parts = hostWithoutPort.replace(`.${MAIN_DOMAIN}`, '')
            if (parts && parts !== 'www' && !parts.includes('.')) {
                subdomain = parts
            }
        }
    }

    // Subdomain varsa, company_id'yi bul ve Flutter'a yönlendir
    if (subdomain && pathname === '/') {
        console.log('🔍 Subdomain detected:', subdomain)
        try {
            const { data: company, error } = await supabase
                .from('companies')
                .select('id')
                .eq('subdomain', subdomain)
                .single()

            console.log('🔍 Supabase query result:', { company, error })

            if (company) {
                // Flutter uygulamasına yönlendir
                const url = request.nextUrl.clone()
                url.pathname = '/app'
                url.searchParams.set('company_id', company.id)
                console.log('✅ Redirecting to:', url.toString())
                return NextResponse.redirect(url)
            } else {
                console.log('⚠️ No company found for subdomain:', subdomain)
            }
        } catch (error) {
            console.error('❌ Subdomain lookup error:', error)
        }
    }

    // Protected routes kontrolü
    const protectedRoutes = ['/dashboard']
    if (protectedRoutes.some(route => pathname.startsWith(route))) {
        return NextResponse.next()
    }

    return NextResponse.next()
}

export const config = {
    matcher: ['/', '/dashboard/:path*']
}

