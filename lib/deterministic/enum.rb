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

      private
        def pretty_name
          self.class.name.split("::")[-1]
        end        
      end

      module Nullary
        def initialize(*args)
          @value = nil
        end

        def inspect
          pretty_name
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
          "#{pretty_name}(#{params.join(', ')})"
        end
      end

      def self.create(parent, name, args)
        raise ArgumentError, "#{args} may not contain the reserved name :value" if args.include? :value
        dt = Class.new(parent)

        dt.instance_eval {
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
            raise Enum::MatchError, "Pattern (#{args.join(', ')}) must match (#{obj.args.join(', ')})" if args.count != obj.args.count
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
