"use client";

import { Avatar, Skeleton } from "@mui/material";
import { useMemo, useState } from "react";

type UserAvatarProps = {
  displayName?: string | null;
  avatarURL?: string | null;
  isLoading?: boolean;
  width?: number;
  height?: number;
};

export function UserAvatar({
  displayName,
  avatarURL,
  isLoading = false,
  width = 40,
  height = 40,
}: UserAvatarProps) {
  const [failedAvatarUrl, setFailedAvatarUrl] = useState<string | null>(null);

  const avatarSrc =
    avatarURL && avatarURL !== failedAvatarUrl ? avatarURL : undefined;

  const initials = useMemo(() => getInitials(displayName), [displayName]);

  function handleAvatarError() {
    if (avatarURL) {
      setFailedAvatarUrl(avatarURL);
    }
  }

  if (isLoading) {
    return (
      <Skeleton
        variant="circular"
        animation="wave"
        width={width}
        height={height}
      />
    );
  }

  return (
    <Avatar
      src={avatarSrc}
      alt={displayName ?? "User"}
      onError={handleAvatarError}
      sx={{
        width,
        height,
        bgcolor: avatarSrc ? undefined : "primary.main",
        color: avatarSrc ? undefined : "primary.contrastText",
      }}
    >
      {initials}
    </Avatar>
  );
}

function getInitials(name?: string | null) {
  if (!name) return "U";
  const parts = name.trim().split(" ").filter(Boolean);
  const initials = parts.slice(0, 2).map((part) => part[0]);
  return initials.join("").toUpperCase();
}
