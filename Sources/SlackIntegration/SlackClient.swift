import Vapor

public struct SlackClient: Sendable {
    public var send: @Sendable (String, String) async throws -> Void
}

struct PostMessageContent: Content {
    let channel: String
    let text: String
}

extension SlackClient {
    public static func vapor(client: any Client, token: String) -> SlackClient {
        .init(
            send: { message, channel in
                _ = try await client.post("https://slack.com/api/chat.postMessage") { req in
                    req.headers.bearerAuthorization = .init(token: token)
                    let content = PostMessageContent(channel: channel, text: message)
                    try req.content.encode(content)
                }
            }
        )
    }
}
