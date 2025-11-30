"use client";

import HardwareIcon from "@mui/icons-material/Hardware";
import { Container, Stack, Typography } from "@mui/material";

export default function HomePage() {
  return (
    <Container maxWidth="lg">
      <Stack spacing={3}>
        <Typography variant="h5">Welcome to MiniDex!</Typography>
        <HardwareIcon fontSize="large" />
        <Typography>
          This app is still heavily under development, so check back later for
          more features!
        </Typography>
      </Stack>
    </Container>
  );
}
