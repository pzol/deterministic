# Deterministic

[![Gem Version](https://badge.fury.io/rb/deterministic.png)](http://badge.fury.io/rb/deterministic)

Deterministic is to help your code to be more confident, it's specialty is flow control of actions that either succeed or fail.

This is a spiritual successor of the [Monadic gem](http://github.com/pzol/monadic). The goal of the rewrite is to get away from a bit to forceful aproach I took in Monadic, especially when it comes to coercing monads, but also a more practical but at the same time more strict adherence to monad laws.


## Usage

### Result: Success & Failure

```ruby
Success(1).to_s                        # => "1"
Success(Success(1))                    # => Success(1)

Failure(1).to_s                        # => "1"
Failure(Failure(1))                    # => Failure(1)
```

#### `fmap(self: Result(a), op: |a| -> b) -> Result(b)`

Maps a `Result` with the value `a` to the same `Result` with the value `b`.

```ruby
Success(1).fmap { |v| v + 1}           # => Success(2)
Failure(1).fmap { |v| v - 1}           # => Failure(0)
```

#### `bind(self: Result(a), op: |a| -> Result(b)) -> Result(b)`

Maps a `Result` with the value `a` to another `Result` with the value `b`.

```ruby
Success(1).bind { |v| Failure(v + 1) } # => Failure(2)
Failure(1).fmap { |v| Success(v - 1) } # => Success(0)
```

#### `map(self: Success(a), op: |a| -> Result(b)) -> Result(b)`

Maps a `Success` with the value `a` to another `Result` with the value `b`. It works like `#bind` but only on `Success`.

```ruby
Success(1).map { |n| n + 1 }           # => Success(2)
Failure(0).map { |n| n + 1 }           # => Failure(0)
```

#### `map_err(self: Failure(a), op: |a| -> Result(b)) -> Result(b)`

Maps a `Failure` with the value `a` to another `Result` with the value `b`. It works like `#bind` but only on `Failure`.

```ruby
Failure(1).map_err { |n| n + 1 } # => Success(2)
Success(0).map_err { |n| n + 1 } # => Success(0)
```

#### `try(self: Success(a),  op: |a| -> Result(b)) -> Result(b)`

Just like `#map`, transforms `a` to another `Result`, but it will also catch raised exceptions and wrap them with a `Failure`.

```ruby
Success(0).try { |n| raise "Error" }   # => Failure(Error)
```

#### `and(self: Success(a), other: Result(b)) -> Result(b)`

Replaces `Success a` with `Result b`. If a `Failure` is passed as argument, it is ignored.

```ruby
Success(1).and Success(2)            # => Success(2)
Failure(1).and Success(2)            # => Failure(1)
```

#### `and_then(self: Success(a), op: |a| -> Result(b)) -> Result(b)`

Replaces `Success a` with the result of the block. If a `Failure` is passed as argument, it is ignored.

```ruby
Success(1).and_then { Success(2) }   # => Success(2)
Failure(1).and_then { Success(2) }   # => Failure(1)
```

#### `or(self: Failure(a), other: Result(b)) -> Result(b)` 
Replaces `Failure a` with `Result`. If a `Failure` is passed as argument, it is ignored.

```ruby
Success(1).or Success(2)             # => Success(1)
Failure(1).or Success(1)             # => Success(1)
```

#### `or_else(self: Failure(a),  op: |a| -> Result(b)) -> Result(b)`

Replaces `Failure a` with the result of the block. If a `Success` is passed as argument, it is ignored.

```ruby
Success(1).or_else { Success(2) }    # => Success(1)
Failure(1).or_else { |n| Success(n)} # => Success(1)
```

#### `pipe(self: Result(a), op: |Result(a)| -> b) -> Result(a)`

Executes the block passed, but completely ignores its result. If an error is raised within the block it will **NOT** be catched.

```ruby
Success(1).try { |n| log(n.value) }  # => Success(1)
```

The value or block result must always be a `Result` i.e. `Success` or `Failure`.

### Result Chaining

You can easily chain the execution of several operations. Here we got some nice function composition.  
The method must be a unary function, i.e. it always takes one parameter - the context, which is passed from call to call.

The following aliases are defined

```ruby
alias :>> :map
alias :>= :try
alias :** :pipe       # the operator must be right associative
```

This allows the composition of procs or lambdas and thus allow a clear definiton of a pipeline.

```ruby
Success(params) >> validate >> build_request ** log >> send ** log >> build_response
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

### Pattern matching
Now that you have some result, you want to control flow by providing patterns.
`#match` can match by

 * success, failure, result or any
 * values
 * lambdas
 * classes

```ruby
Success(1).match do
  success { |v| "success #{v}"}
  failure { |v| "failure #{v}"}
  result  { |v| "result #{v}"}
end # => "success 1"
```
Note1: the inner value has been unwrapped! 

Note2: only the __first__ matching pattern block will be executed, so order __can__ be important.

The result returned will be the result of the __first__ `#try` or `#let`. As a side note, `#try` is a monad, `#let` is a functor.

Values for patterns are good, too:

```ruby
Success(1).match do
  success(1) {|v| "Success #{v}" }
end # => "Success 1"
```

You can and should also use procs for patterns:

```ruby
Success(1).match do
  success ->(v) { v == 1 } {|v| "Success #{v}" }
end # => "Success 1"
```

Also you can match the result class

```ruby
Success([1, 2, 3]).match do
  success(Array) { |v| v.first }
end # => 1
```

If no match was found a `NoMatchError` is raised, so make sure you always cover all possible outcomes.

```ruby
Success(1).match do
  failure(1) { "you'll never get me" }
end # => NoMatchError
```

A way to have a catch-all would be using an `any`:

```ruby
Success(1).match do
  any { "catch-all" }
end # => "catch-all"
```

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

Some(1).fmap { |n| n + 1 }             # => Some(2)
None.fmap { |n| n + 1 }                # => None

Some(1).map  { |n| Some(n + 1) }       # => Some(2)
Some(1).map  { |n| None }              # => None
None.map     { |n| Some(n + 1) }       # => None

Some(1).value                          # => 1
Some(1).value_or(2)                    # => 1
None.value                             # => NoMethodError
None.value_or(0)                       # => 0

Some(1).value_to_a                     # => Some([1])
Some([1]).value_to_a                   # => Some([1])
None.value_to_a                        # => None

Some(1) + Some(1)                      # => Some(2)
Some([1]) + Some(1)                    # => TypeError: No implicit conversion
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
  some(1) { |n| n + 1 }
  some    { 1 }
  none    { 0 }
}                                      # => 2
```


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
