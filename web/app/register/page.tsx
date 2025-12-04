"use client";

import {
  Alert,
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
import { ChangeEvent, FormEvent, Suspense, useState } from "react";

import { AuthCard } from "@/app/components/AuthCard";
import { IntroBackground } from "@/app/components/IntroBackground";
import { PasswordField } from "@/app/components/PasswordField";
import { useCurrentUser, type UserRole } from "@/app/providers/user-provider";
import { registerMessages as m } from "@/app/register/messages";
import { metallicButtonStyle } from "@/app/theme";
import { normalizeReturnUrl } from "@/app/utils/normalize-return-url";
import { useApiMutation } from "@/lib/hooks/use-api-mutation";

type RegisterPayload = {
  username: string;
  password: string;
  confirmPassword: string;
};

type RegisterResponse = {
  userId: string;
  expiresIn?: number;
  roles?: UserRole[];
};

export default function RegisterPage() {
  return (
    <IntroBackground>
      <Suspense
        fallback={
          <AuthCard maxWidth="sm" elevation={1}>
            <Typography variant="h5">Loading...</Typography>
          </AuthCard>
        }
      >
        <RegisterForm />
      </Suspense>
    </IntroBackground>
  );
}

function RegisterForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const queryClient = useQueryClient();
  const { setUser } = useCurrentUser();

  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");

  const redirectTo = normalizeReturnUrl(searchParams.get("returnUrl"));

  const registerMutation = useApiMutation<RegisterResponse, RegisterPayload>({
    method: "post",
    path: "/auth/register",
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
  });

  const trimmedUsername = username.trim();
  const trimmedPassword = password.trim();
  const trimmedConfirmPassword = confirmPassword.trim();

  const passwordTooShort =
    trimmedPassword.length > 0 && trimmedPassword.length < 8;
  const confirmPasswordTooShort =
    trimmedConfirmPassword.length > 0 && trimmedConfirmPassword.length < 8;

  const passwordsMatch =
    trimmedPassword.length > 0 &&
    trimmedConfirmPassword.length > 0 &&
    trimmedPassword === trimmedConfirmPassword;

  const isFormValid =
    trimmedUsername.length > 0 &&
    trimmedPassword.length >= 8 &&
    trimmedConfirmPassword.length >= 8 &&
    passwordsMatch;

  const passwordValidationMessage = (() => {
    if (passwordTooShort || confirmPasswordTooShort) {
      return m.passwordTooShort;
    }
    if (confirmPassword.length > 0 && !passwordsMatch) {
      return m.passwordMismatch;
    }
    return undefined;
  })();

  const confirmPasswordError = Boolean(passwordValidationMessage);

  const handleUsernameChange = (event: ChangeEvent<HTMLInputElement>) => {
    if (registerMutation.isError) registerMutation.reset();
    setUsername(event.target.value);
  };

  const handlePasswordChange = (event: ChangeEvent<HTMLInputElement>) => {
    if (registerMutation.isError) registerMutation.reset();
    setPassword(event.target.value);
  };

  const handleConfirmPasswordChange = (
    event: ChangeEvent<HTMLInputElement>,
  ) => {
    if (registerMutation.isError) registerMutation.reset();
    setConfirmPassword(event.target.value);
  };

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    registerMutation.mutate({ username, password, confirmPassword });
  }

  return (
    <AuthCard>
      <Stack spacing={3} component="form" onSubmit={handleSubmit}>
        <Box textAlign="center">
          <Typography variant="h4" component="h1" gutterBottom>
            {m.title}
          </Typography>
          <Typography variant="body1" color="text.secondary">
            {m.subtitlePrefix}{" "}
            <MuiLink component={Link} href="/login" underline="hover">
              {m.subtitleLink}
            </MuiLink>
          </Typography>
        </Box>

        <Alert severity="warning">
          MiniDex is still in its early stages. I’m actively restructuring data
          and testing features, so your account and any saved data may be reset
          or deleted during development.
        </Alert>

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
          autoComplete="new-password"
          required
          fullWidth
          InputLabelProps={{ shrink: true, required: false }}
          error={passwordTooShort}
        />

        <PasswordField
          label={m.confirmPasswordLabel}
          value={confirmPassword}
          onChange={handleConfirmPasswordChange}
          autoComplete="new-password"
          required
          fullWidth
          InputLabelProps={{ shrink: true, required: false }}
          error={confirmPasswordError}
          helperText={passwordValidationMessage}
        />

        <Button
          type="submit"
          variant="contained"
          size="large"
          disabled={!isFormValid || registerMutation.isPending}
          sx={metallicButtonStyle}
        >
          {registerMutation.isPending ? m.submitPending : m.submitIdle}
        </Button>
      </Stack>
    </AuthCard>
  );
}
