require 'spec_helper'
require_relative 'monad_axioms'


describe Deterministic::Option do
  include Deterministic
  Some = Deterministic::Some
  None = Deterministic::None

  # nil?
  specify { expect(described_class.some?(nil)).to eq None }
  specify { expect(described_class.some?(1)).to be_some }
  specify { expect(described_class.some?(1)).to eq Some(1) }

  # any?
  specify { expect(described_class.any?(nil)).to be_none }
  specify { expect(described_class.any?(None)).to be_none }
  specify { expect(described_class.any?("")).to  be_none }
  specify { expect(described_class.any?([])).to  be_none }
  specify { expect(described_class.any?({})).to  be_none }
  specify { expect(described_class.any?([1])).to eq Some([1]) }
  specify { expect(described_class.any?({foo: 1})).to eq Some({foo: 1}) }

  # try!
  specify { expect(described_class.try! { raise "error" }).to be_none }
end

describe Deterministic::Option do
  include Deterministic
  Option = Deterministic::Option

  #  it_behaves_like 'a Monad' do
  #   let(:monad) { described_class }
  # end

  specify { expect(Option::Some.new(0)).to be_a Option::Some }
  specify { expect(Option::Some.new(0)).to eq Some(0) }

  specify { expect(Option::None.new).to eq Option::None.new }
  specify { expect(Option::None.new).to eq None }

  # some?, none?
  specify { expect(None.some?).to be_falsey }
  specify { expect(None.none?).to be_truthy }
  specify { expect(Some(0).some?).to be_truthy }
  specify { expect(Some(0).none?).to be_falsey }

  # value, value_or
  specify { expect(Some(0).value).to eq 0 }
  specify { expect(Some(1).value_or(2)).to eq 1}
  specify { expect { None.value }.to raise_error NoMethodError }
  specify { expect(None.value_or(2)).to eq 2}

  # fmap
  specify { expect(Some(1).fmap { |n| n + 1}).to eq Some(2) }
  specify { expect(None.fmap { |n| n + 1}).to eq None }

  # map
  specify { expect(Some(1).map { |n| Some(n + 1)}).to eq Some(2) }
  specify { expect(Some(1).map { |n| None }).to eq None }
  specify { expect(None.map { |n| nil }).to eq None }

  # to_a
  specify { expect(Some(1).value_to_a). to eq Some([1])}
  specify { expect(Some([1]).value_to_a). to eq Some([1])}
  specify { expect(None.value_to_a). to eq None}

  # +
  specify { expect(Some(1) + None).to eq Some(1) }
  specify { expect(Some(1) + None + None).to eq Some(1) }
  specify { expect(Some(1) + Some(1)).to eq Some(2) }
  specify { expect(None + Some(1)).to eq Some(1) }
  specify { expect(None + None + Some(1)).to eq Some(1) }
  specify { expect(None + None + Some(1) + None).to eq Some(1) }
  specify { expect { Some([1]) + Some(1)}.to raise_error TypeError}

  # join
  specify{ expect(Some(Success(1))).to eq(Some(Success(1)))}
  specify{ expect(Some(None)).to eq(Some(None))}
  specify{ expect(Some(Failure(1))).to eq(Some(Failure(1)))}

  # match
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

describe Deterministic::Option::Some do
  include Deterministic

  it_behaves_like 'a Monad' do
    let(:monad) { described_class }
  end
end

describe Deterministic::Option::None do
  include Deterministic

  it_behaves_like 'a Monad' do
    let(:monad) { described_class }
  end
end
