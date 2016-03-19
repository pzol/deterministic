module Deterministic
  Option = Deterministic::enum {
    Some(:s)
    None()
  }

  class Option
    class << self
      def some?(expr)
        to_option(expr) { expr.nil? }
      end

      def any?(expr)
        to_option(expr) { expr.nil? || (expr.respond_to?(:empty?) && expr.empty?) }
      end

      def to_option(expr, &predicate)
        predicate.call(expr) ? None.new : Some.new(expr)
      end

      def try!
        yield rescue None.new
      end
    end
  end

  impl(Option) {
    class NoneValueError < StandardError; end

    def fmap(&fn)
      match {
        Some() {|s| self.class.new(fn.(s)) }
        None() {    self }
      }
    end

    def map(&fn)
      match {
        Some() {|s| self.bind(&fn) }
        None() {    self }
      }
    end

    def some?
      is_a? Option::Some
    end

    def none?
      is_a? Option::None
    end

    alias :empty? :none?

    def value_or(n)
      match {
        Some() {|s| s }
        None() {    n }
      }
    end

    def value_to_a
      @value
    end

    def +(other)
      match {
        None() { other }
        Some(where { !other.is_a?(Option) }) {|_| raise TypeError, "Other must be an #{Option}"}
        Some(where { other.some? }) {|s| Option::Some.new(s + other.value) }
        Some() {|_| self }
      }
    end
  }

  module Prelude
    module Option
      None = Deterministic::Option::None.new
      def Some(s); Deterministic::Option::Some.new(s); end
      def None(); Deterministic::Prelude::Option::None; end
    end
  end
end
