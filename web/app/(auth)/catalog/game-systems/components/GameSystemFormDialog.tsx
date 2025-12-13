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
import { FormEvent, useMemo, useState } from "react";

import { CatalogItemVisibilityField } from "@/app/(auth)/catalog/components/CatalogItemVisibilityField";
import { type CatalogItemVisibility } from "@/app/(auth)/catalog/game-systems/hooks/use-game-systems";
import { gameSystemFormMessages as m } from "@/app/(auth)/catalog/game-systems/messages";
import { type UserRole } from "@/app/contexts/user-context";
import { useFormChanges } from "@/lib/hooks/use-form-changes";
import { isValidUrl } from "@/lib/utils/url-validation";

export type GameSystemFormValues = {
  name: string;
  publisher: string | null;
  releaseYear: number | null;
  website: string | null;
  visibility: CatalogItemVisibility;
};

// Default values constant to avoid recreating on every render
const DEFAULT_GAME_SYSTEM_VALUES: GameSystemFormValues = {
  name: "",
  publisher: null,
  releaseYear: null,
  website: null,
  visibility: "private",
};

type GameSystemFormDialogProps = {
  open: boolean;
  mode: "create" | "edit";
  initialValues?: Partial<GameSystemFormValues>;
  userRoles: UserRole[];
  onClose: () => void;
  onSave: (
    values: GameSystemFormValues | Partial<GameSystemFormValues>,
  ) => void;
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
  const initialFormValues = useMemo(
    () =>
      mode === "edit" && initialValues
        ? {
            name: initialValues.name ?? "",
            publisher: initialValues.publisher ?? null,
            releaseYear: initialValues.releaseYear ?? null,
            website: initialValues.website ?? null,
            visibility: initialValues.visibility ?? "private",
          }
        : DEFAULT_GAME_SYSTEM_VALUES,
    [mode, initialValues],
  );

  const { values, setValue, hasChanges, getCreatePayload, getUpdatePayload } =
    useFormChanges<GameSystemFormValues>({
      initialValues: initialFormValues,
    });

  const [nameError, setNameError] = useState<string | null>(null);
  const [websiteError, setWebsiteError] = useState<string | null>(null);
  const [releaseYearError, setReleaseYearError] = useState<string | null>(null);

  const dialogTitle = mode === "create" ? m.createTitle : m.editTitle;

  const handleSubmit = (event: FormEvent) => {
    event.preventDefault();

    const trimmedName = values.name.trim();
    const trimmedWebsite = values.website?.toString().trim() ?? "";

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

    if (values.releaseYear !== null) {
      const yearNumber = Number(values.releaseYear);
      if (!Number.isInteger(yearNumber) || yearNumber <= 0) {
        setReleaseYearError(m.releaseYearError);
        hasError = true;
      } else {
        setReleaseYearError(null);
      }
    } else {
      setReleaseYearError(null);
    }

    if (hasError) return;

    setValue("name", trimmedName);
    const payload = mode === "create" ? getCreatePayload() : getUpdatePayload();
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
            value={values.name}
            onChange={(event) => setValue("name", event.target.value)}
            fullWidth
            disabled={isFormDisabled}
            error={Boolean(nameError)}
            helperText={nameError}
            InputLabelProps={{ shrink: true, required: true }}
          />

          <TextField
            label={m.publisherLabel}
            placeholder={m.publisherPlaceholder}
            value={values.publisher ?? ""}
            onChange={(event) =>
              setValue("publisher", event.target.value || null)
            }
            fullWidth
            disabled={isFormDisabled}
            InputLabelProps={{ shrink: true, required: false }}
          />

          <TextField
            label={m.releaseYearLabel}
            placeholder={m.releaseYearPlaceholder}
            value={values.releaseYear ?? ""}
            onChange={(event) => {
              const value = event.target.value;
              setValue("releaseYear", value ? Number(value) : null);
            }}
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
            value={values.website ?? ""}
            onChange={(event) =>
              setValue("website", event.target.value || null)
            }
            fullWidth
            disabled={isFormDisabled}
            error={Boolean(websiteError)}
            helperText={websiteError}
            InputLabelProps={{ shrink: true, required: false }}
          />

          <CatalogItemVisibilityField
            mode={mode}
            value={values.visibility}
            userRoles={userRoles}
            disabled={isFormDisabled}
            onChange={(value) => setValue("visibility", value)}
          />
        </Stack>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>{m.cancel}</Button>
        <Button
          onClick={handleSubmit}
          disabled={isFormDisabled || (mode === "edit" && !hasChanges)}
        >
          {m.save}
        </Button>
      </DialogActions>
    </Dialog>
  );
}
