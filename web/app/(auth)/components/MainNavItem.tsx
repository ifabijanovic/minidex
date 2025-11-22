"use client";

import { ListItemButton, ListItemIcon, ListItemText } from "@mui/material";
import Link from "next/link";
import { usePathname } from "next/navigation";
import type { ElementType } from "react";

type MainNavItemProps = {
  label: string;
  href: string;
  icon: ElementType;
  exact?: boolean;
};

const baseStyles = {
  borderRadius: 1.5,
  "&:hover": {
    bgcolor: "primary.light",
  },
  "&.Mui-selected": {
    bgcolor: "primary.main",
    color: "primary.contrastText",
    "& .MuiListItemIcon-root": {
      color: "primary.contrastText",
    },
    "&:hover": {
      bgcolor: "primary.light",
      color: "primary.contrastText",
      "& .MuiListItemIcon-root": {
        color: "primary.contrastText",
      },
    },
  },
};

export function MainNavItem({
  label,
  href,
  icon: Icon,
  exact = false,
}: MainNavItemProps) {
  const pathname = usePathname();
  const isActive = exact ? pathname === href : pathname.startsWith(href);

  return (
    <ListItemButton
      component={Link}
      href={href}
      selected={isActive}
      sx={baseStyles}
    >
      <ListItemIcon>
        <Icon fontSize="small" />
      </ListItemIcon>
      <ListItemText primary={label} />
    </ListItemButton>
  );
}
