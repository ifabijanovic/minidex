public enum CatalogItemVisibility: String, Codable, Sendable {
    /// Private catalog items are visible only to the creator.
    case `private`
    /// Limited catalog items are visible to the creator and cataloguers.
    case limited
    /// Public catalog items are visible to everyone.
    case `public`
}
