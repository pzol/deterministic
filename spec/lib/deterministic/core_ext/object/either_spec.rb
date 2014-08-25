require "spec_helper"
require "deterministic/core_ext/object/result"

describe Deterministic::CoreExt::Result, "object", isolate: true do
  it "does something" do
    h = {a: 1}
    expect(h.success?).to be_falsey
    expect(h.failure?).to be_falsey
    expect(h.result?).to be_falsey
  end
end
