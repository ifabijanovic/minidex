import AuthAPI

extension TokenAuthenticator {
    init() {
        self.init(
            cacheExpiration: Settings.Auth.cacheExpiration,
            checksumSecret: Settings.Auth.cacheChecksumSecret ?? "insecure-secret",
        )
    }
}
