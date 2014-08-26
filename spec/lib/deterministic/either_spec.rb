require 'spec_helper'

include Deterministic

describe Deterministic::Either do
  it "+ does not change operands" do
    l = Left(1)
    r = Right(2)

    either = l + r
    expect(l).to eq Left(1)
    expect(r).to eq Right(2)
    expect(either).to eq Either.new([1], [2])
  end

  it "allows adding multiple Eithers" do
    either = Left(1) + Left(2) + Right(:a) + Right(:b)
    expect(either.left).to eq [1, 2]
    expect(either.right).to eq [:a, :b]
  end

  it "works" do
    actual = [1, 2, 3, 4].inject(Either.new) { |acc, value|
      acc + (value % 2 == 0 ? Right(value) : Left(value))
    }
    expect(actual).to eq Either.new([1, 3], [2, 4])
  end
end
