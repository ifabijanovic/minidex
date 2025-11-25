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
import { useState } from "react";

import { useUsers } from "@/app/(auth)/admin/users/hooks/use-users";
import { usersManagementMessages as m } from "@/app/(auth)/admin/users/messages";

type SortField = "roles" | "isActive" | null;
type SortOrder = "asc" | "desc";

export default function UsersManagementPage() {
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(25);
  const [sortField, setSortField] = useState<SortField>(null);
  const [sortOrder, setSortOrder] = useState<SortOrder>("asc");
  const [menuAnchor, setMenuAnchor] = useState<{
    element: HTMLElement;
    userId: string;
    isActive: boolean;
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

  const handleUpdateRoles = () => {
    if (menuAnchor) {
      // TODO: Implement update roles
      console.log("Update roles for user:", menuAnchor.userId);
      handleMenuClose();
    }
  };

  const handleActivate = () => {
    if (menuAnchor) {
      // TODO: Implement activate
      console.log("Activate user:", menuAnchor.userId);
      handleMenuClose();
    }
  };

  const handleDeactivate = () => {
    if (menuAnchor) {
      // TODO: Implement deactivate
      console.log("Deactivate user:", menuAnchor.userId);
      handleMenuClose();
    }
  };

  const handleRevokeAccess = () => {
    if (menuAnchor) {
      // TODO: Implement revoke access
      console.log("Revoke access for user:", menuAnchor.userId);
      handleMenuClose();
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
                      <TableCell colSpan={4} align="center">
                        <Box sx={{ py: 4 }}>
                          <Typography variant="body2" color="text.secondary">
                            {m.noUsers}
                          </Typography>
                        </Box>
                      </TableCell>
                    </TableRow>
                  ) : (
                    users.map((user) => (
                      <TableRow key={user.id} hover>
                        <TableCell>
                          <Typography variant="body2" fontFamily="monospace">
                            {user.id}
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
                        <TableCell align="right">
                          <IconButton
                            size="small"
                            onClick={(e) =>
                              handleMenuOpen(e, user.id, user.isActive)
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
          <MenuItem onClick={handleRevokeAccess}>{m.revokeAccess}</MenuItem>
        </Menu>
      </Stack>
    </Container>
  );
}
