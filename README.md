# Excom

Flexible and highly extensible Commands (Service Objects) for business logic.

[![build status](https://secure.travis-ci.org/akuzko/excom.png)](http://travis-ci.org/akuzko/excom)
[![github release](https://img.shields.io/github/release/akuzko/excom.svg)](https://github.com/akuzko/excom/releases)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'excom'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install excom

## Preface

`Excom` stands for **Ex**excutable **Com**and. Initially, `Excom::Command` was the main
class, provided by the gem. But it seems that "Service" name become more popular and
common for describing classes for business logic, so it was renamed in this gem too.

## Usage

General idea behind every `excom` service is simple: each service can have arguments,
options (named arguments), and should define `execute!` method that is called during
service execution. Executed service has `status` and `result`.

The **very basic usage** of `Excom` services can be shown with following example:

```rb
# app/services/todos/update.rb
module Todos
  class Update < Excom::Command
    args :todo
    opts :params

    def execute!
      if todo.update(params)
        success { todo.as_json }
      else
        failure { todo.errors }
      end
    end
  end
end

# app/controllers/todos/controller
class TodosController < ApplicationController
  def update
    service = Todos::Update.new(todo, params: todo_params)

    if service.execute.success?
      render json: todo.result
    else
      render json: todo.cause, status: :unprocessable_entity
    end
  end
end
```

However, even this basic example can be highly optimized by using Excom extensions and helper methods.

### Service arguments and options

Read full version on [wiki](https://github.com/akuzko/excom/wiki#instantiating-command-with-arguments-and-options).

Excom services can be initialized with _arguments_ and _options_ (named arguments). To specify list
of available arguments and options, use `args` and `opts` class methods. All arguments and options
are optional during service initialization. However, you cannot pass more arguments to service or
options that were not declared with `opts` method.

```rb
class MyService < Excom::Service
  args :foo
  opts :bar

  def execute!
    # do something
  end

  def foo
    super || 5
  end
end

s1 = MyService.new
s1.foo # => 5
s1.bar # => nil

s2 = s1.with_args(1).with_opts(bar: 2)
s2.foo # => 1
s2.bar # => 2
```

### Service Execution

Read full version on [wiki](https://github.com/akuzko/excom/wiki#command-execution).

At the core of each service's execution lies `execute!` method. You can use `status` and/or
`result` methods to set execution status and result. If none were used, result and status
will be set based on `run` method's return value.

Example:

```rb
class MyService < Excom::Service
  alias_success :ok
  args :foo

  def execute!
    if foo > 2
      result ok: foo * 2
    else
      result failure: -1
    end
  end
end

service = MyService.new(3)
service.execute.success? # => true
service.status # => :ok
service.result # => 6
```

### Core API

Please read about core API and available class and instance methods on [wiki](https://github.com/akuzko/excom/wiki#core-api)

### Service Extensions (Plugins)

Read full version on [wiki](https://github.com/akuzko/excom/wiki/Plugins).

Excom is built with extensions in mind. Even core functionality is organized in plugins that are
used in base `Excom::Service` class. Bellow you can see a list of plugins with some description
and examples that are shipped with `excom`:

- [`:status_helpers`](https://github.com/akuzko/excom/wiki/Plugins#status-helpers) - Allows you to
define status aliases and helper methods named after them to immediately and more explicitly assign
both status and result at the same time:

```rb
class Todos::Update
  use :status_helpers, success: [:ok], failure: [:unprocessable_entity]
  args :todo, :params

  def execute!
    if todo.update(params)
      ok todo.as_json
    else
      unprocessable_entity todo.errors
    end
  end
end

service = Todos::Update.(todo, todo_params)
# in case params were valid you will have:
service.success? # => true
service.status # => :ok
service.result # => {'id' => 1, ...}
```

- [`:context`](https://github.com/akuzko/excom/wiki/Plugins#context) - Allows you to set an execution
context for a block that will be available to any service that uses this plugin via `context` method.

```rb
# application_controller.rb
around_action :with_context

def with_context
  Excom.with_context(current_user: current_user) do
    yield
  end
end
```

```rb
class Posts::Archive < Excom::Command
  use :context
  args :post

  def execute!
    post.update(archived: true, archived_by: context[:current_user])
  end
end
```

- [`:sentry`](https://github.com/akuzko/excom/wiki/Plugins#sentry) - Allows you to define sentry logic that
will allow or deny service's execution or other related checks. This logic can be defined inline in service
classes or in dedicated Sentry classes. Much like [pundit](https://github.com/elabs/pundit) Policies, but
more. Where pundit governs only authorization logic, Excom's Sentries can deny execution with any reason
you find appropriate.

```rb
class Posts::Destroy < Excom::Command
  use :context
  use :sentry

  args :post

  def execute!
    post.destroy
  end

  sentry delegate: [:context] do
    deny_with :unauthorized

    def execute?
      # only author can destroy a post
      post.author_id == context[:current_user].id
    end

    deny_with :unprocessable_entity do
      def execute?
        # disallow to destroy posts that are older than 1 hour
        (post.created_at + 1.hour).past?
      end
    end
  end
end
```

- [`:assertions`](https://github.com/akuzko/excom/wiki/Plugins#assertions) - Provides `assert` method that
can be used for different logic checks during service execution.

- [`:dry_types`](https://github.com/akuzko/excom/wiki/Plugins#dry-types) - Allows you to use
[dry-types](http://dry-rb.org/gems/dry-types/) attributes instead of default `args` and `opts`.

- [`:caching`](https://github.com/akuzko/excom/wiki/Plugins#caching) - Simple plugin that will prevent
re-execution of service if it already has been executed, and will immediately return result.

- [`:rescue`](https://github.com/akuzko/excom/wiki/Plugins#rescue) - Provides `:rescue` execution option.
If set to `true`, any error occurred during service execution will not be raised outside.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/akuzko/excom.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

