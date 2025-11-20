import { Buffer } from "node:buffer";

import { NextRequest, NextResponse } from "next/server";

import { clearAuthCookie, setAuthCookie } from "@/lib/auth-cookies";

const API_URL = process.env.API_URL || "http://localhost:8080";

type LoginResponse = {
  accessToken?: string;
  expiresIn?: number;
  userId?: string;
  error?: string;
  message?: string;
  reason?: string;
};

export async function POST(request: NextRequest) {
  const body = await request.json().catch(() => ({}));
  const username = typeof body.username === "string" ? body.username : "";
  const password = typeof body.password === "string" ? body.password : "";

  if (!username || !password) {
    return respondWithError(400, "Username and password are required");
  }

  try {
    const upstream = await fetch(`${API_URL}/v1/auth/login`, {
      method: "POST",
      headers: {
        Authorization: buildBasicAuthHeader(username, password),
        Accept: "application/json",
      },
      cache: "no-store",
    });

    const payload = await upstream.json().catch<LoginResponse>(() => ({}));

    if (!upstream.ok || !payload?.accessToken) {
      const message =
        extractMessage(payload) ||
        "Unable to login with the provided credentials";
      return respondWithError(upstream.status || 500, message);
    }

    const response = NextResponse.json(
      {
        userId: payload.userId,
        expiresIn: payload.expiresIn,
      },
      { status: 200 },
    );

    setAuthCookie(response, payload.accessToken, payload.expiresIn);
    return response;
  } catch (error) {
    console.error("Login route error:", error);
    return respondWithError(500, "Internal server error");
  }
}

function buildBasicAuthHeader(username: string, password: string): string {
  const encoded = Buffer.from(`${username}:${password}`, "utf-8").toString(
    "base64",
  );
  return `Basic ${encoded}`;
}

function extractMessage(payload?: LoginResponse | null): string | null {
  if (!payload) return null;
  return payload.message || payload.error || payload.reason || null;
}

function respondWithError(status: number, message: string): NextResponse {
  const response = NextResponse.json({ error: message }, { status });
  clearAuthCookie(response);
  return response;
}
