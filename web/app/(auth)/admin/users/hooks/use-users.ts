"use client";

import { UserRole } from "@/app/providers/user-provider";
import { useApiQuery } from "@/lib/hooks/use-api-query";
import { queryKeys } from "@/lib/query-keys";

export type User = {
  userID: string;
  roles: UserRole[];
  isActive: boolean;
  profileID?: string;
  displayName?: string;
  avatarURL?: string;
};

export type PagedUsersResponse = {
  data: User[];
  page: number;
  limit: number;
  sort: string | null;
  order: "asc" | "desc" | null;
  query: string | null;
};

type UseUsersOptions = {
  page?: number;
  limit?: number;
  sort?: string;
  order?: "asc" | "desc";
  query?: string;
};

export function useUsers(options?: UseUsersOptions) {
  const { page = 0, limit = 25, sort, order, query } = options ?? {};

  const params: Record<string, string> = {
    page: page.toString(),
    limit: limit.toString(),
  };

  if (sort) {
    params.sort = sort;
    if (order) {
      params.order = order;
    }
  }

  if (query && query.length >= 3) {
    params.q = query;
  }

  return useApiQuery<PagedUsersResponse>({
    queryKey: queryKeys.users(page, limit, sort, order, query),
    path: "/v1/admin/users",
    request: { params },
  });
}
