require 'spec_helper'

include Deterministic

describe Deterministic::Option do
  pending {
  # nil?
  specify { expect(described_class.some?(nil)).to eq None }
  specify { expect(described_class.some?(1)).to be_some }
  specify { expect(described_class.some?(1)).to eq Some(1) }


  # # any?
  specify { expect(described_class.any?(nil)).to be_none }
  specify { expect(described_class.any?(None)).to be_none }
  specify { expect(described_class.any?("")).to  be_none }
  specify { expect(described_class.any?([])).to  be_none }
  specify { expect(described_class.any?({})).to  be_none }
  specify { expect(described_class.any?([1])).to eq Some([1]) }
  specify { expect(described_class.any?({foo: 1})).to eq Some({foo: 1}) }

  # try!
  specify { expect(described_class.try! { raise "error" }).to be_none }
  }
end
