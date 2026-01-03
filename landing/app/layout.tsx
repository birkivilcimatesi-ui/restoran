import type { Metadata } from "next";
import { Geist } from "next/font/google";
import "./globals.css";

const geist = Geist({
  subsets: ["latin"],
  variable: "--font-geist-sans",
});

export const metadata: Metadata = {
  title: "TableFlow | Akıllı Restoran Yönetim Sistemi",
  description: "Restoranınızı dijitalleştirin. Masa yönetimi, sipariş takibi ve anlık senkronizasyon ile işletmenizi modernize edin.",
  keywords: ["restoran", "adisyon", "sipariş yönetimi", "masa takibi", "pos sistemi"],
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="tr">
      <body className={geist.variable}>
        {children}
      </body>
    </html>
  );
}
