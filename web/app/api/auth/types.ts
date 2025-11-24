export type AuthResponse = {
  accessToken?: string;
  expiresIn?: number;
  userId?: string;
  roles?: string[];
  error?: string;
  message?: string;
  reason?: string;
};

export type AuthErrorPayload = {
  error?: string;
  message?: string;
  reason?: string;
};
