"use client";

import {
  type MutationFunctionContext,
  useMutation,
  UseMutationOptions,
  UseMutationResult,
} from "@tanstack/react-query";
import { enqueueSnackbar } from "notistack";

import { api, ApiRequestOptions } from "@/lib/api-client";
import { getFriendlyErrorMessage } from "@/lib/errors";

type UseApiMutationOptions<TData, TVariables> = Omit<
  UseMutationOptions<TData, Error, TVariables>,
  "mutationFn"
> & {
  method: "post" | "put" | "patch";
  path: string;
  request?: Omit<ApiRequestOptions<TVariables>, "method" | "body">;
  suppressToast?: boolean;
  genericErrorMessage?: string;
};

type UseApiDeleteMutationOptions<TData> = Omit<
  UseMutationOptions<TData, Error, void>,
  "mutationFn"
> & {
  path: string;
  request?: Omit<ApiRequestOptions, "method" | "body">;
  suppressToast?: boolean;
  genericErrorMessage?: string;
};

function createErrorHandler<TVariables>(
  suppressToast: boolean | undefined,
  genericErrorMessage: string | undefined,
  onError:
    | ((
        error: Error,
        variables: TVariables,
        onMutateResult: unknown,
        context: MutationFunctionContext,
      ) => Promise<unknown> | unknown)
    | undefined,
) {
  return (
    error: Error,
    variables: TVariables,
    onMutateResult: unknown,
    context: MutationFunctionContext,
  ) => {
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
    onError?.(error, variables, onMutateResult, context);
  };
}

export function useApiMutation<TData = unknown, TVariables = unknown>(
  options: UseApiMutationOptions<TData, TVariables>,
): UseMutationResult<TData, Error, TVariables> {
  const {
    method,
    path,
    request,
    suppressToast,
    genericErrorMessage,
    onError,
    ...rest
  } = options;

  return useMutation<TData, Error, TVariables>({
    ...rest,
    mutationFn: (variables: TVariables) => {
      switch (method) {
        case "post":
          return api.post<TData, TVariables>(path, variables, request);
        case "put":
          return api.put<TData, TVariables>(path, variables, request);
        case "patch":
          return api.patch<TData, TVariables>(path, variables, request);
        default:
          throw new Error(`Unsupported HTTP method: ${method}`);
      }
    },
    onError: createErrorHandler(suppressToast, genericErrorMessage, onError),
  });
}

export function useApiDeleteMutation<TData = unknown>(
  options: UseApiDeleteMutationOptions<TData>,
): UseMutationResult<TData, Error, void> {
  const {
    path,
    request,
    suppressToast,
    genericErrorMessage,
    onError,
    ...rest
  } = options;

  return useMutation<TData, Error, void>({
    ...rest,
    mutationFn: () => {
      return api.delete<TData>(path, request);
    },
    onError: createErrorHandler(suppressToast, genericErrorMessage, onError),
  });
}
