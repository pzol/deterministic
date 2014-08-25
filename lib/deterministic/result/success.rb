module Deterministic
  class Success < Result
    class << self; public :new; end

    def and(other)
      raise NotMonadError, "Expected #{other.inspect} to be an Result" unless other.is_a? Result
      other
    end

    def and_then(&block)
      bind(&block)
    end

    def or(other)
      self
    end

    def or_else(&block)
      self
    end
  end
end
