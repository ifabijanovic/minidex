"use client";

import { useCurrentUser } from "@/app/contexts/user-context";
import { useApiQuery } from "@/lib/hooks/use-api-query";
import { queryKeys } from "@/lib/query-keys";

export type CatalogItemVisibility = "private" | "limited" | "public";

export type GameSystem = {
  id: string;
  name: string;
  publisher?: string | null;
  releaseYear?: number | null;
  website?: string | null;
  createdByID: string;
  visibility: CatalogItemVisibility;
};

export type PagedGameSystemsResponse = {
  data: GameSystem[];
  page: number;
  limit: number;
  sort: string | null;
  order: "asc" | "desc" | null;
  query: string | null;
};

type UseGameSystemsOptions = {
  page?: number;
  limit?: number;
  sort?: string;
  order?: "asc" | "desc";
  query?: string;
  enabled?: boolean;
};

export function useGameSystems(options?: UseGameSystemsOptions) {
  const { user } = useCurrentUser();

  const {
    page = 0,
    limit = 25,
    sort,
    order,
    query,
    enabled: optionsEnabled = true,
  } = options ?? {};

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

  return useApiQuery<PagedGameSystemsResponse>({
    queryKey: queryKeys.gameSystems(page, limit, sort, order, query),
    path: "/v1/game-systems",
    request: { params },
    enabled: user !== null && optionsEnabled,
  });
}
