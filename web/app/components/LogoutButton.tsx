"use client";

import {
  Alert,
  Button,
  ButtonProps,
  CircularProgress,
  Snackbar,
} from "@mui/material";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { useState } from "react";

import { api } from "@/lib/api-client";
import { queryKeys } from "@/lib/query-keys";

type LogoutButtonProps = ButtonProps & {
  redirectTo?: string;
  onLoggedOut?: () => void;
};

export function LogoutButton({
  redirectTo = "/login",
  onLoggedOut,
  children,
  ...buttonProps
}: LogoutButtonProps) {
  const router = useRouter();
  const queryClient = useQueryClient();
  const [error, setError] = useState<string | null>(null);

  const logoutMutation = useMutation({
    mutationFn: () => api.post<{ success: boolean }>("/auth/logout"),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: queryKeys.currentUser });
      router.replace(redirectTo);
      router.refresh();
      onLoggedOut?.();
    },
    onError: (err) => {
      setError(err instanceof Error ? err.message : "Failed to logout");
    },
  });

  async function handleLogout() {
    setError(null);
    try {
      await logoutMutation.mutateAsync();
    } catch {
      // Error state is handled in onError
    }
  }

  return (
    <>
      <Button
        {...buttonProps}
        onClick={handleLogout}
        disabled={logoutMutation.isPending || buttonProps.disabled}
        startIcon={
          logoutMutation.isPending ? (
            <CircularProgress size={16} />
          ) : (
            buttonProps.startIcon
          )
        }
      >
        {children ?? "Logout"}
      </Button>
      <Snackbar
        open={Boolean(error)}
        autoHideDuration={6000}
        onClose={() => setError(null)}
      >
        <Alert
          severity="error"
          onClose={() => setError(null)}
          sx={{ width: "100%" }}
        >
          {error}
        </Alert>
      </Snackbar>
    </>
  );
}

export default LogoutButton;
