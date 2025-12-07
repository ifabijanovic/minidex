/**
 * Next.js API route that proxies requests to the Vapor server
 *
 * This route handles all API requests and forwards them to the Vapor server
 * with the authentication token from HttpOnly cookies.
 *
 * Usage: /api/* will be proxied to http://server:8080/*
 */

import { NextRequest, NextResponse } from "next/server";

import { getApiUrl } from "@/lib/env";

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
    const path = relativePath ? `/${relativePath}` : "";

    // Get query parameters from the request
    const searchParams = request.nextUrl.searchParams;
    const queryString = searchParams.toString();
    const baseUrl = await getApiUrl(path);
    const url = `${baseUrl}${queryString ? `?${queryString}` : ""}`;

    // Get the auth token from HttpOnly cookie
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

    const status = response.status;
    const contentType = response.headers.get("content-type");
    const contentLength = response.headers.get("content-length");

    if (
      status === 204 ||
      status === 205 ||
      status === 304 ||
      contentLength === "0"
    ) {
      return new NextResponse(null, { status });
    }

    if (contentType?.includes("application/json")) {
      const data = await response.json();
      const nextResponse = NextResponse.json(data, { status });

      // Forward relevant headers (excluding ones that shouldn't be forwarded)
      const headersToForward = ["content-type"];
      response.headers.forEach((value, key) => {
        if (headersToForward.includes(key.toLowerCase())) {
          nextResponse.headers.set(key, value);
        }
      });

      return nextResponse;
    }

    const textData = await response.text();
    const nextResponse = new NextResponse(textData, { status });

    if (contentType) {
      nextResponse.headers.set("content-type", contentType);
    }

    return nextResponse;
  } catch (error) {
    console.error("Proxy error:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 },
    );
  }
}
