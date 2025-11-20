import type { NextRequest, NextResponse } from "next/server";

export const AUTH_COOKIE_NAME = "auth_token";

const BASE_COOKIE_OPTIONS = {
  httpOnly: true,
  secure: true,
  sameSite: "strict" as const,
  path: "/",
};

export function setAuthCookie(
  response: NextResponse,
  token: string,
  maxAgeSeconds?: number,
): void {
  const maxAge =
    typeof maxAgeSeconds === "number" && Number.isFinite(maxAgeSeconds)
      ? Math.max(0, Math.floor(maxAgeSeconds))
      : undefined;

  response.cookies.set({
    name: AUTH_COOKIE_NAME,
    value: token,
    ...BASE_COOKIE_OPTIONS,
    ...(maxAge !== undefined ? { maxAge } : {}),
  });
}

export function clearAuthCookie(response: NextResponse): void {
  response.cookies.set({
    name: AUTH_COOKIE_NAME,
    value: "",
    ...BASE_COOKIE_OPTIONS,
    maxAge: 0,
  });
}

export function getAuthTokenFromRequest(
  request: Pick<NextRequest, "cookies">,
): string | null {
  return request.cookies.get(AUTH_COOKIE_NAME)?.value ?? null;
}
