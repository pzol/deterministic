module Deterministic
  module Monad
    class NotMonadError < StandardError; end

    # Basicly the `pure` function
    def initialize(value)
      @value = join(value)
    end

    # If the passed value is monad already, get the value to avoid nesting
    # M[M[A]] is equivalent to M[A]
    def join(value)
      parent = self.class.superclass === Object ? self.class : self.class.superclass
      if value.is_a?(parent) && value.class != Option::None then value.value
      else value end
    end

    # The functor: takes a function (a -> b) and applies it to the inner value of the monad (Ma),
    # boxes it back to the same monad (Mb)
    # fmap :: (a -> b) -> M a -> M b
    def fmap(proc=nil, &block)
      result = (proc || block).call(value)
      self.class.new(result)
    end

    # The monad: takes a function which returns a monad (of the same type), applies the function
    # bind :: (a -> Mb) -> M a  -> M b
    # the self.class, i.e. the containing monad is passed as a second (optional) arg to the function
    def bind(proc=nil, &block)
      (proc || block).call(value).tap do |result|
        parent = self.class.superclass === Object ? self.class : self.class.superclass
        raise NotMonadError, "Expected #{result.inspect} to be an #{parent}" unless result.is_a? parent
      end
    end
    alias :'>>=' :bind

    # Get the underlying value, return in Haskell
    # return :: M a -> a
    def value
      @value
    end

    def to_s
      value.to_s
    end

    def inspect
      name = self.class.name.split("::")[-1]
      "#{name}(#{value})"
    end

    # Two monads are equivalent if they are of the same type and when their values are equal
    def ==(other)
      return false unless other.is_a? self.class
      @value == other.instance_variable_get(:@value)
    end

    # Return the string representation of the Monad
    def inspect
      pretty_class_name = self.class.name.split('::')[-1]
      "#{pretty_class_name}(#{self.value.inspect})"
    end
  end
end
