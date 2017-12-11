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

## Usage

General idea behind every `excom` command is simple: each command can have arguments,
options (named arguments), and should define `run` method that is called during
command execution. Executed command has `status` and `result`.

The **very basic usage** of `Excom` commands can be shown with following example:

```rb
# app/commands/todos/update.rb
module Todos
  class Update < Excom::Command
    args :todo
    opts :params

    def run
      if todo.update(params)
        result success: todo.as_json
      else
        result failure: todo.errors
      end
    end
  end
end

# app/controllers/todos/controller
class TodosController < ApplicationController
  def update
    command = Todos::Update.new(todo, params: todo_params)

    if command.execute.success?
      render json: todo.result
    else
      render json: todo.result, status: :unprocessable_entity
    end
  end
end
```

However, even this basic example can be highly optimized by using Excom extensions and helper methods.

### Command arguments and options

Read full version on [wiki](https://github.com/akuzko/excom/wiki#instantiating-command-with-arguments-and-options).

Excom commands can be initialized with _arguments_ and _options_ (named arguments). To specify list
of available arguments and options, use `args` and `opts` class methods. All arguments and options
are optional during command initialization. However, you cannot pass more arguments to command or
options that were not declared with `opts` method.

```rb
class MyCommand < Excom::Command
  args :foo
  opts :bar

  def run
    # do something
  end

  def foo
    super || 5
  end
end

c1 = MyCommand.new
c1.foo # => 5
c1.bar # => nil

c2 = c1.with_args(1).with_opts(bar: 2)
c2.foo # => 1
c2.bar # => 2
```

### Command Execution

Read full version on [wiki](https://github.com/akuzko/excom/wiki#command-execution).

At the core of each command's execution lies `run` method. You can use `status` and/or
`result` methods to set execution status and result. If none were used, result and status
will be set based on `run` method's return value.

Example:

```rb
class MyCommand < Excom::Command
  alias_success :ok
  args :foo

  def run
    if foo > 2
      result ok: foo * 2
    else
      result failure: -1
    end
  end
end

command = MyCommand.new(3)
command.execute.success? # => true
command.status # => :ok
command.result # => 6
```

### Core API

Please read about core API and available class and instance methods on [wiki](https://github.com/akuzko/excom/wiki#core-api)

### Command Extensions (Plugins)

Read full version on [wiki](https://github.com/akuzko/excom/wiki/Plugins).

Excom is built with extensions in mind. Even core functionality is organized in plugins that are
used in base `Excom::Command` class. Bellow you can see a list of plugins with some description
and examples that are shipped with `excom`:

- [`:status_helpers`](https://github.com/akuzko/excom/wiki/Plugins#status-helpers) - Allows you to
define status aliases and helper methods named after them to immediately and more explicitly assign
both status and result at the same time:

```rb
class Todos::Update
  use :status_helpers, success: [:ok], failure: [:unprocessable_entity]
  args :todo, :params

  def run
    if todo.update(params)
      ok todo.as_json
    else
      unprocessable_entity todo.errors
    end
  end
end

command = Todos::Update.(todo, todo_params)
# in case params were valid you will have:
command.success? # => true
command.status # => :ok
command.result # => {'id' => 1, ...}
```

- [`:context`](https://github.com/akuzko/excom/wiki/Plugins#context) - Allows you to set an execution
context for a block that will be available to any command that uses this plugin via `context` method.

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

  def run
    post.update(archived: true, archived_by: context[:current_user])
  end
end
```

- [`:sentry`](https://github.com/akuzko/excom/wiki/Plugins#sentry) - Allows you to provide Sentry classes
for commands that use this plugin. Each Sentry class hosts logic responsible for allowing or denying
corresponding command's execution or related checks. Much like [pundit](https://github.com/elabs/pundit)
Policies, but more. Where pundit governs only authorization logic, Excom's Sentries can deny execution
with any reason you find appropriate.

```rb
class Posts::Destroy < Excom::Command
  use :context
  use :sentry
  args :post

  def run
    post.destroy
  end
end

class Posts::DestroySentry < Excom::Sentry
  delegate :post, :context, to: :command
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
```

- [`:assertions`](https://github.com/akuzko/excom/wiki/Plugins#assertions) - Provides `assert` method that
can be used for different logic checks during command execution.

- [`:caching`](https://github.com/akuzko/excom/wiki/Plugins#caching) - Simple plugin that will prevent
re-execution of command if it already has been executed, and will immediately return result.

- [`:rescue`](https://github.com/akuzko/excom/wiki/Plugins#rescue) - Provides `:rescue` execution option.
If set to `true`, any error occurred during command execution will not be raised outside.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/akuzko/excom.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

