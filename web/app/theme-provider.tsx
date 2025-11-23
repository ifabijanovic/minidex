"use client";

import CssBaseline from "@mui/material/CssBaseline";
import { ThemeProvider } from "@mui/material/styles";
import { useEffect, useMemo, useState } from "react";

import { themes } from "@/app/theme";

export function AppThemeProvider({ children }: { children: React.ReactNode }) {
  const [mode, setMode] = useState<"light" | "dark">("light");

  useEffect(() => {
    const match = window.matchMedia("(prefers-color-scheme: dark)");
    const listener = (event: MediaQueryListEvent) => {
      setMode(event.matches ? "dark" : "light");
    };
    listener(match as unknown as MediaQueryListEvent);
    match.addEventListener("change", listener);
    return () => match.removeEventListener("change", listener);
  }, []);

  const theme = useMemo(() => themes[mode], [mode]);

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      {children}
    </ThemeProvider>
  );
}
