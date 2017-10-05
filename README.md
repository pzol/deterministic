# Deterministic
[![Gitter](https://badges.gitter.im/Join Chat.svg)](https://gitter.im/pzol/deterministic?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

[![Gem Version](https://badge.fury.io/rb/deterministic.png)](http://badge.fury.io/rb/deterministic)

Deterministic is to help your code to be more confident, by utilizing functional programming patterns.

This is a spiritual successor of the [Monadic gem](http://github.com/pzol/monadic). The goal of the rewrite is to get away from a bit too forceful aproach I took in Monadic, especially when it comes to coercing monads, but also a more practical but at the same time more strict adherence to monad laws.

## Patterns

Deterministic provides different monads, here is a short guide, when to use which

#### Result: Success & Failure
- an operation which can succeed or fail
- the result (content) of of the success or failure is important
- you are building one thing
- chaining: if one fails (Failure), don't execute the rest

#### Option: Some & None
- an operation which returns either some result or nothing
- in case it returns nothing it is not important to know why
- you are working rather with a collection of things
- chaining: execute all and then select the successful ones (Some)

#### Either: Left & Right
- an operation which returns several good and bad results
- the results of both are important
- chaining: if one fails, continue, the content of the failed and successful are important

#### Maybe
- an object may be nil, you want to avoid endless nil? checks

#### Enums (Algebraic Data Types)
- roll your own pattern

## Usage

### Result: Success & Failure

```ruby
Success(1).to_s                        # => "1"
Success(Success(1))                    # => Success(1)

Failure(1).to_s                        # => "1"
Failure(Failure(1))                    # => Failure(1)
```

Maps a `Result` with the value `a` to the same `Result` with the value `b`.

```ruby
Success(1).fmap { |v| v + 1}           # => Success(2)
Failure(1).fmap { |v| v - 1}           # => Failure(0)
```

Maps a `Result` with the value `a` to another `Result` with the value `b`.

```ruby
Success(1).bind { |v| Failure(v + 1) } # => Failure(2)
Failure(1).bind { |v| Success(v - 1) } # => Success(0)
```

Maps a `Success` with the value `a` to another `Result` with the value `b`. It works like `#bind` but only on `Success`.

```ruby
Success(1).map { |n| Success(n + 1) }  # => Success(2)
Failure(0).map { |n| Success(n + 1) }  # => Failure(0)
```
Maps a `Failure` with the value `a` to another `Result` with the value `b`. It works like `#bind` but only on `Failure`.

```ruby
Failure(1).map_err { |n| Success(n + 1) } # => Success(2)
Success(0).map_err { |n| Success(n + 1) } # => Success(0)
```

```ruby
Success(0).try { |n| raise "Error" }   # => Failure(Error)
```

Replaces `Success a` with `Result b`. If a `Failure` is passed as argument, it is ignored.

```ruby
Success(1).and Success(2)              # => Success(2)
Failure(1).and Success(2)              # => Failure(1)
```

Replaces `Success a` with the result of the block. If a `Failure` is passed as argument, it is ignored.

```ruby
Success(1).and_then { Success(2) }     # => Success(2)
Failure(1).and_then { Success(2) }     # => Failure(1)
```

Replaces `Failure a` with `Result`. If a `Failure` is passed as argument, it is ignored.

```ruby
Success(1).or Success(2)               # => Success(1)
Failure(1).or Success(1)               # => Success(1)
```

Replaces `Failure a` with the result of the block. If a `Success` is passed as argument, it is ignored.

```ruby
Success(1).or_else { Success(2) }      # => Success(1)
Failure(1).or_else { |n| Success(n)}   # => Success(1)
```

Executes the block passed, but completely ignores its result. If an error is raised within the block it will **NOT** be catched.

Try failable operations to return `Success` or `Failure`

```ruby
include Deterministic::Prelude::Result

try! { 1 }                             # => Success(1)
try! { raise "hell" }                  # => Failure(#<RuntimeError: hell>)
```

### Result Chaining

You can easily chain the execution of several operations. Here we got some nice function composition.  
The method must be a unary function, i.e. it always takes one parameter - the context, which is passed from call to call.

The following aliases are defined

```ruby
alias :>> :map
alias :<< :pipe
```

This allows the composition of procs or lambdas and thus allow a clear definiton of a pipeline.

```ruby
Success(params) >>
  validate >>
  build_request << log >>
  send << log >>
  build_response
```

#### Complex Example in a Builder Class

```ruby
class Foo
  include Deterministic
  alias :m :method # method conveniently returns a Proc to a method

  def call(params)
    Success(params) >> m(:validate) >> m(:send)
  end

  def validate(params)
    # do stuff
    Success(validate_and_cleansed_params)
  end

  def send(clean_params)
    # do stuff
    Success(result)
  end
end

Foo.new.call # Success(3)
```

Chaining works with blocks (`#map` is an alias for `#>>`)

```ruby
Success(1).map {|ctx| Success(ctx + 1)}
```

it also works with lambdas
```ruby
Success(1) >> ->(ctx) { Success(ctx + 1) } >> ->(ctx) { Success(ctx + 1) }
```

and it will break the chain of execution, when it encounters a `Failure` on its way

```ruby
def works(ctx)
  Success(1)
end

def breaks(ctx)
  Failure(2)
end

def never_executed(ctx)
  Success(99)
end

Success(0) >> method(:works) >> method(:breaks) >> method(:never_executed) # Failure(2)
```

`#map` aka `#>>` will not catch any exceptions raised. If you want automatic exception handling, the `#try` aka `#>=` will catch an error and wrap it with a failure

```ruby
def error(ctx)
  raise "error #{ctx}"
end

Success(1) >= method(:error) # Failure(RuntimeError(error 1))
```

### Chaining with #in_sequence

When creating long chains with e.g. `#>>`, it can get cumbersome carrying
around the entire context required for every function within the chain. Also,
every function within the chain requires some boilerplate code for extracting the
relevant information from the context.

Similarly to, for example, the `do` notation in Haskell and _sequence
comprehensions_ or _for comprehensions_ in Scala, `#in_sequence` can be used to
streamline the same process while keeping the code more readable. Using
`#in_sequence` provides all the benefits of using the `Result` monad while
still allowing to write code that reads very much like standard imperative
Ruby.

Here's an example:

```ruby
class Foo
  include Deterministic::Prelude

  def call(input)
    in_sequence do
      get(:sanitized_input) { sanitize(input) }
      and_then              { validate(sanitized_input) }
      get(:user)            { get_user_from_db(sanitized_input) }
      get(:request)         { build_request(sanitized_input, user) }
      observe               { log('sending request', request) }
      get(:response)        { send_request(request) }
      observe               { log('got response', response) }
      and_yield             { format_response(response) }
    end
  end

  def sanitize(input)
    sanitized_input = input
    Success(sanitized_input)
  end

  def validate(sanitized_input)
    Success(sanitized_input)
  end

  def get_user_from_db(sanitized_input)
    Success(type: :admin, id: sanitized_input.fetch(:id))
  end

  def build_request(sanitized_input, user)
    Success(input: sanitized_input, user: user)
  end

  def log(message, data)
    # logger.info(message, data)
  end

  def send_request(request)
    Success(status: 200)
  end

  def format_response(response)
    Success(response: response, message: 'it worked')
  end
end

Foo.new.call(id: 1)
```

Notice how the functions don't necessarily have to accept only a single
argument (`build_request` accepts 2). Also notice how the methods can be used
directly, without having to call `#method` or having them return procs.

The chain will still be short-circuited when e.g. `#validate` returns a
`Failure`.

Here's what the operators used in this example mean:
* `get` - Execute the provided block and expect a `Result` as its return value.
  If the `Result` is a `Success`, then the `Success` value is assigned to the
  specified identifier. The value is then accessible in subsequent blocks by
  that identifier. If the `Result` is a `Failure`, then the entire chain will
  be short-circuited and the `Failure` will be returned as the result of the
  `in_sequence` call.
* `and_then` - Execute the provided block and expect a `Result` as its return
  value. If the `Result` is a `Success`, then the chain continues, otherwise
  the chain is short-circuited and the `Failure` will be returned as the result
  of the `in_sequence` call.
* `observe` - Execute the provided block whose return value will be ignored.
  The chain continues regardless.
* `and_yield` - Execute the provided block and expect a `Result` as its return
  value. The `Result` will be returned as the result of the `in_sequence` call.

### Pattern matching
Now that you have some result, you want to control flow by providing patterns.
`#match` can match by

 * success, failure, result or any
 * values
 * lambdas
 * classes

```ruby
Success(1).match do
  Success() { |s| "success #{s}"}
  Failure() { |f| "failure #{f}"}
end # => "success 1"
```
Note1: the variant's inner value(s) have been unwrapped, and passed to the block.

Note2: only the __first__ matching pattern block will be executed, so order __can__ be important.

Note3: you can omit block parameters if you don't use them, or you can use `_` to signify that you don't care about their values. If you specify parameters, their number must match the number of values in the variant.

The result returned will be the result of the __first__ `#try` or `#let`. As a side note, `#try` is a monad, `#let` is a functor.

Guards

```ruby
Success(1).match do
  Success(where { s == 1 }) { |s| "Success #{s}" }
end # => "Success 1"
```

Note1: the guard has access to variable names defined by the block arguments.

Note2: the guard is not evaluated using the enclosing context's `self`; if you need to call methods on the enclosing scope, you must specify a receiver.

Also you can match the result class

```ruby
Success([1, 2, 3]).match do
  Success(where { s.is_a?(Array) }) { |s| s.first }
end # => 1
```

If no match was found a `NoMatchError` is raised, so make sure you always cover all possible outcomes.

```ruby
Success(1).match do
  Failure() { |f| "you'll never get me" }
end # => NoMatchError
```

Matches must be exhaustive, otherwise an error will be raised, showing the variants which have not been covered.

## core_ext
You can use a core extension, to include Result in your own class or in Object, i.e. in all classes.

```ruby
require 'deterministic/core_ext/object/result'

[1].success?        # => false
Success(1).failure? # => false
Success(1).success? # => true
Failure(1).result?  # => true
```

## Option

```ruby
Some(1).some?                          # #=> true
Some(1).none?                          # #=> false
None.some?                             # #=> false
None.none?                             # #=> true
```

Maps an `Option` with the value `a` to the same `Option` with the value `b`.

```ruby
Some(1).fmap { |n| n + 1 }             # => Some(2)
None.fmap { |n| n + 1 }                # => None
```

Maps a `Result` with the value `a` to another `Result` with the value `b`.

```ruby
Some(1).map  { |n| Some(n + 1) }       # => Some(2)
Some(1).map  { |n| None }              # => None
None.map     { |n| Some(n + 1) }       # => None
```

Get the inner value or provide a default for a `None`. Calling `#value` on a `None` will raise a `NoMethodError`

```ruby
Some(1).value                          # => 1
Some(1).value_or(2)                    # => 1
None.value                             # => NoMethodError
None.value_or(0)                       # => 0
```

Add the inner values of option using `+`.

```ruby
Some(1) + Some(1)                      # => Some(2)
Some([1]) + Some(1)                    # => TypeError: No implicit conversion
None + Some(1)                         # => Some(1)
Some(1) + None                         # => Some(1)
Some([1]) + None + Some([2])           # => Some([1, 2])
```

### Coercion
```ruby
Option.any?(nil)                       # => None
Option.any?([])                        # => None
Option.any?({})                        # => None
Option.any?(1)                         # => Some(1)

Option.some?(nil)                      # => None
Option.some?([])                       # => Some([])
Option.some?({})                       # => Some({})
Option.some?(1)                        # => Some(1)

Option.try! { 1 }                      # => Some(1)
Option.try! { raise "error"}           # => None
```

### Pattern Matching
```ruby
Some(1).match {
  Some(where { s == 1 }) { |s| s + 1 }
  Some()                 { |s| 1 }
  None()                 { 0 }
}                                      # => 2
```

## Enums
All the above are implemented using enums, see their definition, for more details.

Define it, with all variants:

```ruby
Threenum = Deterministic::enum {
            Nullary()
            Unary(:a)
            Binary(:a, :b)
           }

Threenum.variants                      # => [:Nullary, :Unary, :Binary]
```

Initialize

```ruby
n = Threenum.Nullary                   # => Threenum::Nullary.new()
n.value                                # => Error

u = Threenum.Unary(1)                  # => Threenum::Unary.new(1)
u.value                                # => 1

b = Threenum::Binary(2, 3)             # => Threenum::Binary(2, 3)
b.value                                # => { a:2, b: 3 }
```

Pattern matching

```ruby
Threenum::Unary(5).match {
  Nullary() {        0 }
  Unary()   { |u|    u }
  Binary()  { |a, b| a + b }
}                                      # => 5

# or
t = Threenum::Unary(5)
Threenum.match(t) {
  Nullary() {        0 }
  Unary()   { |u|    u }
  Binary()  { |a, b| a + b }
}                                      # => 5
```

If you want to return the whole matched object, you'll need to pass a reference to the object (second case). Note that `self` refers to the scope enclosing the `match` call.

```ruby
def drop(n)
  match {
    Cons(where { n > 0 }) { |h, t| t.drop(n - 1) }
    Cons()                { |_, _| self }
    Nil() { raise EmptyListError }
  }
end
```

See the linked list implementation in the specs for more examples

With guard clauses

```ruby
Threenum::Unary(5).match {
  Nullary() {     0 }
  Unary()   { |u| u }
  Binary(where { a.is_a?(Fixnum) && b.is_a?(Fixnum) }) { |a, b| a + b }
  Binary()  { |a, b| raise "Expected a, b to be numbers" }
}                                      # => 5
```

Implementing methods for enums

```ruby
Deterministic::impl(Threenum) {
  def sum
    match {
      Nullary() {        0 }
      Unary()   { |u|    u }
      Binary()  { |a, b| a + b }
    }
  end

  def +(other)
    match {
      Nullary() {        other.sum }
      Unary()   { |a|    self.sum + other.sum }
      Binary()  { |a, b| self.sum + other.sum }
    }
  end
}

Threenum.Nullary + Threenum.Unary(1)   # => Unary(1)
```

All matches must be exhaustive, i.e. cover all variants

## Maybe
The simplest NullObject wrapper there can be. It adds `#some?` and `#null?` to `Object` though.

```ruby
require 'deterministic/maybe' # you need to do this explicitly
Maybe(nil).foo        # => Null
Maybe(nil).foo.bar    # => Null
Maybe({a: 1})[:a]     # => 1

Maybe(nil).null?      # => true
Maybe({}).null?       # => false

Maybe(nil).some?      # => false
Maybe({}).some?       # => true
```

## Mimic

If you want a custom NullObject which mimicks another class.

```ruby
class Mimick
  def test; end
end

naught = Maybe.mimick(Mimick)
naught.test             # => Null
naught.foo              # => NoMethodError
```

## Inspirations
 * My [Monadic gem](http://github.com/pzol/monadic) of course
 * `#attempt_all` was somewhat inspired by [An error monad in Clojure](http://brehaut.net/blog/2011/error_monads) (attempt all has now been removed)
 * [Pithyless' rumblings](https://gist.github.com/pithyless/2216519)
 * [either by rsslldnphy](https://github.com/rsslldnphy/either)
 * [Functors, Applicatives, And Monads In Pictures](http://adit.io/posts/2013-04-17-functors,_applicatives,_and_monads_in_pictures.html)
 * [Naught by avdi](https://github.com/avdi/naught/)
 * [Rust's Result](http://static.rust-lang.org/doc/master/std/result/enum.Result.html)

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
