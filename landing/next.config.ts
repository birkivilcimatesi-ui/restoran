import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Flutter uygulaması için /app yolunu static olarak serve et
  async rewrites() {
    return [
      {
        source: '/app',
        destination: '/app/index.html',
      },
      {
        source: '/app/:path*',
        destination: '/app/:path*',
      },
    ];
  },
};

export default nextConfig;
