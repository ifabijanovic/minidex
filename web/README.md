# MiniDex Web

Next.js frontend application for MiniDex.

## Making API Calls

All API calls go through custom hooks that enforce using the `api-client` and provide automatic error handling.

### Queries

Use `useApiQuery` for GET requests:

```typescript
import { useApiQuery } from "@/lib/hooks/use-api-query";
import { queryKeys } from "@/lib/query-keys";

const { data, isLoading, error } = useApiQuery<ResponseType>({
  queryKey: queryKeys.someResource,
  path: "/v1/resource",
  // Optional: override query options
  staleTime: 1000 * 60 * 10,
});
```

**Best Practice:** Create domain-specific hooks that wrap `useApiQuery`. See `useCurrentProfile` for an example:

```typescript
// app/(auth)/hooks/use-current-profile.ts
export function useCurrentProfile() {
  return useApiQuery<CurrentProfile>({
    queryKey: queryKeys.currentProfile,
    path: "/v1/me",
    onError: (error) => {
      // Handle 404 gracefully - profile doesn't exist yet
      if (error instanceof ApiError && error.status === 404) {
        return placeholderProfile;
      }
      throw error;
    },
  });
}
```

### Mutations

Use `useApiMutation` for POST/PUT/PATCH and `useApiDeleteMutation` for DELETE:

```typescript
import { useApiMutation } from "@/lib/hooks/use-api-mutation";

const mutation = useApiMutation<ResponseType, PayloadType>({
  method: "post",
  path: "/v1/resource",
  onSuccess: (data) => {
    // Handle success
  },
});

// Call it
mutation.mutate({ field: "value" });
```

**Best Practices for Mutations:**

<!-- TODO: Add mutation best practices examples -->

## API Proxy

All API requests are automatically proxied through Next.js routes (`/api/*`) to the Vapor server:

- Frontend calls `/api/v1/me` → Next.js proxy → `http://server:8080/v1/me`
- Authentication tokens are automatically forwarded from HttpOnly cookies
- The proxy handles CORS and adds the `Authorization` header

See `app/api/[...path]/route.ts` for implementation details.

## Error Handling

Both `useApiQuery` and `useApiMutation` automatically show error snackbars for failed requests.

**Suppress error toast:**

```typescript
useApiQuery({
  path: "/v1/resource",
  suppressToast: true, // Don't show error snackbar
});
```

**Custom error message:**

```typescript
useApiMutation({
  method: "post",
  path: "/v1/resource",
  genericErrorMessage: "Failed to save resource",
});
```

**Handle errors gracefully:**

```typescript
useApiQuery({
  path: "/v1/resource",
  onError: (error) => {
    if (error instanceof ApiError && error.status === 404) {
      return defaultValue; // Return fallback instead of erroring
    }
    throw error; // Re-throw to show error toast
  },
});
```

## Query Keys

Centralize query keys in `lib/query-keys.ts` for consistency and easy invalidation:

```typescript
export const queryKeys = {
  currentUser: ["current-user"] as const,
  currentProfile: ["current-profile"] as const,
};
```

## Type Safety

All hooks are fully typed. Always provide type parameters:

```typescript
useApiQuery<ResponseType>({ ... })
useApiMutation<ResponseType, PayloadType>({ ... })
```

## Development Tools

### Slow Query Tool

In development mode, you can artificially delay queries to test loading states (e.g., skeleton animations):

- Add `?slow=true` to your URL for a 3-second delay (default)
- Add `?slow=<int>` for a custom delay in milliseconds

**Examples:**

- `http://localhost:3000/home?slow=true` - 3 second delay
- `http://localhost:3000/home?slow=5000` - 5 second delay

The delay happens before the API call, so TanStack Query will show `isLoading: true` during the delay period. This is useful for testing skeleton loaders and other loading UI states.

**Note:** This tool only works in development mode and has zero impact on production builds.
