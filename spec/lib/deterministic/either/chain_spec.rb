require 'spec_helper'

include Deterministic

describe Deterministic::Either do
  context ">> (chain)" do
    it "Failure stops execution" do
      class ChainUnderTest
        alias :m :method

        def call
          init >> 
            m(:validate) >> 
            m(:send) >> 
            m(:parse)
        end

        def init
          Success({step: 1})
        end

        def validate(i)
          i[:step] = i[:step] + 1
          Success(i)
        end

        def send(i)
          i[:step] = i[:step] + 1
          Failure("Error @ #{i.fetch(:step)}")
        end

        def parse(i)
          i[:step] = i[:step] + 1
          Success(i)
        end
      end

      test = ChainUnderTest.new

      expect(test.call).to eq Failure("Error @ 3")
    end

    it "expects an Either" do
      def returns_non_either(i)
        2
      end

      expect { Success(1) >> method(:returns_non_either) }.to raise_error(Deterministic::Monad::NotMonadError)
    end

    it "works with a block" do
      expect(
        Success(1).chain { |i| Success(i + 1) }
      ).to eq Success(2)
    end

    it "works with a lambda" do
      expect(
        Success(1) >> ->(i) { Success(i + 1) }
      ).to eq Success(2)
    end

    it "does not catch exceptions" do
      expect {
        Success(1) >> ->(i) { raise "error" }
      }.to raise_error(RuntimeError)
    end
  end

  context ">= (try)" do
    it "try (>=) catches errors and wraps them as Failure" do
      def error(ctx)
        raise "error #{ctx}"
      end

      actual = Success(1) >= method(:error)
      expect(actual.inspect).to eq "Failure(error 1)"
    end
  end
end
