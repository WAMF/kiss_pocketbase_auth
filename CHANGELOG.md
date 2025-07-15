# Changelog

## [0.1.0] - 2025-01-15

### Initial Release

- `PocketBaseAuthValidator` implementing `AuthValidator` interface for token validation
- `PocketBaseLoginProvider` implementing `LoginProvider` interface with support for:
  - Email/password authentication
  - Username/password authentication
  - OAuth2 authentication (Google, GitHub, Facebook, and more)
  - API key authentication (JWT format)
  - Token refresh and validation
  - User registration
- `PocketBaseAuthenticationData` with PocketBase-specific user fields
- Complete example Flutter app demonstrating login/signup flows
- Comprehensive documentation and API reference
- Docker-based integration testing setup