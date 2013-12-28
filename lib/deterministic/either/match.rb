module Deterministic::Match

  def match(proc=nil, &block)
    match = Match.new(self)
    match.instance_eval &(proc || block)
    match.result
  end

  class Match
    def initialize(container)
      @container  = container
      @collection = []
    end

    def result
      matcher = @collection.select { |m| m.condition.call(@container.value) }.last
      matcher.block.call(@container.value)
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
    Matcher = Struct.new(:condition, :block)

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
