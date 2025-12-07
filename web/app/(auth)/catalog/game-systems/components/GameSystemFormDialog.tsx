"use client";

import {
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Stack,
  TextField,
} from "@mui/material";
import { FormEvent, useState } from "react";

import { CatalogItemVisibilityField } from "@/app/(auth)/catalog/components/CatalogItemVisibilityField";
import { type CatalogItemVisibility } from "@/app/(auth)/catalog/game-systems/hooks/use-game-systems";
import { gameSystemFormMessages as m } from "@/app/(auth)/catalog/game-systems/messages";
import { type UserRole } from "@/app/contexts/user-context";
import { isValidUrl } from "@/lib/utils/url-validation";

type GameSystemFormValues = {
  name: string;
  publisher: string | null;
  releaseYear: number | null;
  website: string | null;
  visibility: CatalogItemVisibility;
};

type GameSystemFormDialogProps = {
  open: boolean;
  mode: "create" | "edit";
  initialValues?: Partial<GameSystemFormValues>;
  userRoles: UserRole[];
  onClose: () => void;
  onSave: (values: GameSystemFormValues) => void;
  isPending?: boolean;
};

export function GameSystemFormDialog({
  open,
  mode,
  initialValues,
  userRoles,
  onClose,
  onSave,
  isPending = false,
}: GameSystemFormDialogProps) {
  const [name, setName] = useState(initialValues?.name ?? "");
  const [publisher, setPublisher] = useState(initialValues?.publisher ?? "");
  const [releaseYear, setReleaseYear] = useState(
    initialValues?.releaseYear?.toString() ?? "",
  );
  const [website, setWebsite] = useState(initialValues?.website ?? "");
  const [visibility, setVisibility] = useState<CatalogItemVisibility>(
    initialValues?.visibility ?? "private",
  );

  const [nameError, setNameError] = useState<string | null>(null);
  const [websiteError, setWebsiteError] = useState<string | null>(null);
  const [releaseYearError, setReleaseYearError] = useState<string | null>(null);

  const dialogTitle = mode === "create" ? m.createTitle : m.editTitle;

  const handleSubmit = (event: FormEvent) => {
    event.preventDefault();

    const trimmedName = name.trim();
    const trimmedPublisher = publisher?.toString().trim() ?? "";
    const trimmedWebsite = website?.toString().trim() ?? "";
    const trimmedReleaseYear = releaseYear?.toString().trim() ?? "";

    let hasError = false;

    if (!trimmedName) {
      setNameError(m.nameRequired);
      hasError = true;
    } else {
      setNameError(null);
    }

    if (trimmedWebsite && !isValidUrl(trimmedWebsite)) {
      setWebsiteError(m.websiteError);
      hasError = true;
    } else {
      setWebsiteError(null);
    }

    if (trimmedReleaseYear) {
      const yearNumber = Number(trimmedReleaseYear);
      if (!Number.isInteger(yearNumber) || yearNumber <= 0) {
        setReleaseYearError(m.releaseYearError);
        hasError = true;
      } else {
        setReleaseYearError(null);
      }
    } else {
      setReleaseYearError(null);
    }

    if (hasError) {
      return;
    }

    const payload: GameSystemFormValues = {
      name: trimmedName,
      publisher: trimmedPublisher || null,
      releaseYear: trimmedReleaseYear ? Number(trimmedReleaseYear) : null,
      website: trimmedWebsite || null,
      visibility,
    };

    onSave(payload);
  };

  const isFormDisabled = isPending;

  return (
    <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle>{dialogTitle}</DialogTitle>
      <DialogContent>
        <Stack
          component="form"
          onSubmit={handleSubmit}
          spacing={2}
          sx={{ pt: 2 }}
        >
          <TextField
            label={m.nameLabel}
            placeholder={m.namePlaceholder}
            value={name}
            onChange={(event) => setName(event.target.value)}
            fullWidth
            disabled={isFormDisabled}
            error={Boolean(nameError)}
            helperText={nameError}
            InputLabelProps={{ shrink: true, required: true }}
          />

          <TextField
            label={m.publisherLabel}
            placeholder={m.publisherPlaceholder}
            value={publisher}
            onChange={(event) => setPublisher(event.target.value)}
            fullWidth
            disabled={isFormDisabled}
            InputLabelProps={{ shrink: true, required: false }}
          />

          <TextField
            label={m.releaseYearLabel}
            placeholder={m.releaseYearPlaceholder}
            value={releaseYear}
            onChange={(event) => setReleaseYear(event.target.value)}
            fullWidth
            type="number"
            disabled={isFormDisabled}
            error={Boolean(releaseYearError)}
            helperText={releaseYearError}
            InputLabelProps={{ shrink: true, required: false }}
          />

          <TextField
            label={m.websiteLabel}
            placeholder={m.websitePlaceholder}
            value={website}
            onChange={(event) => setWebsite(event.target.value)}
            fullWidth
            disabled={isFormDisabled}
            error={Boolean(websiteError)}
            helperText={websiteError}
            InputLabelProps={{ shrink: true, required: false }}
          />

          <CatalogItemVisibilityField
            mode={mode}
            value={visibility}
            userRoles={userRoles}
            disabled={isFormDisabled}
            onChange={setVisibility}
          />
        </Stack>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>{m.cancel}</Button>
        <Button onClick={handleSubmit} disabled={isFormDisabled}>
          {m.save}
        </Button>
      </DialogActions>
    </Dialog>
  );
}
