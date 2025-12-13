// Relation fields mapping for API endpoints
// Used by the proxy to convert null values to sentinel UUIDs for relation clearing

export const RELATION_FIELDS_BY_ENDPOINT: Record<string, string[]> = {
  factions: ["gameSystemID", "parentFactionID"],
  // Add other endpoints as needed
};
