"use client";

import Contrast from "@mui/icons-material/Contrast";
import DarkMode from "@mui/icons-material/DarkMode";
import LightMode from "@mui/icons-material/LightMode";
import { IconButton, Tooltip } from "@mui/material";
import { useTheme } from "next-themes";
import { useEffect, useState } from "react";

import { colorModeMessages as m } from "@/app/components/messages";

export function ColorModeSwitch() {
  const { theme, setTheme } = useTheme();
  const [mounted, setMounted] = useState(false);

  /* eslint-disable react-hooks/set-state-in-effect */
  useEffect(() => {
    setMounted(true);
  }, []);
  /* eslint-enable react-hooks/set-state-in-effect */

  function handleClick() {
    const nextMode =
      theme === "system" ? "light" : theme === "light" ? "dark" : "system";
    setTheme(nextMode);
  }

  const icon =
    theme === "system" ? (
      <Contrast />
    ) : theme === "light" ? (
      <LightMode />
    ) : (
      <DarkMode />
    );

  const tooltip =
    theme === "system" ? m.auto : theme === "light" ? m.light : m.dark;

  return (
    <Tooltip title={tooltip}>
      <IconButton onClick={handleClick} color="inherit">
        {icon}
      </IconButton>
    </Tooltip>
  );
}
