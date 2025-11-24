import { NextRequest } from "next/server";

import type { AuthResponse } from "@/app/api/auth/types";
import {
  createAuthSuccessResponse,
  handleUpstreamError,
  respondWithError,
} from "@/app/api/auth/utils";
import { getApiUrl } from "@/lib/env";

type RegisterRequestBody = {
  username?: unknown;
  password?: unknown;
  confirmPassword?: unknown;
};

export async function POST(request: NextRequest) {
  const body = (await request.json().catch(() => ({}))) as RegisterRequestBody;
  const username = typeof body.username === "string" ? body.username : "";
  const password = typeof body.password === "string" ? body.password : "";
  const confirmPassword =
    typeof body.confirmPassword === "string" ? body.confirmPassword : "";

  if (!username || !password || !confirmPassword) {
    return respondWithError(400, "Username and passwords are required");
  }

  if (password !== confirmPassword) {
    return respondWithError(400, "Passwords must match");
  }

  try {
    const registerUrl = await getApiUrl("/v1/auth/register");
    const upstream = await fetch(registerUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
      },
      body: JSON.stringify({ username, password, confirmPassword }),
      cache: "no-store",
    });

    const payload = await upstream.json().catch<AuthResponse>(() => ({}));

    if (!upstream.ok || !payload?.accessToken) {
      return handleUpstreamError(
        upstream,
        payload,
        "Unable to register with the provided credentials",
      );
    }

    return createAuthSuccessResponse(
      payload.accessToken,
      payload.userId,
      payload.expiresIn,
      payload.roles,
      upstream.status || 201,
    );
  } catch (error) {
    console.error("Register route error:", error);
    return respondWithError(500, "Internal server error");
  }
}
