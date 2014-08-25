require 'spec_helper'

describe Deterministic::Result do
  it "can't call Result#new directly" do
   expect { described_class.new(1)}
    .to raise_error(NoMethodError, "protected method `new' called for Deterministic::Result:Class")
  end
end
