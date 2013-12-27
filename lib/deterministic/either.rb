module Deterministic::Either
  def Success(value)
    Success.unit(value)
  end

  def Failure(value)
    Failure.unit(value)
  end

  class Abstract
    def self.unit(value)
      return value if value.is_a? Abstract
      # return Failure.new(value)       if value.nil? || (value.respond_to?(:empty?) && value.empty?) || !value
      # return Success.new(value)
      return new(value)
    end

    def success?
      is_a? Success
    end

    def failure?
      is_a? Failure
    end

    def bind(proc=nil, &block)
      return self if failure?
      return concat(proc) if proc.is_a? Either

      # begin
      #   Either(call(proc, block))
      # rescue StandardError => error
      #   Failure(error)
      # end
    end

    # get the underlying value
    def value
      @value
    end

    # dsl
    def match(&block)
      match = Match.new(self)
      block.call(match)
      match.result
    end

    def ==(other)
      return false unless other.is_a? self.class
      @value == other.instance_variable_get(:@value)
    end

  private
    def concat(other)
      failure? ? self : other
    end

    def initialize(value) 
      @value = value
    end
  end
end
