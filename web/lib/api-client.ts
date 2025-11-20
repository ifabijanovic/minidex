/**
 * API client utility for making requests to Next.js proxy routes
 * All requests go through /api/* routes which proxy to the Vapor server
 */

import { type QueryKey, queryOptions } from "@tanstack/react-query";

import { API_BASE_URL } from "@/lib/query-client";

type QueryParams = Record<string, string | number | boolean>;

export interface ApiRequestOptions<TBody = unknown>
  extends Omit<RequestInit, "body"> {
  params?: QueryParams;
  body?: TBody;
}

/**
 * Builds a URL with query parameters
 */
function buildUrl(path: string, params?: QueryParams): string {
  let url = path;
  if (params && Object.keys(params).length > 0) {
    const searchParams = new URLSearchParams();
    Object.entries(params).forEach(([key, value]) => {
      searchParams.append(key, String(value));
    });
    url += `?${searchParams.toString()}`;
  }
  return url;
}

/**
 * Determines whether the provided body can be sent as-is
 */
function isNativeBody(body: unknown): body is BodyInit {
  if (body == null) return false;
  return (
    typeof body === "string" ||
    body instanceof Blob ||
    body instanceof FormData ||
    body instanceof URLSearchParams ||
    body instanceof ReadableStream ||
    body instanceof ArrayBuffer ||
    ArrayBuffer.isView(body)
  );
}

/**
 * Prepares the body for fetch and returns the serialized body plus any headers to include
 */
function prepareBody(body: unknown): {
  payload?: BodyInit;
  contentType?: string;
} {
  if (body == null) {
    return {};
  }

  if (isNativeBody(body)) {
    return { payload: body };
  }

  return {
    payload: JSON.stringify(body),
    contentType: "application/json",
  };
}

/**
 * Makes a request to a Next.js API proxy route
 * All requests automatically go through /api/* routes
 */
export async function apiRequest<TResponse, TBody = unknown>(
  path: string,
  options: ApiRequestOptions<TBody> = {},
): Promise<TResponse> {
  const { params, body, headers: customHeaders, ...fetchOptions } = options;

  // Ensure path starts with /api
  const apiPath = path.startsWith("/api") ? path : `${API_BASE_URL}${path}`;
  const url = buildUrl(apiPath, params);

  const { payload, contentType: preparedContentType } = prepareBody(body);

  const headers: HeadersInit = {
    ...(preparedContentType ? { "Content-Type": preparedContentType } : {}),
    ...customHeaders,
  };

  const response = await fetch(url, {
    ...fetchOptions,
    headers,
    body: payload,
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({
      message: `HTTP error! status: ${response.status}`,
    }));
    throw new Error(
      error.message || `Request failed with status ${response.status}`,
    );
  }

  // Handle empty responses
  const contentType = response.headers.get("content-type");
  if (contentType && contentType.includes("application/json")) {
    return response.json();
  }

  return response.text() as unknown as TResponse;
}

/**
 * Convenience methods for common HTTP verbs
 */
export const api = {
  get: <TResponse>(
    path: string,
    options?: Omit<ApiRequestOptions, "method" | "body">,
  ) => apiRequest<TResponse>(path, { ...options, method: "GET" }),

  post: <TResponse, TBody = unknown>(
    path: string,
    body?: TBody,
    options?: Omit<ApiRequestOptions<TBody>, "method" | "body">,
  ) =>
    apiRequest<TResponse, TBody>(path, {
      ...options,
      method: "POST",
      body,
    }),

  put: <TResponse, TBody = unknown>(
    path: string,
    body?: TBody,
    options?: Omit<ApiRequestOptions<TBody>, "method" | "body">,
  ) =>
    apiRequest<TResponse, TBody>(path, {
      ...options,
      method: "PUT",
      body,
    }),

  patch: <TResponse, TBody = unknown>(
    path: string,
    body?: TBody,
    options?: Omit<ApiRequestOptions<TBody>, "method" | "body">,
  ) =>
    apiRequest<TResponse, TBody>(path, {
      ...options,
      method: "PATCH",
      body,
    }),

  delete: <TResponse>(
    path: string,
    options?: Omit<ApiRequestOptions, "method">,
  ) => apiRequest<TResponse>(path, { ...options, method: "DELETE" }),
};

const DEFAULT_QUERY_BEHAVIOR = {
  staleTime: 1000 * 60 * 5, // 5 minutes
  gcTime: 1000 * 60 * 30, // 30 minutes
  retry: 1,
} as const;

type QueryBehaviorOverrides = Partial<typeof DEFAULT_QUERY_BEHAVIOR>;

type ApiQueryOptionsConfig<TResponse> = {
  queryKey: QueryKey;
  path: string;
  request?: ApiRequestOptions;
  behavior?: QueryBehaviorOverrides;
};

export function apiQueryOptions<TResponse>({
  queryKey,
  path,
  request,
  behavior,
}: ApiQueryOptionsConfig<TResponse>) {
  return queryOptions({
    queryKey,
    queryFn: () => apiRequest<TResponse>(path, request),
    ...DEFAULT_QUERY_BEHAVIOR,
    ...behavior,
  });
}
