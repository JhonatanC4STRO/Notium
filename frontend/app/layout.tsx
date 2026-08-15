import type { Metadata } from "next";
import { headers } from "next/headers";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const geistSans = Geist({ variable: "--font-geist-sans", subsets: ["latin"] });
const geistMono = Geist_Mono({ variable: "--font-geist-mono", subsets: ["latin"] });

export async function generateMetadata(): Promise<Metadata> {
  const requestHeaders = await headers();
  const host = requestHeaders.get("x-forwarded-host") ?? requestHeaders.get("host") ?? "notium.shona.lat";
  const protocol = requestHeaders.get("x-forwarded-proto") ?? (host.includes("localhost") ? "http" : "https");
  const metadataBase = new URL(`${protocol}://${host}`);

  return {
    metadataBase,
    title: "Notium — Notas offline-first para Android",
    description: "Aplicación Android cifrada que funciona sin conexión y sincroniza cuando la red vuelve.",
    keywords: ["Flutter", "offline-first", "Android", "SQLCipher", "PostgreSQL", "sincronización"],
    authors: [{ name: "Jhonatan Castro" }],
    openGraph: {
      title: "Notium — Notas offline-first",
      description: "Tus notas no deberían esperar por la red.",
      type: "website",
      locale: "es_CO",
      images: [{ url: "/og.png", width: 1536, height: 1024, alt: "Notium, notas offline-first" }],
    },
    twitter: {
      card: "summary_large_image",
      title: "Notium — Notas offline-first",
      description: "Tus notas no deberían esperar por la red.",
      images: ["/og.png"],
    },
  };
}

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="es">
      <body className={`${geistSans.variable} ${geistMono.variable}`}>{children}</body>
    </html>
  );
}
