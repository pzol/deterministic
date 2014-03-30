require "spec_helper"
require "deterministic/none"

describe None do
  it "None is a Singleton" do
    expect(None.instance).to be_a None
    expect { None.new }.to raise_error(NoMethodError, "private method `new' called for None:Class")
  end

  it "explicit conversions" do
    expect(None.to_s).to eq 'None'
    expect(None.inspect).to eq 'None'
  end

  it "compares to None" do
    expect(None === None.instance).to be_truthy
    expect(None.instance === None).to be_truthy
    expect(None.instance).to eq None
    expect(None).to eq None.instance
    expect(1).not_to be None
    expect(1).not_to be None.instance
    expect(None.instance).not_to be 1
    expect(None).not_to be 1
    expect(None.instance).not_to be_nil
    expect(None).not_to be_nil
  end

  it "implicit conversions" do
    none = None.instance
    expect(none.to_str).to eq ""
    expect(none.to_ary).to eq []
    expect("" + none).to eq ""

    a, b, c = none
    expect(a).to be_nil
    expect(b).to be_nil
    expect(c).to be_nil
  end

  it "mimicks other classes and returns None for their public methods" do
    class UnderMimickTest
      def test; end
    end

    mimick = None.mimic(UnderMimickTest)
    expect(mimick.test).to be_none
    expect { mimick.i_dont_exist}.to raise_error(NoMethodError)
  end
end
