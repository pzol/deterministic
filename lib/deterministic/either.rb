module Deterministic::Either
  def Success(value)
    Success.unit(value)
  end

  def Failure(value)
    Failure.unit(value)
  end

  class Either
    def self.unit(value)
      return value if value.is_a? Either
      # return Failure.new(value)       if value.nil? || (value.respond_to?(:empty?) && value.empty?) || !value
      # return Success.new(value)
      return new(value)
    end

    def is?(s)
      const_name = s.slice(0,1).capitalize + s.slice(1..-1)
      is_a? Module.const_get(const_name)
    end

    def success?
      is_a? Success
    end

    def failure?
      is_a? Failure
    end

    def bind(other)
      return self if failure?
      return other if other.is_a? Either
      # return concat(proc) if proc.is_a? Either

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

    def ==(other)
      return false unless other.is_a? self.class
      @value == other.instance_variable_get(:@value)
    end

  private
    def initialize(value) 
      @value = value
    end
  end
end
