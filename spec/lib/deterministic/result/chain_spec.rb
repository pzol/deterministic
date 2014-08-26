require 'spec_helper'

include Deterministic

describe Deterministic::Result do
  context ">> (map)" do
    specify { expect(Success(0).map { |n| Success(n + 1) }).to eq Success(1) }
    specify { expect(Failure(0).map { |n| Success(n + 1) }).to eq Failure(0) }

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

    it "expects an Result" do
      def returns_non_result(i)
        2
      end

      expect { Success(1) >> method(:returns_non_result) }.to raise_error(Deterministic::Monad::NotMonadError)
    end

    it "works with a block" do
      expect(
        Success(1).map { |i| Success(i + 1) }
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

  context "using self as the context for success" do
    class SelfContextUnderTest
      def call
        @step = 0
        Success(self).
          map(&:validate).
          map(&:build).
          map(&:send)
      end

      def validate
        @step = 1
        Success(self)
      end

      def build
        @step = 2
        Success(self)
      end

      def send
        @step = 3
        Success(self)
      end

      def inspect
        "Step #{@step}"
      end

      # # def self.procify(*meths)
      # #   meths.each do |m|
      # #     new_m = "__#{m}__procified".to_sym
      # #     alias new_m m
      # #     define_method new_m do |ctx|
      # #       method(m)
      # #     end
      # #   end
      # # end

      # procify :send
    end

    it "works" do
      test = SelfContextUnderTest.new.call
      expect(test).to be_a described_class::Success
      expect(test.inspect).to eq "Success(Step 3)"
    end
  end

  context "** (pipe)" do
    it "ignores the output of pipe" do
      acc = "ctx: "
      log = ->(ctx) { acc += ctx.inspect }

      actual = Success(1).pipe(log).map { Success(2) }
      expect(actual).to eq Success(2)
      expect(acc).to eq "ctx: Success(1)"
    end

    it "works with **" do
      log = ->(n) { n.value + 1 }
      foo = ->(n) { Success(n + 1) }

      actual = Success(1) ** log >> foo 
    end
  end

  context ">= (try)" do
    it "try (>=) catches errors and wraps them as Failure" do
      def error(ctx)
        raise "error #{ctx}"
      end

      actual = Success(1) >= method(:error)
      expect(actual.inspect).to eq "Failure(#<RuntimeError: error 1>)"
    end
  end
end
