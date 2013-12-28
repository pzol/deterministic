module Deterministic::Match

  def match(proc=nil, &block)
    match = Match.new(self)
    match.instance_eval &(proc || block)
    match.result
  end

  class NoMatchError < StandardError; end

  class Match
    def initialize(container)
      @container  = container
      @collection = []
    end

    def result
      matcher = @collection.select { |m| m.matches?(@container.value) }.last
      raise NoMatchError if matcher.nil?
      matcher.result(@container.value)
    end

    # Either specific DSL
    def success(value=nil, &block)
      q(:success, value, block)
    end

    def failure(value=nil, &block)
      q(:failure, value, block)
    end

    def either(value=nil, &block)
      q(:either, value, block)
    end

  private
    Matcher = Struct.new(:condition, :block) do 
      def matches?(value)
        condition.call(value)
      end

      def result(value)
        block.call(value)
      end
    end

    def q(type, condition, block)
      if condition.nil?
        condition_p = ->(v) { true }
      elsif condition.is_a?(Proc)
        condition_p = condition
      else
        condition_p = ->(v) { condition == @container.value }
      end

      @collection << Matcher.new(condition_p, block) if @container.is? type
    end
  end
end
