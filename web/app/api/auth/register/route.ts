import { NextRequest, NextResponse } from "next/server";

import { clearAuthCookie, setAuthCookie } from "@/lib/auth-cookies";
import { getApiUrl } from "@/lib/env";

type RegisterRequestBody = {
  username?: unknown;
  password?: unknown;
  confirmPassword?: unknown;
};

type RegisterResponse = {
  accessToken?: string;
  expiresIn?: number;
  userId?: string;
  error?: string;
  message?: string;
  reason?: string;
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

    const payload = await upstream.json().catch<RegisterResponse>(() => ({}));

    if (!upstream.ok || !payload?.accessToken) {
      const message =
        extractMessage(payload) ||
        "Unable to register with the provided credentials";
      return respondWithError(upstream.status || 500, message);
    }

    const response = NextResponse.json(
      {
        userId: payload.userId,
        expiresIn: payload.expiresIn,
      },
      { status: upstream.status || 201 },
    );

    setAuthCookie(response, payload.accessToken, payload.expiresIn);
    return response;
  } catch (error) {
    console.error("Register route error:", error);
    return respondWithError(500, "Internal server error");
  }
}

function extractMessage(payload?: RegisterResponse | null): string | null {
  if (!payload) return null;
  return payload.message || payload.reason || payload.error || null;
}

function respondWithError(status: number, message: string): NextResponse {
  const response = NextResponse.json({ message }, { status });
  clearAuthCookie(response);
  return response;
}
