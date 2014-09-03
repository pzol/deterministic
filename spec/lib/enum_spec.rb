require 'spec_helper'
require 'deterministic/enum'

describe Deterministic::Enum  do
  include Deterministic

  context "Nullary, Unary, Binary" do
    MyEnym = Deterministic::enum {
      Nullary()
      Unary(:a)
      Binary(:a, :b)
    }

    it "Nullary" do
      n = MyEnym::Nullary.new
      expect(n).to be_a MyEnym::Nullary
      expect { n.value }.to raise_error
      expect(n.inspect).to eq "Nullary"
      expect(n.to_s).to eq ""
      expect(n.fmap { }).to eq n
      expect(n.inner_value).to eq []
    end

    it "Unary" do
      u= MyEnym::Unary.new(1)

      expect(u).to be_a MyEnym::Unary
      expect(u.a).to eq 1
      expect(u.value).to eq 1
      expect(u.inspect).to eq "Unary(1)"
      expect(u.to_s).to eq "1"
      expect(u.inner_value).to eq [1]
    end

    it "generated enum" do
      expect(MyEnym.variants).to eq [:Nullary, :Unary, :Binary]
      expect(MyEnym.constants.inspect).to eq "[:Nullary, :Unary, :Binary, :Matcher]"


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
