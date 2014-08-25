module Deterministic
  # Abstract parent of Success and Failure
  class Result
    include Monad
    include Deterministic::PatternMatching
    include Chain

    def bind(proc=nil, &block)
      (proc || block).call(value).tap do |result|
        raise NotMonadError, "Expected #{result.inspect} to be an Result" unless result.is_a? self.class.superclass
      end
    end

    def success?
      is_a? Success
    end

    def failure?
      is_a? Failure
    end

    def and(other)
      return self if failure?
      raise NotMonadError, "Expected #{other.inspect} to be an Result" unless other.is_a? Result
      other
    end

    def and_then(&block)
      return self if failure?
      bind(&block)
    end

    def or(other)
      return self if success?
      raise NotMonadError, "Expected #{other.inspect} to be an Result" unless other.is_a? Result
      return other
    end

    def or_else(&block)
      return self if success?
      bind(&block)
    end

    # This is an abstract class, can't ever instantiate it directly
    class << self
      protected :new
    end

    def to_s
      value.to_s
    end

    def inspect
      name = self.class.name.split("::")[-1]
      "#{name}(#{value})"
    end
  end

module_function

  def Success(value)
    Success.new(value)
  end

  def Failure(value)
    Failure.new(value)
  end
end
