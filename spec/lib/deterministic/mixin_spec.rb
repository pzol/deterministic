require 'spec_helper'

# The helpers are NOT included in these tests so we can
# safely test for helpers within a specified context
describe 'Mixin Functionality' do

  module MyApp
    class Thing
      include Deterministic::Helpers
      def run
        attempt_all(self) do
          try { 57 }
          let {|num| double(num)}
        end
      end

      def double(num)
        Success(num * 2)
      end
    end
  end

  it "cleanly mixes into a class" do
    result = MyApp::Thing.new.run
    expect(result).to eq Deterministic::Success.new(114)
  end
end
