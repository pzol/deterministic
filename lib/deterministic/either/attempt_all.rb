require 'ostruct'

class Deterministic::Either
  def self.attempt_all(context=OpenStruct.new, &block)
    AttemptAll.new(context, &block).call
  end

  class AttemptAll
    class EitherExpectedError < StandardError; end
    def initialize(context, &block)
      @context = context || self
      @tries = []
      instance_eval(&block)
    end

    def call(initial=nil)
      result = @tries.inject(Success(initial)) do |acc, try|
        acc.success? ? acc << try.call(acc) : acc
      end
    end

    # This is a functor
    def try(&block)
      try_p = ->(acc) {
        begin
          value = @context.instance_exec(acc.value, &block)
          Success(value)
        rescue => ex
          Failure(ex)
        end
      }

      @tries << try_p
    end

    # Basicly a monad
    def let(sym=nil, &block)
      @tries << ->(acc) { 
        @context.instance_exec(acc.value, &block).tap do |value|
          raise EitherExpectedError, "Expected the result to be either Success or Failure" unless value.is_a? Either
        end
      }
    end
  end
end
