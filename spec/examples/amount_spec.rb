require 'spec_helper'
require 'deterministic/enum'

Amount = Deterministic::enum {
  Due(:amount)
  Paid(:amount)
  Info(:amount)
}

class Amount
  def self.from_f(f)
    f >= 0 ? Amount::Due.new(f) : Amount::Paid.new(-1 * f)
  end
end

Deterministic::impl(Amount) {
  def to_s
    match {
      Due(a)  {|a| "%0.2f" % [a] }
      Paid(a) {|a| "-%0.2f" % [a] }
      Info(a) {|a| "(%0.2f)" % [a] }
    }
  end

  def to_f
    match {
      Info(a) {|a| 0 }
      Due(a)  {|a| a }
      Paid(a) {|a| -1 * a }
    }
  end

  def +(other)
    raise TypeError "Expected other to be an Amount, got #{other.class}" unless other.is_a? Amount

    Amount.from_f(to_f + other.to_f)
  end
}

describe Amount do
  def Due(a);  Amount::Due.new(a);  end
  def Paid(a); Amount::Paid.new(a); end
  def Info(a); Amount::Info.new(a); end

  it "due" do
    amount = Amount::Due.new(100.2)
    expect(amount.to_s).to eq "100.20"
  end

  it "paid" do
    amount = Amount::Paid.new(100.1)
    expect(amount.to_s).to eq "-100.10"
  end

  it "paid" do
    amount = Amount::Info.new(100.31)
    expect(amount.to_s).to eq "(100.31)"
  end

  it "+" do
    expect(Due(10) + Paid(20)).to eq Paid(10)
    expect(Due(10) + Paid(10)).to eq Due(0)
    expect(Due(10) + Due(10)).to eq Due(20)
    expect(Paid(10) + Paid(10)).to eq Paid(20)
    expect(Paid(10) + Due(1) + Info(99)).to eq Paid(9)
  end
end
