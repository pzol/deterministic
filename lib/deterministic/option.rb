module Deterministic
  # Abstract parent of Some and None
  class Option
    include Monad

    module PatternMatching
      include Deterministic::PatternMatching
      class Match
        include Deterministic::PatternMatching::Match

        %w[Some None Option].each do |s|
          define_method s.downcase.to_sym do |value=nil, &block|
            klas = Deterministic::Option.const_get(s)
            push(klas, value, block)
          end
        end
      end
    end

    include PatternMatching

    # This is an abstract class, can't ever instantiate it directly
    class << self
      protected :new

      def some?(expr)
        to_option(expr) { expr.nil? }
      end

      def any?(expr)
        to_option(expr) { expr.nil? || not(expr.respond_to?(:empty?)) || expr.empty? }
      end

      def to_option(expr, &predicate)
        predicate.call(expr) ? None.new : Some.new(expr)
      end

      def try!
        yield rescue None.new
      end
    end

    def map(proc=nil, &block)
      return self if none?
      bind(proc || block)
    end

    def some?
      is_a? Some
    end

    def none?
      is_a? None
    end

    class Some < Option
      class << self; public :new; end
    end

    class None < Option
      class << self; public :new; end
      def initialize(*args); end

      def inspect
        "None"
      end

      # def value
      #   self
      # end
      def none(*args)
        self
      end

      alias :fmap :none
      alias :map :none

      def ==(other)
        other.class == self.class
      end

      # def value
      #   self # raise "value called on a None"
      # end
    end
  end

  module_function
  def Some(value)
    Option::Some.new(value)
  end

  None = Deterministic::Option::None.new
end
# p Deterministic::Option::Some::Match.new(.methods
