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

import {
  type CurrentProfile,
  useCurrentProfile,
} from "@/app/(auth)/hooks/use-current-profile";
import { profileEditMessages as m } from "@/app/(auth)/me/messages";
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
      await queryClient.invalidateQueries({
        queryKey: queryKeys.currentProfile,
      });
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

  if (isProfileLoading) {
    return (
      <Container maxWidth="md">
        <Stack spacing={3}>
          <Card>
            <CardContent>
              <Skeleton
                variant="text"
                width="40%"
                height={32}
                animation="wave"
                sx={{ mb: 1 }}
              />
              <Stack spacing={3}>
                <Skeleton variant="rectangular" height={56} animation="wave" />
                <Skeleton variant="rectangular" height={56} animation="wave" />
                <Skeleton variant="rectangular" height={40} animation="wave" />
              </Stack>
            </CardContent>
          </Card>
        </Stack>
      </Container>
    );
  }

  return (
    <Container maxWidth="md">
      <Stack spacing={3}>
        <Card>
          <CardContent>
            <Typography variant="h5" gutterBottom>
              {m.title}
            </Typography>

            <Box component="form" onSubmit={handleSubmit}>
              <Stack spacing={3}>
                <TextField
                  label={m.displayNameLabel}
                  value={displayName}
                  onChange={handleDisplayNameChange}
                  placeholder={m.displayNamePlaceholder}
                  fullWidth
                  disabled={isFormDisabled}
                  InputLabelProps={{ shrink: true, required: false }}
                />

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

                <Box>
                  <Button
                    type="submit"
                    variant="contained"
                    size="large"
                    disabled={isFormDisabled || hasFormError}
                    fullWidth
                  >
                    {saveMutation.isPending ? m.submitPending : m.submitIdle}
                  </Button>
                </Box>
              </Stack>
            </Box>
          </CardContent>
        </Card>
      </Stack>
    </Container>
  );
}
