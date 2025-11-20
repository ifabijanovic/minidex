import { NextRequest, NextResponse } from "next/server";

import { clearAuthCookie, getAuthTokenFromRequest } from "@/lib/auth-cookies";

const API_URL = process.env.API_URL || "http://localhost:8080";

export async function POST(request: NextRequest) {
  const token = getAuthTokenFromRequest(request);

  if (!token) {
    return respondWithSuccess();
  }

  try {
    const upstream = await fetch(`${API_URL}/v1/auth/logout`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        Accept: "application/json",
      },
      cache: "no-store",
    });

    if (!upstream.ok) {
      const payload = await upstream.json().catch(() => ({}));
      const message =
        payload.message ||
        payload.error ||
        payload.reason ||
        "Failed to logout";
      return respondWithError(upstream.status || 500, message);
    }
  } catch (error) {
    console.error("Logout route error:", error);
    return respondWithError(500, "Internal server error");
  }

  return respondWithSuccess();
}

function respondWithSuccess(): NextResponse {
  const response = NextResponse.json({ success: true }, { status: 200 });
  clearAuthCookie(response);
  return response;
}

function respondWithError(status: number, message: string): NextResponse {
  const response = NextResponse.json({ error: message }, { status });
  clearAuthCookie(response);
  return response;
}
