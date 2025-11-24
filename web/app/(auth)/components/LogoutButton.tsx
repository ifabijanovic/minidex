"use client";

import { Button, ButtonProps, CircularProgress } from "@mui/material";
import { useQueryClient } from "@tanstack/react-query";
import { useRouter } from "next/navigation";

import { useApiMutation } from "@/lib/hooks/use-api-mutation";
import { useCurrentUser } from "@/app/context/user-context";

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
  const { setUser } = useCurrentUser();

  const logoutMutation = useApiMutation<{ success: boolean }, void>({
    method: "post",
    path: "/auth/logout",
    suppressToast: true,
  });

  async function handleLogout() {
    try {
      await logoutMutation.mutateAsync(undefined);
    } finally {
      setUser(null);
      await queryClient.resetQueries();
      router.replace(redirectTo);
      router.refresh();
      onLoggedOut?.();
    }
  }

  return (
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
  );
}

export default LogoutButton;
