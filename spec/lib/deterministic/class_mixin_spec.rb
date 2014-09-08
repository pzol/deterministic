require 'spec_helper'

describe 'Class Mixin' do
  describe 'try' do
    module MyApp
      class Thing
        include Deterministic::Prelude::Result

        def run
          Success(11) >> method(:double)
        end

        def double(num)
          Success(num * 2)
        end
      end
    end

    it "cleanly mixes into a class" do
      result = MyApp::Thing.new.run
      expect(result).to eq Deterministic::Result::Success.new(22)
    end
  end
end
