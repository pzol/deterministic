require 'spec_helper'
require 'deterministic/enum'

describe Deterministic::Enum  do
  include Deterministic

  context "Nullary, Unary, Binary" do
    MyEnym = Deterministic::enum {
      Nullary()
      Unary(:i)
      Binary(:a, :b)
    }

    it "does something" do
      expect(MyEnym.variants).to eq [:Nullary, :Unary, :Binary]
      expect(MyEnym.constants.inspect).to eq "[:Nullary, :Unary, :Binary, :Matcher, :MatchError]"

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
    end
  end
end
