require 'spec_helper'
require 'deterministic'

include Deterministic

describe Deterministic::Either::AttemptAll do
  it "#try evaluates the result as Success" do
    expect(
      Either.attempt_all do
        try { @a = 1 }
        try { @b = @a + 1 }
      end
    ).to eq Success(2)
  end

  it "#try values are passed to the next command" do
    expect(
      Either.attempt_all do
        try { 1 }
        try { |v| v + 1 }
      end
    ).to eq Success(2)
  end

  it "try treat exceptions as Failure" do
    attempt = Either.attempt_all do
      try { 1 }
      try { raise "error" }
    end.value
    expect(attempt).to be_a RuntimeError
    expect(attempt.message).to eq "error"
  end
  
  it "don't continue on failure" do
    fake = double()
    expect(
      Either.attempt_all do
        try { 1 }
        let { Failure(2) }
        try { fake.should_not_be_called }
      end
    ).to eq Failure(2)
  end

  it "#let expects Success or Failure" do
    expect(
      Either.attempt_all do
        let { Success(1) }
      end
    ).to eq Success(1)

    expect {
      Either.attempt_all do
        let { 1 }
      end
    }.to raise_error(Deterministic::Either::AttemptAll::EitherExpectedError)
  end

  it "#let will not catch errors" do
    expect {
      Either.attempt_all do
        let { raise "error" }
      end
    }.to raise_error
  end

  it "#let passes params unboxed" do
    expect(
      Either.attempt_all do
        try { 1 }
        let { |v| Success(v + 1) }
      end
    ).to eq Success(2)
  end

  it "works with an OpenStruct" do
    context = OpenStruct.new
    attempt = Either.attempt_all(context) do
      let { Success(self.alpha = 2) }
      try { self.res = 1 }
    end

    expect(context.res).to eq 1
    expect(context.alpha).to eq 2
  end

  it "can operate in the context of a context" do
    class Context
      attr_accessor :a
      def initialize
        @a = 1
      end
    end

    context = Context.new

    expect(
      Either.attempt_all(context) do
        try { self.a += 1 }
        try { self.a + 1 }
      end
    ).to eq Success(3)

    expect(context.a).to eq 2
  end
end
