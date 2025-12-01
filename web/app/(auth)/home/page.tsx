"use client";

import HardwareIcon from "@mui/icons-material/Hardware";
import { Container, Stack, Typography } from "@mui/material";

export default function HomePage() {
  return (
    <Container maxWidth="lg">
      <Stack spacing={{ xs: 2, sm: 3 }}>
        <Typography variant="h5">Welcome to MiniDex!</Typography>
        <HardwareIcon sx={{ fontSize: { xs: "2rem", sm: "3rem" } }} />
        <Typography variant="body1">
          This app is still heavily under development, so check back later for
          more features!
        </Typography>
      </Stack>
    </Container>
  );
}
