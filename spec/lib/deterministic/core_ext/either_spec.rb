require "spec_helper"
require "deterministic"
require "deterministic/core_ext/either"

describe Deterministic::CoreExt::Either do
  it "does something" do
    h = {}
    h.extend(Deterministic::CoreExt::Either)
    expect(h.success?).to be_falsey
    expect(h.failure?).to be_falsey
    expect(h.either?).to be_falsey
  end

  it "enables #success?, #failure?, #either? on all Objects" do
    ary = [Deterministic::Success(true), Deterministic::Success(1)]
    expect(ary.all?(&:success?)).to be_truthy

    ary = [Deterministic::Success(true), Deterministic::Failure(1)]
    expect(ary.all?(&:success?)).to be_falsey
    expect(ary.any?(&:failure?)).to be_truthy
  end

  it "allows using attempt_all on all Objects" do
    h = {a: 1}
    h.extend(Deterministic::CoreExt::Either)
    res = h.attempt_all do
      try { |s| s[:a] + 1}
    end

    expect(res).to eq Deterministic::Success(2)
  end

  it "use attempt_all in an instance" do
    class UnderTest
      include Deterministic::CoreExt::Either
      def test
        attempt_all do
          try { foo }
        end
      end

      def foo
        1
      end
    end

    ut = UnderTest.new
    expect(ut.test).to eq Success(1)
  end
end
