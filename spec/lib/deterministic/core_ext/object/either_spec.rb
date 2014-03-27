require "spec_helper"
require "deterministic/core_ext/object/either"

describe Deterministic::CoreExt::Either, "object", isolate: true do
  it "does something" do
    h = {a: 1}
    expect(h.success?).to be_falsey
    expect(h.failure?).to be_falsey
    expect(h.either?).to be_falsey
  end

  it "use attempt_all in an instance" do
    class UnderTest
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
