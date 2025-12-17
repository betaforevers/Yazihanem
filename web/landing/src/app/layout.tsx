import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
  display: "swap",
});

export const metadata: Metadata = {
  title: "Yazıhanem - Balıkçılık Sektörü Yönetim Sistemi | SaaS",
  description: "Balık ihracatçıları ve su ürünleri işletmeleri için tasarlanmış dijital yönetim platformu. Stok takibi, soğuk zincir kontrolü, nakliye yönetimi ve raporlama bir arada.",
  keywords: ["balıkçılık yazılımı", "balık ihracat sistemi", "su ürünleri yönetimi", "soğuk zincir takibi", "balık stok yönetimi", "seafood management"],
  authors: [{ name: "Yazıhanem" }],
  creator: "Yazıhanem",
  publisher: "Yazıhanem",
  metadataBase: new URL("https://yazihanem.com"),
  openGraph: {
    title: "Yazıhanem - Balıkçılık Sektörü Dijital Yönetim Platformu",
    description: "Balık ihracatçıları ve su ürünleri işletmeleri için özel tasarlanmış yönetim sistemi.",
    url: "https://yazihanem.com",
    siteName: "Yazıhanem",
    locale: "tr_TR",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Yazıhanem - Balıkçılık Sektörü Yönetim Sistemi",
    description: "Balık ihracatçıları için dijital dönüşüm platformu.",
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
    },
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="tr">
      <body className={`${inter.variable} font-sans antialiased`}>
        {children}
      </body>
    </html>
  );
}
