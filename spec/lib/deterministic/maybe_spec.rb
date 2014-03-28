require 'spec_helper'
require 'deterministic/maybe'

describe 'maybe' do
  it "does something" do
    expect(maybe(nil).foo).to be_nothing
    expect(maybe(nil).fetch(:a)).to be_nothing
    expect(maybe({a: 1}).fetch(:a)).to eq 1
    expect(maybe("a").upcase).to eq "A"
    expect(maybe("a")).not_to be_nothing
  end

  it 'Nothing#to_s' do
    expect(Nothing.to_s).to eq 'Nothing'
  end
end
