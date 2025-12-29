# Copilot Instructions for zen-service

## Project Overview

`zen-service` is a Ruby gem providing a flexible, plugin-based service object pattern. The architecture emphasizes extensibility through a plugin system where even core functionality (callable, attributes) is implemented as plugins.

## Architecture Fundamentals

### Plugin System

The entire gem is built around `Zen::Service::Plugins` - a dynamic plugin registration and loading system:

- Plugins auto-register using `extend Zen::Service::Plugins::Plugin` (converts module name to snake_case key)
- Services use plugins via `use :plugin_name, **options`
- Plugin lifecycle (first use): `used(service_class)` → includes module → `configure(service_class)` if defined
- Plugin reconfiguration (ancestor already used): only `configure(service_class)` is called, module not re-included
- See [plugin.rb](lib/zen/service/plugins/plugin.rb) for the DSL: `register_as`, `default_options`, `service_extension`

### Core Plugins Architecture

Base `Zen::Service` uses two foundational plugins:

- `:callable` - provides `.call` and `.[]` class methods that instantiate + call
- `:attributes` - manages initialization parameters with runtime validation

### Service Attributes Pattern

Attributes are positional-or-named parameters resolved during initialization:

```ruby
attributes :foo, :bar
new(1, bar: 2) # foo=1, bar=2
new(foo: 1)    # foo=1, bar=nil
```

- Attributes generate reader methods dynamically in a dedicated `AttributeMethods` module
- Each service class gets its own `AttributeMethods` constant to isolate attribute methods
- `with_attributes(hash)` creates clones with merged attributes

## Development Workflow

### Running Tests

```bash
bundle exec rspec spec          # Run all specs
bundle exec rspec spec/zen/service_spec.rb  # Single file
rake                            # Run specs + rubocop
```

### Test Patterns

- Use `def_service { ... }` helper to define service classes in specs (see [spec_helper.rb](spec/spec_helper.rb))
- `build_service(*args, **kwargs)` instantiates service with attributes
- Services are frozen_string_literal by convention

### Building & Releasing

```bash
rake build                      # Build gem to pkg/
rake install                    # Install locally
rake release                    # Tag + push to rubygems.org
```

## Key Conventions

### Plugin Implementation Pattern

1. Create module in `lib/zen/service/plugins/`
2. `extend Zen::Service::Plugins::Plugin` (auto-registers)
3. Define `used(service_class, **opts, &block)` for one-time setup
4. Define `configure(service_class, **opts, &block)` for reconfiguration
5. Use `prepend Extension` (for wrapping `call`) or `include` (for adding methods)
6. Add `ClassMethods` module for class-level functionality

Example from [result_yielding.rb](lib/zen/service/plugins/result_yielding.rb):

```ruby
module ResultYielding
  extend Plugin

  module Extension
    def call
      return super unless block_given?
      result = nil
      super { result = yield }
      result
    end
  end

  def self.used(service_class)
    service_class.prepend(Extension)
  end
end
```

### Plugin Option Handling

- Use `default_options foo: 5` in plugin definition
- Access via `self.class.plugins[:plugin_name].options[:foo]`
- Options merge with defaults when using plugin
- Blocks passed to `use` are stored in `reflection.block`, separate from options (not polluting options hash)

### Plugin Inheritance & Reconfiguration

- When a child class uses a plugin already used by an ancestor, only `configure` callback is invoked (not `used`)
- This allows child classes to reconfigure plugin behavior without re-including the module
- Example: `BaseService` uses `:persisted_result` with default options, `ChildService` can reconfigure with different options

### Inheritance Behavior

- `attributes_list` is duplicated on inheritance
- Each subclass gets its own `AttributeMethods` module
- Plugin reflections accumulate through `ancestors.flat_map(&:service_plugins)`

## Critical Implementation Details

### Why Prepend vs Include

- `prepend Extension` - use when wrapping `call` method (allows `super` to reach original)
- `include` - use for adding new methods
- See `:result_yielding` (prepend) vs `:persisted_result` (extend in initialize)

### Attributes Resolution Edge Cases

- Cannot pass same attribute as both positional and named
- Cannot pass more attributes than declared
- Args filled in declaration order, then kwargs merged

### Plugin DSL Methods

From [plugin.rb](lib/zen/service/plugins/plugin.rb):

- `register_as :custom_name` - override auto-generated registration name
- `default_options hash` - set default plugin options
- `service_extension module` - extend `Zen::Service` base class globally

## Files of Note

- [plugins.rb](lib/zen/service/plugins.rb) - central plugin registry with `fetch` and `register`
- [pluggable.rb](lib/zen/service/plugins/pluggable.rb) - `use` DSL and plugin reflection system
- [spec_helper.rb](spec/spec_helper.rb) - `def_service` pattern for testing services
