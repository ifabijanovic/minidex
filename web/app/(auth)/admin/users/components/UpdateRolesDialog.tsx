"use client";

import {
  Button,
  Checkbox,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  FormControlLabel,
  FormGroup,
} from "@mui/material";
import { useState } from "react";

import { updateRolesDialogMessages as m } from "@/app/(auth)/admin/users/messages";
import { ALL_USER_ROLES, type UserRole } from "@/app/contexts/user-context";

type UpdateRolesDialogProps = {
  open: boolean;
  currentRoles: UserRole[];
  onClose: () => void;
  onSave: (roles: UserRole[]) => void;
  isPending?: boolean;
};

export function UpdateRolesDialog({
  open,
  currentRoles,
  onClose,
  onSave,
  isPending = false,
}: UpdateRolesDialogProps) {
  const [selectedRoles, setSelectedRoles] = useState<Set<UserRole>>(
    new Set(currentRoles),
  );

  const handleRoleToggle = (role: UserRole) => {
    setSelectedRoles((prev) => {
      const next = new Set(prev);
      if (next.has(role)) {
        next.delete(role);
      } else {
        next.add(role);
      }
      return next;
    });
  };

  const handleSave = () => {
    onSave(Array.from(selectedRoles));
  };

  return (
    <Dialog open={open} onClose={onClose} maxWidth="xs" fullWidth>
      <DialogTitle>{m.title}</DialogTitle>
      <DialogContent>
        <FormGroup>
          {ALL_USER_ROLES.map((role) => (
            <FormControlLabel
              key={role}
              control={
                <Checkbox
                  checked={selectedRoles.has(role)}
                  onChange={() => handleRoleToggle(role)}
                />
              }
              label={role.charAt(0).toUpperCase() + role.slice(1)}
            />
          ))}
        </FormGroup>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>{m.cancel}</Button>
        <Button onClick={handleSave} disabled={isPending}>
          {m.save}
        </Button>
      </DialogActions>
    </Dialog>
  );
}
