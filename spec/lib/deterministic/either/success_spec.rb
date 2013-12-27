require 'spec_helper'
require 'deterministic'

include Deterministic::Either

describe Deterministic::Either::Success do
  subject { described_class.unit(1) }

  specify { expect(subject).to be_an_instance_of described_class }
  specify { expect(subject.value).to eq 1 }
  specify { expect(subject).to be_success }
  specify { expect(subject).not_to be_failure }

  # public constructor #Success[]
  specify { expect(described_class.unit(1)).to be_an_instance_of described_class }
  specify { expect(subject).to eq(described_class.unit(1))}

  it "handles chaining using &" do
    expect(Success(1).bind Success(2)).to eq(Success(2))
    expect(Success(1).bind Failure(2)).to eq(Failure(2))
  end

  specify { expect(Success(Success(1))).to eq Success(1) }
  specify { expect(Success(1).is? :success).to be true }
  specify { expect(Success(1).is? :either).to  be true  }
  specify { expect(Success(1).is? :failure).to be false }
end
