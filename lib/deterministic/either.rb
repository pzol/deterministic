module Deterministic
  class Either
    include Monad
    include PatternMatching

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
end
