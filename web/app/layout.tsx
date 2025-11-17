import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import { AppThemeProvider } from '@/app/theme-provider'
import { QueryProvider } from '@/app/query-provider'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'MiniDex',
  description: 'MiniDex Web Application',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <QueryProvider>
          <AppThemeProvider>{children}</AppThemeProvider>
        </QueryProvider>
      </body>
    </html>
  )
}
