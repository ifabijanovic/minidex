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
import { FormEvent, useCallback, useMemo } from "react";

import { CatalogItemVisibilityField } from "@/app/(auth)/catalog/components/CatalogItemVisibilityField";
import { type Faction } from "@/app/(auth)/catalog/factions/hooks/use-factions";
import { factionFormMessages as m } from "@/app/(auth)/catalog/factions/messages";
import { type CatalogItemVisibility } from "@/app/(auth)/catalog/game-systems/hooks/use-game-systems";
import { LookupDropdown } from "@/app/(auth)/components/LookupDropdown";
import { type UserRole } from "@/app/contexts/user-context";
import { api } from "@/lib/api-client";
import { useFormChanges, useLookupField } from "@/lib/hooks/use-form-changes";

export type FactionFormValues = {
  name: string;
  gameSystemID: string | null;
  parentFactionID: string | null;
  visibility: CatalogItemVisibility;
};

const DEFAULT_FACTION_VALUES: FactionFormValues = {
  name: "",
  gameSystemID: null,
  parentFactionID: null,
  visibility: "private",
};

type FactionFormDialogProps = {
  open: boolean;
  mode: "create" | "edit";
  initialValues?: Partial<
    FactionFormValues & {
      gameSystemName?: string | null;
      parentFactionName?: string | null;
    }
  >;
  currentFactionId?: string | null;
  userRoles: UserRole[];
  onClose: () => void;
  onSave: (values: FactionFormValues | Partial<FactionFormValues>) => void;
  isPending?: boolean;
};

export function FactionFormDialog({
  open,
  mode,
  initialValues,
  currentFactionId,
  userRoles,
  onClose,
  onSave,
  isPending = false,
}: FactionFormDialogProps) {
  const initialFormValues = useMemo(
    () =>
      mode === "edit" && initialValues
        ? {
            name: initialValues.name ?? "",
            gameSystemID: initialValues.gameSystemID ?? null,
            parentFactionID: initialValues.parentFactionID ?? null,
            visibility: initialValues.visibility ?? "private",
          }
        : DEFAULT_FACTION_VALUES,
    [mode, initialValues],
  );

  const {
    values,
    setValue,
    hasChanges,
    getCreatePayload,
    getUpdatePayload,
    errors,
    setError,
  } = useFormChanges<FactionFormValues>({
    initialValues: initialFormValues,
  });

  const gameSystemField = useLookupField({
    initialId: initialValues?.gameSystemID,
    initialName: initialValues?.gameSystemName,
    onIdChange: (id) => setValue("gameSystemID", id),
  });

  const parentFactionField = useLookupField({
    initialId: initialValues?.parentFactionID,
    initialName: initialValues?.parentFactionName,
    onIdChange: (id) => setValue("parentFactionID", id),
  });
  const dialogTitle = mode === "create" ? m.createTitle : m.editTitle;

  const excludeIds = useMemo(
    () => (currentFactionId ? [currentFactionId] : undefined),
    [currentFactionId],
  );

  const handleSubmit = (event: FormEvent) => {
    event.preventDefault();

    const trimmedName = values.name.trim();

    let hasError = false;

    if (!trimmedName) {
      setError("name", m.nameRequired);
      hasError = true;
    } else {
      setError("name", null);
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
            error={Boolean(errors.name)}
            helperText={errors.name}
            InputLabelProps={{ shrink: true, required: true }}
          />

          <LookupDropdown
            label={m.gameSystemLabel}
            placeholder={m.gameSystemPlaceholder}
            value={gameSystemField.value}
            onChange={gameSystemField.onChange}
            fetcher={useCallback(async (q: string) => {
              const res = await api.get<{
                data: { id: string; name: string }[];
              }>("/v1/game-systems", { params: { q, limit: 10 } });
              return res.data;
            }, [])}
            disabled={isFormDisabled}
            queryKeyPrefix="game-systems-lookup"
          />

          <LookupDropdown
            label={m.parentFactionLabel}
            placeholder={m.parentFactionPlaceholder}
            value={parentFactionField.value}
            onChange={parentFactionField.onChange}
            excludeIds={excludeIds}
            fetcher={useCallback(async (q: string) => {
              const res = await api.get<{ data: Faction[] }>("/v1/factions", {
                params: { q, limit: 10 },
              });
              return res.data.map((f) => ({ id: f.id, name: f.name }));
            }, [])}
            disabled={isFormDisabled}
            queryKeyPrefix="factions-lookup"
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
        <Button onClick={onClose} color="secondary" disabled={isFormDisabled}>
          {m.cancel}
        </Button>
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
