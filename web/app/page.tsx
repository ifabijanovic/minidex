"use client";

import { Box, Container, Typography } from "@mui/material";

export default function Home() {
  return (
    <Container maxWidth="md">
      <Box
        sx={{
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          minHeight: "100vh",
          textAlign: "center",
        }}
      >
        <Typography variant="h2" component="h1" gutterBottom>
          Hello World
        </Typography>
        <Typography variant="h5" color="text.secondary">
          MiniDex Web App
        </Typography>
      </Box>
    </Container>
  );
}
