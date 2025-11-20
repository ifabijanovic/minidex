"use client";

import {
  Alert,
  Box,
  Button,
  Container,
  Paper,
  Stack,
  TextField,
  Typography,
} from "@mui/material";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { useRouter, useSearchParams } from "next/navigation";
import { FormEvent, Suspense, useState } from "react";

import { api } from "@/lib/api-client";
import { queryKeys } from "@/lib/query-keys";

type LoginResponse = {
  userId: string;
  expiresIn?: number;
};

export default function LoginPage() {
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
      <LoginForm />
    </Suspense>
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

  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);

  const redirectTo = searchParams.get("returnUrl") || "/dashboard";

  const loginMutation = useMutation({
    mutationFn: (credentials: LoginPayload) =>
      api.post<LoginResponse, LoginPayload>("/auth/login", credentials),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: queryKeys.currentUser });
      router.replace(redirectTo);
      router.refresh();
    },
    onError: (err) => {
      setError(err instanceof Error ? err.message : "Unable to login");
    },
  });

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError(null);

    try {
      await loginMutation.mutateAsync({ username, password });
    } catch {
      // error handled in onError
    }
  }

  const isFormValid = username.trim().length > 0 && password.trim().length > 0;
  const handleUsernameChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    if (error) setError(null);
    if (loginMutation.isError) loginMutation.reset();
    setUsername(event.target.value);
  };
  const handlePasswordChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    if (error) setError(null);
    if (loginMutation.isError) loginMutation.reset();
    setPassword(event.target.value);
  };

  return (
    <Container
      maxWidth="sm"
      sx={{
        display: "flex",
        alignItems: "center",
        minHeight: "100vh",
      }}
    >
      <Paper elevation={3} sx={{ p: 4, width: "100%" }}>
        <Stack spacing={3} component="form" onSubmit={handleSubmit}>
          <Box>
            <Typography variant="h4" component="h1" gutterBottom>
              Sign in
            </Typography>
            <Typography variant="body1" color="text.secondary">
              Enter your MiniDex credentials to continue.
            </Typography>
          </Box>

          {error && (
            <Alert severity="error" onClose={() => setError(null)}>
              {error}
            </Alert>
          )}

          <TextField
            label="Username"
            value={username}
            onChange={handleUsernameChange}
            autoComplete="username"
            autoFocus
            required
            fullWidth
          />

          <TextField
            label="Password"
            type="password"
            value={password}
            onChange={handlePasswordChange}
            autoComplete="current-password"
            required
            fullWidth
          />

          <Button
            type="submit"
            variant="contained"
            size="large"
            disabled={!isFormValid || loginMutation.isPending}
          >
            {loginMutation.isPending ? "Signing in..." : "Sign in"}
          </Button>
        </Stack>
      </Paper>
    </Container>
  );
}
