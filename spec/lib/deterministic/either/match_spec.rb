require 'spec_helper'
require 'deterministic'

include Deterministic::Either

describe Deterministic::Either::Match do
  it "can be match Success" do
    expect(
      Success(1).match do |m|
        m.success { |v| "Success #{v}" }
        m.failure { |v| "Failure #{v}" }
      end
    ).to eq "Success 1" 
  end

  it "can be match Failure" do
    expect(
      Failure(1).match do |m|
        m.success { |v| "Success #{v}" }
        m.failure { |v| "Failure #{v}" }
      end
    ).to eq "Failure 1" 
  end
end
