module Deterministic
  module Enum
    class MatchError < StandardError; end
  end

  class EnumBuilder
    def initialize(parent)
      @parent = parent
    end

    class DataType
      module AnyEnum
        include Deterministic::Monad

        def match(&block)
          parent.match(self, &block)
        end

        def to_s
          value.to_s
        end

        def name
          self.class.name.split("::")[-1]
        end

        # Returns array. Will fail on Nullary objects.
        # TODO: define a Unary module so we can define this method differently on Unary vs Binary
        def wrapped_values
          if self.is_a?(Deterministic::EnumBuilder::DataType::Binary)
            value.values
          else
            [value]
          end
        end
      end

      module Nullary
        def initialize(*args)
          @value = nil
        end

        def inspect
          name
        end
      end

      module Binary
        def initialize(*init)
          raise ArgumentError, "Expected arguments for #{args}, got #{init}" unless (init.count == 1 && init[0].is_a?(Hash)) || init.count == args.count
          if init.count == 1 && init[0].is_a?(Hash)
            @value = Hash[args.zip(init[0].values)]
          else
            @value = Hash[args.zip(init)]
          end
        end

        def inspect
          params = value.map { |k, v| "#{k}: #{v.inspect}" }
          "#{name}(#{params.join(', ')})"
        end
      end

      def self.create(parent, name, args)
        raise ArgumentError, "#{args} may not contain the reserved name :value" if args.include? :value
        dt = Class.new(parent)

        dt.instance_eval {
          class << self; public :new; end
          include AnyEnum
          define_method(:args) { args }

          define_method(:parent) { parent }
          private :parent
        }

        if args.count == 0
          dt.instance_eval {
            include Nullary
            private :value
          }
        elsif args.count == 1
          dt.instance_eval {
            define_method(args[0].to_sym) { value }
          }
        else
          dt.instance_eval {
            include Binary

            args.each do |m|
              define_method(m) do
                @value[m]
              end
            end
          }
        end
        dt
      end

      class << self
        public :new;
      end
    end

    def method_missing(m, *args)
      @parent.const_set(m, DataType.create(@parent, m, args))
    end
  end

module_function
  def enum(&block)
    mod = Class.new do # the enum to be built
      class << self; private :new; end

      def self.match(obj, &block)
        caller_ctx = block.binding.eval 'self'

        matcher = self::Matcher.new(obj)
        matcher.instance_eval(&block)

        variants_in_match = matcher.matches.collect {|e| e[1].name.split('::')[-1].to_sym}.uniq.sort
        variants_not_covered = variants - variants_in_match
        raise Enum::MatchError, "Match is non-exhaustive, #{variants_not_covered} not covered" unless variants_not_covered.empty?

        type_matches = matcher.matches.select { |r| r[0].is_a?(r[1]) }

        type_matches.each { |match|
          obj, type, block, args, guard = match

          if args.count == 0
            return caller_ctx.instance_eval(&block)
          else
            if args.count != obj.args.count
              raise Enum::MatchError, "Pattern (#{args.join(', ')}) must match (#{obj.args.join(', ')})"
            end
            guard_ctx = guard_context(obj, args)

            if guard
              if guard_ctx.instance_exec(obj, &guard)
                return caller_ctx.instance_exec(* obj.wrapped_values, &block)
              end
            else
              return caller_ctx.instance_exec(* obj.wrapped_values, &block)
            end
          end
        }

        raise Enum::MatchError, "No match could be made"
      end

      def self.variants; constants - [:Matcher, :MatchError]; end

      private
      def self.guard_context(obj, args)
        if obj.is_a?(Deterministic::EnumBuilder::DataType::Binary)
          Struct.new(*(args)).new(*(obj.value.values))
        else
          Struct.new(*(args)).new(obj.value)
        end
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
          raise ArgumentError, "No block given to `#{m}`" if block.nil?
          type = Kernel.eval("#{mod.name}::#{m}")

          if args.count > 0 && args[-1].is_a?(Proc)
            guard = args.delete_at(-1)
          end

          @matches << [@obj, type, block, args, guard]
        }
      }
    }

    mod.const_set(:Matcher, matcher)

    type_variants.each { |variant|
      mod.singleton_class.class_exec {
        define_method(variant) { |*args|
          const_get(variant).new(*args)
        }
      }
    }
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
