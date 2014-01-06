require 'spec_helper'

describe Deterministic::Either do
  it "can't call Either#new directly" do
   expect { described_class.new(1)}
    .to raise_error(NoMethodError, "protected method `new' called for Deterministic::Either:Class")
  end
end
