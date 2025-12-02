"use client";

import HomeOutlined from "@mui/icons-material/HomeOutlined";
import MenuIcon from "@mui/icons-material/Menu";
import PeopleOutlined from "@mui/icons-material/PeopleOutlined";
import PersonOutlined from "@mui/icons-material/PersonOutlined";
import SettingsOutlined from "@mui/icons-material/SettingsOutlined";
import {
  Box,
  Divider,
  Drawer,
  IconButton,
  List,
  ListItemIcon,
  Menu,
  MenuItem,
  Typography,
  useMediaQuery,
  useTheme,
} from "@mui/material";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useState } from "react";

import LogoutButton from "@/app/(auth)/components/LogoutButton";
import {
  ExpandableNavItem,
  NavItem,
  NavItemChild,
} from "@/app/(auth)/components/NavItems";
import { UserAvatar } from "@/app/(auth)/components/UserAvatar";
import { useCurrentProfile } from "@/app/(auth)/hooks/use-current-profile";
import { layoutMessages as m } from "@/app/(auth)/messages";
import { useCurrentUser } from "@/app/context/user-context";

const DRAWER_WIDTH = 260;

function SidebarContent({ isAdmin }: { isAdmin: boolean }) {
  return (
    <>
      <Box sx={{ px: 2, py: 1 }}>
        <Typography variant="h5" fontWeight={700} color="primary.main">
          {m.appName}
        </Typography>
        <Typography variant="body2" color="text.secondary">
          {m.adminConsole}
        </Typography>
      </Box>

      <List sx={{ flexGrow: 1, p: 0.5 }}>
        <NavItem label={m.home} href="/home" icon={HomeOutlined} exact />
        {isAdmin && (
          <ExpandableNavItem
            label={m.admin}
            icon={SettingsOutlined}
            basePath="/admin"
          >
            <NavItemChild
              label={m.users}
              href="/admin/users"
              icon={PeopleOutlined}
            />
          </ExpandableNavItem>
        )}
      </List>

      <Typography
        variant="caption"
        color="text.secondary"
        sx={{ px: 2, pb: 1 }}
      >
        © {new Date().getFullYear()} {m.appName}
      </Typography>
    </>
  );
}

export default function AuthenticatedLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("md"));
  const pathname = usePathname();
  const { data: profile, isLoading: isProfileLoading } = useCurrentProfile();
  const { user } = useCurrentUser();
  const [menuAnchor, setMenuAnchor] = useState<null | HTMLElement>(null);
  const [mobileOpen, setMobileOpen] = useState(false);
  const isMenuOpen = Boolean(menuAnchor);

  const displayName = profile?.displayName ?? m.user;
  const isAdmin = user?.roles.includes("admin") ?? false;

  /* eslint-disable react-hooks/set-state-in-effect */
  useEffect(() => {
    if (isMobile) {
      setMobileOpen(false);
    }
  }, [pathname, isMobile]);
  /* eslint-enable react-hooks/set-state-in-effect */

  function handleAvatarClick(event: React.MouseEvent<HTMLElement>) {
    setMenuAnchor(event.currentTarget);
  }

  function handleMenuClose() {
    setMenuAnchor(null);
  }

  function handleDrawerToggle() {
    setMobileOpen(!mobileOpen);
  }

  return (
    <Box
      sx={{
        display: "flex",
        minHeight: "100vh",
        bgcolor: "background.default",
      }}
    >
      {/* Desktop Sidebar */}
      <Box
        component="aside"
        sx={{
          width: DRAWER_WIDTH,
          flexShrink: 0,
          display: { xs: "none", md: "flex" },
          flexDirection: "column",
          borderRight: (theme) => `1px solid ${theme.palette.divider}`,
          bgcolor: "background.default",
          px: 2,
          py: 1,
          gap: 4,
        }}
      >
        <SidebarContent isAdmin={isAdmin} />
      </Box>

      {/* Mobile Drawer */}
      <Drawer
        variant="temporary"
        open={mobileOpen}
        onClose={handleDrawerToggle}
        ModalProps={{
          keepMounted: true,
        }}
        sx={{
          display: { xs: "block", md: "none" },
          "& .MuiDrawer-paper": {
            boxSizing: "border-box",
            width: DRAWER_WIDTH,
          },
        }}
      >
        <Box
          sx={{
            display: "flex",
            flexDirection: "column",
            height: "100%",
            bgcolor: "background.default",
            gap: 4,
          }}
        >
          <SidebarContent isAdmin={isAdmin} />
        </Box>
      </Drawer>

      <Box
        sx={{ flex: 1, display: "flex", flexDirection: "column", minWidth: 0 }}
      >
        <Box
          component="header"
          sx={{
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            px: 2,
            py: 1,
            bgcolor: "background.default",
            borderBottom: (theme) => `1px solid ${theme.palette.divider}`,
          }}
        >
          <IconButton
            color="inherit"
            aria-label="open drawer"
            edge="start"
            onClick={handleDrawerToggle}
            sx={{ mr: 2, display: { md: "none" } }}
          >
            <MenuIcon />
          </IconButton>

          <Box sx={{ flexGrow: 1 }} />

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
              {m.home}
            </MenuItem>
            <MenuItem
              component={Link}
              href="/me"
              onClick={handleMenuClose}
              sx={{ px: 1, mx: 1, mt: 1, borderRadius: 1 }}
            >
              <ListItemIcon sx={{ minWidth: 32 }}>
                <PersonOutlined fontSize="small" />
              </ListItemIcon>
              {m.profile}
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
                disableRipple
                fullWidth
                color="secondary"
                sx={{
                  fontSize: "inherit",
                  fontWeight: "inherit !important",
                  lineHeight: "inherit",
                  fontFamily: "inherit",
                  textTransform: "inherit",
                  p: 0,
                }}
                onLoggedOut={handleMenuClose}
              >
                {m.logout}
              </LogoutButton>
            </MenuItem>
          </Menu>
        </Box>

        <Box
          component="main"
          sx={{
            flex: 1,
            px: { xs: 1, sm: 2, md: 4 },
            py: { xs: 1, sm: 2 },
            overflow: "auto",
          }}
        >
          {children}
        </Box>
      </Box>
    </Box>
  );
}
