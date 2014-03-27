module Deterministic
  module Helpers
    def Success(value)
      Success.new(value)
    end

    def Failure(value)
      Failure.new(value)
    end

    def attempt_all(*args, &block)
      Either.attempt_all(*args, &block)
    end
  end
end
