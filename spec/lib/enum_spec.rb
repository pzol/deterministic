require 'spec_helper'

module Deterministic
  module Enum
  end

  class EnumBuilder
    def initialize(mod)
      @mod = mod
    end


    class DataType #< Deterministic::Option::None
      include Deterministic::Monad

      module AnyEnum
        def match(&block)
          parent.match(self, &block)
        end

        def parent
          eval(self.class.name.split("::")[-2])
        end
      end

      module Nullary
        def initialize(*args)
          @value = []
        end

        def inspect
          self.class.name.split("::")[-1]
        end
      end

      module Binary
        def initialize(*args)
          @value = args
        end

        def inspect
          pretty_name = self.class.name.split("::")[-1]
          params = args.zip(@value).map { |e| "#{e[0]}: #{e[1].inspect}" }
          "#{pretty_name}(#{params.join(", ")})"
        end

      end

      def self.create(name, args)
        dt = Class.new

        if args.count == 0
          dt.instance_eval {
            include Deterministic::Monad
            include Nullary
            include AnyEnum
            private :value
          }
        else
          dt.instance_eval {
            include Deterministic::Monad
            include Binary
            include AnyEnum

            define_method(:args) { args }

            args.each_with_index do |m, i|
              define_method(m) do
                @value[i]
              end
            end
          }
        end
        dt
      end

      class << self
        public :new; 
      end

      def initialize(*args)
        @value = None
      end


      def self.inspect 
        "Deterministic::Enum::Empty"
      end
    end

    def method_missing(m, *args)
      @mod.const_set(m, DataType.create(m, args))
    end
  end

module_function
  def enum(&block)
    mod = Class.new do # the enum to be built
      def self.match(obj, &block)
        matcher = self::Matcher.new(obj)
        matcher.instance_eval(&block)

        type_matches = matcher.matches.select { |r| r[0].is_a?(r[1]) }

        match = type_matches[0]
        type_matches.each { |match|

          obj, type, block, args, guard = match
          
          if args.count > 0
            raise "Pattern (#{args.join(', ')}) must match (#{obj.args.join(', ')})" if args.count != obj.value.count
            context = Struct.new(*args).new(*obj.value)

            # p [:guard, guard]
            if guard 
              if context.instance_exec(*(obj.value), &guard)
              p [:yep]
                return context.instance_exec(*(obj.value), &block)
              end
            else
              return context.instance_exec(*(obj.value), &block)
            end
          else
            return instance_exec(&block)
          end
        }

        raise "No match could be made"
      end
      
      include Enum
      def self.variants; constants - [:Matcher]; end
    end
    enum = EnumBuilder.new(mod)
    enum.instance_eval(&block)

    type_variants = mod.constants

    matcher = Class.new {
      def initialize(obj)
        @obj = obj
        @matches = []
        @vars = []
      end

      attr_reader :matches, :vars

      def where(&guard)
        guard
      end

      def method_missing(m)
        m
      end

      type_variants.each { |m|
        define_method(m) { |*args, &block|
          type = Kernel.eval("#{mod.name}::#{m}")

          if args.count > 0 && args[-1].is_a?(Proc)
            guard = args.delete_at(-1) 
          end

          @matches << [@obj, type, block, args, guard]
        }
      }
    }

    mod.const_set(:Matcher, matcher)
    mod
  end

  def impl(enum_type, &block)
    enum_type.variants.each { |v|
      name = "#{enum_type.name}::#{v.to_s}"
      type = Kernel.eval(name)
      type.class_eval(&block)
    }
  end
end

describe Deterministic::EnumBuilder  do
  Object.extend(Deterministic)

  MyEnym = enum {
    Nullary()
    Unary(:i)
    Binary(:a, :b)
  }

  it "does something" do
    expect(MyEnym.variants).to eq [:Nullary, :Unary, :Binary]
    expect(MyEnym.constants.inspect).to eq "[:Nullary, :Unary, :Binary, :Matcher]"

    n = MyEnym::Nullary.new

    expect(n).to be_a MyEnym::Nullary

    u = MyEnym::Unary.new(1)

    expect(u.value).to eq [1]
    expect(u).to be_a MyEnym::Unary
    expect(u.i).to eq 1
    expect(u.inspect).to eq "Unary(i: 1)"

    b = MyEnym::Binary.new(1, 2)

    expect(b.value).to eq ([1, 2])
    expect(b).to be_a MyEnym::Binary
    expect(b.a).to eq 1
    expect(b.b).to eq 2
    expect(b.inspect).to eq "Binary(a: 1, b: 2)"


    res =
      MyEnym.match(b) {
        Nullary  { 0 }
        Unary(a) { [a, b] }
        Binary(x, y) { [x, y]}
      }

    expect(res).to eq [1, 2]

    List = enum {
      Cons(:head, :tail)
      Nil()
    }

    impl(List) {
      def append(elem)
        List::Cons.new(elem, self)
      end

      def head
        match {
          Cons(h, _) { h }
          Nil() { self }
        }
      end

      def tail
        0
      end

      def len
        match {
          Cons(h, tail) { 1 + tail.len }
          Nil() { 0 }
        }
      end

      def map(&block)
        match {
          Cons(h, t) { List::Cons.new(block.call(h), t.map(&block)) }
          Nil() { List::Nil.new }
        }
      end

      def reverse
        match {
          Cons(h, t) { List::Cons.new(h, t.reverse) }
          Nil() { List::Nil.new }
        }
      end

      def to_s
        match {
          Nil() { "Nil" }
          Cons(head, tail) { head.to_s + ", " + tail.to_s }
        }
      end
    }

    a = List::Nil.new
    b = a.append(1)

    first = List.match(b) {
      Nil()       { self }
      Cons(h, t, where { h == 0 })  { h }
      Cons(h, t)  { h }
    }


    expect(first).to eq 1

    b = b.append(2).append(3).append(4)

    p [:list, b, b.len, b.to_s]
    p [:map, b.map { |h, t| h + 1 }.to_s]
    r = b.reverse

    p [:rev, b.tail, r]


    p [:res, res]
  end
end
