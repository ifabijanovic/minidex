export const queryKeys = {
  currentProfile: (userId: string) => ["current-profile", userId] as const,
};
