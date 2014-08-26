module Deterministic
  class Either
    include Monad
    class << self
      public :new
    end

    def initialize(left=[], right=[])
      @left, @right = left, right
    end

    attr_reader :left, :right

    def +(other)
      raise Deterministic::Monad::NotMonadError, "Expected an Either, got #{other.class}" unless other.is_a? Either

      Either.new(left + other.left, right + other.right)
    end

    undef :value

    def inspect
      "Either(left: #{left.inspect}, right: #{right.inspect})"
    end

  end
module_function
  def Left(value)
    Either.new(Array[value], [])
  end

  def Right(value)
    Either.new([], Array[value])
  end
end
