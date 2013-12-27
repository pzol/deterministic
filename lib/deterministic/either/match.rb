module Deterministic::Either
  class Match
    def initialize(either)
      @either    = either
      @successes = []
      @failures  = []
    end

    def success(&block)
      @successes << yield(@either.value) if @either.success?
    end

    def failure
      @failures << yield(@either.value) if @either.failure?
    end

    def result
      @failures.any? ? @failures.last : @successes.last
    end
  end
end
