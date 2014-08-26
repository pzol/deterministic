require 'spec_helper'
require_relative '../monad_axioms'
require_relative 'result_shared'

include Deterministic

describe Deterministic::Result::Success do

  it_behaves_like 'a Monad' do
    let(:monad) { described_class }
  end

  subject { described_class.new(1) }

  specify { expect(subject).to be_an_instance_of described_class }
  specify { expect(subject).to be_success }
  specify { expect(subject).not_to be_failure }
  specify { expect(subject.success?).to be_truthy }
  specify { expect(subject.failure?).to be_falsey }

  specify { expect(subject).to be_an_instance_of described_class }
  specify { expect(subject).to eq(described_class.new(1)) }
  specify { expect(subject.fmap { |v| v + 1} ).to eq Success(2) }
  specify { expect(subject.map { |v| Failure(v + 1) } ).to eq Failure(2) }
  specify { expect(subject.map_err { |v| Failure(v + 1) } ).to eq Success(1) }

  specify { expect(subject.pipe{ |r| raise RuntimeError unless r == Success(1) } ).to eq Success(1) }

  specify { expect(subject.or(Success(2))).to eq Success(1)}
  specify { expect(subject.or_else { Success(2) }).to eq Success(1)}

  specify { expect(subject.and(Success(2))).to eq Success(2)}
  specify { expect(subject.and(Failure(2))).to eq Failure(2)}
  specify { expect(subject.and_then { Success(2) }).to eq Success(2)}
  specify { expect(subject.and_then { Failure(2) }).to eq Failure(2)}

  it_behaves_like 'Result' do
    let(:result) { described_class }
  end
end
