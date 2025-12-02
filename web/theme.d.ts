import { PaletteColor, SimplePaletteColorOptions } from "@mui/material/styles";

declare module "@mui/material/styles" {
  interface PaletteColor {
    lightest: string;
    darkest: string;
  }
  interface SimplePaletteColorOptions {
    lightest?: string;
    darkest?: string;
  }
}
