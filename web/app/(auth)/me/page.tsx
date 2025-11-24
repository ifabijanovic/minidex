"use client";

import {
  Box,
  Button,
  Card,
  CardContent,
  Container,
  Skeleton,
  Stack,
  TextField,
  Typography,
} from "@mui/material";
import { useQueryClient } from "@tanstack/react-query";
import { enqueueSnackbar } from "notistack";
import { FormEvent, useEffect, useState } from "react";

import { UserAvatar } from "@/app/(auth)/components/UserAvatar";
import {
  type CurrentProfile,
  useCurrentProfile,
} from "@/app/(auth)/hooks/use-current-profile";
import { profileEditMessages as m } from "@/app/(auth)/me/messages";
import { useCurrentUser } from "@/app/context/user-context";
import { useApiMutation } from "@/lib/hooks/use-api-mutation";
import { queryKeys } from "@/lib/query-keys";

type ProfilePayload = {
  displayName?: string | null;
  avatarURL?: string | null;
};

function isValidUrl(url: string): boolean {
  if (!url.trim()) return true; // Empty is valid (will be null)
  try {
    new URL(url);
    return true;
  } catch {
    return false;
  }
}

export default function ProfileEditPage() {
  const queryClient = useQueryClient();
  const { user } = useCurrentUser();
  const { data: profile, isLoading: isProfileLoading } = useCurrentProfile();

  const [displayName, setDisplayName] = useState("");
  const [avatarURL, setAvatarURL] = useState("");
  const [avatarUrlError, setAvatarUrlError] = useState<string | null>(null);

  // Initialize form with profile data when it loads
  useEffect(() => {
    /* eslint-disable react-hooks/set-state-in-effect */
    if (profile) {
      setDisplayName(profile.displayName ?? "");
      setAvatarURL(profile.avatarURL ?? "");
    } else {
      setDisplayName("");
      setAvatarURL("");
    }
    /* eslint-enable react-hooks/set-state-in-effect */
  }, [profile]);

  const saveMutation = useApiMutation<CurrentProfile, ProfilePayload>({
    method: profile ? "patch" : "post",
    path: "/v1/me",
    onSuccess: async () => {
      if (user) {
        await queryClient.invalidateQueries({
          queryKey: queryKeys.currentProfile(user.userId),
        });
      }
      enqueueSnackbar(m.saveSuccess, { variant: "success" });
    },
  });

  const handleDisplayNameChange = (
    event: React.ChangeEvent<HTMLInputElement>,
  ) => {
    if (saveMutation.isError) saveMutation.reset();
    setDisplayName(event.target.value);
  };

  const handleAvatarUrlChange = (
    event: React.ChangeEvent<HTMLInputElement>,
  ) => {
    if (saveMutation.isError) saveMutation.reset();
    const value = event.target.value;
    setAvatarURL(value);

    if (value.trim() && !isValidUrl(value)) {
      setAvatarUrlError(m.avatarUrlError);
    } else {
      setAvatarUrlError(null);
    }
  };

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    const payload: ProfilePayload = {
      displayName: displayName.trim() || null,
      avatarURL: avatarURL.trim() || null,
    };

    saveMutation.mutate(payload);
  }

  const isFormDisabled = isProfileLoading || saveMutation.isPending;
  const hasFormError = avatarUrlError !== null;

  return (
    <Container maxWidth="md" component="form" onSubmit={handleSubmit}>
      <Stack spacing={3}>
        <Typography variant="h5">{m.title}</Typography>

        <Card>
          <CardContent>
            <Stack spacing={3} sx={{ p: 2 }}>
              {isProfileLoading ? (
                <Skeleton variant="rectangular" height={56} animation="wave" />
              ) : (
                <TextField
                  label={m.displayNameLabel}
                  value={displayName}
                  onChange={handleDisplayNameChange}
                  placeholder={m.displayNamePlaceholder}
                  fullWidth
                  disabled={isFormDisabled}
                  InputLabelProps={{ shrink: true, required: false }}
                />
              )}

              {isProfileLoading ? (
                <Skeleton variant="rectangular" height={56} animation="wave" />
              ) : (
                <Box sx={{ display: "flex", gap: 2, alignItems: "flex-start" }}>
                  <TextField
                    label={m.avatarUrlLabel}
                    value={avatarURL}
                    onChange={handleAvatarUrlChange}
                    placeholder={m.avatarUrlPlaceholder}
                    fullWidth
                    disabled={isFormDisabled}
                    error={hasFormError}
                    helperText={avatarUrlError}
                    InputLabelProps={{ shrink: true, required: false }}
                  />
                  {avatarURL.trim() &&
                    isValidUrl(avatarURL) &&
                    !hasFormError && (
                      <UserAvatar
                        displayName={displayName}
                        avatarURL={avatarURL.trim()}
                        width={56}
                        height={56}
                      />
                    )}
                </Box>
              )}
            </Stack>
          </CardContent>
        </Card>

        <Box sx={{ display: "flex", justifyContent: "flex-end" }}>
          <Button
            type="submit"
            variant="contained"
            size="large"
            disabled={isFormDisabled || hasFormError}
          >
            {saveMutation.isPending ? m.submitPending : m.submitIdle}
          </Button>
        </Box>
      </Stack>
    </Container>
  );
}
