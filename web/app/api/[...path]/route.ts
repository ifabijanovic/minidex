/**
 * Next.js API route that proxies requests to the Vapor server
 *
 * This route handles all API requests and forwards them to the Vapor server
 * with the authentication token from HttpOnly cookies.
 *
 * Usage: /api/* will be proxied to http://server:8080/v1/*
 */

import { NextRequest, NextResponse } from "next/server";

const API_URL = process.env.API_URL || "http://localhost:8080";

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ path: string[] }> },
) {
  const { path } = await params;
  return proxyRequest(request, path, "GET");
}

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ path: string[] }> },
) {
  const { path } = await params;
  return proxyRequest(request, path, "POST");
}

export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ path: string[] }> },
) {
  const { path } = await params;
  return proxyRequest(request, path, "PUT");
}

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ path: string[] }> },
) {
  const { path } = await params;
  return proxyRequest(request, path, "PATCH");
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ path: string[] }> },
) {
  const { path } = await params;
  return proxyRequest(request, path, "DELETE");
}

async function proxyRequest(
  request: NextRequest,
  pathSegments: string[],
  method: string,
) {
  try {
    // Reconstruct the versioned path
    const relativePath = pathSegments.join("/");
    const path = `/v1${relativePath ? `/${relativePath}` : ""}`;

    // Get query parameters from the request
    const searchParams = request.nextUrl.searchParams;
    const queryString = searchParams.toString();
    const url = `${API_URL}${path}${queryString ? `?${queryString}` : ""}`;

    // Get the auth token from HttpOnly cookie
    // TODO: Implement cookie reading when authentication is set up
    const authToken = request.cookies.get("auth_token")?.value;

    // Prepare headers
    const headers: HeadersInit = {
      "Content-Type": "application/json",
    };

    // Add Authorization header if token exists
    if (authToken) {
      headers["Authorization"] = `Bearer ${authToken}`;
    }

    // Forward the request body if present
    let body: string | undefined;
    if (method !== "GET" && method !== "DELETE") {
      try {
        body = await request.text();
      } catch {
        // No body to forward
      }
    }

    // Make the request to the Vapor server
    const response = await fetch(url, {
      method,
      headers,
      body,
    });

    // Get response data
    const contentType = response.headers.get("content-type");
    let data: unknown;

    if (contentType?.includes("application/json")) {
      data = await response.json();
    } else {
      data = await response.text();
    }

    // Create response with same status and headers
    const nextResponse = NextResponse.json(data, {
      status: response.status,
    });

    // Forward relevant headers (excluding ones that shouldn't be forwarded)
    const headersToForward = ["content-type", "content-length"];
    response.headers.forEach((value, key) => {
      if (headersToForward.includes(key.toLowerCase())) {
        nextResponse.headers.set(key, value);
      }
    });

    return nextResponse;
  } catch (error) {
    console.error("Proxy error:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 },
    );
  }
}
