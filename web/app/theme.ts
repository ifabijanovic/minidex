"use client";

// theme.ts
import { createTheme } from "@mui/material/styles";

const lightPalette = {
  primary: {
    lightest: "#D2D9EE",
    light: "#4A63A5",
    main: "#1A2F7A",
    dark: "#13245C",
    darkest: "#0C1639",
    contrastText: "#FFFFFF",
  },
  secondary: {
    lightest: "#F3D6D6",
    light: "#C66666",
    main: "#9A3F3F",
    dark: "#6F2929",
    darkest: "#481919",
    contrastText: "#FFFFFF",
  },
  grey: {
    50: "#FAFAFA",
    100: "#F3F4F6",
    300: "#D1D5DB",
    600: "#1F2937",
    900: "#111827",
  },
  success: {
    lightest: "#D2F2EA",
    light: "#4CC3A8",
    main: "#1A9E7A",
    dark: "#14775B",
    darkest: "#0C4A39",
    contrastText: "#FFFFFF",
  },
  warning: {
    lightest: "#FFF4D6",
    light: "#F2C56A",
    main: "#D79A28",
    dark: "#A7731A",
    darkest: "#6A4A0E",
    contrastText: "#000000",
  },
  error: {
    lightest: "#F9D5D5",
    light: "#E08A8A",
    main: "#C73F3F",
    dark: "#932B2B",
    darkest: "#611B1B",
    contrastText: "#FFFFFF",
  },
  background: {
    default: "#FAFAFA",
    paper: "#FFFFFF",
  },
  text: {
    primary: "#1F2937",
    secondary: "#4B5563",
  },
};

const darkPalette = {
  primary: {
    lightest: "#4A63A5",
    light: "#233C8D",
    main: "#1A2F7A",
    dark: "#13245C",
    darkest: "#0C1639",
    contrastText: "#FFFFFF",
  },
  secondary: {
    lightest: "#C66666",
    light: "#B05050",
    main: "#9A3F3F",
    dark: "#6F2929",
    darkest: "#481919",
    contrastText: "#FFFFFF",
  },
  grey: {
    50: "#1A1C1E",
    100: "#232629",
    300: "#384047",
    600: "#AEB4BA",
    900: "#ECEFF1",
  },
  success: {
    lightest: "#4CC3A8",
    light: "#3BAE96",
    main: "#1A9E7A",
    dark: "#14775B",
    darkest: "#0C4A39",
    contrastText: "#000000",
  },
  warning: {
    lightest: "#F2C56A",
    light: "#DFA640",
    main: "#D79A28",
    dark: "#A7731A",
    darkest: "#6A4A0E",
    contrastText: "#000000",
  },
  error: {
    lightest: "#E08A8A",
    light: "#D46868",
    main: "#C73F3F",
    dark: "#932B2B",
    darkest: "#611B1B",
    contrastText: "#FFFFFF",
  },
  background: {
    default: "#1A1C1E",
    paper: "#232629",
  },
  text: {
    primary: "#ECEFF1",
    secondary: "#AEB4BA",
  },
};

const typography = {
  fontFamily: ["Inter", "Roboto", "Helvetica Neue", "Arial", "sans-serif"].join(
    ",",
  ),
  h1: { fontSize: "2.25rem", fontWeight: 600, lineHeight: 1.2 },
  h2: { fontSize: "1.75rem", fontWeight: 600, lineHeight: 1.25 },
  h3: { fontSize: "1.5rem", fontWeight: 600, lineHeight: 1.3 },
  h4: { fontSize: "1.25rem", fontWeight: 600 },
  h5: { fontSize: "1.125rem", fontWeight: 500 },
  h6: { fontSize: "1rem", fontWeight: 500 },
  body1: { fontSize: "1rem", lineHeight: 1.6 },
  body2: { fontSize: "0.875rem", lineHeight: 1.5 },
  subtitle1: { fontSize: "1rem", fontWeight: 500 },
  subtitle2: { fontSize: "0.875rem", fontWeight: 500 },
  button: { fontWeight: 600, textTransform: "none" },
  caption: { fontSize: "0.75rem", color: "#6B7280" },
};

const spacing = {
  unit: 8,
};

const buildTheme = (mode: "light" | "dark") => {
  const paletteSource = mode === "light" ? lightPalette : darkPalette;

  return createTheme({
    palette: {
      mode,
      primary: {
        main: paletteSource.primary.main,
        light: paletteSource.primary.light,
        dark: paletteSource.primary.dark,
        contrastText: paletteSource.primary.contrastText,
      },
      secondary: {
        main: paletteSource.secondary.main,
        light: paletteSource.secondary.light,
        dark: paletteSource.secondary.dark,
        contrastText: paletteSource.secondary.contrastText,
      },
      error: {
        main: paletteSource.error.main,
        light: paletteSource.error.lightest,
        dark: paletteSource.error.dark,
        contrastText: paletteSource.error.contrastText,
      },
      warning: {
        main: paletteSource.warning.main,
        light: paletteSource.warning.lightest,
        dark: paletteSource.warning.dark,
        contrastText: paletteSource.warning.contrastText,
      },
      success: {
        main: paletteSource.success.main,
        light: paletteSource.success.lightest,
        dark: paletteSource.success.dark,
        contrastText: paletteSource.success.contrastText,
      },
      background: paletteSource.background,
      text: paletteSource.text,
      grey: paletteSource.grey,
      divider: paletteSource.grey[300],
    },
    typography,
    spacing: spacing.unit,
    shape: {
      borderRadius: 12,
    },
    components: {
      MuiCssBaseline: {
        styleOverrides: {
          body: {
            backgroundColor: paletteSource.background.default,
            color: paletteSource.text.primary,
          },
          a: { color: "inherit" },
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
            backgroundColor: paletteSource.background.paper,
            border: `1px solid ${paletteSource.grey[300]}`,
            boxShadow: "none",
            borderRadius: 20,
          },
        },
      },
      MuiOutlinedInput: {
        styleOverrides: {
          root: {
            backgroundColor: paletteSource.background.paper,
            borderRadius: 12,
            "& fieldset": {
              borderColor: paletteSource.grey[300],
            },
            "&:hover fieldset": {
              borderColor: paletteSource.primary.main,
            },
            "&.Mui-focused fieldset": {
              borderColor: paletteSource.primary.main,
            },
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
