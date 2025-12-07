"use client";

import {
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
} from "@mui/material";

import { deleteGameSystemMessages as m } from "@/app/(auth)/catalog/game-systems/messages";

type DeleteGameSystemDialogProps = {
  open: boolean;
  onClose: () => void;
  onConfirm: () => void;
  isPending?: boolean;
};

export function DeleteGameSystemDialog({
  open,
  onClose,
  onConfirm,
  isPending = false,
}: DeleteGameSystemDialogProps) {
  return (
    <Dialog open={open} onClose={onClose} maxWidth="xs" fullWidth>
      <DialogTitle>{m.title}</DialogTitle>
      <DialogContent>
        <DialogContentText>{m.description}</DialogContentText>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose} color="secondary" disabled={isPending}>
          {m.cancel}
        </Button>
        <Button onClick={onConfirm} color="error" disabled={isPending}>
          {m.confirm}
        </Button>
      </DialogActions>
    </Dialog>
  );
}
