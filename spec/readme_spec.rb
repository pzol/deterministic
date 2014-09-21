require 'spec_helper'

include Deterministic::Prelude::Result

Success(1).to_s                        # => "1"
Success(Success(1))                    # => Success(1)

Failure(1).to_s                        # => "1"
Failure(Failure(1))                    # => Failure(1)

Success(1).fmap { |v| v + 1}           # => Success(2)
Failure(1).fmap { |v| v - 1}           # => Failure(0)


Threenum = Deterministic::enum {
            Nullary()
            Unary(:a)
            Binary(:a, :b)
           }

Deterministic::impl(Threenum) {
  def sum

    match {
      Nullary()    { 0 }
      Unary(u)     { u }
      Binary(a, b) { a + b }
    }
  end

  def +(other)
    match {
      Nullary()    { other.sum }
      Unary(a)     { |this| this.sum + other.sum }
      Binary(a, b) { |this| this.sum + other.sum }
    }
  end
}

describe Threenum  do
  it "works" do
    expect(Threenum.Nullary + Threenum.Unary(1)).to eq 1
    expect(Threenum.Nullary + Threenum.Binary(2, 3)).to eq 5
    expect(Threenum.Unary(1) + Threenum.Binary(2, 3)).to eq 6
    expect(Threenum.Binary(2, 3) + Threenum.Binary(2, 3)).to eq 10
  end
end
