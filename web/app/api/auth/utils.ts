import { NextResponse } from "next/server";

import type { AuthErrorPayload, AuthResponse } from "@/app/api/auth/types";
import { clearAuthCookie, setAuthCookie } from "@/lib/auth-cookies";

export function extractErrorMessage(
  payload?: AuthErrorPayload | AuthResponse | null,
): string | null {
  if (!payload) return null;
  return payload.message || payload.reason || payload.error || null;
}

export function respondWithError(
  status: number,
  message: string,
): NextResponse {
  const response = NextResponse.json({ message }, { status });
  clearAuthCookie(response);
  return response;
}

export function createAuthSuccessResponse(
  accessToken: string,
  userId: string | undefined,
  expiresIn: number | undefined,
  roles: string[] | undefined,
  status: number = 200,
): NextResponse {
  const response = NextResponse.json(
    {
      userId,
      expiresIn,
      roles,
    },
    { status },
  );

  setAuthCookie(response, accessToken, expiresIn);
  return response;
}

export function handleUpstreamError(
  upstream: Response,
  payload: unknown,
  defaultMessage: string,
): NextResponse {
  const errorPayload = payload as AuthErrorPayload | null;
  const message = extractErrorMessage(errorPayload) || defaultMessage;
  return respondWithError(upstream.status || 500, message);
}
