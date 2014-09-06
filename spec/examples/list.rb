require 'deterministic/enum'

List = Deterministic::enum {
  Cons(:head, :tail)
  Nil()
}

Deterministic::impl(List) {
  class EmptyListError < StandardError; end

  def append(elem)
    List::Cons.new(elem, self)
  end

  def null?
    is_a? Nil
  end

  def first
    match {
      Cons(_, _) { |c| c }
      Nil() { |n| n }
    }
  end

  def last
    match {
      Cons(h, t, where { t.null? }) { |c| return c }
      Cons(_, t) { t.last }
      Nil() { |n| n }
    }
  end

  def head
    match {
      Cons(h, _) { h }
      Nil() { |n| n }
    }
  end

  def tail
    match {
      Cons(_, t) { t }
      Nil() { |n| raise EmptyListError }
    }
  end

  def init
    match {
      Cons(h, t, where { |c| t.tail.null? } ) { |c| Cons.new(h, Nil.new) }
      Cons(h, t) { |c| Cons.new(h, t.init) }
      Nil() { raise EmptyListError }
    }
  end

  def filter(&pred)
    match {
      Cons(h, t, where { pred.(h) }) { |c| Cons.new(h, t.filter(&pred)) }
      Cons(_, t) { t.filter(&pred) }
      Nil() { |n| n }
    }
  end

  # The find function takes a predicate and a list and returns the first element in the list matching the predicate,
  # or None if there is no such element.
  def find(&pred)
    match {
      Nil() { Deterministic::Option::None.new }
      Cons(h, t) { if pred.(h) then Deterministic::Option::Some.new(h) else t.find(&pred) end }
    }
  end

  def length
    match {
      Cons(h, t) { 1 + t.length }
      Nil() { 0 }
    }
  end

  def map(&fn)
    match {
      Cons(h, t) { Cons.new(fn.(h), t.map(&fn)) }
      Nil() { |n| n }
    }
  end

  def sum
    foldl(0, &:+)
  end

  def foldl(start, &fn)
    match {
      Cons(h, t, where { t.null? }) { fn.(h, start) }
      Cons(h, t) { fn.(h, t.foldl(start, &fn)) }
      Nil() { |n| raise EmptyListError }
    }
  end

  def take(n)
    match {
      Cons(h, t, where { n > 0 }) { Cons.new(h, t.take(n - 1))}
      Cons(_, _) { Nil.new }
      Nil() { raise EmptyListError}
    }
  end

  def drop(n)
    match {
      Cons(h, t, where { n > 0 }) { t.drop(n - 1) }
      Cons(_, _) { |c| c }
      Nil() { raise EmptyListError}
    }
  end

  def to_a
    foldl([]) { |x, ary| ary << x }
  end

  def any?(&pred)
    match {
      Nil() { false }
      Cons(h, t, where { t.null? }) { pred.(h) }
      Cons(h, t) { pred.(h) || t.any?(&pred) }
    }
  end

  def all?(&pred)
    match {
      Nil() { false }
      Cons(h, t, where { t.null? }) { pred.(h) }
      Cons(h, t)                    { pred.(h) && t.all?(&pred) }
    }
  end

  def reverse
    match {
      Nil() { |n| n }
      Cons(_, t, where { t.null? }) { |c| c }
      Cons(h, t) { |c| Cons.new(c.last.head, c.init.reverse) }
    }
  end

  def to_s(joiner = ", ")
    match {
      Nil() { "Nil" }
      Cons(head, tail) { head.to_s + joiner + tail.to_s }
    }
  end
}
