import "@/app/globals.css";

import type { Metadata } from "next";
import { Inter } from "next/font/google";
import { ThemeProvider as NextThemeProvider } from "next-themes";

import { UserProvider } from "@/app/contexts/user-context";
import { QueryProvider } from "@/app/providers/query-provider";
import { AppThemeProvider } from "@/app/providers/theme-provider";
import { ToastProvider } from "@/app/providers/toast-provider";

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
    <html lang="en" suppressHydrationWarning>
      <body className={inter.className}>
        <QueryProvider>
          <NextThemeProvider
            attribute="class"
            defaultTheme="system"
            enableSystem
          >
            <AppThemeProvider>
              <UserProvider>
                <ToastProvider>{children}</ToastProvider>
              </UserProvider>
            </AppThemeProvider>
          </NextThemeProvider>
        </QueryProvider>
      </body>
    </html>
  );
}
