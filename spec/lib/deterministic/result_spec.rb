require 'spec_helper'

describe Deterministic::Result do
  it "can't call Result#new directly" do
   expect { described_class.new(1)}
    .to raise_error(NoMethodError, "protected method `new' called for Deterministic::Result:Class")
  end
end

describe Deterministic::Result do
  include Deterministic

  specify{ expect(Success(Success(1))).to eq(Success(1)) }
  specify{ expect(Failure(Failure(1))).to eq(Failure(1)) }
  specify{ expect(Success(Failure(1))).to eq(Success(1)) }
  specify{ expect(Failure(Success(1))).to eq(Failure(1)) }
  specify{ expect(Success(Some(1))).to eq(Success(1))}
end
