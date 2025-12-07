"use client";

import { Alert, MenuItem, Stack, TextField, Typography } from "@mui/material";
import { useEffect, useMemo, useRef } from "react";

import { catalogVisibilityMessages as m } from "@/app/(auth)/catalog/components/messages";
import { type CatalogItemVisibility } from "@/app/(auth)/catalog/game-systems/hooks/use-game-systems";
import { type UserRole } from "@/app/contexts/user-context";

const ALL_VISIBILITIES: CatalogItemVisibility[] = [
  "private",
  "limited",
  "public",
];

const VISIBILITY_LABELS: Record<CatalogItemVisibility, string> = {
  private: m.visibilityOptions.private,
  limited: m.visibilityOptions.limited,
  public: m.visibilityOptions.public,
};

type CatalogItemVisibilityFieldProps = {
  mode: "create" | "edit";
  value: CatalogItemVisibility;
  userRoles: UserRole[];
  disabled?: boolean;
  onChange: (value: CatalogItemVisibility) => void;
};

export function CatalogItemVisibilityField({
  mode,
  value,
  userRoles,
  disabled = false,
  onChange,
}: CatalogItemVisibilityFieldProps) {
  const isAdmin = userRoles.includes("admin");
  const isCataloguer = userRoles.includes("cataloguer");
  const isHobbyist = userRoles.includes("hobbyist");

  const isVisibilityReadOnly =
    mode === "edit" && !isAdmin && isCataloguer && value === "public";

  const visibilityOptions: CatalogItemVisibility[] = useMemo(() => {
    if (isAdmin) return ALL_VISIBILITIES;

    if (mode === "create") {
      const set = new Set<CatalogItemVisibility>();
      if (isCataloguer) {
        set.add("private");
        set.add("public");
      }
      if (isHobbyist) {
        set.add("private");
        set.add("limited");
      }
      if (set.size === 0) {
        set.add("private");
      }
      return Array.from(set);
    }

    if (mode === "edit") {
      if (isAdmin) return ALL_VISIBILITIES;

      if (isCataloguer) {
        if (value === "public") {
          return ["public"];
        }
        return ["private", "limited"];
      }

      if (isHobbyist) {
        return ["private", "limited"];
      }

      return ["private"];
    }

    return ["private"];
  }, [isAdmin, isCataloguer, isHobbyist, mode, value]);

  const didSetInitialDefault = useRef(false);

  useEffect(() => {
    if (mode !== "create" || didSetInitialDefault.current) return;
    if ((isAdmin || isCataloguer) && visibilityOptions.includes("public")) {
      onChange("public");
    } else if (isHobbyist && visibilityOptions.includes("limited")) {
      onChange("limited");
    }
    didSetInitialDefault.current = true;
  }, [mode, isAdmin, isCataloguer, isHobbyist, visibilityOptions, onChange]);

  if (isVisibilityReadOnly) {
    return (
      <Stack spacing={1.5}>
        <TextField
          label={m.visibilityLabel}
          value={VISIBILITY_LABELS[value]}
          fullWidth
          disabled
          InputLabelProps={{ shrink: true, required: true }}
        />
        <Alert severity="info" variant="outlined">
          <Typography variant="subtitle2" fontWeight={700} gutterBottom>
            {m.visibilityHelp.title}
          </Typography>
          <Typography variant="body2" color="text.secondary">
            {m.visibilityHelp[value]}
          </Typography>
        </Alert>
      </Stack>
    );
  }

  return (
    <Stack spacing={1.5}>
      <TextField
        select
        label={m.visibilityLabel}
        value={value}
        onChange={(event) =>
          onChange(event.target.value as CatalogItemVisibility)
        }
        fullWidth
        disabled={disabled}
        InputLabelProps={{ shrink: true, required: true }}
      >
        {visibilityOptions.map((option) => (
          <MenuItem key={option} value={option}>
            {VISIBILITY_LABELS[option]}
          </MenuItem>
        ))}
      </TextField>
      <Alert severity="info" variant="outlined">
        <Typography variant="subtitle2" fontWeight={700} gutterBottom>
          {m.visibilityHelp.title}
        </Typography>
        <Typography variant="body2" color="text.secondary">
          {m.visibilityHelp[value]}
        </Typography>
      </Alert>
    </Stack>
  );
}
