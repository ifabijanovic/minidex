export function isValidUrl(url: string): boolean {
  if (!url.trim()) return true; // Empty is valid (will be null)
  try {
    new URL(url);
    return true;
  } catch {
    return false;
  }
}
