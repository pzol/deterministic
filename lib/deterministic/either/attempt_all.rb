module Deterministic::Either
  def self.attempt_all(&block)
    AttemptAll.new(&block).call
  end

  class AttemptAll
    class EitherExpectedError < StandardError; end
    def initialize(&block)
      @__tries = []
      instance_eval(&block)
    end

    def call(initial=nil)
      result = @__tries.inject(Success(initial)) do |acc, try|
        acc.success? ? acc.bind(try.call(acc)) : acc
      end
    end

    def try(proc=nil, &block)
      try_p = ->(acc) {
        begin
          value = instance_exec(acc.value, &(proc ||block))
          Success(value)
        rescue => ex
          Failure(ex)
        end
      }

      @__tries << try_p
    end

    def let(proc=nil, &block)
      @__tries << ->(acc) { 
        instance_exec(acc, &(proc || block)).tap do |value|
          raise EitherExpectedError unless value.is_a? Either
        end
      }
    end
  end
end
