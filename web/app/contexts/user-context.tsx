"use client";

import {
  createContext,
  ReactNode,
  useContext,
  useEffect,
  useState,
} from "react";

import { api } from "@/lib/api-client";
import { ApiError } from "@/lib/api-client";

export const ALL_USER_ROLES = ["admin", "hobbyist", "cataloguer"] as const;

export type UserRole = (typeof ALL_USER_ROLES)[number];

export type User = {
  userId: string;
  roles: UserRole[];
};

type UserContextType = {
  user: User | null;
  setUser: (user: User | null) => void;
};

type MeResponse = {
  userId: string;
  roles: UserRole[];
};

const UserContext = createContext<UserContextType | undefined>(undefined);

export function UserProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);

  // Restore user context on page refresh: React state is lost on refresh,
  // but auth cookie persists, so fetch user info from backend
  useEffect(() => {
    async function fetchUser() {
      try {
        const data = await api.get<MeResponse>("/v1/auth/me");
        setUser({
          userId: data.userId,
          roles: data.roles || [],
        });
      } catch (error) {
        // If 401/403/404, user is not authenticated - leave user as null
        if (error instanceof ApiError) {
          if (
            error.status === 401 ||
            error.status === 403 ||
            error.status === 404
          ) {
            setUser(null);
          } else {
            // Other errors - log but don't set user
            console.error("Failed to fetch user:", error);
          }
        } else {
          console.error("Unexpected error fetching user:", error);
        }
      }
    }

    fetchUser();
  }, []);

  return (
    <UserContext.Provider value={{ user, setUser }}>
      {children}
    </UserContext.Provider>
  );
}

export function useCurrentUser() {
  const context = useContext(UserContext);
  if (context === undefined) {
    throw new Error("useCurrentUser must be used within a UserProvider");
  }
  return context;
}
