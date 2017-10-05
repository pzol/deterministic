module Deterministic
  module Sequencer
    InvalidSequenceError = Class.new(StandardError)

    Operation = Deterministic.enum do
      Get(:block, :name)
      Let(:block, :name)
      AndThen(:block)
      Observe(:block)
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

        @operations.unshift(Operation::Get(block, name))
      end

      def let(name, &block)
        raise ArgumentError, 'no block given'.freeze unless block_given?
        raise InvalidSequenceError, 'and_yield already called'.freeze if @sequenced_operations

        @operations.unshift(Operation::Let(block, name))
      end

      def and_then(&block)
        raise ArgumentError, 'no block given'.freeze unless block_given?
        raise InvalidSequenceError, 'and_yield already called'.freeze if @sequenced_operations

        @operations.unshift(Operation::AndThen(block))
      end

      def observe(&block)
        raise ArgumentError, 'no block given'.freeze unless block_given?
        raise InvalidSequenceError, 'and_yield already called'.freeze if @sequenced_operations

        @operations.unshift(Operation::Observe(block))
      end

      def and_yield(&yield_block)
        raise ArgumentError, 'no block given'.freeze unless block_given?
        raise InvalidSequenceError, 'and_yield already called'.freeze if @sequenced_operations

        @sequenced_operations = @operations.inject(yield_block) do |memo, cur|
          lambda do |*|
            cur.match do
              Get do |block, name|
                instance_eval(&block).map do |output|
                  # This will be executed in the context of the OperationWrapper
                  # and so the results will be stored within the
                  # OperationWrapper.
                  @gotten_results[name] = output
                  instance_eval(&memo)
                end
              end
              Let do |block, name|
                @gotten_results[name] = instance_eval(&block)
                instance_eval(&memo)
              end
              AndThen do |block|
                instance_eval(&block).map do |_|
                  instance_eval(&memo)
                end
              end
              Observe do |block|
                instance_eval(&block)
                instance_eval(&memo)
              end
            end
          end
        end
      end

      def yield
        raise InvalidSequenceError, 'and_yield not called'.freeze unless @sequenced_operations

        @operation_wrapper.instance_eval(&@sequenced_operations)
      end
    end

    # OperationWrapper proxies all method calls to the wrapped instance, but
    # first checks if the name of the called method matches a value stored
    # within @gotten_results and returns the value if it does.
    class OperationWrapper
      def initialize(instance)
        @instance = instance
        @gotten_results = {}
      end

      # Disable rubocop rule which requires the method to fall back onto super,
      # which is not what we want to do here, because we want the wrapped
      # instance to have the last word.
      def method_missing(name, *args, &block) # rubocop:disable Style/MethodMissing
        if @gotten_results.key?(name)
          @gotten_results[name]
        else
          @instance.send(name, *args, &block)
        end
      end

      def respond_to_missing?(name, include_private = false)
        @gotten_results.key?(name) || @instance.send(:respond_to_missing?, name, include_private)
      end
    end
  end

  module Prelude
    include Sequencer
  end
end
