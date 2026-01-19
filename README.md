# Zen::Service

Flexible and highly extensible Service Objects for business logic organization.

[![Gem Version](https://img.shields.io/gem/v/zen-service.svg)](https://rubygems.org/gems/zen-service)
[![CI Status](https://github.com/akuzko/zen-service/actions/workflows/ci.yml/badge.svg)](https://github.com/akuzko/zen-service/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/akuzko/zen-service/branch/master/graph/badge.svg)](https://codecov.io/gh/akuzko/zen-service)
[![Ruby Version](https://img.shields.io/badge/ruby-%3E%3D%203.2-ruby.svg)](https://www.ruby-lang.org)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'zen-service'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install zen-service

## Usage

The most basic usage of `Zen::Service` can be demonstrated with the following example:

```ruby
# app/services/todos/update.rb
module Todos
  class Update < ApplicationService # Base class for app services, inherits from Zen::Service
    attributes :todo, :params

    def call
      if todo.update(params)
        [:ok, todo]
      else
        [:error, todo.errors.messages]
      end
    end
  end
end

# app/controllers/todos_controller.rb
class TodosController < ApplicationController
  def update
    case Todos::Update.call(todo, params: todo_params)
    in [:ok, todo] then render json: Todos::Show.call(todo)
    in [:error, errors] then render json: errors, status: :unprocessable_content
    end
  end
end
```

### Service Attributes

`Zen::Service` instances are initialized with _attributes_. To specify the list of available attributes, use the `attributes`
class method. All attributes are optional during initialization. You can omit keys and pass attributes as positional
parameters—they will be assigned in the order they were declared. However, you cannot:

- Pass more attributes than declared
- Pass the same attribute multiple times (both as positional and keyword argument)
- Pass undeclared attributes

```ruby
class MyService < Zen::Service
  attributes :foo, :bar

  def call
    # Your business logic here
  end

  def foo
    super || 5 # Provide default value
  end
end

# Different ways to initialize services
s1 = MyService.new
s1.foo # => 5
s1.bar # => nil

s2 = MyService.new(6)
s2.foo # => 6
s2.bar # => nil

s3 = MyService.new(foo: 1, bar: 2)
s3.foo # => 1
s3.bar # => 2

# Create a new service from an existing one with some attributes changed
s4 = s3.with_attributes(bar: 3)
s4.foo # => 1
s4.bar # => 3

# Create a service from another service's attributes
s5 = MyService.from(s3)
s5.foo # => 1
s5.bar # => 2
```

### Service Extensions (Plugins)

`zen-service` is built with extensibility at its core. Even fundamental functionality like callable behavior
and attributes are implemented as plugins. The base `Zen::Service` class uses two core plugins:

- `:callable` - Provides class methods `.call` and `.[]` that instantiate and call the service
- `:attributes` - Manages service initialization parameters with runtime validation

In addition, `zen-service` provides optional built-in plugins:

#### `:persisted_result`

Provides `#result` method that returns the value from the most recent `#call` invocation, along with a
`#called?` helper method.

**Options:**

- `call_unless_called: false` (default) - When `true`, accessing `service.result` will automatically
  call `#call` if it hasn't been called yet.

```ruby
class MyService < Zen::Service
  use :persisted_result, call_unless_called: true

  attributes :value

  def call
    value * 2
  end
end

service = MyService.new(5)
service.called? # => false
service.result  # => 10 (automatically calls #call)
service.called? # => true
```

#### `:result_yielding`

Enables nested service calls to return block-provided values instead of the nested service's return value.
Useful for wrapping service calls with cross-cutting concerns like logging or error handling.

```ruby
class Logger < Zen::Service
  use :result_yielding

  # Will result with value return by `yield` expression
  def call
    Rails.logger.info("Starting operation")
    result = yield
    Rails.logger.info("Operation completed: #{result.inspect}")
  end
end

class UpdateTodo < Zen::Service
  attributes :todo, :params

  def call
    Logger.call do
      todo.update!(params)
      [:ok, todo]
    rescue ActiveRecord::RecordInvalid
      [:error, todo.errors.messages]
    end
  end
end
```

### Creating Custom Plugins

Creating custom plugins is straightforward. Below is an example of a plugin that transforms results to
camelCase notation (using ActiveSupport's core extensions):

```ruby
module CamelizeResult
  extend Zen::Service::Plugins::Plugin

  def self.used(service_class)
    service_class.prepend(Extension)
  end

  def self.camelize(obj)
    case obj
    when Array then obj.map { |item| camelize(item) }
    when Hash then obj.deep_transform_keys { |key| key.to_s.camelize(:lower).to_sym }
    else obj
    end
  end

  module Extension
    def call
      CamelizeResult.camelize(super)
    end
  end
end

class Todos::Show < Zen::Service
  attributes :todo

  use :camelize_result

  def call
    {
      id: todo.id,
      is_completed: todo.completed?
    }
  end
end

Todos::Show[todo] # => { id: 1, isCompleted: true }
```

#### Plugin Registration

Plugins that extend `Zen::Service::Plugins::Plugin` are automatically registered when the module is loaded.
You can also register plugins manually:

```ruby
# Register a plugin module
Zen::Service::Plugins.register(:my_plugin, MyPlugin)

# Register by class name (useful when autoload isn't available yet, e.g., during Rails initialization)
Zen::Service::Plugins.register(:my_plugin, "MyApp::Services::MyPlugin")
```

#### Plugin Lifecycle

When using a plugin on a service class:

- **First use**: Both `used` and `configure` callbacks are invoked, and the module is included
- **Inheritance**: If a plugin was already used by an ancestor class, only `configure` is called,
  allowing reconfiguration without re-including the module

This design enables child classes to customize inherited plugin behavior:

```ruby
class BaseService < Zen::Service
  use :persisted_result, call_unless_called: false
end

class ChildService < BaseService
  use :persisted_result, call_unless_called: true  # Reconfigures without re-including
end
```

#### Plugin DSL

Plugins can use several DSL methods when extending `Zen::Service::Plugins::Plugin`:

```ruby
module MyPlugin
  extend Zen::Service::Plugins::Plugin

  # Override the auto-generated registration name
  register_as :custom_name

  # Set default options
  default_options foo: 5, bar: false

  # Called when plugin is first used on a class
  def self.used(service_class, **options, &block)
    # Include/prepend modules, add class methods, etc.
  end

  # Called every time the plugin is used (including on child classes)
  def self.configure(service_class, **options, &block)
    # Configure behavior based on options
  end
end
```

## Testing

The gem has 100% test coverage with both line and branch coverage. To run the test suite:

```bash
bundle exec rspec
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rspec` to run
the tests. You can also run `bin/console` for an interactive prompt that allows you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/akuzko/zen-service.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
