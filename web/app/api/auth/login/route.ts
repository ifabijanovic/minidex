import { Buffer } from "node:buffer";

import { NextRequest } from "next/server";

import type { AuthResponse } from "@/app/api/auth/types";
import {
  createAuthSuccessResponse,
  handleUpstreamError,
  respondWithError,
} from "@/app/api/auth/utils";
import { getApiUrl } from "@/lib/env";

export async function POST(request: NextRequest) {
  const body = await request.json().catch(() => ({}));
  const username = typeof body.username === "string" ? body.username : "";
  const password = typeof body.password === "string" ? body.password : "";

  if (!username || !password) {
    return respondWithError(400, "Username and password are required");
  }

  try {
    const loginUrl = await getApiUrl("/v1/auth/login");
    const upstream = await fetch(loginUrl, {
      method: "POST",
      headers: {
        Authorization: buildBasicAuthHeader(username, password),
        Accept: "application/json",
      },
      cache: "no-store",
    });

    const payload = await upstream.json().catch<AuthResponse>(() => ({}));

    if (!upstream.ok || !payload?.accessToken) {
      return handleUpstreamError(
        upstream,
        payload,
        "Unable to login with the provided credentials",
      );
    }

    return createAuthSuccessResponse(
      payload.accessToken,
      payload.userId,
      payload.expiresIn,
      payload.roles,
      200,
    );
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
