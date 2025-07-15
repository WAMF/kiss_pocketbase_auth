# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Complete implementation of `LoginProvider` interface from kiss_auth
- Support for multiple authentication methods:
  - Email/password authentication
  - Username/password authentication
  - OAuth2 authentication with multiple providers
  - API key authentication (JWT format)
- Token validation and refresh functionality
- User registration with `createUser` method
- Comprehensive error handling with specific error codes
- Example Flutter app with login/signup screens
- Integration with `shared_preferences` for token persistence

### Changed
- Refactored `PocketBaseAuthValidator` to focus on token validation only
- Updated to use non-deprecated `baseURL` property for PocketBase client
- Improved example app with proper authentication flow

### Fixed
- Startup issues in example app
- Analyzer warnings and linting issues

## [0.1.0] - 2024-01-XX

### Added
- Initial release
- `PocketBaseAuthValidator` implementing `AuthValidator` interface
- `PocketBaseAuthenticationData` with PocketBase-specific fields
- Basic authentication support
- Docker-based integration tests
- Comprehensive documentation