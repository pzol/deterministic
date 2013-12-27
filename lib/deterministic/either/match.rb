module Deterministic::Either
  def match(proc=nil, &block)
    match = Match.new(self)
    match.instance_eval &(proc || block)
    match.result
  end

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
