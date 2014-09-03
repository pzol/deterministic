require 'spec_helper'
require 'deterministic/enum'

Resultal = Deterministic::enum {
  Success(:s)
  Failure(:f)
}

Deterministic::impl(Resultal) {
  def map(&fn)
    match {
      Success(_) { |s| s.bind(&fn) }
      Failure(_) { |f| f }
    }
  end

  alias :and_then :map

  def map_err(&fn)
    match {
      Success(_) { |s| s }
      Failure(_) { |f| f.fmap(&fn) }
    }
  end

  alias :or_else :map_err

  def pipe(&fn)
    fn.call(self)
    self
  end

  def success?
    is_a? Resultal::Success
  end

  def failure?
    is_a? Resultal::Failure
  end

  def or(other)
    match {
      Success(_) { |s| s }
      Failure(_) { other}
    }
  end

  def and(other)
    match {
      Success(_) { other }
      Failure(_) { |f| f }
    }
  end
}

describe Resultal do
  Success = described_class::Success
  Failure = described_class::Failure

  def Success(s); Success.new(s); end
  def Failure(f); Failure.new(f); end

  it "fmap" do
    expect(Success(1).fmap { |n| n + 1}).to eq Success(2)
    expect(Failure(0).fmap { |n| n + 1}).to eq Failure(1)
  end

  it "map" do
    expect(Success(1).map { |n| Success(n + 1)}).to eq Success(2)
    expect(Failure(0).map { |n| Success(n + 1)}).to eq Failure(0)
  end

  subject { Success(1) }
  # specify { expect(subject).to be_an_instance_of described_class }
  specify { expect(subject).to be_success }
  specify { expect(subject).not_to be_failure }
  specify { expect(subject.success?).to be_truthy }
  specify { expect(subject.failure?).to be_falsey }

  # specify { expect(subject).to be_a described_class }
  # specify { expect(subject).to eq(described_class.new(1)) }
  specify { expect(subject.fmap { |v| v + 1} ).to eq Success(2) }
  specify { expect(subject.map { |v| Failure(v + 1) } ).to eq Failure(2) }
  specify { expect(subject.map_err { |v| Failure(v + 1) } ).to eq Success(1) }

  specify { expect(subject.pipe{ |r| raise RuntimeError unless r == Success(1) } ).to eq Success(1) }

  specify { expect(subject.or(Success(2))).to eq Success(1)}
  specify { expect(subject.or_else { Success(2) }).to eq Success(1)}

  specify { expect(subject.and(Success(2))).to eq Success(2)}
  specify { expect(subject.and(Failure(2))).to eq Failure(2)}
  specify { expect(subject.and_then { Success(2) }).to eq Success(2)}
  specify { expect(subject.and_then { Failure(2) }).to eq Failure(2)}
end
