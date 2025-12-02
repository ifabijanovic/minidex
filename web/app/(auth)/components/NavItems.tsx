"use client";

import ExpandLess from "@mui/icons-material/ExpandLess";
import ExpandMore from "@mui/icons-material/ExpandMore";
import {
  Collapse,
  List,
  ListItemButton,
  ListItemIcon,
  ListItemText,
} from "@mui/material";
import { Theme } from "@mui/material/styles";
import Link from "next/link";
import { usePathname } from "next/navigation";
import type { ElementType } from "react";
import { ReactNode, useState } from "react";

const baseStyles = (theme: Theme) => {
  const isLight = theme.palette.mode === "light";
  return {
    borderRadius: 1.5,
    mb: 1,
    "&:hover": {
      bgcolor: isLight
        ? theme.palette.primary.light
        : theme.palette.primary.dark,
    },
    "&.Mui-selected": {
      bgcolor: "primary.main",
      color: "primary.contrastText",
      "& .MuiListItemIcon-root": {
        color: "primary.contrastText",
      },
      "&:hover": {
        bgcolor: isLight
          ? theme.palette.primary.light
          : theme.palette.primary.dark,
        color: "primary.contrastText",
        "& .MuiListItemIcon-root": {
          color: "primary.contrastText",
        },
      },
    },
  };
};

const childItemStyles = (theme: Theme) => ({
  ...baseStyles(theme),
  pl: 4,
});

type NavItemProps = {
  label: string;
  href: string;
  icon: ElementType;
  exact?: boolean;
};

export function NavItem({
  label,
  href,
  icon: Icon,
  exact = false,
}: NavItemProps) {
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

type ExpandableNavItemProps = {
  label: string;
  icon: ElementType;
  children: ReactNode;
  basePath?: string;
};

export function ExpandableNavItem({
  label,
  icon: Icon,
  children,
  basePath,
}: ExpandableNavItemProps) {
  const pathname = usePathname();
  const isRouteActive = basePath ? pathname.startsWith(basePath) : false;
  const [open, setOpen] = useState(isRouteActive);

  const handleClick = () => {
    setOpen(!open);
  };

  return (
    <>
      <ListItemButton onClick={handleClick} sx={baseStyles}>
        <ListItemIcon>
          <Icon fontSize="small" />
        </ListItemIcon>
        <ListItemText primary={label} />
        {open ? <ExpandLess /> : <ExpandMore />}
      </ListItemButton>
      <Collapse in={open} timeout="auto" unmountOnExit>
        <List component="div" disablePadding>
          {children}
        </List>
      </Collapse>
    </>
  );
}

type NavItemChildProps = {
  label: string;
  href: string;
  icon: ElementType;
};

export function NavItemChild({ label, href, icon: Icon }: NavItemChildProps) {
  const pathname = usePathname();
  const isActive = pathname.startsWith(href);

  return (
    <ListItemButton
      component={Link}
      href={href}
      selected={isActive}
      sx={childItemStyles}
    >
      <ListItemIcon>
        <Icon fontSize="small" />
      </ListItemIcon>
      <ListItemText primary={label} />
    </ListItemButton>
  );
}
