"use client";

import { UserRole } from "@/app/context/user-context";
import { useApiQuery } from "@/lib/hooks/use-api-query";
import { queryKeys } from "@/lib/query-keys";

export type User = {
  id: string;
  roles: UserRole[];
  isActive: boolean;
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
};

export function useUsers(options?: UseUsersOptions) {
  const { page = 0, limit = 25, sort, order } = options ?? {};

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

  return useApiQuery<PagedUsersResponse>({
    queryKey: queryKeys.users(page, limit, sort, order),
    path: "/v1/users",
    request: { params },
  });
}
