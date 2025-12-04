"use client";

import { Box, BoxProps, useTheme } from "@mui/material";
import { usePathname } from "next/navigation";
import { ReactNode, useMemo } from "react";

type CinematicBackgroundProps = {
  children: ReactNode;
} & Omit<BoxProps, "children">;

export function CinematicBackground({
  children,
  sx,
  ...boxProps
}: CinematicBackgroundProps) {
  const theme = useTheme();
  const mode = theme.palette.mode;
  const pathname = usePathname();

  // Randomly pick direction, re-run when pathname changes
  /* eslint-disable react-hooks/purity, react-hooks/exhaustive-deps */
  const direction = useMemo<"left" | "right">(() => {
    return Math.random() < 0.5 ? "left" : "right";
  }, [pathname]);
  /* eslint-enable react-hooks/purity, react-hooks/exhaustive-deps */

  const imageName = `bg_${direction}_${mode}_fade.webp`;
  const backgroundPosition = `bottom ${direction}`;

  return (
    <Box
      component="main"
      sx={{
        flex: 1,
        px: { xs: 1, sm: 2, md: 4 },
        py: { xs: 1, sm: 2 },
        overflow: "auto",
        position: "relative",
        "&::before": {
          content: '""',
          position: "absolute",
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          backgroundImage: `url(/images/${imageName})`,
          backgroundPosition,
          backgroundRepeat: "no-repeat",
          backgroundSize: "contain",
          pointerEvents: "none",
          zIndex: 0,
        },
        "& > *": {
          position: "relative",
          zIndex: 1,
        },
        ...sx,
      }}
      {...boxProps}
    >
      {children}
    </Box>
  );
}
