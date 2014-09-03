require 'spec_helper'

module Deterministic
  class ProtocolBuilder

    def initialize(generic, block)
      @generic, @block = generic, block
    end

    def build
      instance_exec(&@block)
    end

    def method_missing(m, *args)
      [m, args]
    end

    def type(m)
      p [:type, m]
    end

    def fn(signature)
      p [:fn, signature]
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
  def protocol(generic, &block)
    ProtocolBuilder.new(generic, block).build
  end

  def instance(protocol, type, &block)
    InstanceBuilder.new(protocol, type, block).build
  end
end

include Deterministic

Monoid = protocol(:M) {
  fn(empty() => :M)
  fn(append(a: :M, b: :M) => :M) {
    a + b
  }
}

instance(Monoid, Fixnum) {
  fn(empty() => Fixnum) {
    [0]
  }
}
