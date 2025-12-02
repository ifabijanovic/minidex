"use client";

import { Container, ContainerProps, Paper } from "@mui/material";
import { ReactNode } from "react";

type AuthCardProps = {
  children: ReactNode;
  maxWidth?: ContainerProps["maxWidth"];
  elevation?: number;
};

export function AuthCard({
  children,
  maxWidth = "xs",
  elevation = 3,
}: AuthCardProps) {
  return (
    <Container
      maxWidth={maxWidth}
      sx={(theme) => {
        const color =
          theme.palette.mode === "light"
            ? theme.palette.warning.lightest
            : theme.palette.warning.darkest;
        return {
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          minHeight: { xs: "100dvh", sm: "100vh" },
          py: { xs: 2, sm: 3 },
          boxSizing: "border-box",
          "& input:-webkit-autofill": {
            boxShadow: `0 0 0 1000px ${color} inset !important`,
            WebkitTextFillColor: "inherit !important",
          },
          "& input:-webkit-autofill:hover": {
            boxShadow: `0 0 0 1000px ${color} inset !important`,
          },
          "& input:-webkit-autofill:focus": {
            boxShadow: `0 0 0 1000px ${color} inset !important`,
          },
        };
      }}
    >
      <Paper elevation={elevation} sx={{ p: { xs: 3, md: 4 }, width: "100%" }}>
        {children}
      </Paper>
    </Container>
  );
}
