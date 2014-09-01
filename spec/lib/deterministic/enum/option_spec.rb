require 'spec_helper'
require 'deterministic/enum/option'

describe Optional do
  Some = described_class::Some
  None = described_class::None.new

  def Some(s); Some.new(s); end

  it "fmap" do
    expect(Some(1).fmap { |n| n + 1}).to eq Some(2)
    expect(None.fmap { |n| n + 1}).to eq None
  end

  it "map" do
    expect(Some(1).map { |n| n + 1}).to eq Some(2)
    expect(None.fmap { |n| n + 1}).to eq None
  end

  it "some?" do
    expect(Some(1).some?).to be_truthy
    expect(None.some?).to be_falsey
  end

  it "none?" do
    expect(None.none?).to be_truthy
    expect(Some(1).none?).to be_falsey
  end

  it "unwrap" do
    expect(Some(1).unwrap).to eq 1
    expect{ None.unwrap }.to raise_error NoneValueError
  end

  it "unwrap_or" do
    expect(Some(1).unwrap_or(2)).to eq 1
    expect(None.unwrap_or(0)).to eq 0
  end

  it "+" do
    expect(Some(1) + None).to eq Some(1)
    expect(Some(1) + None + None).to eq Some(1)
    expect(Some(1) + Some(1)).to eq Some(2)
    expect(None + Some(1)).to eq Some(1)
    expect(None + None + Some(1)).to eq Some(1)
    expect(None + None + Some(1) + None).to eq Some(1)
    expect { Some([1]) + Some(1)}.to raise_error TypeError
  end

  it "inspect" do
    expect(Some(1).inspect).to eq "Some(s: 1)"
    expect(Optional::None.new.inspect).to eq "None"
  end

  it "to_s" do
    expect(Some(1).to_s).to eq "[1]"
    expect(Optional::None.new.to_s).to eq ""
  end
end
