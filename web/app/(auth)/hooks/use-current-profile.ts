"use client";

import { useCurrentUser } from "@/app/context/user-context";
import { ApiError } from "@/lib/api-client";
import { useApiQuery } from "@/lib/hooks/use-api-query";
import { queryKeys } from "@/lib/query-keys";

export type CurrentProfile = {
  id: string;
  userID: string;
  displayName?: string | null;
  avatarURL?: string | null;
};

type UseCurrentProfileOptions = {
  enabled?: boolean;
};

export function useCurrentProfile(options?: UseCurrentProfileOptions) {
  const { user } = useCurrentUser();
  const { enabled: optionsEnabled = true } = options ?? {};

  return useApiQuery<CurrentProfile | null>({
    queryKey: queryKeys.currentProfile(user?.userId ?? ""),
    path: "/v1/me",
    request: { cache: "no-store" },
    enabled: user !== null && optionsEnabled,
    onError: (error) => {
      if (error instanceof ApiError && error.status === 404) {
        return null;
      }
      throw error;
    },
  });
}
