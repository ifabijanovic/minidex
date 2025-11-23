"use client";

import Visibility from "@mui/icons-material/Visibility";
import VisibilityOff from "@mui/icons-material/VisibilityOff";
import {
  Box,
  Button,
  Container,
  IconButton,
  InputAdornment,
  Link as MuiLink,
  Paper,
  Stack,
  TextField,
  Typography,
} from "@mui/material";
import { useQueryClient } from "@tanstack/react-query";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { ChangeEvent, FormEvent, Suspense, useState } from "react";

import { registerMessages as m } from "@/app/register/messages";
import { api } from "@/lib/api-client";
import { useApiMutation } from "@/lib/hooks/use-api-mutation";
import { queryKeys } from "@/lib/query-keys";

type RegisterPayload = {
  username: string;
  password: string;
  confirmPassword: string;
};

type RegisterResponse = {
  userId: string;
  expiresIn?: number;
};

export default function RegisterPage() {
  return (
    <Suspense
      fallback={
        <Container
          maxWidth="sm"
          sx={{ display: "flex", alignItems: "center", minHeight: "100vh" }}
        >
          <Paper elevation={1} sx={{ p: 4, width: "100%" }}>
            <Typography variant="h5">Loading...</Typography>
          </Paper>
        </Container>
      }
    >
      <RegisterForm />
    </Suspense>
  );
}

function RegisterForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const queryClient = useQueryClient();

  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  const redirectTo = normalizeReturnUrl(searchParams.get("returnUrl"));

  const registerMutation = useApiMutation({
    mutationFn: (payload) =>
      api.post<RegisterResponse, RegisterPayload>("/auth/register", payload),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: queryKeys.currentUser });
      router.replace(redirectTo);
      router.refresh();
    },
  });

  const trimmedUsername = username.trim();
  const trimmedPassword = password.trim();
  const trimmedConfirmPassword = confirmPassword.trim();

  const passwordsMatch =
    trimmedPassword.length > 0 &&
    trimmedConfirmPassword.length > 0 &&
    trimmedPassword === trimmedConfirmPassword;

  const isFormValid =
    trimmedUsername.length > 0 &&
    trimmedPassword.length >= 8 &&
    trimmedConfirmPassword.length >= 8 &&
    passwordsMatch;

  const confirmPasswordError = confirmPassword.length > 0 && !passwordsMatch;

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
    <Container
      maxWidth="xs"
      sx={{
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        minHeight: "100vh",
      }}
    >
      <Paper elevation={3} sx={{ p: { xs: 3, md: 4 }, width: "100%" }}>
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

          <TextField
            label={m.passwordLabel}
            type={showPassword ? "text" : "password"}
            value={password}
            onChange={handlePasswordChange}
            autoComplete="new-password"
            required
            fullWidth
            InputLabelProps={{ shrink: true, required: false }}
            InputProps={{
              endAdornment: (
                <InputAdornment position="end">
                  <IconButton
                    onClick={() => setShowPassword((prev) => !prev)}
                    edge="end"
                  >
                    {showPassword ? <VisibilityOff /> : <Visibility />}
                  </IconButton>
                </InputAdornment>
              ),
            }}
          />

          <TextField
            label={m.confirmPasswordLabel}
            type={showConfirmPassword ? "text" : "password"}
            value={confirmPassword}
            onChange={handleConfirmPasswordChange}
            autoComplete="new-password"
            required
            fullWidth
            InputLabelProps={{ shrink: true, required: false }}
            error={confirmPasswordError}
            helperText={confirmPasswordError ? "Passwords must match" : undefined}
            InputProps={{
              endAdornment: (
                <InputAdornment position="end">
                  <IconButton
                    onClick={() => setShowConfirmPassword((prev) => !prev)}
                    edge="end"
                  >
                    {showConfirmPassword ? <VisibilityOff /> : <Visibility />}
                  </IconButton>
                </InputAdornment>
              ),
            }}
          />

          <Button
            type="submit"
            variant="contained"
            size="large"
            disabled={!isFormValid || registerMutation.isPending}
          >
            {registerMutation.isPending ? m.submitPending : m.submitIdle}
          </Button>
        </Stack>
      </Paper>
    </Container>
  );
}

function normalizeReturnUrl(value: string | null) {
  if (!value || value === "/login" || value === "/register") {
    return "/home";
  }
  return value;
}
