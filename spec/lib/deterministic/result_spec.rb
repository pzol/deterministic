require 'spec_helper'

describe Deterministic::Result do
  it "can't call Result#new directly" do
    expect { described_class.new(1)}
    .to raise_error(NoMethodError, "protected method `new' called for Deterministic::Result:Class")
  end
end

describe Deterministic::Result do
  include Deterministic
  describe "+" do
    specify { expect(Success(1) + Success(1)).to eq Success(2) }
    specify { expect(Failure(1) + Failure(1)).to eq Failure(2) }
    specify { expect { Success([1]) + Success(1)}.to raise_error TypeError}
    specify { expect { Failure([1]) + Failure(1)}.to raise_error TypeError}
    specify { expect(Success(1) + Failure(2)).to eq Failure(2) }
    specify { expect(Failure(1) + Success(2)).to eq Failure(1) }
    specify { expect(Success(1) + Failure(2) + Failure(3)).to eq Failure(5) }
    specify { expect(Failure([2]) + Failure([3]) + Success(1)).to eq Failure([2, 3]) }
    specify { expect(Success([1]) + Success([1])).to eq Success([1, 1]) }
  end
end
