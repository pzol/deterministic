module Deterministic
  class Success < Either
    class << self; public :new; end

    def and(other)
      raise NotMonadError, "Expected #{other.inspect} to be an Either" unless other.is_a? Either
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
