require 'spec_helper'
require_relative 'monad_axioms'
require 'deterministic'


describe Deterministic::Monad do
  class Identity 
    include Deterministic::Monad
  end

  it_behaves_like 'a Monad' do 
    let(:monad) { Identity }
  end

  specify { expect(Identity.new(1).to_s).to  eq 'Identity(1)' }
  specify { expect(Identity.new(nil).to_s).to  eq 'Identity(nil)' }
  specify { expect(Identity.new([1, 2]).map(&:to_s)).to eq Identity.new("[1, 2]") }
  specify { expect(Identity.new(1).map {|v| v + 2}).to eq Identity.new(3) }
  specify { expect(Identity.new('foo').map(&:upcase)).to eq Identity.new('FOO')}
  specify { expect { Identity.new(1).bind {} }.to raise_error(Deterministic::Monad::NotMonadError) }
  specify { expect(Identity.new(Identity.new(1))).to eq Identity.new(1) }

  # it 'delegates #flat_map to an underlying collection and wraps the resulting collection' do
  #   Identity.unit([1,2]).flat_map {|v| v + 1}.should == Identity.unit([2, 3])
  #   Identity.unit(['foo', 'bar']).flat_map(&:upcase).should == Identity.unit(['FOO', 'BAR'])
  #   expect { Identity.unit(1).flat_map {|v| v + 1 } }.to raise_error(RuntimeError)
  # end

end
