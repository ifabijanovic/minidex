"use client";

// theme.ts
import { createTheme } from "@mui/material/styles";

const primary = {
  lightest: "#C6D4FF",
  light: "#7C95E3",
  main: "#4C6CE8",
  dark: "#2F47AC",
  darkest: "#1A2F7A",
  contrastText: "#FFFFFF",
};

const secondary = {
  lightest: "#FFD4D4",
  light: "#E98989",
  main: "#D75A5A",
  dark: "#B04444",
  darkest: "#9A3F3F",
  contrastText: "#FFFFFF",
};

const success = {
  lightest: "#D8F5E5",
  light: "#72D7A5",
  main: "#31B77A",
  dark: "#1E8156",
  darkest: "#11523A",
  contrastText: "#FFFFFF",
};

const warning = {
  lightest: "#FFF4D6",
  light: "#F9D686",
  main: "#F5B945",
  dark: "#C98D2C",
  darkest: "#8A5E13",
  contrastText: "#000000",
};

const error = {
  lightest: "#F8D8DB",
  light: "#E78A92",
  main: "#D84C57",
  dark: "#A8323A",
  darkest: "#721F23",
  contrastText: "#FFFFFF",
};

const lightPalette = {
  primary,
  secondary,
  success,
  warning,
  error,
  background: {
    default: "#F7F9FC",
    paper: "#FFFFFF",
  },
  text: {
    primary: "#1A1A1A",
    secondary: "#3A3A3A",
    disabled: "rgba(0,0,0,0.38)",
  },
  grey: {
    50: "#FAFAFA",
    100: "#F3F4F6",
    200: "#E5E7EB",
    300: "#D1D5DB",
    400: "#9CA3AF",
    500: "#6B7280",
    600: "#4B5563",
    700: "#374151",
    800: "#1F2937",
    900: "#111827",
  },
  divider: "rgba(0,0,0,0.12)",
};

const darkPalette = {
  primary,
  secondary,
  success,
  warning,
  error,
  background: {
    default: "#0E1117",
    paper: "#14171D",
  },
  text: {
    primary: "#FFFFFF",
    secondary: "#E6E6E6",
    disabled: "rgba(255,255,255,0.38)",
  },
  grey: {
    50: "#E6E6E6",
    100: "#C8C8C8",
    200: "#A9A9A9",
    300: "#8B8B8B",
    400: "#6E6E6E",
    500: "#515151",
    600: "#3A3A3A",
    700: "#26292E",
    800: "#1A1D22",
    900: "#14171D",
  },
  divider: "rgba(255,255,255,0.12)",
};

const typography = {
  fontFamily: `"Inter", "Roboto", "Helvetica", "Arial", sans-serif`,
  h1: { fontSize: "2.5rem", fontWeight: 700 },
  h2: { fontSize: "2rem", fontWeight: 700 },
  h3: { fontSize: "1.75rem", fontWeight: 600 },
  h4: { fontSize: "1.5rem", fontWeight: 600 },
  h5: { fontSize: "1.25rem", fontWeight: 600 },
  h6: { fontSize: "1.1rem", fontWeight: 600 },
  body1: { fontSize: "1rem" },
  body2: { fontSize: "0.875rem" },
  button: { textTransform: "none", fontWeight: 600 },
};

const shape = {
  borderRadius: 8,
};

const spacing = 8;

const buildTheme = (mode: "light" | "dark") => {
  const paletteSource = mode === "light" ? lightPalette : darkPalette;

  return createTheme({
    palette: {
      mode,
      primary: paletteSource.primary,
      secondary: paletteSource.secondary,
      success: paletteSource.success,
      warning: paletteSource.warning,
      error: paletteSource.error,
      background: paletteSource.background,
      text: paletteSource.text,
      grey: paletteSource.grey, // TODO: light theme uses default greys
      divider: paletteSource.divider,
    },
    typography,
    shape,
    spacing,
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
      MuiTypography: {
        styleOverrides: {
          h2: ({ theme }) => ({
            [theme.breakpoints.down("sm")]: {
              fontSize: "2rem",
            },
            [theme.breakpoints.between("sm", "md")]: {
              fontSize: "2.5rem",
            },
            [theme.breakpoints.up("md")]: {
              fontSize: "3rem",
            },
          }),
          h4: ({ theme }) => ({
            [theme.breakpoints.down("sm")]: {
              fontSize: "1.5rem",
            },
            [theme.breakpoints.between("sm", "md")]: {
              fontSize: "1.75rem",
            },
            [theme.breakpoints.up("md")]: {
              fontSize: "2rem",
            },
          }),
          h5: ({ theme }) => ({
            [theme.breakpoints.down("sm")]: {
              fontSize: "1.1rem",
            },
            [theme.breakpoints.between("sm", "md")]: {
              fontSize: "1.25rem",
            },
            [theme.breakpoints.up("md")]: {
              fontSize: "1.5rem",
            },
          }),
        },
      },
      MuiButton: {
        styleOverrides: {
          root: ({ theme }) => ({
            borderRadius: 12,
            textTransform: "none",
            fontWeight: 600,
            [theme.breakpoints.down("sm")]: {
              width: "100%",
            },
            [theme.breakpoints.up("sm")]: {
              width: "auto",
            },
          }),
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
      MuiCardContent: {
        styleOverrides: {
          root: ({ theme }) => ({
            [theme.breakpoints.down("sm")]: {
              padding: "8px",
            },
            [theme.breakpoints.up("sm")]: {
              padding: "16px",
            },
          }),
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
      MuiTableContainer: {
        styleOverrides: {
          root: {
            overflowX: "auto",
            "& .MuiTable-root": {
              minWidth: 800, // Ensure table has minimum width for readability
            },
          },
        },
      },
      MuiTablePagination: {
        styleOverrides: {
          root: {
            overflowX: "auto",
            "& .MuiTablePagination-toolbar": {
              flexWrap: "wrap",
              gap: 1,
            },
            "& .MuiTablePagination-selectLabel, & .MuiTablePagination-displayedRows":
              {
                m: 0,
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
