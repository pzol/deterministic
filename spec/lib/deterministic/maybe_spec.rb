require 'spec_helper'
require 'deterministic/maybe'

describe 'maybe' do
  it "does something" do
    expect(maybe(nil).foo).to be_none
    expect(maybe(nil).foo.bar.baz).to be_none
    expect(maybe(nil).fetch(:a)).to be_none
    expect(maybe(1)).to be_some
    expect(maybe({a: 1}).fetch(:a)).to eq 1
    expect(maybe({a: 1})[:a]).to eq 1
    expect(maybe("a").upcase).to eq "A"
    expect(maybe("a")).not_to be_none
  end

  it 'Nothing#to_s' do
    expect(None.to_s).to eq 'None'
  end
end
