require 'spec_helper'

# The helpers are NOT included in these tests so we can
# safely test for helpers within clean contexts
describe Deterministic::Either::AttemptAll do
  it "#try evaluates the result as Success" do
    expect(
      Deterministic::Either.attempt_all do
        try { @a = 1 }
        try { @b = @a + 1 }
      end
    ).to eq Deterministic::Success.new(2)
  end

  it "#try values are passed to the next command" do
    expect(
      Deterministic::Either.attempt_all do
        try { 1 }
        try { |v| v + 1 }
      end
    ).to eq Deterministic::Success.new(2)
  end

  it "try treat exceptions as Failure" do
    attempt = Deterministic::Either.attempt_all do
      try { 1 }
      try { raise "error" }
    end.value
    expect(attempt).to be_a RuntimeError
    expect(attempt.message).to eq "error"
  end

  it "don't continue on failure" do
    fake = double()
    expect(
      Deterministic::Either.attempt_all do
        try { 1 }
        let { Failure(2) }
        try { fake.should_not_be_called }
      end
    ).to eq Deterministic::Failure.new(2)
  end

  it "#let expects Success or Failure" do
    expect(
      Deterministic::Either.attempt_all do
        let { Success(1) }
      end
    ).to eq Deterministic::Success.new(1)

    expect {
      Deterministic::Either.attempt_all do
        let { 1 }
      end
    }.to raise_error(Deterministic::Either::AttemptAll::EitherExpectedError)
  end

  it "#let will not catch errors" do
    expect {
      Deterministic::Either.attempt_all do
        let { raise "error" }
      end
    }.to raise_error
  end

  it "#let passes params unboxed" do
    expect(
      Deterministic::Either.attempt_all do
        try { 1 }
        let { |v| Success(v + 1) }
      end
    ).to eq Deterministic::Success.new(2)
  end

  it "works with an OpenStruct" do
    context = OpenStruct.new
    context.extend Deterministic::Helpers

    attempt = Deterministic::Either.attempt_all(context) do
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
      Deterministic::Either.attempt_all(context) do
        try { self.a += 1 }
        try { self.a + 1 }
      end
    ).to eq Deterministic::Success.new(3)

    expect(context.a).to eq 2
  end
end
