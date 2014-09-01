module Deterministic
  module Enum
    class MatchError < StandardError; end
  end

  class EnumBuilder
    def initialize(mod)
      @mod = mod
    end


    class DataType
      include Deterministic::Monad

      module AnyEnum
        def match(&block)
          parent.match(self, &block)
        end

        def parent
          eval(self.class.name.split("::")[-2])
        end

        def pretty_name
          self.class.name.split("::")[-1]
        end
        
        def value
          @value
        end
      end

      module Nullary
        def initialize(*args)
          @value = []
        end

        def to_s
          ""
        end

        def inspect
            pretty_name
        end
      end

      module Binary
        def initialize(*args)
          @value = args
        end

        def inspect
          params = args.zip(@value).map { |e| "#{e[0]}: #{e[1].inspect}" }
          "#{pretty_name}(#{params.join(", ")})"
        end

      end

      def self.create(name, args)
        dt = Class.new

        if args.count == 0
          dt.instance_eval {
            include Deterministic::Monad
            include Nullary
            include AnyEnum
            private :value
          }
        else
          dt.instance_eval {
            include Deterministic::Monad
            include Binary
            include AnyEnum

            define_method(:args) { args }

            args.each_with_index do |m, i|
              define_method(m) do
                @value[i]
              end
            end
          }
        end
        dt
      end

      class << self
        public :new; 
      end

      def initialize(*args)
        @value = None
      end


      def self.inspect 
        "Deterministic::Enum::Empty"
      end
    end

    def method_missing(m, *args)
      @mod.const_set(m, DataType.create(m, args))
    end
  end

module_function
  def enum(&block)
    mod = Class.new do # the enum to be built
      def self.match(obj, &block)
        matcher = self::Matcher.new(obj)
        matcher.instance_eval(&block)

        variants_in_match = matcher.matches.collect {|e| e[1].name.split('::')[-1].to_sym}.uniq.sort
        variants_not_covered = variants - variants_in_match
        raise Enum::MatchError, "Match is non-exhaustive, #{variants_not_covered} not covered" unless variants_not_covered.empty?

        type_matches = matcher.matches.select { |r| r[0].is_a?(r[1]) }

        type_matches.each { |match|

          obj, type, block, args, guard = match
          
          if args.count == 0
            return instance_exec(obj, &block)
          else
            raise Enum::MatchError, "Pattern (#{args.join(', ')}) must match (#{obj.args.join(', ')})" if args.count != obj.value.count
            context = exec_context(obj, args)

            if guard 
              if context.instance_exec(obj, &guard)
                return context.instance_exec(obj, &block)
              end
            else
              return context.instance_exec(obj, &block)
            end
          end
        }

        raise Enum::MatchError, "No match could be made"
      end

      def self.variants; constants - [:Matcher, :MatchError]; end

      private
      def self.exec_context(obj, args)
        Struct.new(*(args + [:self])).new(*(obj.value + [obj]))
      end
    end
    enum = EnumBuilder.new(mod)
    enum.instance_eval(&block)

    type_variants = mod.constants

    matcher = Class.new {
      def initialize(obj)
        @obj = obj
        @matches = []
        @vars = []
      end

      attr_reader :matches, :vars

      def where(&guard)
        guard
      end

      def method_missing(m)
        m
      end

      type_variants.each { |m|
        define_method(m) { |*args, &block|
          type = Kernel.eval("#{mod.name}::#{m}")

          if args.count > 0 && args[-1].is_a?(Proc)
            guard = args.delete_at(-1) 
          end

          @matches << [@obj, type, block, args, guard]
        }
      }
    }

    mod.const_set(:Matcher, matcher)
    mod
  end

  def impl(enum_type, &block)
    enum_type.variants.each { |v|
      name = "#{enum_type.name}::#{v.to_s}"
      type = Kernel.eval(name)
      type.class_eval(&block)
    }
  end
end
