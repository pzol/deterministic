require 'spec_helper'

include Deterministic

module Deterministic
  class Destructor
    include Monad

    class NoMatchError < StandardError; end

    def match(context=nil, &block)
      @context = value #block.binding.eval('self')
      @collection = []
      instance_eval &block

      matcher = @collection.detect { |m| m.matches?(value)  }
      raise NoMatchError, "No match could be made" if matcher.nil?

      if value.is_a?(Monad) && value.respond_to?(:value)
        @context.instance_exec(value.value, &matcher.block)
      else
        @context.instance_exec(value, &matcher.block)
      end
    end

    def method_missing(m, *args, &guard)
      Matcher.new(m.to_s, predicate(m, guard))
    end

    def where(&block)
      block
    end

    def on(matcher, guard=nil, &block)
      if matcher.is_a? Matcher
        matcher.block = block
      else
        matcher = NilClass if matcher.nil?
        matcher = Matcher.new(name, predicate(matcher, guard), block)
      end

      push(matcher)
    end

    def any(guard=nil, &block)
      on(Object, guard, &block)
    end

  private
    Matcher = Struct.new(:expr, :condition, :block) do
      def matches?(value)
        condition.(value)
      end
    end

    def predicate(expr, guard)
      type = Kernel.eval(expr.to_s)

      if guard.nil?
        ->(v) { v.is_a? type }
      else
        ->(v) { v.is_a?(type) && @context.instance_exec(v, &guard) }
      end
    end

    def push(matcher)
      @collection << matcher
    end
  end
end

class Object
  def destruct(&block)
    Destructor.new(self).match(&block)
  end

  alias :match :destruct
end

describe Destructor do
  it "matches type with guard" do
    expect(
      1.match {
        on(Fixnum { |v| v == 0}) { 0 }
        on(Fixnum { self == 1}) { self }
        on(String) { 2 }
      }
    ).to eq 1
  end

  it "matches type without guard" do
    expect(
      1.match {
        on(String) { 2 }
        on(Fixnum) { |v| v }
      }
    ).to eq 1
  end


  it "Unwraps Some" do
    
    expect(
      Some(1).destruct {
        on(Some, where { value == 0}) { |v| v + 1 }
        on(Some) { |v| v }
        on(Option::None) { |v| 0 }
      }
    ).to eq 1
  end

  it "Unwraps None" do
    expect(
      None.destruct {
        on(Some) { |v| v }
        on(Option::None) { |v| value_or(0) }
      }
    ).to eq 0
  end

  it "Unwraps Success" do
    expect(
      Success(1).destruct {
        on(Success) { |v| v }
        on(Failure) { |v| 0 }
      }
    ).to eq 1
  end

  it "Unwraps Failure" do
    expect(
      Failure(0).destruct {
        on(Success) { |v| v }
        on(Failure) { value } # value is in the context of Failure(0)
      }
    ).to eq 0
  end

  it "Unwraps nil" do
    expect(
      nil.match {
        on(nil) { 0 }
        # on(Failure) { value } # value is in the context of Failure(0)
      }
    ).to eq 0
  end

  it "Object" do
    expect(
      1.match {
        on(Object) { 0 }
        # on(Failure) { value } # value is in the context of Failure(0)
      }
    ).to eq 0
  end

  it "any" do
    expect(
      1.match {
        any(where { self == 1 }) { 1 }
        any { 0 }
        # on(Failure) { value } # value is in the context of Failure(0)
      }
    ).to eq 1
  end

  it "test" do
    params = { foo: 1 }
    actual = 
      params.match {
        on(nil)                           { Failure("Can't be nil") }
        on(Hash, where { has_key? :foo})  { Success(fetch(:foo)) }
        on(Hash)                          { Failure("Missing :foo") }
        any                               { Failure("It ain't a Hash, or ") }
      }

      expect(actual).to eq Success(1)
  end

  # return Failure() if params.nil?
  # return Failure() unless params.is_a? Hash
  # return Failure() unless params.has_key? :foo
  # return params.fetch(:foo)
end
