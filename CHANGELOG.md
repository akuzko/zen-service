# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.2.3] - 2026-01-19

### Fixed

- Fix block passing when calling service using `.call` and `.[]` class methods

### Changed

- Add CI workflow with GitHub Actions
- Add SimpleCov integration with 100% test coverage (line and branch coverage)
- Update README with comprehensive documentation, shield badges, and improved examples

## [2.2.2] - 2025-12-30

### Fixed

- Fix re-using plugin by inherited service classes

## [2.2.1] - 2025-12-29

### Fixed

- Fix plugin reflection options and configuration check

## [2.2.0] - 2025-12-28

### Added

- Allow registering plugins with class names (strings) instead of requiring class constants
  - Useful when autoload isn't available yet, e.g., during Rails initialization

### Changed

- Update README with improved documentation

## [2.1.0] - 2025-12-20

### Added

- Add `:call_unless_called` option to `:persisted_result` plugin
  - When set to `true`, accessing `service.result` will automatically call `#call` if not yet called
  - Default value is `false`

### Changed

- Allow plugin re-registration with updated configuration
- Code cleanup and refactoring

### Fixed

- Drop obsolete statements from codebase

## [2.0.0] - 2025-12-06

### Breaking Changes

- Complete rewrite focused on simplicity and extensibility
- Drop majority of built-in plugins from v1.x
- New plugin API based on `Zen::Service::Plugins::Plugin`

### Added

- New core plugin architecture where even fundamental features are plugins
  - `:callable` - Provides `.call` and `.[]` class methods
  - `:attributes` - Manages service initialization parameters with runtime validation
- `:persisted_result` plugin - Provides `#result` method and `#called?` helper
- `:result_yielding` plugin - Enables nested service calls to return block-provided values
- Plugin lifecycle with `used` and `configure` callbacks
- Plugin inheritance and reconfiguration support
- Automatic plugin registration for modules extending `Plugin`
- Manual plugin registration via `Zen::Service::Plugins.register`

### Changed

3]: https://github.com/akuzko/zen-service/compare/v2.2.2...v2.2.3
[2.2.

- Simplified service object pattern focusing on essential functionality
- Improved plugin DSL with `register_as`, `default_options`, and `service_extension`
- Complete README rewrite with comprehensive examples

### Removed

- Most built-in plugins from v1.x for simplicity
- Removed legacy plugin APIs

[2.2.2]: https://github.com/akuzko/zen-service/compare/v2.2.1...v2.2.2
[2.2.1]: https://github.com/akuzko/zen-service/compare/v2.2.0...v2.2.1
[2.2.0]: https://github.com/akuzko/zen-service/compare/v2.1.0...v2.2.0
[2.1.0]: https://github.com/akuzko/zen-service/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/akuzko/zen-service/releases/tag/v2.0.0
