"use client";

import MoreVert from "@mui/icons-material/MoreVert";
import {
  Box,
  Card,
  CardContent,
  Container,
  IconButton,
  Menu,
  MenuItem,
  Paper,
  Skeleton,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TablePagination,
  TableRow,
  TableSortLabel,
  Typography,
} from "@mui/material";
import { useQueryClient } from "@tanstack/react-query";
import { enqueueSnackbar } from "notistack";
import { useState } from "react";

import { UpdateRolesDialog } from "@/app/(auth)/admin/users/components/UpdateRolesDialog";
import { useUsers } from "@/app/(auth)/admin/users/hooks/use-users";
import { usersManagementMessages as m } from "@/app/(auth)/admin/users/messages";
import { UserAvatar } from "@/app/(auth)/components/UserAvatar";
import { UuidPreview } from "@/app/components/UuidPreview";
import { type UserRole } from "@/app/context/user-context";
import { useApiMutation } from "@/lib/hooks/use-api-mutation";

type SortField = "roles" | "isActive" | null;
type SortOrder = "asc" | "desc";

export default function UsersManagementPage() {
  const queryClient = useQueryClient();
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(25);
  const [sortField, setSortField] = useState<SortField>(null);
  const [sortOrder, setSortOrder] = useState<SortOrder>("asc");
  const [menuAnchor, setMenuAnchor] = useState<{
    element: HTMLElement;
    userId: string;
    isActive: boolean;
  } | null>(null);
  const [updateRolesDialog, setUpdateRolesDialog] = useState<{
    userId: string;
    currentRoles: UserRole[];
  } | null>(null);

  const { data, isLoading } = useUsers({
    page,
    limit: rowsPerPage,
    sort: sortField ?? undefined,
    order: sortField ? sortOrder : undefined,
  });

  const handleChangePage = (_event: unknown, newPage: number) => {
    setPage(newPage);
  };

  const handleChangeRowsPerPage = (
    event: React.ChangeEvent<HTMLInputElement>,
  ) => {
    setRowsPerPage(parseInt(event.target.value, 10));
    setPage(0);
  };

  const handleSort = (field: SortField) => {
    if (sortField === field) {
      setSortOrder(sortOrder === "asc" ? "desc" : "asc");
    } else {
      setSortField(field);
      setSortOrder("asc");
    }
  };

  const handleMenuOpen = (
    event: React.MouseEvent<HTMLElement>,
    userId: string,
    isActive: boolean,
  ) => {
    setMenuAnchor({ element: event.currentTarget, userId, isActive });
  };

  const handleMenuClose = () => {
    setMenuAnchor(null);
  };

  const patchMutation = useApiMutation<
    { id: string; roles: UserRole[]; isActive: boolean },
    { userId: string; isActive?: boolean; roles?: UserRole[] }
  >({
    method: "patch",
    path: (variables) => `/v1/admin/users/${variables.userId}`,
    onSuccess: async (_, variables) => {
      await queryClient.invalidateQueries({
        queryKey: ["users"],
      });
      if (variables.isActive !== undefined) {
        enqueueSnackbar(
          variables.isActive ? m.activateSuccess : m.deactivateSuccess,
          { variant: "success" },
        );
      }
      if (variables.roles !== undefined) {
        enqueueSnackbar(m.updateRolesSuccess, { variant: "success" });
        setUpdateRolesDialog(null);
      }
      handleMenuClose();
    },
  });

  const invalidateSessionsMutation = useApiMutation<void, { userId: string }>({
    method: "post",
    path: (variables) =>
      `/v1/admin/users/${variables.userId}/invalidateSessions`,
    onSuccess: async () => {
      enqueueSnackbar(m.invalidateSessionsSuccess, { variant: "success" });
      handleMenuClose();
    },
  });

  const handleUpdateRoles = () => {
    if (menuAnchor) {
      const user = users.find((u) => u.userID === menuAnchor.userId);
      if (user) {
        setUpdateRolesDialog({
          userId: menuAnchor.userId,
          currentRoles: user.roles,
        });
      }
      handleMenuClose();
    }
  };

  const handleUpdateRolesDialogClose = () => {
    setUpdateRolesDialog(null);
  };

  const handleUpdateRolesSave = (roles: UserRole[]) => {
    if (updateRolesDialog) {
      patchMutation.mutate({
        userId: updateRolesDialog.userId,
        roles,
      });
    }
  };

  const handleActivate = () => {
    if (menuAnchor) {
      patchMutation.mutate({
        userId: menuAnchor.userId,
        isActive: true,
      });
    }
  };

  const handleDeactivate = () => {
    if (menuAnchor) {
      patchMutation.mutate({
        userId: menuAnchor.userId,
        isActive: false,
      });
    }
  };

  const handleInvalidateSessions = () => {
    if (menuAnchor) {
      invalidateSessionsMutation.mutate({ userId: menuAnchor.userId });
    }
  };

  const users = data?.data ?? [];
  // If we got a full page, there might be more. Otherwise, this is the last page.
  const hasMore = users.length === rowsPerPage;
  const totalRows = hasMore
    ? (page + 1) * rowsPerPage + 1 // Indicate there are more pages
    : page * rowsPerPage + users.length;

  return (
    <Container maxWidth="lg">
      <Stack spacing={3}>
        <Typography variant="h5">{m.title}</Typography>

        <Card>
          <CardContent>
            <TableContainer component={Paper} variant="outlined">
              <Table>
                <TableHead>
                  <TableRow>
                    <TableCell>
                      <Typography variant="subtitle2" fontWeight={600}>
                        {m.id}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Typography variant="subtitle2" fontWeight={600}>
                        {m.avatar}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Typography variant="subtitle2" fontWeight={600}>
                        {m.displayName}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <TableSortLabel
                        active={sortField === "roles"}
                        direction={sortField === "roles" ? sortOrder : "asc"}
                        onClick={() => handleSort("roles")}
                      >
                        <Typography variant="subtitle2" fontWeight={600}>
                          {m.roles}
                        </Typography>
                      </TableSortLabel>
                    </TableCell>
                    <TableCell>
                      <TableSortLabel
                        active={sortField === "isActive"}
                        direction={sortField === "isActive" ? sortOrder : "asc"}
                        onClick={() => handleSort("isActive")}
                      >
                        <Typography variant="subtitle2" fontWeight={600}>
                          {m.isActive}
                        </Typography>
                      </TableSortLabel>
                    </TableCell>
                    <TableCell>
                      <Typography variant="subtitle2" fontWeight={600}>
                        {m.profileID}
                      </Typography>
                    </TableCell>
                    <TableCell align="right">
                      <Typography variant="subtitle2" fontWeight={600}>
                        {m.actions}
                      </Typography>
                    </TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {isLoading ? (
                    Array.from({ length: rowsPerPage }).map((_, index) => (
                      <TableRow key={index}>
                        <TableCell>
                          <Skeleton variant="text" width="100%" />
                        </TableCell>
                        <TableCell>
                          <Skeleton variant="circular" width={40} height={40} />
                        </TableCell>
                        <TableCell>
                          <Skeleton variant="text" width="100%" />
                        </TableCell>
                        <TableCell>
                          <Skeleton variant="text" width="100%" />
                        </TableCell>
                        <TableCell>
                          <Skeleton variant="text" width="100%" />
                        </TableCell>
                        <TableCell>
                          <Skeleton variant="text" width="100%" />
                        </TableCell>
                        <TableCell>
                          <Skeleton variant="circular" width={32} height={32} />
                        </TableCell>
                      </TableRow>
                    ))
                  ) : users.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={7} align="center">
                        <Box sx={{ py: 4 }}>
                          <Typography variant="body2" color="text.secondary">
                            {m.noUsers}
                          </Typography>
                        </Box>
                      </TableCell>
                    </TableRow>
                  ) : (
                    users.map((user) => (
                      <TableRow key={user.userID} hover>
                        <TableCell>
                          <UuidPreview id={user.userID} />
                        </TableCell>
                        <TableCell>
                          <UserAvatar
                            displayName={user.displayName}
                            avatarURL={user.avatarURL}
                            isLoading={isLoading}
                          />
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2">
                            {user.displayName ?? "—"}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2">
                            {user.roles.length > 0
                              ? user.roles.join(", ")
                              : "—"}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2">
                            {user.isActive ? m.active : m.inactive}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <UuidPreview id={user.profileID} />
                        </TableCell>
                        <TableCell align="right">
                          <IconButton
                            size="small"
                            onClick={(e) =>
                              handleMenuOpen(e, user.userID, user.isActive)
                            }
                          >
                            <MoreVert fontSize="small" />
                          </IconButton>
                        </TableCell>
                      </TableRow>
                    ))
                  )}
                </TableBody>
              </Table>
            </TableContainer>

            <TablePagination
              component="div"
              count={totalRows}
              page={page}
              onPageChange={handleChangePage}
              rowsPerPage={rowsPerPage}
              onRowsPerPageChange={handleChangeRowsPerPage}
              rowsPerPageOptions={[10, 25, 50, 100]}
            />
          </CardContent>
        </Card>

        <Menu
          anchorEl={menuAnchor?.element ?? null}
          open={Boolean(menuAnchor)}
          onClose={handleMenuClose}
          anchorOrigin={{ vertical: "bottom", horizontal: "right" }}
          transformOrigin={{ vertical: "top", horizontal: "right" }}
        >
          <MenuItem onClick={handleUpdateRoles}>{m.updateRoles}</MenuItem>
          {menuAnchor?.isActive ? (
            <MenuItem onClick={handleDeactivate}>{m.deactivate}</MenuItem>
          ) : (
            <MenuItem onClick={handleActivate}>{m.activate}</MenuItem>
          )}
          <MenuItem onClick={handleInvalidateSessions}>
            {m.invalidateSessions}
          </MenuItem>
        </Menu>

        {updateRolesDialog && (
          <UpdateRolesDialog
            open={true}
            currentRoles={updateRolesDialog.currentRoles}
            onClose={handleUpdateRolesDialogClose}
            onSave={handleUpdateRolesSave}
            isPending={patchMutation.isPending}
          />
        )}
      </Stack>
    </Container>
  );
}
