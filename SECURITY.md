# Security Practices

## Environment Variables

This project uses environment variables to manage sensitive information. Do **NOT** hardcode secrets in the codebase.

### Web (Landing)

Create a `.env.local` file in the `landing` directory based on `.env.example`:

```bash
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
```

### Mobile (Flutter)

For the Flutter app, ensure you update `lib/core/constants/api_constants.dart` with your keys or use `--dart-define` to inject them at build time.

## Row Level Security (RLS)

**CRITICAL:** Do not disable RLS. It is the primary security mechanism for the database.

*   `rls_policies.sql` contains the active security policies.
*   Ensure RLS is enabled on all tables containing sensitive user data.
*   Never use scripts like `rls_disable_dev.sql` in production or shared environments.
