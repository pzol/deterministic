require 'spec_helper'

include Deterministic

describe Deterministic::Option do
  include Deterministic::Prelude::Option
  None = Deterministic::Prelude::Option::None

  specify { expect(described_class::Some.new(0)).to be_a described_class::Some }
  specify { expect(described_class::Some.new(0)).to be_a described_class }
  specify { expect(described_class::Some.new(0)).to eq Some(0) }

  specify { expect(described_class::None.new).to eq described_class::None.new }
  specify { expect(described_class::None.new).to be_a described_class::None }
  specify { expect(described_class::None.new).to be_a described_class }
  specify { expect(described_class::None.new).to eq None }

  it "join" do
    expect(Some(Some(1))).to eq Some(1)
  end

  it "fmap" do
    expect(Some(1).fmap { |n| n + 1}).to eq Some(2)
    expect(None.fmap { |n| n + 1}).to eq None
  end

  it "map" do
    expect(Some(1).map { |n| Some(n + 1)}).to eq Some(2)
    expect(Some(1).map { |n| None }).to eq None
    expect(None.map { |n| Some(n + 1)}).to eq None
  end

  it "some?" do
    expect(Some(1).some?).to be_truthy
    expect(None.some?).to be_falsey
  end

  it "none?" do
    expect(None.none?).to be_truthy
    expect(Some(1).none?).to be_falsey
  end

  it "value" do
    expect(Some(1).value).to eq 1
    expect{ None.value }.to raise_error NoMethodError
  end

  it "value_or" do
    expect(Some(1).value_or(2)).to eq 1
    expect(None.value_or(0)).to eq 0
  end

  it "+" do
    expect(Some([1]) + None).to eq Some([1])
    expect(Some(1) + None + None).to eq Some(1)
    expect(Some(1) + Some(1)).to eq Some(2)
    expect(None + Some(1)).to eq Some(1)
    expect(None + None + Some(1)).to eq Some(1)
    expect(None + None + Some(1) + None).to eq Some(1)
    expect(None + Some({foo: 1})).to eq Some({:foo=>1})
    expect(Some([1]) + Some([1])).to eq Some([1, 1])
    expect { Some([1]) + Some(1)}.to raise_error TypeError
  end

  it "inspect" do
    expect(Some(1).inspect).to eq "Some(1)"
    expect(described_class::None.new.inspect).to eq "None"
  end

  it "to_s" do
    expect(Some(1).to_s).to eq "1"
    expect(described_class::None.new.to_s).to eq ""
  end

  it "match" do
    expect(
      Some(0).match {
        Some(s, where { s == 1 } ) { |n| 99 }
        Some(s, where { s == 0 }) { |n| s + 1 }
        None() {}
      }
    ).to eq 1

    expect(
      Some(1).match {
        None() { 0 }
        Some(s) { 1 }
      }
    ).to eq 1

    expect(
      Some(1).match {
        None() { 0 }
        Some(s, where { s.is_a? Fixnum }) { 1 }
      }
    ).to eq 1

    expect(
      None.match {
        None() { 0 }
        Some() { 1 }
      }
    ).to eq 0
  end

  it "nil?" do
    expect(described_class.some?(nil)).to eq None
    expect(described_class.some?(1)).to be_some
    expect(described_class.some?(1)).to eq Some(1)
  end

  it "any?" do
    expect(described_class.any?(nil)).to be_none
    expect(described_class.any?(None)).to be_none
    expect(described_class.any?("")).to  be_none
    expect(described_class.any?([])).to  be_none
    expect(described_class.any?({})).to  be_none
    expect(described_class.any?([1])).to eq Some([1])
    expect(described_class.any?({foo: 1})).to eq Some({foo: 1})
  end

  it "try!" do
    expect(described_class.try! { raise "error" }).to be_none
  end
end

require_relative 'monad_axioms'

describe Deterministic::Option::Some do
   it_behaves_like 'a Monad' do
    let(:monad) { described_class }
  end
end

# describe Deterministic::Option::None do
#    it_behaves_like 'a Monad' do

#     let(:monad) { described_class }
#   end
# end
