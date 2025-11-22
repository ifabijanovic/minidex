"use client";

import { useQuery } from "@tanstack/react-query";

import { apiQueryOptions } from "@/lib/api-client";
import { queryKeys } from "@/lib/query-keys";

export type CurrentUser = {
  id: string;
  displayName?: string | null;
  roles: number;
  isActive: boolean;
};

const currentUserQuery = apiQueryOptions<CurrentUser>({
  queryKey: queryKeys.currentUser,
  path: "/user",
  request: { cache: "no-store" },
});

type UseCurrentUserOptions = {
  enabled?: boolean;
  placeholderData?: CurrentUser;
};

export function useCurrentUser(options?: UseCurrentUserOptions) {
  const { enabled = true, placeholderData } = options ?? {};

  return useQuery<CurrentUser>({
    ...currentUserQuery,
    enabled,
    initialData: placeholderData,
  });
}
