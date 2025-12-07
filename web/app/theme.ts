"use client";

// theme.ts
import { createTheme, type SxProps, type Theme } from "@mui/material/styles";

const primary = {
  lightest: "#D4E0FF",
  light: "#7BA2FF",
  main: "#1F4CEB",
  dark: "#173AB3",
  darkest: "#0F2876",
  contrastText: "#FFFFFF",
};

const secondary = {
  lightest: "#F4D5D5",
  light: "#DE8A8A",
  main: "#B84242",
  dark: "#8A3232",
  darkest: "#5A1F1F",
  contrastText: "#FFFFFF",
};

const success = {
  lightest: "#D8F5E5",
  light: "#72D7A5",
  main: "#31B77A",
  dark: "#1C7A50",
  darkest: "#114C31",
  contrastText: "#FFFFFF",
};

const warning = {
  lightest: "#FFF2D4",
  light: "#F8D387",
  main: "#F5B743",
  dark: "#C2872A",
  darkest: "#815612",
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
    default: "#F5F7FA",
    paper: "#FFFFFF",
  },
  text: {
    primary: "#1A1A1A",
    secondary: "#3A3A3A",
    disabled: "rgba(0,0,0,0.38)",
  },
  grey: {
    50: "#FAFAFA",
    100: "#F1F3F5",
    200: "#E2E6EA",
    300: "#CBD2D9",
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
  primary: {
    ...primary,
    main: "#3B63FF",
    dark: "#1A3CA9",
    darkest: "#0F2876",
  },
  secondary: {
    ...secondary,
    main: "#CC4949",
    dark: "#9B3434",
    darkest: "#5A1F1F",
  },
  success,
  warning,
  error,
  background: {
    default: "#0C0F14",
    paper: "#0F131A",
  },
  text: {
    primary: "#FFFFFF",
    secondary: "#E2E2E2",
    disabled: "rgba(255,255,255,0.38)",
  },
  grey: {
    50: "#E6E6E6",
    100: "#C8C8C8",
    200: "#A9A9A9",
    300: "#8B8B8B",
    400: "#6E6E6E",
    500: "#515151",
    600: "#393C40",
    700: "#272A2F",
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
      MuiTableRow: {
        styleOverrides: {
          root: ({ theme }) => {
            const color =
              theme.palette.mode === "light"
                ? theme.palette.primary.light
                : theme.palette.primary.dark;
            return {
              "&.MuiTableRow-hover:hover": {
                backgroundColor: `${color} !important`,
              },
              "&.MuiTableRow-hover:hover .MuiTableCell-root": {
                color: theme.palette.primary.contrastText,
              },
            };
          },
        },
      },
      MuiMenuItem: {
        styleOverrides: {
          root: ({ theme }) => {
            const color =
              theme.palette.mode === "light"
                ? theme.palette.primary.light
                : theme.palette.primary.dark;
            return {
              "&:hover": {
                backgroundColor: color,
                color: theme.palette.primary.contrastText,
                "& .MuiListItemIcon-root": {
                  color: theme.palette.primary.contrastText,
                },
                "& .MuiTypography-root": {
                  color: theme.palette.primary.contrastText,
                },
              },
            };
          },
        },
      },
      MuiDialog: {
        styleOverrides: {
          paper: ({ theme }) => ({
            backgroundImage:
              theme.palette.mode === "light"
                ? "none"
                : "linear-gradient(rgba(255,255,255,0.05), rgba(255,255,255,0.05))",
          }),
        },
      },
      MuiDialogActions: {
        styleOverrides: {
          root: {
            "& .MuiButton-root": {
              textTransform: "uppercase",
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

export const metallicButtonStyle: SxProps<Theme> = {
  background: "linear-gradient(145deg, #4a5568 0%, #2d3748 50%, #1a202c 100%)",
  border: "2px solid #3b82f6",
  borderRadius: "8px",
  color: "#ffffff",
  fontWeight: 600,
  textTransform: "none",
  fontSize: "1.1rem",
  letterSpacing: "0.5px",
  boxShadow: `
    0 0 20px rgba(59, 130, 246, 0.4),
    0 4px 6px rgba(0, 0, 0, 0.3),
    inset 0 1px 0 rgba(255, 255, 255, 0.1)
  `,
  textShadow: "0 0 8px rgba(59, 130, 246, 0.8), 0 1px 2px rgba(0, 0, 0, 0.5)",
  position: "relative",
  overflow: "hidden",
  "&::before": {
    content: '""',
    position: "absolute",
    top: 0,
    left: "-100%",
    width: "100%",
    height: "100%",
    background:
      "linear-gradient(90deg, transparent, rgba(59, 130, 246, 0.3), transparent)",
    transition: "left 0.5s",
  },
  "&:hover": {
    background:
      "linear-gradient(145deg, #556175 0%, #374151 50%, #1f2937 100%)",
    borderColor: "#60a5fa",
    boxShadow: `
      0 0 30px rgba(59, 130, 246, 0.6),
      0 6px 12px rgba(0, 0, 0, 0.4),
      inset 0 1px 0 rgba(255, 255, 255, 0.15)
    `,
    transform: "translateY(-2px)",
    "&::before": {
      left: "100%",
    },
  },
  "&:active": {
    transform: "translateY(0px)",
    boxShadow: `
      0 0 15px rgba(59, 130, 246, 0.5),
      0 2px 4px rgba(0, 0, 0, 0.3),
      inset 0 1px 0 rgba(255, 255, 255, 0.1)
    `,
  },
  "&:disabled": {
    background:
      "linear-gradient(145deg, #374151 0%, #1f2937 50%, #111827 100%)",
    borderColor: "#1e3a8a",
    color: "rgba(255, 255, 255, 0.5)",
    boxShadow: "none",
    textShadow: "none",
  },
  transition: "all 0.3s ease",
};
