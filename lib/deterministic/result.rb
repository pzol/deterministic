module Deterministic
  # Abstract parent of Success and Failure
  #
  # `fmap(self: Result(a), op: |a| -> b) -> Result(b)`
  # Maps a `Result` with the value `a` to the same `Result` with the value `b`.
  #
  # `bind(self: Result(a), op: |a| -> Result(b)) -> Result(b)`
  # Maps a `Result` with the value `a` to another `Result` with the value `b`.
  class Result
    include Monad

    module PatternMatching
      include Deterministic::PatternMatching
      class Match
        include Deterministic::PatternMatching::Match

        %w[Success Failure Result].each do |s|
          define_method s.downcase.to_sym do |value=nil, &block|
            klas = klas = self.class.module_eval(s)
            push(klas, value, block)
          end
        end
      end
    end

    include PatternMatching
    include Chain

    # This is an abstract class, can't ever instantiate it directly
    class << self
      protected :new
    end

    def success?
      is_a? Success
    end

    def failure?
      is_a? Failure
    end

    # `pipe(self: Result(a), op: |Result(a)| -> b) -> Result(a)`
    # Executes the block passed, but completely ignores its result. If an error is raised within the block it will **NOT** be catched.
    def pipe(proc=nil, &block)
      (proc || block).call(self)
      self
    end

    alias :** :pipe

    # `pipe(self: Result(a), op: |Result(a)| -> b) -> Result(a)`
    # Executes the block passed, but completely ignores its result. If an error is raised within the block it will **NOT** be catched.
    def and(other)
      return self if failure?
      raise NotMonadError, "Expected #{other.inspect} to be an Result" unless other.is_a? Result
      other
    end

    # `and_then(self: Success(a), op: |a| -> Result(b)) -> Result(b)`
    # Replaces `Success a` with the result of the block. If a `Failure` is passed as argument, it is ignored.
    def and_then(&block)
      return self if failure?
      bind(&block)
    end

    # `or(self: Failure(a), other: Result(b)) -> Result(b)` 
    # Replaces `Failure a` with `Result`. If a `Failure` is passed as argument, it is ignored.
    def or(other)
      return self if success?
      raise NotMonadError, "Expected #{other.inspect} to be an Result" unless other.is_a? Result
      return other
    end

    # `or_else(self: Failure(a),  op: |a| -> Result(b)) -> Result(b)`
    # Replaces `Failure a` with the result of the block. If a `Success` is passed as argument, it is ignored.
    def or_else(&block)
      return self if success?
      bind(&block)
    end

    # `map(self: Success(a), op: |a| -> Result(b)) -> Result(b)`
    # Maps a `Success` with the value `a` to another `Result` with the value `b`. It works like `#bind` but only on `Success`.
    def map(proc=nil, &block)
      return self if failure?
      bind(proc || block)
    end

    alias :>> :map

    # `map_err(self: Failure(a), op: |a| -> Result(b)) -> Result(b)`
    # Maps a `Failure` with the value `a` to another `Result` with the value `b`. It works like `#bind` but only on `Failure`.
    def map_err(proc=nil, &block)
      return self if success?
      bind(proc || block)
    end

    # `pipe(self: Result(a), op: |Result(a)| -> b) -> Result(a)`
    # Executes the block passed, but completely ignores its result. If an error is raised within the block it will **NOT** be catched.
    def try(proc=nil, &block)
      map(proc, &block)
    rescue => err
      Failure(err)
    end

    alias :>= :try
    
    class Failure < Result
      class << self; public :new; end
    end
    
    class Success < Result
      class << self; public :new; end
    end
  end

module_function
  def Success(value)
    Result::Success.new(value)
  end

  def Failure(value)
    Result::Failure.new(value)
  end
end
