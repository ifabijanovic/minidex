import { QueryClient } from "@tanstack/react-query";

// Base URL for API calls - all calls go through Next.js proxy routes
export const API_BASE_URL = "/api";

// Default query client configuration
export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      // Stale time: how long data is considered fresh
      staleTime: 1000 * 60 * 5, // 5 minutes
      // Cache time: how long unused data stays in cache
      gcTime: 1000 * 60 * 30, // 30 minutes (formerly cacheTime)
      // Retry failed requests
      retry: 1,
      // Refetch on window focus
      refetchOnWindowFocus: false,
    },
    mutations: {
      retry: 1,
    },
  },
});
