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
        acc.success? ? acc.bind(try.call(acc)) : acc
      end
    end

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

    def let(sym=nil, &block)
      @tries << ->(acc) { 
        @context.instance_exec(acc, &block).tap do |value|
          raise EitherExpectedError unless value.is_a? Either
        end
      }
    end
  end
end
