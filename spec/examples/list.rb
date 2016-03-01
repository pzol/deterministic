require 'deterministic/enum'

List = Deterministic::enum {
  Cons(:head, :tail)
  Nil()
}

class List
  def self.[](*ary)
    ary.reverse.inject(Nil.new) { |xs, x| xs.append(x) }
  end

  def self.empty
    @empty ||= Nil.new
  end
end

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
      Cons(_, _) { |_, _| self }
      Nil() {  self }
    }
  end

  def last
    match {
      Cons(h, t, where { t.null? }) { |h, t| return self }
      Cons(_, t) { |_, t| t.last }
      Nil() { self }
    }
  end

  def head
    match {
      Cons(h, _) { |h, _| h }
      Nil() { self }
    }
  end

  def tail
    match {
      Cons(_, t) { |_, t| t }
      Nil() { raise EmptyListError }
    }
  end

  def init
    match {
      Cons(h, t, where {  t.tail.null? } ) { |h, t| Cons.new(h, Nil.new) }
      Cons(h, t) { |h, t| Cons.new(h, t.init) }
      Nil() { raise EmptyListError }
    }
  end

  def filter(&pred)
    match {
      Cons(h, t, where { pred.(h) }) { |h, t| Cons.new(h, t.filter(&pred)) }
      Cons(_, t) { |_, t| t.filter(&pred) }
      Nil() { self }
    }
  end

  # The find function takes a predicate and a list and returns the first element in the list matching the predicate,
  # or None if there is no such element.
  def find(&pred)
    match {
      Nil() { Deterministic::Option::None.new }
      Cons(h, t) { |h, t| if pred.(h) then Deterministic::Option::Some.new(h) else t.find(&pred) end }
    }
  end

  def length
    match {
      Cons(h, t) { |h, t| 1 + t.length }
      Nil() { 0 }
    }
  end

  def map(&fn)
    match {
      Cons(h, t) { |h, t| Cons.new(fn.(h), t.map(&fn)) }
      Nil() { self }
    }
  end

  def sum
    foldl(0, &:+)
  end

  def foldl(start, &fn)
    match {
      Nil() { start }
      # foldl f z (x:xs) = foldl f (f z x) xs
      Cons(h, t) { |h, t| t.foldl(fn.(start, h), &fn) }
    }
  end

  def foldl1(&fn)
    match {
      Nil() { raise EmptyListError }
      Cons(h, t) { |h, t| t.foldl(h, &fn)}
    }
  end

  def foldr(start, &fn)
    match {
      Nil() { start }
      # foldr f z (x:xs) = f x (foldr f z xs)
      Cons(h, t) { |h, t| fn.(h, t.foldr(start, &fn)) }
    }
  end

  def foldr1(&fn)
    match {
      Nil() { raise EmptyListError }
      Cons(h, t, where { t.null? }) { |h, t| h }
      # foldr1 f (x:xs) =  f x (foldr1 f xs)
      Cons(h, t) { |h, t| fn.(h, t.foldr1(&fn)) }
    }
  end

  def take(n)
    match {
      Cons(h, t, where { n > 0 }) { |h, t| Cons.new(h, t.take(n - 1))}
      Cons(_, _) { |_, _| Nil.new }
      Nil() { raise EmptyListError}
    }
  end

  def drop(n)
    match {
      Cons(h, t, where { n > 0 }) { |h, t| t.drop(n - 1) }
      Cons(_, _) { |_, _| self }
      Nil() { raise EmptyListError}
    }
  end

  def to_a
    foldr([]) { |x, ary| ary << x }
  end

  def any?(&pred)
    match {
      Nil() { false }
      Cons(h, t, where { t.null? }) { |h, t| pred.(h) }
      Cons(h, t) { |h, t| pred.(h) || t.any?(&pred) }
    }
  end

  def all?(&pred)
    match {
      Nil() { false }
      Cons(h, t, where { t.null? }) { |h, t| pred.(h) }
      Cons(h, t)                    { |h, t| pred.(h) && t.all?(&pred) }
    }
  end

  def reverse
    match {
      Nil() { self }
      Cons(_, t, where { t.null? }) { |_, t| self }
      Cons(h, t) { |h, t| Cons.new(self.last.head, self.init.reverse) }
    }
  end

  def to_s(joiner = ", ")
    match {
      Nil() { "Nil" }
      Cons(head, tail) { |head, tail| head.to_s + joiner + tail.to_s }
    }
  end
}
