"use client";

import HomeOutlined from "@mui/icons-material/HomeOutlined";
import PersonOutlined from "@mui/icons-material/PersonOutlined";
import {
  Alert,
  Avatar,
  Box,
  Button,
  Card,
  CardContent,
  CircularProgress,
  Divider,
  IconButton,
  List,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Menu,
  MenuItem,
  Stack,
  Typography,
} from "@mui/material";
import Link from "next/link";
import { useMemo, useState } from "react";

import LogoutButton from "@/app/components/LogoutButton";
import { useCurrentUser } from "@/app/hooks/use-current-user";

const placeholderUser = {
  id: "user-1234",
  displayName: "Jordan Miles",
  roles: 1,
  isActive: true,
  email: "jordan.miles@example.com",
  roleTitle: "Product Manager",
};

export default function DashboardPage() {
  const {
    data: user = placeholderUser,
    isPending,
    isFetching,
    error,
  } = useCurrentUser({
    enabled: false,
    placeholderData: placeholderUser,
  });

  const [menuAnchor, setMenuAnchor] = useState<null | HTMLElement>(null);
  const isMenuOpen = Boolean(menuAnchor);

  const showLoading = isPending && !error;
  const initials = useMemo(
    () => getInitials(user.displayName),
    [user.displayName],
  );

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
          <ListItemButton component={Link} href="/dashboard" selected sx={{ borderRadius: 1 }}>
            <ListItemIcon>
              <HomeOutlined fontSize="small" />
            </ListItemIcon>
            <ListItemText primary="Home" />
          </ListItemButton>
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
            alignItems: "end",
            justifyContent: "space-between",
            pl: 4,
            pr: 2,
            pt: 1,
            bgcolor: "background.default",
          }}
        >
          <Box></Box>

          <IconButton
            onClick={handleAvatarClick}
          >
            <Avatar
              src="/images/avatar-placeholder.png"
              alt={user.displayName ?? "User avatar"}
            >
              {initials}
            </Avatar>
          </IconButton>

          <Menu
            anchorEl={menuAnchor}
            open={isMenuOpen}
            onClose={handleMenuClose}
            anchorOrigin={{ vertical: "bottom", horizontal: "right" }}
            transformOrigin={{ vertical: "top", horizontal: "right" }}
          >
            <Box sx={{ px: 2, py: 1 }}>
              <Typography variant="subtitle2">{user.displayName}</Typography>
              <Typography variant="body2" color="text.secondary">
                {placeholderUser.email}
              </Typography>
            </Box>
            <Divider />
            <MenuItem
              component={Link} href="/dashboard"
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
              href="/account" onClick={handleMenuClose}
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
                "&:hover": {
                  backgroundColor: "transparent",
                },
              }}>
              <LogoutButton
                variant="text"
                fullWidth
                color="error"
                onLoggedOut={handleMenuClose}
                sx={{
                  fontWeight: 700,
                  borderRadius: 1,
                }}
              >
                Logout
              </LogoutButton>
            </MenuItem>
          </Menu>
        </Box>

        <Box component="main" sx={{ flex: 1, px: 4 }}>
          <Box sx={{ pb: 2 }}>
            <Typography variant="h6" fontWeight={600}>
              Welcome back, {user.displayName?.split(" ")[0] ?? "there"}!
            </Typography>
          </Box>

          <Stack spacing={3}>
            {showLoading && (
              <Box sx={{ display: "flex", justifyContent: "center", py: 4 }}>
                <CircularProgress />
              </Box>
            )}

            {error && (
              <Alert severity="error">
                Unable to fetch user information. This view is currently using
                placeholder data.
              </Alert>
            )}

            <Card>
              <CardContent>
                <Typography variant="h5" gutterBottom>
                  Account Overview
                </Typography>
                <Typography variant="body2" color="text.secondary" mb={3}>
                  This section will summarize engagement details once the API
                  integration is complete.
                </Typography>
                <Stack direction={{ xs: "column", md: "row" }} spacing={3}>
                  <UserInfoItem label="Name" value={user.displayName} />
                  <UserInfoItem label="Email" value={placeholderUser.email} />
                  <UserInfoItem
                    label="Role"
                    value={placeholderUser.roleTitle}
                  />
                </Stack>
              </CardContent>
            </Card>

            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  Quick Actions
                </Typography>
                <Typography variant="body2" color="text.secondary" mb={2}>
                  Use these shortcuts to navigate once the full experience is
                  ready.
                </Typography>
                <Stack direction={{ xs: "column", sm: "row" }} spacing={2}>
                  <Button
                    variant="contained"
                    component={Link}
                    href="/dashboard"
                  >
                    Go to Home
                  </Button>
                  <Button variant="outlined" component={Link} href="/account">
                    View Profile
                  </Button>
                </Stack>
              </CardContent>
            </Card>
          </Stack>
        </Box>
      </Box>
    </Box>
  );
}

function UserInfoItem({
  label,
  value,
}: {
  label: string;
  value?: string | null;
}) {
  return (
    <Box sx={{ minWidth: 200 }}>
      <Typography variant="overline" color="text.secondary">
        {label}
      </Typography>
      <Typography variant="subtitle1" fontWeight={600}>
        {value ?? "—"}
      </Typography>
    </Box>
  );
}

function getInitials(name?: string | null) {
  if (!name) return "U";
  const parts = name.trim().split(" ").filter(Boolean);
  const initials = parts.slice(0, 2).map((part) => part[0]);
  return initials.join("").toUpperCase();
}
