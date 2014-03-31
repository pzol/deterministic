module Deterministic
  class Failure < Either
    class << self; public :new; end

    def and(other)
      self
    end

    def and_then(&block)
      self
    end

    def or(other)
      raise NotMonadError, "Expected #{other.inspect} to be an Either" unless other.is_a? Either
      other
    end

    def or_else(&block)
      bind(&block)
    end
  end
end
