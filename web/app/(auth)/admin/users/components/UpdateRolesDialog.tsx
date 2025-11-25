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

import { usersManagementMessages as m } from "@/app/(auth)/admin/users/messages";
import { type UserRole } from "@/app/context/user-context";

type UpdateRolesDialogProps = {
  open: boolean;
  userId: string;
  currentRoles: UserRole[];
  onClose: () => void;
  onSave: (roles: UserRole[]) => void;
  isPending?: boolean;
};

const ALL_ROLES: UserRole[] = ["admin", "hobbyist", "cataloguer"];

export function UpdateRolesDialog({
  open,
  userId,
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
      <DialogTitle>{m.updateRolesDialogTitle}</DialogTitle>
      <DialogContent>
        <FormGroup>
          {ALL_ROLES.map((role) => (
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
        <Button onClick={onClose}>{m.updateRolesDialogCancel}</Button>
        <Button onClick={handleSave} disabled={isPending}>
          {m.updateRolesDialogSave}
        </Button>
      </DialogActions>
    </Dialog>
  );
}
