module Deterministic
  module Sequencer
    InvalidSequenceError = Class.new(StandardError)

    module Operation
      Get = Struct.new(:block, :name)
      Let = Struct.new(:block, :name)
      AndThen = Struct.new(:block)
      Observe = Struct.new(:block)
      AndYield = Struct.new(:block)
    end

    def in_sequence(&block)
      sequencer = Sequencer.new(self)
      sequencer.instance_eval(&block)
      sequencer.yield
    end

    class Sequencer
      def initialize(instance)
        @operations = []
        @operation_wrapper = OperationWrapper.new(instance)
      end

      def get(name, &block)
        raise ArgumentError, 'no block given'.freeze unless block_given?
        raise InvalidSequenceError, 'and_yield already called'.freeze if @sequenced_operations

        @operations << Operation::Get.new(block, name)
      end

      def let(name, &block)
        raise ArgumentError, 'no block given'.freeze unless block_given?
        raise InvalidSequenceError, 'and_yield already called'.freeze if @sequenced_operations

        @operations << Operation::Let.new(block, name)
      end

      def and_then(&block)
        raise ArgumentError, 'no block given'.freeze unless block_given?
        raise InvalidSequenceError, 'and_yield already called'.freeze if @sequenced_operations

        @operations << Operation::AndThen.new(block)
      end

      def observe(&block)
        raise ArgumentError, 'no block given'.freeze unless block_given?
        raise InvalidSequenceError, 'and_yield already called'.freeze if @sequenced_operations

        @operations << Operation::Observe.new(block)
      end

      def and_yield(&block)
        raise ArgumentError, 'no block given'.freeze unless block_given?
        raise InvalidSequenceError, 'and_yield already called'.freeze if @sequenced_operations

        @operations << Operation::AndYield.new(block)

        prepare_sequenced_operators
      end

      def yield
        raise InvalidSequenceError, 'and_yield not called'.freeze unless @sequenced_operations

        @operation_wrapper.instance_eval(&@sequenced_operations)
      end

      private

      def prepare_sequenced_operators
        operations = @operations

        @sequenced_operations = lambda do |_|
          operations.reduce(Result::Success(nil)) do |last_result, operation|
            last_result.map do
              case operation
              when Operation::Get
                result = instance_eval(&operation.block)
                result.map do |output|
                  # This will be executed in the context of the OperationWrapper
                  # and so the results will be stored within the
                  # OperationWrapper.
                  @gotten_results[operation.name] = output
                  result
                end
              when Operation::Let
                @gotten_results[operation.name] = instance_eval(&operation.block)
                last_result
              when Operation::AndThen
                instance_eval(&operation.block)
              when Operation::Observe
                instance_eval(&operation.block)
                last_result
              when Operation::AndYield
                instance_eval(&operation.block)
              else
                "Uknown operation: #{operation.class}"
              end
            end
          end
        end
      end
    end

    # OperationWrapper proxies all method calls to the wrapped instance, but
    # first checks if the name of the called method matches a value stored
    # within @gotten_results and returns the value if it does.
    class OperationWrapper < SimpleDelegator
      def initialize(*args)
        super
        @gotten_results = {}
      end

      def method_missing(name, *args, &block)
        if @gotten_results.key?(name)
          @gotten_results[name]
        else
          super
        end
      end

      def respond_to_missing?(name, include_private = false)
        @gotten_results.key?(name) || super
      end
    end
  end

  module Prelude
    include Sequencer
  end
end
