module Deterministic
  class Option
    include Monad

    # This is an abstract class, can't ever instantiate it directly
    class << self
      protected :new
    end

    def map(proc=nil, &block)
      return self if none?
      p [:map, self.inspect]
      bind(proc || block)
    end

    def some?
      is_a? Some
    end

    def none?
      false
    end

    class Some < Option
      # include Enumerable

      class << self
        public :new

        def [](*values)
          Some.new(values)
        end
      end

      def iter
        return value.to_enum(:each) if value.is_a? Enumerable
        return Array[value].to_enum(:each)
      end
    end
  end


module_function
  def Some(value)
    Option::Some.new(value)
  end
  # def None(value)
  #   None.new(value)
  # end
# end
end
