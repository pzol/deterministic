require 'spec_helper'
require 'deterministic/protocol'


module Monoid
  extend Deterministic::Protocol

  Deterministic::protocol(M) {
    fn empty() => M
    fn(append(a => M, b => M) => M) { |a, b|
      a + b
    }
  }

  Int = Deterministic::instance(Monoid, M => Fixnum) {
    def empty()
      0
    end

    def append(a, b)
      a + b + 1
    end
  }

  String = Deterministic::instance(Monoid, M => String) {
    def empty()
      ""
    end
  }
end

describe Monoid do
  it "does something" do
    expect(described_class.constants).to eq [:Protocol, :Int, :String]
    int = described_class::Int.new
    expect(int.empty).to eq 0
    expect(int.append(1, 2)).to eq 4

    str = described_class::String.new
    expect(str.empty).to eq ""
    expect(str.append("a", "b")).to eq "ab"
  end
end
