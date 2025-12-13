import Vapor

public struct ReadQuery<Includes>: Content
where
    Includes: RawRepresentable & Codable & Hashable & Sendable,
    Includes.RawValue == String
{
    public var include: Set<Includes>?

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Accept both repeated params and a single comma-separated param.
        var parsed = Set<Includes>()

        // include=a&include=b
        if let array = try? container.decode([Includes].self, forKey: .include) {
            parsed.formUnion(array)
        }

        // include=a,b
        if let csv = try? container.decode(String.self, forKey: .include) {
            let split = csv
                .split(separator: ",")
                .compactMap { Includes(rawValue: String($0)) }
            parsed.formUnion(split)
        }

        include = parsed.isEmpty ? nil : parsed
    }
}
