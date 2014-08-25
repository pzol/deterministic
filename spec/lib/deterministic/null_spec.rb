require "spec_helper"
require "deterministic/null"

describe Null do
  it "Null is a Singleton" do
    expect(Null.instance).to be_a Null
    expect { Null.new }.to raise_error(NoMethodError, "private method `new' called for Null:Class")
  end

  it "explicit conversions" do
    expect(Null.to_s).to eq 'Null'
    expect(Null.inspect).to eq 'Null'
  end

  it "compares to Null" do
    expect(Null === Null.instance).to be_truthy
    expect(Null.instance === Null).to be_truthy
    expect(Null.instance).to eq Null
    expect(Null).to eq Null.instance
    expect(1).not_to be Null
    expect(1).not_to be Null.instance
    expect(Null.instance).not_to be 1
    expect(Null).not_to be 1
    expect(Null.instance).not_to be_nil
    expect(Null).not_to be_nil
  end

  it "implicit conversions" do
    null = Null.instance
    expect(null.to_str).to eq ""
    expect(null.to_ary).to eq []
    expect("" + null).to eq ""

    a, b, c = null
    expect(a).to be_nil
    expect(b).to be_nil
    expect(c).to be_nil
  end

  it "mimicks other classes and returns Null for their public methods" do
    class UnderMimickTest
      def test; end
    end

    mimick = Null.mimic(UnderMimickTest)
    expect(mimick.test).to be_null
    expect { mimick.i_dont_exist}.to raise_error(NoMethodError)
  end
end
