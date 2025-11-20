import { NextRequest, NextResponse } from "next/server";

import { getAuthTokenFromRequest } from "@/lib/auth-cookies";

const PUBLIC_EXACT_PATHS = ["/", "/login"];
const PUBLIC_PREFIXES = ["/api", "/_next", "/static", "/public"];
const BYPASS_PATHS = [
  "/favicon.ico",
  "/robots.txt",
  "/sitemap.xml",
  "/manifest.json",
];

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  if (shouldBypass(pathname)) {
    return NextResponse.next();
  }

  const token = getAuthTokenFromRequest(request);
  const isPublic = isPublicPath(pathname);

  if (!isPublic && !token) {
    return redirectToLogin(request);
  }

  if (pathname === "/login" && token) {
    return NextResponse.redirect(new URL("/dashboard", request.url));
  }

  return NextResponse.next();
}

function isPublicPath(pathname: string): boolean {
  if (PUBLIC_EXACT_PATHS.includes(pathname)) {
    return true;
  }

  return PUBLIC_PREFIXES.some(
    (prefix) => pathname === prefix || pathname.startsWith(`${prefix}/`),
  );
}

function shouldBypass(pathname: string): boolean {
  if (pathname.startsWith("/_next")) {
    return true;
  }
  if (pathname.startsWith("/api")) {
    return true;
  }
  return BYPASS_PATHS.includes(pathname);
}

function redirectToLogin(request: NextRequest): NextResponse {
  const loginUrl = new URL("/login", request.url);
  const returnUrl = `${request.nextUrl.pathname}${request.nextUrl.search}`;

  if (returnUrl && returnUrl !== "/login") {
    loginUrl.searchParams.set("returnUrl", returnUrl);
  }

  return NextResponse.redirect(loginUrl);
}
