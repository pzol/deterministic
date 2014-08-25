require 'spec_helper'
require_relative 'monad_axioms'

include Deterministic

describe Deterministic::Option::Some do
   it_behaves_like 'a Monad' do
    let(:monad) { described_class }
  end

  specify { expect(described_class.new(0)).to eq Some(0) }
  specify { expect(described_class.new(0).some?).to be_truthy }
  specify { expect(described_class.new(0).none?).to be_falsey }

  # specify { expect(described_class.new(1).map { |n| Some(n + 1)}).to eq Some(2) }

  context 'Enumerable' do
    it '#each with array in value' do
      actual = []
      s = Deterministic::Option::Some[1, 2]
      actual = s.iter.map { |n| n + 1 }
      expect(actual).to eq [2, 3]
    end

    it '' do
      Some(1).iter.map { |e| e + 1 }
    end
    
  end
 
end
