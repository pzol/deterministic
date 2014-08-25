module Deterministic
  class Failure < Result
    class << self; public :new; end

    def and(other)
      self
    end

    def and_then(&block)
      self
    end

    def or(other)
      raise NotMonadError, "Expected #{other.inspect} to be an Result" unless other.is_a? Result
      other
    end

    def or_else(&block)
      bind(&block)
    end
  end
end
