# Excom

Commands (Service Objects) for your business logic that can cover all your needs.

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

### Command Extensions (Plugins)

Excom is built with extensions in mind. Even core functionality is organized in plugins that are
used in base `Excom::Command` class.

#### `:args` (built-in)

Adds ability for command to accept _arguments_ and _options_ . Also adds reader helper methods.
All arguments and options are optional during command initialization. However, you cannot
pass more arguments to command or options that were not declared with `opts` method.

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

#### `:executable` (built-in)

This plugin is responsible for command execution logic, it defines methods that allow to execute command,
read and write it's result and status, and some helper methods. At the core of each command's execution
lies `run` method. You can use `status` and/or `result` methods to set execution status and result. If none
were used, result and status will be set based on `run` method's return value:

- set both status and result explicitly:

```rb
class MyCommand < Excom::Command
  def run
    result ok: 5
  end
end

command = MyCommand.new.execute
command.status # => :ok
command.result # => 5
```

- set only result:

```rb
  def run
    result 5
  end
# ...
command.status # => :success
command.result # => 5
```

- if result has falsy value, execution status will be considered as failure:

```rb
  def run
    result nil
  end
# ...
command.status # => :failure
command.result # => nil
```

- set only status

```rb
  def run
    status :success
  end
# ...
command.status # => :success
command.result # => nil
```

- if no `status` nor `result` were called, those values are set based on `run` return value:

```rb
  def run
    5
  end
# ...
command.status # => :success
command.result # => 5
```

Keep in mind that by default, unless any plugins, such as `:status_helpers` (see bellow) are used,
any non-`:success` status will be considered as failed, i.e.:

```rb
command.status # => :ok
command.success? # => false
```

##### Important `ClassMethods` Helpers

- `.call(*args)` - instantiates a service with `args` and executes it immediately:

```rb
command = MyCommand.(:foo, bar: :baz) # => is the same as:
# command = MyCommand.new(:foo, bar: :baz).execute
```

- `[](*args)` - instantiates a service with `args`, executes it and returns it's execution result:

```rb
result = MyCommand[:foo, bar: :baz] # => is the same as
# result = MyCommand.new(:foo, bar: :baz).execute.result
```

#### `:status_helpers`

Allows you to define status aliases and helper methods named after them to immediately
and more explicitly assign both status and result at the same time:

```rb
class Todos::Update
  use :helper_methods, success: [:ok], failure: [:unprocessable_entity]
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
command.result # => Todo object
```

To use globally:

```rb
Excom::Command.use :status_helpers,
  success: [:ok, :no_content],
  failure: [:unauthorized, :unprocessable_entity]
```

#### `:context`

Allows you to set an execution context for a block that will be available to any command that uses this plugin
via `context` method. To provide a context, use "global" `Excom.with_context` method:

```rb
# application_controller.rb
around_action :with_context

def with_context
  Excom.with_context(user: current_user) do
    yield
  end
end
```

```rb
class Posts::Archive < Excom::Command
  use :context
  args :post

  def run
    post.update(archived: true, archived_by: context[:user])
  end
end
```

you can also set a local context for instantiated command:

```
command = Posts::Archive.new(post)
command.context # => nil
command_with_user = command.with_context(user: admin)
command_with_user.context # => {:user => <User record>}
# previous command remains untouched:
command.context # => nil
```

To use globally:

```rb
Excom::Command.use :context
```

It is generally recommended to use [`Hashie::Mash`](https://github.com/intridea/hashie#mash) object as
context for convenient access to it's content.

#### `:sentry`

This plugin allows you to provide Sentry classes for commands that use this plugin. Each Sentry class hosts
logic responsible for allowing or denying corresponding service's execution or related checks. Much like
[pundit](https://github.com/elabs/pundit) Policies, but more. Where pundit governs only authorization logic,
Excom's Sentries can deny execution with any reason you find appropriate. For example:

```rb
class Posts::Destroy < Excom::Command
  use :context
  use :sentry
  args :post

  def run
    post.destroy
  end

  def user
    context[:user]
  end
end

class Posts::DestroySentry < Excom::Sentry
  delegate :post, :user, to: :command
  deny_with :unauthorized

  def execute?
    # only author can destroy a post
    post.author_id == user.id
  end

  deny_with :unprocessable_entity do
    def execute?
      # disallow to destroy posts that are older than 1 hour
      (post.created_at + 1.hour).past?
    end
  end
end

command = Posts::Destroy.new(post)

# if post doesn't belong to a user in context you will get:
command.execute.success? # => false
command.status # => :unauthorized

# if post is too old you will get:
command.execute.success? # => false
command.status # => :unprocessable_entity
```

Your command object in this case also gets helper methods according to sentry definitions, for example:

```rb
command.can?(:execute) # => false
command.why_cant(:execute) # => :unauthorized
```

All sentry's public methods ending with `?` can be used for such checks. Also, to get return values for
all such methods at once, you can use `#as_json` method:

```rb
command.sentry.as_json # => {:execute => false}
```

It is highly recommended to use this plugin together with `:context` plugin.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/akuzko/excom.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

