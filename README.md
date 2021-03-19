# Zen::Service

Flexible and highly extensible Service Objects for business logic organization.

[![build status](https://secure.travis-ci.org/akuzko/zen-service.png)](http://travis-ci.org/akuzko/zen-service)
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

## Preface

From the beginning of Rails times, proper business logic code organization has always
been a problem. Some code was placed in models, some in controllers, and complexity of
both made applications hard to maintain. Then, patterns like "decorators", "facades" and
"presenters" appeared to take care of certain part of logic. Finally, multiple service
object solutions were proposed by many developers. This gem is one of such solutions, but
with a significant difference.

`Zen` services are aimed to take care of *all* business logic in your application, no
matter what it is aimed for, and how complicated it is. From simplest cases of managing
single model, to the most complicated logic related with external requests, `Zen` services
got you covered. They are highly extendable due to plugin-based approach, composable and
debuggable.

Side note: as can be seen from commit history, this gem was initially called as `excom`,
which stood for **Ex**ecutable **Com**and.

## Usage

General idea behind every `Zen` service is simple: each service can have optional attributes,
and should define `execute!` method that is called during service execution. Executed service
responds to `success?` and has `result`.

The very basic usage of `Zen` services can be shown with following example:

```rb
# app/services/todos/update.rb
module Todos
  class Update < Zen::Service
    attributes :todo, :params

    delegate :errors, to: :todo

    def execute!
      todo.update(params)
    end
  end
end

# app/controllers/todos/controller
class TodosController < ApplicationController
  def update
    service = Todos::Update.new(todo, params: todo_params)

    if service.execute.success?
      # class .[] method initializes service with passed arguments, executes it and returns it's result
      render json: Todos::Show[service.result]
    else
      render json: service.errors, status: service.status
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

s2 = MyService.new(6)
s2.foo # => 6

s3 = s2.with_attributes(foo: 1, bar: 2)
s3.foo # => 1
s3.bar # => 2
```

### Service Execution

Read full version on [wiki](https://github.com/akuzko/zen-service/wiki#service-execution).

At the core of each service's execution lies `execute!` method. By default, you can use
`success`, `failure` and `result` methods to set execution success flag and result. If none
were used, result and success flag will be set based on `execute!` method's return value.

Example:

```rb
class Users::Create < Zen::Service
  attributes :params

  def execute!
    result { User.create(params) } # explicit result assignment

    send_invitation_email if success?
  end
end

class Users::Update < Zen::Service
  attributes :user, :params

  def execute!
    user.update(params) # implicit result assignment
  end
end

service = Users::Create.new(valid_params)
service.execute.success? # => true
service.result # => instance of User
```

### Core API

Please read about core API and available class and instance methods on [wiki](https://github.com/akuzko/zen-service/wiki#core-api)

### Service Extensions (Plugins)

Read full version on [wiki](https://github.com/akuzko/zen-service/wiki/Plugins).

`zen-service` is built with extensions in mind. Even core functionality is organized in plugins that are
used in base `Zen::Service` class. Bellow you can see a list of plugins with some description
and examples that are shipped with the gem:

- [`:status`](https://github.com/akuzko/zen-service/wiki/Plugins#status) - Adds `status` execution state
property to the service, as well as helper methods and behavior to set it. `status` property is not
bound to the "success" flag of execution state and can have any value depending on your needs. It
is up to you to setup which statuses correspond to successful execution and which are not. Generated
status helper methods allow to atomically and more explicitly assign both status and result at
the same time:

```rb
class Posts::Update < Zen::Service
  use :status,
    success: [:ok],
    failure: [:unprocessable_entity]

  attributes :post, :params

  delegate :errors, to: :post

  def execute!
    if post.update(params)
      ok { post.as_json }
    else
      unprocessable_entity
    end
  end
end

service = Posts::Update.(post, post_params)
# in case params were valid you will have:
service.success? # => true
service.status # => :ok
service.result # => {'id' => 1, ...}
```

Note that just like `success`, `failure`, or `result` methods, status helpers accept result value
as result of yielded block.

- [`:context`](https://github.com/akuzko/zen-service/wiki/Plugins#context) - Allows you to set an execution
context for a block that will be available to any service that uses this plugin via `context` method.

```rb
# application_controller.rb
around_action :with_context

def with_context
  Zen::Service.with_context(current_user: current_user) do
    yield
  end
end
```

```rb
class Posts::Archive < Zen::Service
  use :context

  attributes :post

  def execute!
    post.update(archived: true, archived_by: context[:current_user])
  end
end
```

- [`:policies`](https://github.com/akuzko/zen-service/wiki/Plugins#policies) - Allows you to define permission
checks within a service that can be used in other services for checks and guard violations. Much like
[pundit](https://github.com/elabs/pundit) Policies (hence the name), but more. Where pundit governs only
authorization logic, `zen-service`'s "policy" services can have any denial reason you find appropriate, and declare
logic for different denial reasons in single place. It also defines `#execute!` method that will result in
hash with all permission checks.

```rb
class Posts::Policies < Zen::Service
  use :policies

  attributes :post, :user

  deny_with :unauthorized do
    def publish?
      # only author can publish a post
      post.author_id == user.id
    end

    def delete?
      publish?
    end
  end

  deny_with :unprocessable_entity do
    def delete?
      # disallow to destroy posts that are older than 1 hour
      (post.created_at + 1.hour).past?
    end
  end
end

policies = Posts::Policies.new(outdated_post, user)
policies.can?(:publish)     # => true
policies.can?(:delete)      # => false
policies.why_cant?(:delete) # => :unprocessable_entity
policies.guard!(:delete)    # => raises Zen::Service::Plugins::Policies::GuardViolationError, :unprocessable_entity
policies.execute.result     # => {'publish' => true, 'delete' => false}
```

- [`:assertions`](https://github.com/akuzko/zen-service/wiki/Plugins#assertions) - Provides `assert` method that
can be used for different logic checks during service execution.

- [`:execution_cache`](https://github.com/akuzko/zen-service/wiki/Plugins#execution_cache) - Simple plugin that will prevent
re-execution of service if it already has been executed, and will immediately return result.

- [`:rescue`](https://github.com/akuzko/zen-service/wiki/Plugins#rescue) - Provides `:rescue` execution option.
If set to `true`, any error occurred during service execution will not be raised outside.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/akuzko/zen-service.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

