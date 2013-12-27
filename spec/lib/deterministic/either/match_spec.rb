require 'spec_helper'
require 'deterministic'

include Deterministic::Either

describe Deterministic::Either::Match do
  it "can match Success" do
    expect(
      Success(1).match do
        success { |v| "Success #{v}" }
        failure { |v| "Failure #{v}" }
      end
    ).to eq "Success 1" 
  end

  it "can match Failure" do
    expect(
      Failure(1).match do
        success { |v| "Success #{v}" }
        failure { |v| "Failure #{v}" }
      end
    ).to eq "Failure 1" 
  end

  it "can match with values" do
    expect(
      Failure(2).match do
        success    { |v| "not matched s"  }
        success(1) { |v| "not matched s1" }
        failure(1) { |v| "not matched f1" }
        failure(2) { |v| "matched #{v}"   }
        failure(3) { |v| "not matched f3" }
      end
    ).to eq "matched 2"
  end

  it "can match either" do
    expect(
      Failure(2).match do
        success    { |v| "not matched s"  }
        either(2)  { |v| "either #{v}"    }
        failure(3) { |v| "not matched f3" }
      end
    ).to eq "either 2"
  end
end
