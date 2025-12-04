import type { Metadata } from "next";
import { Inter } from "next/font/google";

import { QueryProvider } from "@/app/providers/query-provider";
import { AppThemeProvider } from "@/app/providers/theme-provider";
import { ToastProvider } from "@/app/providers/toast-provider";
import { UserProvider } from "@/app/providers/user-provider";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "MiniDex",
  description: "MiniDex Web Application",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <QueryProvider>
          <AppThemeProvider>
            <UserProvider>
              <ToastProvider>{children}</ToastProvider>
            </UserProvider>
          </AppThemeProvider>
        </QueryProvider>
      </body>
    </html>
  );
}
