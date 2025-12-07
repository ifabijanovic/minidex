"use client";

import MoreVert from "@mui/icons-material/MoreVert";
import { IconButton, Menu, MenuItem } from "@mui/material";
import { useState } from "react";

import { catalogMessages } from "@/app/(auth)/catalog/components/messages";
import { type CatalogItemVisibility } from "@/app/(auth)/catalog/game-systems/hooks/use-game-systems";
import { type UserRole } from "@/app/contexts/user-context";

type CatalogItemRowActionsProps = {
  itemId: string;
  createdById: string;
  visibility: CatalogItemVisibility;
  currentUserId?: string;
  currentUserRoles: UserRole[];
  onEdit: () => void;
  onDelete: () => void;
};

export function CatalogItemRowActions({
  itemId,
  createdById,
  visibility,
  currentUserId,
  currentUserRoles,
  onEdit,
  onDelete,
}: CatalogItemRowActionsProps) {
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);

  const isAdmin = currentUserRoles.includes("admin");
  const isCataloguer = currentUserRoles.includes("cataloguer");
  const isHobbyist = currentUserRoles.includes("hobbyist");
  const isCreator = currentUserId != null && currentUserId === createdById;

  const canEdit =
    isAdmin ||
    (isCataloguer && (isCreator || visibility === "public")) ||
    (isHobbyist && isCreator);

  const canDelete = canEdit;

  const open = Boolean(anchorEl);

  const handleMenuOpen = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(event.currentTarget);
  };

  const handleClose = () => {
    setAnchorEl(null);
  };

  const handleEdit = () => {
    onEdit();
    handleClose();
  };

  const handleDelete = () => {
    onDelete();
    handleClose();
  };

  if (!canEdit && !canDelete) {
    return null;
  }

  return (
    <>
      <IconButton size="small" onClick={handleMenuOpen}>
        <MoreVert fontSize="small" />
      </IconButton>
      <Menu
        anchorEl={anchorEl}
        open={open}
        onClose={handleClose}
        anchorOrigin={{ vertical: "bottom", horizontal: "right" }}
        transformOrigin={{ vertical: "top", horizontal: "right" }}
      >
        <MenuItem onClick={handleEdit} disabled={!canEdit}>
          {catalogMessages.actions.edit}
        </MenuItem>
        <MenuItem onClick={handleDelete} disabled={!canDelete}>
          {catalogMessages.actions.delete}
        </MenuItem>
      </Menu>
    </>
  );
}
