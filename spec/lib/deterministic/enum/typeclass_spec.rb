require 'spec_helper'

module Deterministic
  class ProtocolBuilder

    def initialize(typevar, block)
      @typevar, @block = typevar, block
      @protocol = Class.new
    end

    def build
      instance_exec(&@block)
      @protocol
    end

    def method_missing(m, *args)
      [m, args]
    end

    def type(m)
      p [:type, m]
    end

    def fn(signature, &block)
      m = signature.to_a.flatten
      name        = m[0]
      return_type = m[-1]
      args        = m[1..-2]
      p [:fn, name, args, return_type, block]
      # m, args = signature
      @protocol.instance_eval {

        if block
          define_method(name) { |*args|
            result = block.call
          }
        else
          define_method(name) {
            raise NotImplementedError, "`#{name}` has no default implementation"
          }
        end
      }
    end
  end

  class InstanceBuilder
    def initialize(protocol, type, block)
      @protocol, @type, @block = protocol, type, block
    end

    def build
      instance_exec(&@block)
    end

    def method_missing(m, *args)
      [m, args]
    end
  end

module_function
  def protocol(typevar, &block)
    ProtocolBuilder.new(typevar, block).build
  end

  def instance(protocol, type, &block)
    InstanceBuilder.new(protocol, type, block).build
  end

  module Protocol
    def const_missing(c)
      p [:c, c]
      c
    end
  end
end

include Deterministic

module Haskelly
  extend Deterministic::Protocol

  Monoid = protocol(M) {
    fn empty() => M
    fn(append(a, b) => M) { |a, b|
      a + b
    }
  }

  Int = instance(Monoid, Fixnum) {
    fn empty() => M {
      0
    }

    fn append(a, b) => M {
      a + b
    }
  }
end

describe Haskelly::Monoid do
  it "does something" do
    monoid = described_class.new
    p [:monoid, monoid.methods]
    expect { monoid.empty }.to raise_error(NotImplementedError)
    expect(monoid.append(1, 2)).to eq 3
  end
end
