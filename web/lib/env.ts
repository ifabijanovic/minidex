"use server";

const API_URL = process.env.API_URL || "http://localhost:8080";

export async function getApiUrl(path: string = ""): Promise<string> {
  if (!path) {
    return API_URL;
  }

  const normalized = path.startsWith("/") ? path : `/${path}`;
  return `${API_URL}${normalized}`;
}
