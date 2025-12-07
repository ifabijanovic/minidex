"use client";

import {
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
} from "@mui/material";

import { deleteConfirmationDialogMessages as m } from "@/app/(auth)/components/messages";

type DeleteConfirmationDialogProps = {
  open: boolean;
  title: string;
  description: string;
  onClose: () => void;
  onConfirm: () => void;
  isPending?: boolean;
};

export function DeleteConfirmationDialog({
  open,
  title,
  description,
  onClose,
  onConfirm,
  isPending = false,
}: DeleteConfirmationDialogProps) {
  return (
    <Dialog open={open} onClose={onClose} maxWidth="xs" fullWidth>
      <DialogTitle>{title}</DialogTitle>
      <DialogContent>
        <DialogContentText>{description}</DialogContentText>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose} disabled={isPending}>
          {m.cancel}
        </Button>
        <Button onClick={onConfirm} color="error" disabled={isPending}>
          {m.confirm}
        </Button>
      </DialogActions>
    </Dialog>
  );
}
