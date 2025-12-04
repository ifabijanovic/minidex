"use client";

import { Box, Button, Stack } from "@mui/material";
import Link from "next/link";

import { IntroBackground } from "@/app/components/IntroBackground";
import { metallicButtonStyle } from "@/app/theme";

export default function Home() {
  return (
    <IntroBackground blurAmount="0px" overlayColor={"none"} scale={1}>
      <Box
        sx={{
          display: "flex",
          flexDirection: { xs: "column", sm: "column" },
          alignItems: "center",
          justifyContent: { xs: "flex-end", sm: "center" },
          minHeight: { xs: "100dvh", sm: "100vh" },
          textAlign: "center",
          pb: {
            xs: `calc(32px + env(safe-area-inset-bottom, 0px))`,
            sm: 0,
          },
        }}
      >
        <Stack
          direction={{ xs: "row", sm: "column" }}
          spacing={{ xs: 2, sm: 3 }}
          sx={{
            width: { xs: "100%", sm: "auto" },
            px: { xs: 2, sm: 0 },
            pb: { xs: 0, sm: 0 },
          }}
        >
          <Button
            component={Link}
            href="/login"
            variant="contained"
            size="large"
            sx={{
              ...metallicButtonStyle,
              minWidth: { xs: "auto", sm: 200 },
              width: { xs: "100%", sm: "auto" },
            }}
          >
            Login
          </Button>
          <Button
            component={Link}
            href="/register"
            variant="contained"
            size="large"
            sx={{
              ...metallicButtonStyle,
              minWidth: { xs: "auto", sm: 200 },
              width: { xs: "100%", sm: "auto" },
            }}
          >
            Get started
          </Button>
        </Stack>
      </Box>
    </IntroBackground>
  );
}
