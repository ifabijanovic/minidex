"use client";

import CloseIcon from "@mui/icons-material/Close";
import IconButton from "@mui/material/IconButton";
import { closeSnackbar,SnackbarProvider } from "notistack";

export function ToastProvider({ children }: { children: React.ReactNode }) {
  return (
    <SnackbarProvider
      maxSnack={3}
      anchorOrigin={{ vertical: "bottom", horizontal: "right" }}
      action={(snackbarId) => (
        <IconButton onClick={() => closeSnackbar(snackbarId)} size="small">
          <CloseIcon fontSize="small" />
        </IconButton>
      )}
    >
      {children}
    </SnackbarProvider>
  );
}

