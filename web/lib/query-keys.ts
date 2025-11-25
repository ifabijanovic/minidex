export const queryKeys = {
  currentProfile: (userId: string) => ["current-profile", userId] as const,
  users: (page: number, limit: number, sort?: string, order?: "asc" | "desc") =>
    ["users", page, limit, sort, order] as const,
};
