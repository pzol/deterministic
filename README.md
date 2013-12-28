# Deterministic

This is a spiritual successor of the [Monadic gem](http://github.com/pzol/monadic). 

This gem is still __WORK IN PROGRESS__.

## Usage

### Either#attempt_all
The basic idea is to execute a chain of units of work and make sure all return either `Success` or `Failure`.

```ruby
Either.attempt_all do
  try { 1 }
  try { |prev| prev + 1 }
end # => Success(2)
```
Take notice, that the result of of unit of work will be passed to the next one. So the result of prepare_somehing will be something in the second try.

If any of the units of work in between fail, the rest will not be executed and the last `Failure` will be returned.

```ruby
Either.attempt_all do
  try { 1 }
  try { raise "error" }
  try { 2 }
end # => Failure(RuntimeError("error"))
```

However, the real fun starts if you use it with your own context. You can use this as a state container (meh!) or to pass a dependency locator:

```ruby
  class Context
    attr_accessor :env, :settings
    def some_service
    end
  end

  # exemplary unit of work
  module LoadSettings
    def self.call(env)
      settings = load(env)
      settings.nil? ? Failure('could not load settings') : Success(settings)
    end

    def load(env)
    end
  end

  Either.attempt_all(context) do
    # this unit of work explicitly returns success or failure
    # no exceptions are catched and if they occur, well, they behave as expected
    # methods from the context can be accessed, the use of self for setters is necessary
    let { self.settings = LoadSettings.call(env) }

    # with #try all exceptions will be transformed into a Failure
    try { do_something }
  end
```

### Pattern matching
Now that you have some result, you want to control flow by providing patterns.

```ruby
Success(1).match do
  success { |v| "success #{v}"}
  failure { |v| "failure #{v}"}
  either  { |v| "either #{v}"}
end # => "either 1"
```
Note1: the inner value has been unwrapped! 
Note2: only the last matching pattern block will be executed

The result returned will be the result of the last `#try` or `#let`

Values for patterns are good:

```ruby
Success(1).match do
  success(1) { "Success #{v}" }
end # => "Success 1"
```

You can and should also use procs for patterns:

```ruby
Success(1).match do
  success ->(v) { v == 1} { "Success #{v}" }
end # => "Success 1"
```

Combining `#attempt_all` and `#match` is the ultimate sophistication:

```ruby
Either.attempt_all do
  try { 1 }
  try { |v| v + 1 }
end.match do
  success(1) { |v| "We made it to step #{v}" }
  success(2) { |v| "The correct answer is #{v}"}
end # => "The correct answer is 2"
```

If no match was found a `NoMatchError` is raised, so make sure you always cover all possible outcomes.

```ruby
Success(1).match do
  failure(1) { "you'll never get me" }
end # => NoMatchError
```

A way to have a catch-all would be using an `either`:

```ruby
Success(1).match do
  either { "catch-all" }
end # => "catch-all"
```

## Inspirations
 * My [Monadic gem](http://github.com/pzol/monadic) of course
 * `#attempt_all` was somewhat inspired by [An error monad in Clojure](http://brehaut.net/blog/2011/error_monads)
 * [Pithyless' rumblings](https://gist.github.com/pithyless/2216519) 
 * [either by rsslldnphy](https://github.com/rsslldnphy/either)

## Installation

Add this line to your application's Gemfile:

    gem 'deterministic'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install deterministic

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
