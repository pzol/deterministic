module Deterministic
  Result = Deterministic::enum {
    Success(:s)
    Failure(:f)
  }

  class Result
    class << self
      def try!
        begin
          Success.new(yield)
        rescue => err
          Failure.new(err)
        end
      end
    end
  end

  Deterministic::impl(Result) {
    def map(proc=nil, &block)
      success? ? bind(proc || block) : self
    end

    alias :>> :map
    alias :and_then :map

    def map_err(proc=nil, &block)
      failure? ? bind(proc || block) : self
    end

    alias :or_else :map_err

    def pipe(proc=nil, &block)
      (proc || block).call(self)
      self
    end

    alias :<< :pipe

    def success?
      is_a? Result::Success
    end

    def failure?
      is_a? Result::Failure
    end

    def or(other)
      raise Deterministic::Monad::NotMonadError, "Expected #{other.inspect} to be a Result" unless other.is_a? Result
      match {
        Success() {|_| self }
        Failure() {|_| other }
      }
    end

    def and(other)
      raise Deterministic::Monad::NotMonadError, "Expected #{other.inspect} to be a Result" unless other.is_a? Result
      match {
        Success() {|_| other }
        Failure() {|_| self }
      }
    end

    def +(other)
      raise Deterministic::Monad::NotMonadError, "Expected #{other.inspect} to be a Result" unless other.is_a? Result
      match {
        Success(where { other.success? } ) {|s| Result::Success.new(s + other.value) }
        Failure(where { other.failure? } ) {|f| Result::Failure.new(f + other.value) }
        Success() {|_| other } # implied other.failure?
        Failure() {|_| self } # implied other.success?
      }
    end

    def try(proc=nil, &block)
      map(proc, &block)
    rescue => err
      Result::Failure.new(err)
    end

    alias :>= :try

  }
end

module Deterministic
  module Prelude
    module Result
      def try!(&block); Deterministic::Result.try!(&block); end
      def Success(s); Deterministic::Result::Success.new(s); end
      def Failure(f); Deterministic::Result::Failure.new(f); end
    end

    include Result
  end
end
