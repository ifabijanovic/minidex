"use client";

import Add from "@mui/icons-material/Add";
import MoreVert from "@mui/icons-material/MoreVert";
import {
  Box,
  Button,
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
import { useDebounce } from "@uidotdev/usehooks";
import { enqueueSnackbar } from "notistack";
import { useMemo, useState } from "react";

import { DeleteGameSystemDialog } from "@/app/(auth)/catalog/game-systems/components/DeleteGameSystemDialog";
import { GameSystemFormDialog } from "@/app/(auth)/catalog/game-systems/components/GameSystemFormDialog";
import {
  type CatalogItemVisibility,
  type GameSystem,
  useGameSystems,
} from "@/app/(auth)/catalog/game-systems/hooks/use-game-systems";
import { gameSystemsMessages as m } from "@/app/(auth)/catalog/game-systems/messages";
import { SearchField } from "@/app/components/SearchField";
import { UuidPreview } from "@/app/components/UuidPreview";
import { useCurrentUser } from "@/app/contexts/user-context";
import {
  useApiDeleteMutation,
  useApiMutation,
} from "@/lib/hooks/use-api-mutation";

type SortField = "name" | "publisher" | "releaseYear" | "visibility" | null;
type SortOrder = "asc" | "desc";

const VISIBILITY_LABELS: Record<CatalogItemVisibility, string> = {
  private: "Private",
  limited: "Limited",
  public: "Public",
};

export default function GameSystemsPage() {
  const queryClient = useQueryClient();
  const { user } = useCurrentUser();

  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(25);
  const [sortField, setSortField] = useState<SortField>(null);
  const [sortOrder, setSortOrder] = useState<SortOrder>("asc");
  const [searchQuery, setSearchQuery] = useState("");
  const debouncedSearchQuery = useDebounce(searchQuery, 300);

  const [menuAnchor, setMenuAnchor] = useState<{
    element: HTMLElement;
    gameSystemId: string;
  } | null>(null);

  const [formDialog, setFormDialog] = useState<{
    mode: "create" | "edit";
    gameSystem?: GameSystem;
  } | null>(null);

  const [deleteDialog, setDeleteDialog] = useState<{
    gameSystemId: string;
  } | null>(null);

  const { data, isLoading } = useGameSystems({
    page,
    limit: rowsPerPage,
    sort: sortField ?? undefined,
    order: sortField ? sortOrder : undefined,
    query: debouncedSearchQuery.length >= 3 ? debouncedSearchQuery : undefined,
  });

  const saveMutation = useApiMutation<
    GameSystem,
    {
      id?: string;
      name: string;
      publisher: string | null;
      releaseYear: number | null;
      website: string | null;
      visibility: CatalogItemVisibility;
    }
  >({
    method: (variables) => (variables.id ? "patch" : "post"),
    path: (variables) =>
      variables.id ? `/v1/game-systems/${variables.id}` : "/v1/game-systems",
    onSuccess: async (_, variables) => {
      await queryClient.invalidateQueries({ queryKey: ["game-systems"] });
      enqueueSnackbar(variables.id ? m.updateSuccess : m.createSuccess, {
        variant: "success",
      });
      setFormDialog(null);
      setMenuAnchor(null);
    },
  });

  const deleteMutation = useApiDeleteMutation<void>({
    path: deleteDialog ? `/v1/game-systems/${deleteDialog.gameSystemId}` : "",
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ["game-systems"] });
      enqueueSnackbar(m.deleteSuccess, { variant: "success" });
      setDeleteDialog(null);
      setMenuAnchor(null);
    },
  });

  const gameSystems = data?.data ?? [];
  const hasMore = gameSystems.length === rowsPerPage;
  const totalRows = hasMore
    ? (page + 1) * rowsPerPage + 1
    : page * rowsPerPage + gameSystems.length;

  const canSeeCreatedBy = useMemo(
    () =>
      user?.roles.some((role) => role === "admin" || role === "cataloguer") ??
      false,
    [user?.roles],
  );

  const handleChangePage = (_event: unknown, newPage: number) => {
    setPage(newPage);
  };

  const handleChangeRowsPerPage = (
    event: React.ChangeEvent<HTMLInputElement>,
  ) => {
    setRowsPerPage(parseInt(event.target.value, 10));
    setPage(0);
  };

  const handleSearchChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setSearchQuery(event.target.value);
    setPage(0);
  };

  const handleClearSearch = () => {
    setSearchQuery("");
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
    gameSystemId: string,
  ) => {
    setMenuAnchor({ element: event.currentTarget, gameSystemId });
  };

  const handleMenuClose = () => {
    setMenuAnchor(null);
  };

  const handleAdd = () => {
    setFormDialog({ mode: "create" });
  };

  const getSelectedGameSystem = () => {
    if (!menuAnchor) return null;
    return gameSystems.find((item) => item.id === menuAnchor.gameSystemId);
  };

  const handleEdit = () => {
    const selected = getSelectedGameSystem();
    if (selected) {
      setFormDialog({ mode: "edit", gameSystem: selected });
    }
    handleMenuClose();
  };

  const handleDelete = () => {
    if (menuAnchor) {
      setDeleteDialog({ gameSystemId: menuAnchor.gameSystemId });
    }
    handleMenuClose();
  };

  const handleFormClose = () => {
    setFormDialog(null);
  };

  const handleFormSave = (values: {
    name: string;
    publisher: string | null;
    releaseYear: number | null;
    website: string | null;
    visibility: CatalogItemVisibility;
  }) => {
    saveMutation.mutate({
      ...(formDialog?.mode === "edit" && formDialog.gameSystem
        ? { id: formDialog.gameSystem.id }
        : {}),
      ...values,
    });
  };

  const handleDeleteConfirm = () => {
    if (!deleteDialog) return;
    deleteMutation.mutate();
  };

  const isFormPending = saveMutation.isPending;

  return (
    <Container maxWidth="lg">
      <Stack spacing={3}>
        <Stack
          direction="row"
          alignItems="center"
          justifyContent="space-between"
          spacing={2}
        >
          <Typography variant="h5">{m.title}</Typography>
          <Button
            variant="contained"
            startIcon={<Add />}
            onClick={handleAdd}
            disabled={isFormPending}
          >
            {m.add}
          </Button>
        </Stack>

        <Card>
          <CardContent>
            <Stack spacing={2} sx={{ mb: 2 }}>
              <SearchField
                placeholder={m.searchPlaceholder}
                value={searchQuery}
                onChange={handleSearchChange}
                onClear={handleClearSearch}
                size="small"
              />
            </Stack>
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
                        active={sortField === "name"}
                        direction={sortField === "name" ? sortOrder : "asc"}
                        onClick={() => handleSort("name")}
                      >
                        <Typography variant="subtitle2" fontWeight={600}>
                          {m.name}
                        </Typography>
                      </TableSortLabel>
                    </TableCell>
                    <TableCell>
                      <TableSortLabel
                        active={sortField === "publisher"}
                        direction={
                          sortField === "publisher" ? sortOrder : "asc"
                        }
                        onClick={() => handleSort("publisher")}
                      >
                        <Typography variant="subtitle2" fontWeight={600}>
                          {m.publisher}
                        </Typography>
                      </TableSortLabel>
                    </TableCell>
                    <TableCell>
                      <TableSortLabel
                        active={sortField === "releaseYear"}
                        direction={
                          sortField === "releaseYear" ? sortOrder : "asc"
                        }
                        onClick={() => handleSort("releaseYear")}
                      >
                        <Typography variant="subtitle2" fontWeight={600}>
                          {m.releaseYear}
                        </Typography>
                      </TableSortLabel>
                    </TableCell>
                    <TableCell>
                      <Typography variant="subtitle2" fontWeight={600}>
                        {m.website}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <TableSortLabel
                        active={sortField === "visibility"}
                        direction={
                          sortField === "visibility" ? sortOrder : "asc"
                        }
                        onClick={() => handleSort("visibility")}
                      >
                        <Typography variant="subtitle2" fontWeight={600}>
                          {m.visibility}
                        </Typography>
                      </TableSortLabel>
                    </TableCell>
                    {canSeeCreatedBy && (
                      <TableCell>
                        <Typography variant="subtitle2" fontWeight={600}>
                          {m.createdBy}
                        </Typography>
                      </TableCell>
                    )}
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
                          <Skeleton variant="text" width="100%" />
                        </TableCell>
                        <TableCell>
                          <Skeleton variant="text" width="100%" />
                        </TableCell>
                        <TableCell>
                          <Skeleton variant="text" width="100%" />
                        </TableCell>
                        {canSeeCreatedBy && (
                          <TableCell>
                            <Skeleton variant="text" width="100%" />
                          </TableCell>
                        )}
                        <TableCell align="right">
                          <Skeleton variant="circular" width={32} height={32} />
                        </TableCell>
                      </TableRow>
                    ))
                  ) : gameSystems.length === 0 ? (
                    <TableRow>
                      <TableCell
                        colSpan={canSeeCreatedBy ? 8 : 7}
                        align="center"
                      >
                        <Box sx={{ py: 4 }}>
                          <Typography variant="body2" color="text.secondary">
                            {m.noResults}
                          </Typography>
                        </Box>
                      </TableCell>
                    </TableRow>
                  ) : (
                    gameSystems.map((gameSystem) => (
                      <TableRow key={gameSystem.id} hover>
                        <TableCell>
                          <UuidPreview id={gameSystem.id} />
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2">
                            {gameSystem.name}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2">
                            {gameSystem.publisher || "—"}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2">
                            {gameSystem.releaseYear ?? "—"}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          {gameSystem.website ? (
                            <Typography
                              variant="body2"
                              component="a"
                              href={gameSystem.website}
                              target="_blank"
                              rel="noopener noreferrer"
                              sx={{ textDecoration: "none" }}
                            >
                              {gameSystem.website}
                            </Typography>
                          ) : (
                            <Typography variant="body2">—</Typography>
                          )}
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2">
                            {VISIBILITY_LABELS[gameSystem.visibility]}
                          </Typography>
                        </TableCell>
                        {canSeeCreatedBy && (
                          <TableCell>
                            <UuidPreview id={gameSystem.createdByID} />
                          </TableCell>
                        )}
                        <TableCell align="right">
                          <IconButton
                            size="small"
                            onClick={(event) =>
                              handleMenuOpen(event, gameSystem.id)
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
          <MenuItem onClick={handleEdit}>{m.edit}</MenuItem>
          <MenuItem onClick={handleDelete}>{m.delete}</MenuItem>
        </Menu>

        {formDialog && (
          <GameSystemFormDialog
            open={true}
            mode={formDialog.mode}
            initialValues={
              formDialog.gameSystem
                ? {
                    name: formDialog.gameSystem.name,
                    publisher: formDialog.gameSystem.publisher ?? null,
                    releaseYear: formDialog.gameSystem.releaseYear ?? null,
                    website: formDialog.gameSystem.website ?? null,
                    visibility: formDialog.gameSystem.visibility,
                  }
                : undefined
            }
            onClose={handleFormClose}
            onSave={handleFormSave}
            isPending={isFormPending}
          />
        )}

        {deleteDialog && (
          <DeleteGameSystemDialog
            open={true}
            onClose={() => setDeleteDialog(null)}
            onConfirm={handleDeleteConfirm}
            isPending={deleteMutation.isPending}
          />
        )}
      </Stack>
    </Container>
  );
}
