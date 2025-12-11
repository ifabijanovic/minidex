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
import { type Faction } from "@/app/(auth)/catalog/factions/hooks/use-factions";
import { factionFormMessages as m } from "@/app/(auth)/catalog/factions/messages";
import { type CatalogItemVisibility } from "@/app/(auth)/catalog/game-systems/hooks/use-game-systems";
import {
  LookupDropdown,
  type LookupOption,
} from "@/app/(auth)/components/LookupDropdown";
import { type UserRole } from "@/app/contexts/user-context";
import { api } from "@/lib/api-client";

type FactionFormValues = {
  name: string;
  gameSystemID: string | null;
  parentFactionID: string | null;
  visibility: CatalogItemVisibility;
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
  onSave: (values: FactionFormValues) => void;
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
  const [name, setName] = useState(initialValues?.name ?? "");
  const [gameSystem, setGameSystem] = useState<LookupOption | null>(() => {
    if (initialValues?.gameSystemID) {
      return {
        id: initialValues.gameSystemID,
        name: initialValues.gameSystemName ?? initialValues.gameSystemID,
      };
    }
    return null;
  });
  const [parentFaction, setParentFaction] = useState<LookupOption | null>(
    () => {
      if (initialValues?.parentFactionID) {
        return {
          id: initialValues.parentFactionID,
          name:
            initialValues.parentFactionName ?? initialValues.parentFactionID,
        };
      }
      return null;
    },
  );
  const [visibility, setVisibility] = useState<CatalogItemVisibility>(
    initialValues?.visibility ?? "private",
  );

  const [nameError, setNameError] = useState<string | null>(null);
  const dialogTitle = mode === "create" ? m.createTitle : m.editTitle;

  const handleSubmit = (event: FormEvent) => {
    event.preventDefault();

    const trimmedName = name.trim();
    const trimmedGameSystemID = gameSystem?.id.trim() ?? "";
    const trimmedParentFactionID = parentFaction?.id.trim() ?? "";

    let hasError = false;

    if (!trimmedName) {
      setNameError(m.nameRequired);
      hasError = true;
    } else {
      setNameError(null);
    }

    if (hasError) return;

    onSave({
      name: trimmedName,
      gameSystemID: trimmedGameSystemID || null,
      parentFactionID: trimmedParentFactionID || null,
      visibility,
    });
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

          <LookupDropdown
            label={m.gameSystemLabel}
            placeholder={m.gameSystemPlaceholder}
            value={gameSystem}
            onChange={(option) => setGameSystem(option)}
            fetcher={async (q) => {
              const res = await api.get<{
                data: { id: string; name: string }[];
              }>("/v1/game-systems", { params: { q, limit: 10 } });
              return res.data;
            }}
            disabled={isFormDisabled}
          />

          <LookupDropdown
            label={m.parentFactionLabel}
            placeholder={m.parentFactionPlaceholder}
            value={parentFaction}
            onChange={(option) => setParentFaction(option)}
            excludeIds={currentFactionId ? [currentFactionId] : undefined}
            fetcher={async (q) => {
              const res = await api.get<{ data: Faction[] }>("/v1/factions", {
                params: { q, limit: 10 },
              });
              return res.data.map((f) => ({ id: f.id, name: f.name }));
            }}
            disabled={isFormDisabled}
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
        <Button onClick={onClose} color="secondary" disabled={isFormDisabled}>
          {m.cancel}
        </Button>
        <Button onClick={handleSubmit} disabled={isFormDisabled}>
          {m.save}
        </Button>
      </DialogActions>
    </Dialog>
  );
}
