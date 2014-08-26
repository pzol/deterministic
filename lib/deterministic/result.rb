module Deterministic
  # Abstract parent of Success and Failure
  class Result
    include Monad

    module PatternMatching
      include Deterministic::PatternMatching
      class Match
        include Deterministic::PatternMatching::Match

        %w[Success Failure Result].each do |s|
          define_method s.downcase.to_sym do |value=nil, &block|
            klas = Module.const_get("Deterministic::Result::#{s}")
            push(klas, value, block)
          end
        end
      end
    end

    include PatternMatching
    include Chain

    def success?
      is_a? Success
    end

    def failure?
      is_a? Failure
    end

    def pipe(proc=nil, &block)
      (proc || block).call(self)
      self
    end

    alias :** :pipe

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
  end

  class Failure < Result
    class << self; public :new; end
  end
  
  class Success < Result
    class << self; public :new; end
  end

module_function
  def Success(value)
    Success.new(value)
  end

  def Failure(value)
    Failure.new(value)
  end
end
