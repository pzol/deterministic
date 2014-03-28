require 'spec_helper'
require_relative '../monad_axioms'

include Deterministic

describe Deterministic::Success do

  it_behaves_like 'a Monad' do
    let(:monad) { described_class }
  end

  subject { described_class.new(1) }

  specify { expect(subject).to be_an_instance_of described_class }
  specify { expect(subject.value).to eq 1 }
  specify { expect(subject).to be_success }
  specify { expect(subject).not_to be_failure }

  specify { expect(subject).to be_an_instance_of described_class }
  specify { expect(subject).to eq(described_class.new(1)) }
  specify { expect(subject << Success(2)).to eq(Success(2)) }
  specify { expect(subject << Failure(2)).to eq(Failure(2)) }
  specify { expect(Success(subject)).to eq Success(1) }
  specify { expect(subject.map { |v| v + 1} ).to eq Success(2) }

  it "#bind" do
    expect(
      subject.bind { |v| true ? Success(v + 1) : Failure(v + 2)}
    ).to eq Success(2)
  end

  it "#to_json" do
    expect(Success({a: 1}).to_json).to eq '{"Success":{"a":1}}'
  end

  it "#to_s" do
    expect(Success(1).to_s).to eq "1"
    expect(Success({a: 1}).to_s).to eq "{:a=>1}"
  end
end
