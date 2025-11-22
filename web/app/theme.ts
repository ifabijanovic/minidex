"use client";

import { createTheme } from "@mui/material/styles";

const lightTokens = {
  brandPrimary: "#131F47",
  brandAccent: "#803535",
  brandAccentSoft: "#FCE9E2",
  neutral300: "#8C919B",
  bgDefault: "#F3F4F6",
  bgSubtle: "#FFFFFF",
  bgRaised: "#D4D5D8",
  textPrimary: "#131F47",
  textSecondary: "#4A505E",
  textInverse: "#FFFFFF",
  errorLighter: "#FFE9D5",
  errorLight: "#FFAC82",
  error: "#FF5630",
  errorDark: "#B71D18",
  errorDarker: "#7A0916",
};

const darkTokens = {
  brandPrimary: "#3750A0",
  brandAccent: "#A44A4A",
  brandAccentSoft: "#4D2323",
  neutral300: "#4A505E",
  bgDefault: "#1A1C22",
  bgSubtle: "#2D313A",
  bgRaised: "#4A505E",
  textPrimary: "#F3F4F6",
  textSecondary: "#8C919B",
  textInverse: "#131F47",
  errorLighter: "#FFE9D5",
  errorLight: "#FFAC82",
  error: "#FF5630",
  errorDark: "#B71D18",
  errorDarker: "#7A0916",
};

const buildTheme = (mode: "light" | "dark") => {
  const tokens = mode === "light" ? lightTokens : darkTokens;
  return createTheme({
    palette: {
      mode,
      primary: {
        main: tokens.brandPrimary,
        contrastText: tokens.textInverse,
      },
      secondary: {
        main: tokens.brandAccent,
        contrastText: tokens.textInverse,
      },
      error: {
        main: tokens.error,
        contrastText: tokens.textInverse,
        light: tokens.errorLight,
      },
      background: {
        default: tokens.bgDefault,
        paper: tokens.bgSubtle,
      },
      text: {
        primary: tokens.textPrimary,
        secondary: tokens.textSecondary,
      },
      divider: tokens.bgSubtle,
    },
    shape: {
      borderRadius: 12,
    },
    typography: {
      fontFamily: "Inter, 'Segoe UI', sans-serif",
    },
    components: {
      MuiCssBaseline: {
        styleOverrides: {
          body: {
            backgroundColor: tokens.bgDefault,
            color: tokens.textPrimary,
          },
          a: {
            color: "inherit",
          },
        },
      },
      MuiButton: {
        styleOverrides: {
          root: {
            borderRadius: 12,
            textTransform: "none",
            fontWeight: 600,
          },
        },
      },
      MuiCard: {
        styleOverrides: {
          root: {
            backgroundColor: tokens.bgRaised,
            border: `1px solid ${tokens.neutral300}`,
            boxShadow: "none",
            borderRadius: 20,
          },
        },
      },
      MuiOutlinedInput: {
        styleOverrides: {
          root: {
            backgroundColor: tokens.bgSubtle,
            borderRadius: 12,
          },
        },
      },
    },
  });
};

export const themes = {
  light: buildTheme("light"),
  dark: buildTheme("dark"),
};
