/**
 * Development-only utilities for testing and debugging
 * All functions are no-ops in production builds
 */

/**
 * Check if running in development mode
 */
export function isDevelopment(): boolean {
  return process.env.NODE_ENV === "development";
}

/**
 * Get the slow delay value from URL query parameter
 * Only works in development mode
 *
 * @param defaultDelay - Default delay in milliseconds if ?slow=true (default: 3000)
 * @returns Object with enabled flag and delay duration, or null if not enabled
 *
 * @example
 * - ?slow=true → { enabled: true, delay: 3000 }
 * - ?slow=5000 → { enabled: true, delay: 5000 }
 * - No param → null
 */
export function getSlowDelay(
  defaultDelay: number = 3000,
): { enabled: boolean; delay: number } | null {
  if (!isDevelopment()) {
    return null;
  }

  if (typeof window === "undefined") {
    return null;
  }

  const urlParams = new URLSearchParams(window.location.search);
  const slowParam = urlParams.get("slow");

  if (!slowParam) {
    return null;
  }

  if (slowParam === "true") {
    return { enabled: true, delay: defaultDelay };
  }

  const customDelay = parseInt(slowParam, 10);
  if (!isNaN(customDelay) && customDelay > 0) {
    return { enabled: true, delay: customDelay };
  }

  return null;
}
