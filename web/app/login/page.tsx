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
import { FormEvent, Suspense, useState } from "react";

import { loginMessages as m } from "@/app/login/messages";
import { api } from "@/lib/api-client";
import { useApiMutation } from "@/lib/hooks/use-api-mutation";
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
  const [showPassword, setShowPassword] = useState(false);

  const redirectTo = normalizeReturnUrl(searchParams.get("returnUrl"));

  const loginMutation = useApiMutation({
    mutationFn: (credentials: LoginPayload) =>
      api.post<LoginResponse, LoginPayload>("/auth/login", credentials),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: queryKeys.currentUser });
      router.replace(redirectTo);
      router.refresh();
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

          <Box>
            <Box
              display="flex"
              justifyContent="space-between"
              alignItems="center"
              mb={2}
            >
              <Box />
              <MuiLink
                component={Link}
                href="/forgot-password"
                underline="hover"
              >
                {m.forgotPassword}
              </MuiLink>
            </Box>
            <TextField
              label={m.passwordLabel}
              type={showPassword ? "text" : "password"}
              value={password}
              onChange={handlePasswordChange}
              autoComplete="current-password"
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
          </Box>

          <Button
            type="submit"
            variant="contained"
            size="large"
            disabled={!isFormValid || loginMutation.isPending}
          >
            {loginMutation.isPending ? m.submitPending : m.submitIdle}
          </Button>
        </Stack>
      </Paper>
    </Container>
  );
}

function normalizeReturnUrl(value: string | null) {
  if (!value || value === "/login") {
    return "/home";
  }
  return value;
}
