require 'spec_helper'
require_relative 'monad_axioms'


describe Deterministic::Monad, :include_helpers => true do
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

  context '#bind' do
    it "raises an error if the passed function does not return a monad of the same class" do
      expect { Identity.new(1).bind {} }.to raise_error(Deterministic::Monad::NotMonadError)
    end
    specify { expect(Identity.new(1).bind {|value| Identity.new(value) }).to eq Identity.new(1) }

    it "passes the monad class, this is ruby-fu?!" do
     Identity.new(1)
      .bind do |_, monad|
        expect(monad).to eq Identity
        monad.new(_)
      end
    end

    specify { expect(
      Identity.new(1).bind { |value, monad| monad.new(value + 1) }
      ).to eq Identity.new(2)
    }

  end
  specify { expect(Identity.new(Identity.new(1))).to eq Identity.new(1) }

  # it 'delegates #flat_map to an underlying collection and wraps the resulting collection' do
  #   Identity.unit([1,2]).flat_map {|v| v + 1}.should == Identity.unit([2, 3])
  #   Identity.unit(['foo', 'bar']).flat_map(&:upcase).should == Identity.unit(['FOO', 'BAR'])
  #   expect { Identity.unit(1).flat_map {|v| v + 1 } }.to raise_error(RuntimeError)
  # end

end
