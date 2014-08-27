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
            klas = self.class.module_eval(s)
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

    ## Convert the inner value to an Array
    def value_to_a
      map { self.class.new(Array(value)) }
    end

    ## Add the inner values of two Some
    def +(other)
      return other if none?
      fmap { |v| 
        other.match {
          some { v + other.value }
          none { self }
        }
      }
    end

    def some?
      is_a? Some
    end

    def none?
      is_a? None
    end

    def value_or(default)
      return default if none?
      return value
    end

    class Some < Option
      class << self; public :new; end
    end

    class None < Option
      class << self; public :new; end
      def initialize(*args)
        @value = self
      end

      def inspect
        "None"
      end

      private :value

      def fmap(*args)
        self
      end

      alias :map :fmap

      def ==(other)
        other.class == self.class
      end
    end
  end

module_function
  def Some(value)
    Option::Some.new(value)
  end

  None = Deterministic::Option::None.new
end
# p Deterministic::Option::Some::Match.new(.methods
