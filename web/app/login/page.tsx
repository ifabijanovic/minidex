"use client";

import {
  Box,
  Button,
  Link as MuiLink,
  Stack,
  TextField,
  Typography,
} from "@mui/material";
import { useQueryClient } from "@tanstack/react-query";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { enqueueSnackbar } from "notistack";
import { FormEvent, Suspense, useState } from "react";

import { AuthCard } from "@/app/components/AuthCard";
import { IntroBackground } from "@/app/components/IntroBackground";
import { PasswordField } from "@/app/components/PasswordField";
import { loginMessages as m } from "@/app/login/messages";
import { useCurrentUser, type UserRole } from "@/app/providers/user-provider";
import { metallicButtonStyle } from "@/app/theme";
import { normalizeReturnUrl } from "@/app/utils/normalize-return-url";
import { ApiError } from "@/lib/api-client";
import { getFriendlyErrorMessage } from "@/lib/errors";
import { useApiMutation } from "@/lib/hooks/use-api-mutation";

type LoginResponse = {
  userId: string;
  expiresIn?: number;
  roles?: UserRole[];
};

export default function LoginPage() {
  return (
    <IntroBackground>
      <Suspense
        fallback={
          <AuthCard maxWidth="sm" elevation={1}>
            <Typography variant="h5">Loading...</Typography>
          </AuthCard>
        }
      >
        <LoginForm />
      </Suspense>
    </IntroBackground>
  );
}

type LoginPayload = {
  username: string;
  password: string;
};

function LoginForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const queryClient = useQueryClient();
  const { setUser } = useCurrentUser();

  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");

  const redirectTo = normalizeReturnUrl(searchParams.get("returnUrl"));

  const loginMutation = useApiMutation<LoginResponse, LoginPayload>({
    method: "post",
    path: "/auth/login",
    suppressToast: true,
    onSuccess: async (data) => {
      if (data.userId) {
        setUser({
          userId: data.userId,
          roles: data.roles || [],
        });
      }
      router.replace(redirectTo);
      router.refresh();
    },
    onError: (error) => {
      const message =
        error instanceof ApiError && error.status === 401
          ? m.invalidCredentials
          : getFriendlyErrorMessage(error);
      enqueueSnackbar(message, { variant: "error" });
    },
  });

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    loginMutation.mutate({ username, password });
  }

  const isFormValid = username.trim().length > 0 && password.trim().length > 0;
  const handleUsernameChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    if (loginMutation.isError) loginMutation.reset();
    setUsername(event.target.value);
  };
  const handlePasswordChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    if (loginMutation.isError) loginMutation.reset();
    setPassword(event.target.value);
  };

  return (
    <AuthCard>
      <Stack spacing={3} component="form" onSubmit={handleSubmit}>
        <Box textAlign="center">
          <Typography variant="h4" component="h1" gutterBottom>
            {m.title}
          </Typography>
          <Typography variant="body1" color="text.secondary">
            {m.subtitlePrefix}{" "}
            <MuiLink component={Link} href="/register" underline="hover">
              {m.subtitleLink}
            </MuiLink>
          </Typography>
        </Box>

        <TextField
          label={m.usernameLabel}
          value={username}
          onChange={handleUsernameChange}
          autoComplete="username"
          autoFocus
          required
          fullWidth
          InputLabelProps={{ shrink: true, required: false }}
        />

        <PasswordField
          label={m.passwordLabel}
          value={password}
          onChange={handlePasswordChange}
          autoComplete="current-password"
          required
          fullWidth
          InputLabelProps={{ shrink: true, required: false }}
        />

        <Button
          type="submit"
          variant="contained"
          size="large"
          disabled={!isFormValid || loginMutation.isPending}
          sx={metallicButtonStyle}
        >
          {loginMutation.isPending ? m.submitPending : m.submitIdle}
        </Button>
      </Stack>
    </AuthCard>
  );
}
