require 'spec_helper'
require 'deterministic/maybe'

describe 'maybe' do
  it "does something" do
    expect(Maybe(nil).foo).to be_none
    expect(Maybe(nil).foo.bar.baz).to be_none
    expect(Maybe(nil).fetch(:a)).to be_none
    expect(Maybe(1)).to be_some
    expect(Maybe({a: 1}).fetch(:a)).to eq 1
    expect(Maybe({a: 1})[:a]).to eq 1
    expect(Maybe("a").upcase).to eq "A"
    expect(Maybe("a")).not_to be_none
  end

  it "None is a Singleton" do
    expect(None.instance).to be_a None
    expect { None.new }.to raise_error(NoMethodError, "private method `new' called for None:Class")
  end

  it "implicit conversions" do
    null = Maybe(nil)
    expect(null.to_str).to eq ""
    expect(null.to_ary).to eq []
    expect("" + null).to eq ""

    a, b, c = null
    expect(a).to be_nil
    expect(b).to be_nil
    expect(c).to be_nil
  end

  it "explicit conversions" do
    expect(None.to_s).to eq 'None'
  end

  it "mimic, only return None on specific methods of another class" do
    class MimicTest
      def test
      end
    end

    mimic = None.mimic(MimicTest)
    expect(mimic.test).to be_none
    expect { mimic.foo }.to raise_error(NoMethodError)
  end
end
