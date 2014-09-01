require 'deterministic/enum'
require_relative 'functor'

Optional = Deterministic::enum {
  Some(:s)
  None()
}

Deterministic::impl(Optional) {
  include Functor

  class NoneValueError < StandardError; end

  alias :map :fmap

  def some?
    is_a? Optional::Some
  end

  def none?
    is_a? Optional::None
  end

  def unwrap
    match {
      Some(s) { s }
      None()  { raise NoneValueError }
    }
  end

  def unwrap_or(n)
    match {
      Some(s) { s }
      None()  { n }
    }
  end

  def +(other)
    match {
      None()  { other}
      Some(_) { |t| t.fmap { |s|
          other.match {
            Some(os) { s + os }
            None()   { s }
          }
        }
      }
    }
  end
}
