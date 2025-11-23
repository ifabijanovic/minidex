"use client";

import { SnackbarProvider } from "notistack";

export function ToastProvider({ children }: { children: React.ReactNode }) {
  return (
    <SnackbarProvider
      maxSnack={3}
      autoHideDuration={4000}
      anchorOrigin={{ vertical: "bottom", horizontal: "right" }}
    >
      {children}
    </SnackbarProvider>
  );
}
