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

end
