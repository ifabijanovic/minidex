"use client";

import { useCurrentUser } from "@/app/contexts/user-context";
import { useApiQuery } from "@/lib/hooks/use-api-query";
import { queryKeys } from "@/lib/query-keys";

export type CatalogItemVisibility = "private" | "limited" | "public";

export type Faction = {
  id: string;
  name: string;
  gameSystemID?: string | null;
  gameSystemName?: string | null;
  parentFactionID?: string | null;
  parentFactionName?: string | null;
  createdByID: string;
  visibility: CatalogItemVisibility;
};

export type PagedFactionsResponse = {
  data: Faction[];
  page: number;
  limit: number;
  sort: string | null;
  order: "asc" | "desc" | null;
  query: string | null;
};

type UseFactionsOptions = {
  page?: number;
  limit?: number;
  sort?: string;
  order?: "asc" | "desc";
  query?: string;
  include?: string[];
  enabled?: boolean;
};

export function useFactions(options?: UseFactionsOptions) {
  const { user } = useCurrentUser();

  const {
    page = 0,
    limit = 25,
    sort,
    order,
    query,
    include = ["gameSystem", "parentFaction"],
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

  if (include.length > 0) {
    params.include = include.join(",");
  }

  return useApiQuery<PagedFactionsResponse>({
    queryKey: queryKeys.factions(
      page,
      limit,
      sort,
      order,
      query,
      include.join(","),
    ),
    path: "/v1/factions",
    request: { params },
    enabled: user !== null && optionsEnabled,
  });
}
