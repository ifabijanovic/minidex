import Fluent
import FluentPostgresDriver

extension QueryBuilder {
    public func caseInsensitiveContains<Field>(
        _ field: KeyPath<Model, Field>,
        _ value: String,
    ) -> Self
    where
        Field: QueryableProperty,
        Field.Model == Model,
        Field.Value == String
    {
        if database is any PostgresDatabase {
            filter(field, .custom("ILIKE"), "%\(value)%")
        } else {
            filter(field ~~ value)
        }
    }

    public func caseInsensitiveContains<Field>(
        _ field: KeyPath<Model, Field>,
        _ value: String,
    ) -> Self
    where
        Field: QueryableProperty,
        Field.Model == Model,
        Field.Value: OptionalType,
        Field.Value.Wrapped == String
    {
        if database is any PostgresDatabase {
            filter(field, .custom("ILIKE"), .init("%\(value)%"))
        } else {
            filter(field ~~ value)
        }
    }

    public func caseInsensitiveContains<Joined, Field>(
        _ joined: Joined.Type,
        _ field: KeyPath<Joined, Field>,
        _ value: String,
    ) -> Self
    where
        Joined: Schema,
        Field: QueryableProperty,
        Field.Model == Joined,
        Field.Value == String
    {
        if database is any PostgresDatabase {
            filter(joined, field, .custom("ILIKE"), "%\(value)%")
        } else {
            filter(joined, field ~~ value)
        }
    }

    public func caseInsensitiveContains<Joined, Field>(
        _ joined: Joined.Type,
        _ field: KeyPath<Joined, Field>,
        _ value: String,
    ) -> Self
    where
        Joined: Schema,
        Field: QueryableProperty,
        Field.Model == Joined,
        Field.Value: OptionalType,
        Field.Value.Wrapped == String
    {
        if database is any PostgresDatabase {
            filter(joined, field, .custom("ILIKE"), .init("%\(value)%"))
        } else {
            filter(joined, field ~~ value)
        }
    }
}
