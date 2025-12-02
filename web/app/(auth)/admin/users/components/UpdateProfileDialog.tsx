"use client";

import {
  Box,
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Stack,
  TextField,
} from "@mui/material";
import { FormEvent, useState } from "react";

import { updateProfileDialogMessages as m } from "@/app/(auth)/admin/users/messages";
import { UserAvatar } from "@/app/(auth)/components/UserAvatar";
import { isValidUrl } from "@/lib/utils/url-validation";

type UpdateProfileDialogProps = {
  open: boolean;
  currentDisplayName?: string | null;
  currentAvatarURL?: string | null;
  onClose: () => void;
  onSave: (data: {
    displayName: string | null;
    avatarURL: string | null;
  }) => void;
  isPending?: boolean;
};

export function UpdateProfileDialog({
  open,
  currentDisplayName,
  currentAvatarURL,
  onClose,
  onSave,
  isPending = false,
}: UpdateProfileDialogProps) {
  const [displayName, setDisplayName] = useState(currentDisplayName ?? "");
  const [avatarURL, setAvatarURL] = useState(currentAvatarURL ?? "");
  const [avatarUrlError, setAvatarUrlError] = useState<string | null>(null);

  const handleDisplayNameChange = (
    event: React.ChangeEvent<HTMLInputElement>,
  ) => {
    setDisplayName(event.target.value);
  };

  const handleAvatarUrlChange = (
    event: React.ChangeEvent<HTMLInputElement>,
  ) => {
    const value = event.target.value;
    setAvatarURL(value);

    if (value.trim() && !isValidUrl(value)) {
      setAvatarUrlError(m.avatarUrlError);
    } else {
      setAvatarUrlError(null);
    }
  };

  const handleSave = (event: FormEvent) => {
    event.preventDefault();

    const payload = {
      displayName: displayName.trim() || null,
      avatarURL: avatarURL.trim() || null,
    };

    onSave(payload);
  };

  const hasFormError = avatarUrlError !== null;
  const isFormDisabled = isPending;

  return (
    <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle>{m.title}</DialogTitle>
      <DialogContent>
        <Stack
          component="form"
          onSubmit={handleSave}
          spacing={3}
          sx={{ pt: 2 }}
        >
          <TextField
            label={m.displayNameLabel}
            value={displayName}
            onChange={handleDisplayNameChange}
            placeholder={m.displayNamePlaceholder}
            fullWidth
            disabled={isFormDisabled}
            InputLabelProps={{ shrink: true, required: false }}
          />

          <Box
            sx={{
              display: "flex",
              flexDirection: { xs: "column", sm: "row" },
              gap: 2,
              alignItems: { xs: "flex-start", sm: "flex-start" },
            }}
          >
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
            {avatarURL.trim() && isValidUrl(avatarURL) && !hasFormError && (
              <UserAvatar
                displayName={displayName}
                avatarURL={avatarURL.trim()}
                width={56}
                height={56}
                sx={{ flexShrink: 0 }}
              />
            )}
          </Box>
        </Stack>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose} color="secondary">
          {m.cancel}
        </Button>
        <Button onClick={handleSave} disabled={isFormDisabled || hasFormError}>
          {m.save}
        </Button>
      </DialogActions>
    </Dialog>
  );
}
