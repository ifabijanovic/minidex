import { ApiError } from "@/lib/api-client";

type FriendlyErrorOptions = {
  genericMessage?: string;
};

export function getFriendlyErrorMessage(
  error: unknown,
  options: FriendlyErrorOptions = {},
) {
  const generic = options.genericMessage ?? "Something went wrong. Please try again.";

  if (error instanceof ApiError) {
    if (error.status >= 500) {
      return "Our servers are having trouble right now. Please try again shortly.";
    }
    if (error.status === 401 || error.status === 403) {
      return "Your session has expired. Please login again.";
    }
    return error.message || generic;
  }

  if (error instanceof Error) {
    return error.message || generic;
  }

  return generic;
}

