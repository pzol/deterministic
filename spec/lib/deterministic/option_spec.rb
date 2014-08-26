require 'spec_helper'
require_relative 'monad_axioms'

include Deterministic

describe Deterministic::Option do
  # nil?
  specify { expect(described_class.some?(nil)).to eq None }
  specify { expect(described_class.some?(1)).to be_some }
  specify { expect(described_class.some?(1)).to eq Some(1) }

  # any?
  specify { expect(described_class.any?(nil)).to be_none }
  specify { expect(described_class.any?("")).to  be_none }
  specify { expect(described_class.any?([])).to  be_none }
  specify { expect(described_class.any?({})).to  be_none }
  specify { expect(described_class.any?([1])).to eq Some([1]) }
  specify { expect(described_class.any?({foo: 1})).to eq Some({foo: 1}) }

  # try!
  specify { expect(described_class.try! { raise "error" }).to be_none }
end

describe Deterministic::Option::Some do
   it_behaves_like 'a Monad' do
    let(:monad) { described_class }
  end

  specify { expect(described_class.new(0)).to be_a Option::Some }
  specify { expect(described_class.new(0)).to eq Some(0) }
  specify { expect(described_class.new(0).some?).to be_truthy }
  specify { expect(described_class.new(0).none?).to be_falsey }
  specify { expect(described_class.new(0).value).to eq 0 }

  specify { expect(described_class.new(1).fmap { |n| n + 1}).to eq Some(2) }
  specify { expect(described_class.new(1).map { |n| Some(n + 1)}).to eq Some(2) }
  specify { expect(described_class.new(1).map { |n| None }).to eq None }

  specify {
    expect(
      Some(0).match {
        some(1) { |n| 99 }
        some(0) { |n| n + 1 }
        none(1) {}
      }
    ).to eq 1
  }

  specify {
    expect(
      Some(nil).match {
        none { 0 }
        some { 1 }
      }
    ).to eq 1
  }

  specify {
    expect(
      Some(1).match {
        none { 0 }
        some(Fixnum) { 1 }
      }
    ).to eq 1
  }

  specify {
    expect(
      None.match {
        none { 0 }
        some { 1 }
      }
    ).to eq 0
  }

end

describe Deterministic::Option::None do
  #  it_behaves_like 'a Monad' do
  #   let(:monad) { described_class }
  # end

  specify { expect(described_class.new).to eq None }
  specify { expect(described_class.new.some?).to be_falsey }
  specify { expect(described_class.new.none?).to be_truthy }
  specify { expect { described_class.new.value }.to raise_error NoMethodError }

  specify { expect(described_class.new.fmap { |n| n + 1}).to eq None }
  specify { expect(described_class.new.map { |n| nil }).to eq None }
  specify { expect(described_class.new).to eq Option::None.new }
  specify { expect(described_class.new).to eq None }
end
