module Deterministic
  class Either
    include Monad
    include Deterministic::PatternMatching

    def success?
      is_a? Success
    end

    def failure?
      is_a? Failure
    end

    def <<(other)
      return self if failure?
      return other if other.is_a? Either
    end

    class << self
      protected :new
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
