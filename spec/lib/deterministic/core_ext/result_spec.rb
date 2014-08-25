require "spec_helper"
require "deterministic"
require "deterministic/core_ext/result"

describe Deterministic::CoreExt::Result do
  it "does something" do
    h = {}
    h.extend(Deterministic::CoreExt::Result)
    expect(h.success?).to be_falsey
    expect(h.failure?).to be_falsey
    expect(h.result?).to be_falsey
  end

  it "enables #success?, #failure?, #result? on all Objects" do
    ary = [Deterministic::Success(true), Deterministic::Success(1)]
    expect(ary.all?(&:success?)).to be_truthy

    ary = [Deterministic::Success(true), Deterministic::Failure(1)]
    expect(ary.all?(&:success?)).to be_falsey
    expect(ary.any?(&:failure?)).to be_truthy
  end
end
