require "spec_helper"
require "deterministic/core_ext/object/either"

describe Deterministic::CoreExt::Either, "object", isolate: true do
  it "does something" do
    h = {a: 1}
    expect(h.success?).to be_falsey
    expect(h.failure?).to be_falsey
    expect(h.either?).to be_falsey
  end
end
