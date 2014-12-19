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
      match {
        Success(_) { |s| s.bind(proc || block) }
        Failure(_) { |f| f }
      }
    end

    alias :>> :map
    alias :and_then :map

    def map_err(proc=nil, &block)
      match {
        Success(_) { |s| s }
        Failure(_) { |f| f.bind(proc|| block) }
      }
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
        Success(_) { |s| s }
        Failure(_) { other}
      }
    end

    def and(other)
      raise Deterministic::Monad::NotMonadError, "Expected #{other.inspect} to be a Result" unless other.is_a? Result
      match {
        Success(_) { other }
        Failure(_) { |f| f }
      }
    end

    def +(other)
      raise Deterministic::Monad::NotMonadError, "Expected #{other.inspect} to be a Result" unless other.is_a? Result
      match {
        Success(s, where { other.success?} ) { Result::Success.new(s + other.value) }
        Failure(f, where { other.failure?} ) { Result::Failure.new(f + other.value) }
        Success(_) { other } # implied other.failure?
        Failure(_) { |f| f } # implied other.success?
      }
    end
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
