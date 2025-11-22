"use client";

import { useMutation, UseMutationOptions, UseMutationResult } from "@tanstack/react-query";
import { enqueueSnackbar } from "notistack";

import { getFriendlyErrorMessage } from "@/lib/errors";

type UseApiMutationOptions<TData, TVariables> = UseMutationOptions<TData, Error, TVariables> & {
  suppressToast?: boolean;
};

export function useApiMutation<TData = unknown, TVariables = void>(
  options: UseApiMutationOptions<TData, TVariables>,
): UseMutationResult<TData, Error, TVariables> {
  const { suppressToast, onError, ...rest } = options;

  return useMutation<TData, Error, TVariables>({
    ...rest,
    onError: (error, variables, context) => {
      if (!suppressToast) {
        enqueueSnackbar(getFriendlyErrorMessage(error), { variant: "error" });
      }
      onError?.(error, variables, context, undefined as any);
    },
  });
}

