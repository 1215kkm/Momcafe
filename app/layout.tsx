import type { Metadata, Viewport } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: {
    default: "심박 — 모임의 생사를 책임지는 곳",
    template: "%s · 심박"
  },
  description:
    "누구나 카페를 만드는 멀티 모임 플랫폼. 네이버 카페가 공간 임대업이면 심박은 모임 생물학이다.",
  manifest: "/manifest.json",
  applicationName: "심박",
  keywords: ["모임", "카페", "동네", "맘카페", "커뮤니티", "심박"],
  authors: [{ name: "강팀" }],
  formatDetection: { telephone: false, email: false, address: false },
  openGraph: {
    type: "website",
    locale: "ko_KR",
    siteName: "심박",
    title: "심박 — 모임의 생사를 책임지는 곳",
    description: "누구나 카페를 만드는 멀티 모임 플랫폼"
  }
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 5,
  themeColor: "#3D5A47"
};

export default function RootLayout({
  children
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="ko">
      <body>{children}</body>
    </html>
  );
}
