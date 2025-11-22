import { ApiError } from "@/lib/api-client";
import { errorMessages } from "@/lib/messages/errors";

type FriendlyErrorOptions = {
  genericMessage?: string;
};

export function getFriendlyErrorMessage(
  error: unknown,
  options: FriendlyErrorOptions = {},
) {
  const generic = options.genericMessage ?? errorMessages.generic;

  if (error instanceof ApiError) {
    if (error.status >= 500) {
      return errorMessages.server;
    }
    if (error.status === 401 || error.status === 403) {
      return errorMessages.sessionExpired;
    }
    return error.message || generic;
  }

  if (error instanceof Error) {
    return error.message || generic;
  }

  return generic;
}
