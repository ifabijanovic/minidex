"use client";

import CssBaseline from "@mui/material/CssBaseline";
import { ThemeProvider } from "@mui/material/styles";
import { useTheme } from "next-themes";
import { useEffect, useMemo, useState } from "react";

import { themes } from "@/app/theme";

export function AppThemeProvider({ children }: { children: React.ReactNode }) {
  const { resolvedTheme } = useTheme();
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setMounted(true);
  }, []);

  const theme = useMemo(() => {
    if (mounted) {
      return resolvedTheme === "light" ? themes.light : themes.dark;
    } else {
      return themes.dark;
    }
  }, [resolvedTheme, mounted]);

  if (!mounted) {
    return null;
  }

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      {children}
    </ThemeProvider>
  );
}
