module Deterministic
  module Monad
    class NotMonadError < StandardError; end

    def initialize(value)
      @value = join(value)
    end

    # If the passed value is monad already, get the value to avoid nesting
    # M[M[A]] is equivalent to M[A]
    def join(value)
      if value.is_a? self.class then value.value
      else value end
    end

    # The functor: takes a function (a -> b) and applies it to the inner value of the monad (Ma),
    # boxes it back to the same monad (Mb)
    # fmap :: (a -> b) -> M a -> M b
    def map(proc=nil, &block)
      result = (proc || block).call(value)
      self.class.new(result)
    end

    # The monad: takes a function which returns a monad (of the same type), applies the function
    # bind :: M a  -> (a -> Mb) -> M b
    # the self.class, i.e. the containing monad is passed as a second (optional) arg to the function
    def bind(proc=nil, &block)
      (proc || block).call(value, self.class).tap do |result|
        raise NotMonadError unless result.is_a? self.class
      end
    end
    alias :'>>=' :bind

    # Get the underlying value, return in Haskell
    # return :: M a -> a
    def value
      @value
    end

    # Two monads are equivalent if they are of the same type and when their values are equal
    def ==(other)
      return false unless other.is_a? self.class
      @value == other.instance_variable_get(:@value)
    end

    # Return the string representation of the Monad
    def to_s
      pretty_class_name = self.class.name.split('::')[-1]
      "#{pretty_class_name}(#{self.value.inspect})"
    end
  end
end
