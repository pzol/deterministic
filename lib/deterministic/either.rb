module Deterministic
  # Abstract parent of Success and Failure
  class Either
    include Monad
    include Deterministic::PatternMatching

    def bind(proc=nil, &block)
      (proc || block).call(value, self.class).tap do |result|
        raise NotMonadError, "Expected #{result.inspect} to be an Either" unless result.is_a? self.class.superclass
      end
    end

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

    # This is an abstract class, can't ever instantiate it directly
    class << self
      protected :new
    end

    def to_json(*args)
      name = self.class.name.split('::')[-1]
      "{\"#{name}\":#{value.to_json(*args)}}"
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
