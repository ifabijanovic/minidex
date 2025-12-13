"use client";

import Add from "@mui/icons-material/Add";
import {
  Box,
  Button,
  Card,
  CardContent,
  Container,
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

import { CatalogItemRowActions } from "@/app/(auth)/catalog/components/CatalogItemRowActions";
import {
  FactionFormDialog,
  type FactionFormValues,
} from "@/app/(auth)/catalog/factions/components/FactionFormDialog";
import {
  type CatalogItemVisibility,
  type Faction,
  useFactions,
} from "@/app/(auth)/catalog/factions/hooks/use-factions";
import { factionsMessages as m } from "@/app/(auth)/catalog/factions/messages";
import { DeleteConfirmationDialog } from "@/app/(auth)/components/DeleteConfirmationDialog";
import { SearchField } from "@/app/components/SearchField";
import { UuidPreview } from "@/app/components/UuidPreview";
import { useCurrentUser } from "@/app/contexts/user-context";
import {
  useApiDeleteMutation,
  useApiMutation,
} from "@/lib/hooks/use-api-mutation";

type SortField =
  | "name"
  | "visibility"
  | "gameSystemName"
  | "parentFactionName"
  | null;
type SortOrder = "asc" | "desc";

const VISIBILITY_LABELS: Record<CatalogItemVisibility, string> = {
  private: "Private",
  limited: "Limited",
  public: "Public",
};

export default function FactionsPage() {
  const queryClient = useQueryClient();
  const { user } = useCurrentUser();

  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(25);
  const [sortField, setSortField] = useState<SortField>(null);
  const [sortOrder, setSortOrder] = useState<SortOrder>("asc");
  const [searchQuery, setSearchQuery] = useState("");
  const debouncedSearchQuery = useDebounce(searchQuery, 300);

  const [formDialog, setFormDialog] = useState<{
    mode: "create" | "edit";
    faction?: Faction;
  } | null>(null);

  const [deleteDialog, setDeleteDialog] = useState<{
    factionId: string;
  } | null>(null);

  const { data, isLoading } = useFactions({
    page,
    limit: rowsPerPage,
    sort: sortField ?? undefined,
    order: sortField ? sortOrder : undefined,
    query: debouncedSearchQuery.length >= 3 ? debouncedSearchQuery : undefined,
    enabled: Boolean(user?.userId),
  });

  const saveMutation = useApiMutation<
    Faction,
    {
      id?: string;
    } & (FactionFormValues | Partial<FactionFormValues>)
  >({
    method: (variables) => (variables.id ? "patch" : "post"),
    path: (variables) =>
      variables.id ? `/v1/factions/${variables.id}` : "/v1/factions",
    onSuccess: async (_, variables) => {
      await queryClient.invalidateQueries({ queryKey: ["factions"] });
      enqueueSnackbar(variables.id ? m.updateSuccess : m.createSuccess, {
        variant: "success",
      });
      setFormDialog(null);
    },
  });

  const deleteMutation = useApiDeleteMutation<void>({
    path: deleteDialog ? `/v1/factions/${deleteDialog.factionId}` : "",
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ["factions"] });
      enqueueSnackbar(m.deleteSuccess, { variant: "success" });
      setDeleteDialog(null);
    },
  });

  const factions = data?.data ?? [];
  const hasMore = factions.length === rowsPerPage;
  const totalRows = hasMore
    ? (page + 1) * rowsPerPage + 1
    : page * rowsPerPage + factions.length;

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

  const handleAdd = () => {
    setFormDialog({ mode: "create" });
  };

  const handleFormClose = () => {
    setFormDialog(null);
  };

  const handleFormSave = (
    values: FactionFormValues | Partial<FactionFormValues>,
  ) => {
    saveMutation.mutate({
      ...(formDialog?.mode === "edit" && formDialog.faction
        ? { id: formDialog.faction.id }
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
                        active={sortField === "gameSystemName"}
                        direction={
                          sortField === "gameSystemName" ? sortOrder : "asc"
                        }
                        onClick={() => handleSort("gameSystemName")}
                      >
                        <Typography variant="subtitle2" fontWeight={600}>
                          {m.gameSystem}
                        </Typography>
                      </TableSortLabel>
                    </TableCell>
                    <TableCell>
                      <TableSortLabel
                        active={sortField === "parentFactionName"}
                        direction={
                          sortField === "parentFactionName" ? sortOrder : "asc"
                        }
                        onClick={() => handleSort("parentFactionName")}
                      >
                        <Typography variant="subtitle2" fontWeight={600}>
                          {m.parentFaction}
                        </Typography>
                      </TableSortLabel>
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
                    <TableCell align="right" />
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
                  ) : factions.length === 0 ? (
                    <TableRow>
                      <TableCell
                        colSpan={canSeeCreatedBy ? 7 : 6}
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
                    factions.map((faction) => (
                      <TableRow key={faction.id} hover>
                        <TableCell>
                          <UuidPreview id={faction.id} />
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2">
                            {faction.name}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2">
                            {faction.gameSystemName ||
                              faction.gameSystemID ||
                              "—"}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2">
                            {faction.parentFactionName ||
                              faction.parentFactionID ||
                              "—"}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2">
                            {VISIBILITY_LABELS[faction.visibility]}
                          </Typography>
                        </TableCell>
                        {canSeeCreatedBy && (
                          <TableCell>
                            <UuidPreview id={faction.createdByID} />
                          </TableCell>
                        )}
                        <TableCell align="right">
                          <CatalogItemRowActions
                            itemId={faction.id}
                            createdById={faction.createdByID}
                            visibility={faction.visibility}
                            currentUserId={user?.userId}
                            currentUserRoles={user?.roles ?? []}
                            onEdit={() =>
                              setFormDialog({
                                mode: "edit",
                                faction,
                              })
                            }
                            onDelete={() =>
                              setDeleteDialog({ factionId: faction.id })
                            }
                          />
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

        {formDialog && (
          <FactionFormDialog
            open={true}
            mode={formDialog.mode}
            currentFactionId={formDialog.faction?.id ?? null}
            userRoles={user?.roles ?? []}
            initialValues={
              formDialog.faction
                ? {
                    name: formDialog.faction.name,
                    gameSystemID: formDialog.faction.gameSystemID ?? null,
                    gameSystemName: formDialog.faction.gameSystemName ?? null,
                    parentFactionID: formDialog.faction.parentFactionID ?? null,
                    parentFactionName:
                      formDialog.faction.parentFactionName ?? null,
                    visibility: formDialog.faction.visibility,
                  }
                : undefined
            }
            onClose={handleFormClose}
            onSave={handleFormSave}
            isPending={isFormPending}
          />
        )}

        {deleteDialog && (
          <DeleteConfirmationDialog
            open={true}
            title={m.deleteTitle}
            description={m.deleteDescription}
            onClose={() => setDeleteDialog(null)}
            onConfirm={handleDeleteConfirm}
            isPending={deleteMutation.isPending}
          />
        )}
      </Stack>
    </Container>
  );
}
