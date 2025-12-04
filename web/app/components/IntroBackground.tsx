"use client";

import { Box, BoxProps } from "@mui/material";
import { ReactNode } from "react";

type IntroBackgroundProps = {
  children: ReactNode;
  smallScreenImage?: string;
  largeScreenImage?: string;
  blurAmount?: string;
  overlayColor?: string;
  scale?: number;
} & Omit<BoxProps, "children">;

export function IntroBackground({
  children,
  smallScreenImage = "/images/minidex_portrait.jpg",
  largeScreenImage = "/images/minidex_square.jpg",
  blurAmount = "4px",
  overlayColor = "rgba(0, 0, 0, 0.25)",
  scale = 1,
  ...boxProps
}: IntroBackgroundProps) {
  return (
    <>
      <Box
        sx={{
          position: "fixed",
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          backgroundImage: {
            xs: `url(${smallScreenImage})`,
            md: `url(${largeScreenImage})`,
          },
          backgroundSize: "cover",
          backgroundPosition: "center",
          backgroundRepeat: "no-repeat",
          filter: `blur(${blurAmount})`,
          transform: `scale(${scale})`, // Scale up to prevent blur edge artifacts
          zIndex: 0,
          "&::before": {
            content: '""',
            position: "absolute",
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            backgroundColor: overlayColor,
          },
        }}
      />
      <Box
        sx={{
          position: "relative",
          zIndex: 1,
          minHeight: "100vh",
        }}
        {...boxProps}
      >
        {children}
      </Box>
    </>
  );
}
