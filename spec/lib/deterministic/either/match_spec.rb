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
end
