require 'deterministic/enum'

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
        to_option(expr) { expr.nil? || not(expr.respond_to?(:empty?)) || expr.empty? }
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
        Some(s) { |m| m.class.new(fn.(s)) }
        None()  { |n| n }
      }
    end 

    def map(&fn)
      match {
        Some(s) { |m| m.bind(&fn) }
        None()  { |n| n }
      }
    end 

    def some?
      is_a? Option::Some
    end

    def none?
      is_a? Option::None
    end

    def value_or(n)
      match {
        Some(s) { s }
        None()  { n }
      }
    end

    def value_to_a
      @value
    end

    def +(other)
      match {
        None() { other }
        Some(_, where { !other.is_a?(Option)}) { raise TypeError, "Other must be an #{Option}"}
        Some(s, where { other.some? }) { Option::Some.new(s + other.value) }
        Some(_) { |s| s }
      }
    end
  }
end
