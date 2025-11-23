"use client";

import HomeOutlined from "@mui/icons-material/HomeOutlined";
import PersonOutlined from "@mui/icons-material/PersonOutlined";
import {
  Box,
  Divider,
  IconButton,
  List,
  ListItemIcon,
  Menu,
  MenuItem,
  Typography,
} from "@mui/material";
import Link from "next/link";
import { useState } from "react";

import LogoutButton from "@/app/(auth)/components/LogoutButton";
import { MainNavItem } from "@/app/(auth)/components/MainNavItem";
import { UserAvatar } from "@/app/(auth)/components/UserAvatar";
import { useCurrentProfile } from "@/app/(auth)/hooks/use-current-profile";

export default function AuthenticatedLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const { data: profile, isLoading: isProfileLoading } = useCurrentProfile();
  const [menuAnchor, setMenuAnchor] = useState<null | HTMLElement>(null);
  const isMenuOpen = Boolean(menuAnchor);

  const displayName = profile?.displayName ?? "User";

  function handleAvatarClick(event: React.MouseEvent<HTMLElement>) {
    setMenuAnchor(event.currentTarget);
  }

  function handleMenuClose() {
    setMenuAnchor(null);
  }

  return (
    <Box
      sx={{
        display: "flex",
        minHeight: "100vh",
        bgcolor: "background.default",
      }}
    >
      <Box
        component="aside"
        sx={{
          width: 260,
          borderRight: (theme) => `1px solid ${theme.palette.divider}`,
          bgcolor: "background.default",
          px: 2,
          py: 1,
          display: "flex",
          flexDirection: "column",
          gap: 4,
        }}
      >
        <Box>
          <Typography variant="h5" fontWeight={700} color="primary.main">
            MiniDex
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Admin Console
          </Typography>
        </Box>

        <List sx={{ flexGrow: 1, p: 0 }}>
          <MainNavItem label="Home" href="/home" icon={HomeOutlined} exact />
        </List>

        <Typography variant="caption" color="text.secondary">
          © {new Date().getFullYear()} MiniDex
        </Typography>
      </Box>

      <Box sx={{ flex: 1, display: "flex", flexDirection: "column" }}>
        <Box
          component="header"
          sx={{
            display: "flex",
            alignItems: "flex-start",
            justifyContent: "flex-end",
            pl: 4,
            pr: 2,
            pt: 1,
            bgcolor: "background.default",
          }}
        >
          <IconButton onClick={handleAvatarClick} disabled={isProfileLoading}>
            <UserAvatar
              displayName={displayName}
              avatarURL={profile?.avatarURL}
              isLoading={isProfileLoading}
            />
          </IconButton>

          <Menu
            anchorEl={menuAnchor}
            open={isMenuOpen}
            onClose={handleMenuClose}
            anchorOrigin={{ vertical: "bottom", horizontal: "right" }}
            transformOrigin={{ vertical: "top", horizontal: "right" }}
          >
            <Box sx={{ px: 2, py: 1 }}>
              <Typography variant="subtitle2">{displayName}</Typography>
            </Box>
            <Divider />
            <MenuItem
              component={Link}
              href="/home"
              onClick={handleMenuClose}
              sx={{ px: 1, mx: 1, mt: 1, borderRadius: 1 }}
            >
              <ListItemIcon sx={{ minWidth: 32 }}>
                <HomeOutlined fontSize="small" />
              </ListItemIcon>
              Home
            </MenuItem>
            <MenuItem
              component={Link}
              href="/account"
              onClick={handleMenuClose}
              sx={{ px: 1, mx: 1, mt: 1, borderRadius: 1 }}
            >
              <ListItemIcon sx={{ minWidth: 32 }}>
                <PersonOutlined fontSize="small" />
              </ListItemIcon>
              Profile
            </MenuItem>
            <MenuItem
              disableRipple
              sx={{
                px: 1,
                mx: 1,
                mt: 1,
                borderRadius: 1,
                "&:hover": {
                  backgroundColor: "error.light",
                },
                "& .MuiButton-root": {
                  width: "100%",
                  justifyContent: "center",
                  fontWeight: 700,
                  py: 0,
                  "&:hover": {
                    backgroundColor: "transparent",
                  },
                },
              }}
            >
              <LogoutButton
                variant="text"
                fullWidth
                color="error"
                onLoggedOut={handleMenuClose}
              >
                Logout
              </LogoutButton>
            </MenuItem>
          </Menu>
        </Box>

        <Box component="main" sx={{ flex: 1, px: 4, py: 2 }}>
          {children}
        </Box>
      </Box>
    </Box>
  );
}
