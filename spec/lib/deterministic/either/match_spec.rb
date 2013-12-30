require 'spec_helper'
require 'deterministic'

include Deterministic

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

  it "can match with classes" do
    expect(
      Success([1, 2, 3]).match do
        success(Array) { |v| v.first }
      end
    ).to eq 1

    expect(
      Success(1).match do
        success(Fixnum) { |v| v }
      end
    ).to eq 1
  end

  it "catch-all" do
    expect(
      Success(1).match do
        any { "catch-all" }
      end
    ).to eq "catch-all"
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

  it "can match with lambdas" do
    expect(
      Success(1).match do
        failure                  { "not me" }
        success ->(v) { v == 1 } { |v| "matched #{v}" }
      end
    ).to eq "matched 1"
  end

  it "no match" do
    expect {
      Success(1).match do
        failure { "you'll never get me" }
      end
    }.to raise_error Deterministic::PatternMatching::NoMatchError
  end
end
