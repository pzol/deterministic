require 'spec_helper'
require_relative 'monad_axioms'


describe Deterministic::Monad do
  class Identity
    include Deterministic::Monad
  end

  let(:monad) { Identity }
  it_behaves_like 'a Monad' do
    # let(:monad) { monad }
  end

  specify { expect(Identity.new(1).inspect).to  eq 'Identity(1)' }
  specify { expect(Identity.new(1).to_s).to  eq '1' }
  specify { expect(Identity.new(nil).inspect).to  eq 'Identity(nil)' }
  specify { expect(Identity.new(nil).to_s).to  eq '' }
  specify { expect(Identity.new([1, 2]).fmap(&:to_s)).to eq Identity.new("[1, 2]") }
  specify { expect(Identity.new(1).fmap {|v| v + 2}).to eq Identity.new(3) }
  specify { expect(Identity.new('foo').fmap(&:upcase)).to eq Identity.new('FOO')}

  context '#bind' do
    it "raises an error if the passed function does not return a monad of the same class" do
      expect { Identity.new(1).bind {} }.to raise_error(Deterministic::Monad::NotMonadError)
    end
    specify { expect(Identity.new(1).bind {|value| Identity.new(value) }).to eq Identity.new(1) }

    it "passes the monad class, this is ruby-fu?!" do
     Identity.new(1)
      .bind do |_|
        expect(monad).to eq Identity
        monad.new(_)
      end
    end

    specify { expect(
      monad.new(1).bind { |value| monad.new(value + 1) }
      ).to eq Identity.new(2)
    }

  end
  specify { expect(Identity.new(Identity.new(1))).to eq Identity.new(1) }
end
