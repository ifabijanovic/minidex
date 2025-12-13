export const queryKeys = {
  currentProfile: (userId: string) => ["current-profile", userId] as const,
  users: (
    page: number,
    limit: number,
    sort?: string,
    order?: "asc" | "desc",
    query?: string,
  ) => ["users", page, limit, sort, order, query] as const,
  gameSystems: (
    page: number,
    limit: number,
    sort?: string,
    order?: "asc" | "desc",
    query?: string,
  ) => ["game-systems", page, limit, sort, order, query] as const,
  factions: (
    page: number,
    limit: number,
    sort?: string,
    order?: "asc" | "desc",
    query?: string,
    include?: string,
  ) => ["factions", page, limit, sort, order, query, include] as const,
};
