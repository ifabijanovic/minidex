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
import Link from "next/link";
import { FormEvent, Suspense, useState } from "react";

import { registerMessages as m } from "@/app/register/messages";

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
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  const passwordsMatch =
    password.trim().length > 0 &&
    confirmPassword.trim().length > 0 &&
    password === confirmPassword;
  const isFormValid =
    username.trim().length > 0 &&
    password.trim().length >= 8 &&
    confirmPassword.trim().length >= 8 &&
    passwordsMatch;

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
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
            onChange={(event) => setUsername(event.target.value)}
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
            onChange={(event) => setPassword(event.target.value)}
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
            onChange={(event) => setConfirmPassword(event.target.value)}
            autoComplete="new-password"
            required
            fullWidth
            InputLabelProps={{ shrink: true, required: false }}
            error={confirmPassword.length > 0 && !passwordsMatch}
            helperText={
              confirmPassword.length > 0 && !passwordsMatch
                ? "Passwords must match"
                : undefined
            }
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
            disabled={!isFormValid}
          >
            {m.submitIdle}
          </Button>
        </Stack>
      </Paper>
    </Container>
  );
}
