require 'spec_helper'
require_relative '../monad_axioms'
require_relative 'either_shared'

include Deterministic

describe Deterministic::Failure do

  it_behaves_like 'a Monad' do
    let(:monad) { described_class }
  end

  subject { described_class.new(1) }

  specify { expect(subject).to be_an_instance_of described_class }
  specify { expect(subject).to be_failure }
  specify { expect(subject).not_to be_success }

  specify { expect(subject).to be_an_instance_of described_class }
  specify { expect(subject).to eq(described_class.new(1)) }
  specify { expect(subject << Success(2)).to eq(Failure(1)) }
  specify { expect(subject << Failure(2)).to eq(Failure(1)) }
  specify { expect(subject.map { |v| v + 1} ).to eq Failure(2) }

  it_behaves_like 'Either' do
    let(:either) { described_class }
  end
end


describe "Chaining" do
  it "#or" do
    expect(Success(1).or(Failure(2))).to eq Success(1)
    expect(Failure(1).or(Success(2))).to eq Success(2)
    expect { Failure(1).or(2) }.to raise_error(Deterministic::Monad::NotMonadError)
  end

  it "#or_else" do
    expect(Success(1).or_else { Failure(2) }).to eq Success(1)
    expect(Failure(1).or_else { |v| Success(v + 1) }).to eq Success(2)
    expect { Failure(1).or_else { 2 } }.to raise_error(Deterministic::Monad::NotMonadError)
  end

  it "#and" do
    expect(Success(1).and(Success(2))).to eq Success(2)
    expect(Failure(1).and(Success(2))).to eq Failure(1)
    expect { Success(1).and(2) }.to raise_error(Deterministic::Monad::NotMonadError)
  end

  it "#and_then" do
    expect(Success(1).and_then { Success(2) }).to eq Success(2)
    expect(Failure(1).and_then { Success(2) }).to eq Failure(1)
    expect { Success(1).and_then { 2 } }.to raise_error(Deterministic::Monad::NotMonadError)
  end
end
