require 'spec_helper'

module Deterministic
  module Currify
    module ClassMethods
      def currify(*names)
        names.each { |name|
          unbound_method = instance_method(name)

          define_method(name) { |*args|
            curried_method = unbound_method.bind(self).to_proc.curry
            curried_method[*args]
          }
        }
      end
    end

    def self.included(curried)
      curried.extend ClassMethods
    end

  end
end

class ::Proc
  def self.compose(f, g)
    lambda { |*args| f[g[*args]] }
  end

  # Compose left to right
  def |(g)
    Proc.compose(g, self)
  end

  # Compose right to left
  def *(g)
    Proc.compose(self, g)
  end
end

class Booking
  include Deterministic::Currify
  include Deterministic::Prelude::Result

  def initialize(deps)
    @deps = deps
  end

  def build(id, format)
    validate(id) | req | find | render(format)

    validate(id) | rq = request(id) | find()
  end

  def validate(id)
    Success(id)
  end

  def req(a, id)
    Success(id: id + a)
  end

  def find(req)
    Success({ found: req})
  end

  def render(format, req)
    Success("rendered in #{format}: #{req[:found]}")
  end

  currify :find, :render, :req

end

describe "Pref" do
  include Deterministic::Prelude::Result

  it "does something" do
    b = Booking.new(1)
    actual = b.validate(1) >> b.req(2) >> b.find >> b.render(:html)

    expected = Deterministic::Result::Success.new("rendered in html: {:id=>3}")
    expect(actual).to eq expected
  end
end
