"use client";

import {
  type QueryKey,
  useQuery,
  UseQueryOptions,
  UseQueryResult,
} from "@tanstack/react-query";
import { enqueueSnackbar } from "notistack";

import { api, ApiRequestOptions } from "@/lib/api-client";
import { getFriendlyErrorMessage } from "@/lib/errors";
import { getSlowDelay } from "@/lib/utils/dev-helpers";

type UseApiQueryOptions<TResponse> = Omit<
  UseQueryOptions<TResponse>,
  "queryKey" | "queryFn"
> & {
  queryKey: QueryKey;
  path: string;
  request?: ApiRequestOptions;
  suppressToast?: boolean;
  genericErrorMessage?: string;
  onError?: (error: unknown) => TResponse;
};

export function useApiQuery<TResponse = unknown>(
  options: UseApiQueryOptions<TResponse>,
): UseQueryResult<TResponse, Error> {
  const {
    queryKey,
    path,
    request,
    onError,
    suppressToast,
    genericErrorMessage,
    ...rest
  } = options;

  // Check if slowdown is enabled (dev mode only)
  const slowConfig = getSlowDelay();

  return useQuery<TResponse>({
    ...rest,
    queryKey,
    queryFn: async () => {
      // Add artificial delay in development mode if ?slow param is present
      if (slowConfig?.enabled) {
        await new Promise((resolve) => setTimeout(resolve, slowConfig.delay));
      }

      try {
        return await api.get<TResponse>(path, request);
      } catch (error) {
        if (onError) {
          try {
            return onError(error);
          } catch (innerError) {
            error = innerError;
          }
        }

        if (!suppressToast) {
          enqueueSnackbar(
            getFriendlyErrorMessage(error, {
              genericMessage: genericErrorMessage,
            }),
            {
              variant: "error",
            },
          );
        }

        throw error;
      }
    },
  });
}
