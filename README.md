# Zen::Service

Flexible and highly extensible Service Objects for business logic organization.

[![github release](https://img.shields.io/github/release/akuzko/zen-service.svg)](https://github.com/akuzko/zen-service/releases)

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

The very basic usage of `Zen` services can be shown with following example:

```rb
# app/services/todos/update.rb
module Todos
  class Update < ApplicationService # base class for app services, inherits from Zen::Service
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

# app/controllers/todos/controller
class TodosController < ApplicationController
  def update
    case Todos::Update.call(todo, params: todo_params)
    in [:ok, todo] then render json: Todos::Show.call(todo)
    in [:error, errors] then render json: errors, status: :unprocessable_content
    end
  end
end
```

### Service attributes

Read full version on [wiki](https://github.com/akuzko/zen-service/wiki#instantiating-service-with-attributes).

`Zen` services are initialized with _attributes_. To specify list of available attributes, use `attributes`
class method. All attributes are optional during service initialization. It is possible to omit keys during
initialization, and pass attributes as parameters - in this case attributes will be filled in correspondance
to the order they were defined. However, you cannot pass more attributes than declared attributes list, as
well as cannot pass single attribute multiple times (as parameter and as named attribute) or attributes that
were not declared with `attributes` class method.

```rb
class MyService < Zen::Service
  attributes :foo, :bar

  def call
    # do something
  end

  def foo
    super || 5
  end
end

s1 = MyService.new
s1.foo # => 5
s1.bar # => nil

s2 = MyService.new(6)
s2.foo # => 6

s3 = s2.with_attributes(foo: 1, bar: 2)
s3.foo # => 1
s3.bar # => 2
```

### Service Extensions (Plugins)

Read full version on [wiki](https://github.com/akuzko/zen-service/wiki/Plugins).

`zen-service` is built with extensions in mind. Even core functionality is organized in plugins that are
used in base `Zen::Service` class. Version 2.0.0 drops majority of built-in plugins for sake of
simplicity.

However, `zen-service` still provides a couple of helpfull plugins out-of-the-box:

- `:persisted_result` - provides `#result` method that returns value of the latest `#call`
  method call. Also provides `#called?` helper method.

- `:result_yielding` - can be used in junction with nested service calls to result with
  block-provided value instead of nested service `call` return value. For example:

  ```rb
    def call
      logger.call do # logger uses `:result_yielding` plugin
        todo.update!(params)
        [:ok, todo]
      rescue ActiveRecord::RecordInvalid
        [:error, todo.errors.messages]
      end
    end
  ```

Bellow you can see sample implementation of a plugin that transforms resulting objects
to camel-case notation (relying on ActiveSupport's core extensions)

```rb
module CamelizeResult
  extend Zen::Service::Plugin

  def self.used(service_class)
    service_class.prepend(Extension)
  end

  def self.camelize(obj)
    case obj
    when Array then obj.map { camelize(_1) }
    when Hash then obj.deep_transform_keys { _1.to_s.camelize(:lower).to_sym }
    else obj
    end
  end

  module Extension
    def call
      CamelizeResult.camelize(super)
    end
  end
end
```

and then

```rb
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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/akuzko/zen-service.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
