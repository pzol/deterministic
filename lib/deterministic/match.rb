module Deterministic
  module GlobalPatternMatching

    def match(context=nil, &block)
      context ||= block.binding.eval('self') # the instance containing the match block
      match = binding.eval('self.class::Match.new(self, context)') # the class defining the Match
      match.instance_eval &block
      match.call
    end

    class NoMatchError < StandardError; end

    module Match
      def initialize(container, context)
        @container  = container
        @context    = context
        @collection = []
      end

      def call
        matcher = @collection.detect { |m| m.matches?(@container.value) }
        raise NoMatchError, "No match could be made for #{@container.inspect}" if matcher.nil?
        @context.instance_exec(@container.value, &matcher.block)
      end

      # catch-all
      def any(value=nil, &result_block)
        push(Object, value, result_block)
      end

    private
      Matcher = Struct.new(:condition, :block) do
        def matches?(value)
          condition.call(value)
        end
      end

      def push(type, condition, result_block)
        condition_pred = case
        when condition.nil?;          ->(v) { true }
        when condition.is_a?(Proc);   condition
        when condition.is_a?(Class);  ->(v) { condition === @container.value }
        else                          ->(v) { @container.value == condition }
        end

        matcher_pred = compose_predicates(type_pred[type], condition_pred)
        @collection << Matcher.new(matcher_pred, result_block)
      end

      def compose_predicates(f, g)
        ->(*args) { f[*args] && g[*args] }
      end

      # return a partial function for matching a matcher's type
      def type_pred
        (->(type, x) { @container.is_a? type }).curry
      end
    end
  end
end
