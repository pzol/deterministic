module Deterministic
  class ProtocolBuilder

    def initialize(typevar, block)
      @typevar, @block = typevar, block
      @protocol = Class.new
    end

    def build
      instance_exec(&@block)
      @protocol
    end

    def method_missing(m, *args)
      [m, args]
    end

    Signature = Struct.new(:name, :params, :return_type, :block)

    def fn(signature, &block)
      m = signature.to_a.flatten
      name        = m[0]
      return_type = m[-1]
      params      = Hash[(m[1..-2][0] || {}).map { |k, v| [k[0], v] }]

      @protocol.instance_eval {
          define_singleton_method(name) {
            Signature.new(name, params, return_type, block)
          }
      }

      @protocol.instance_eval {
        if block
          define_method(name) { |*args|
            block.call(args)
          }
        end
      }
    end
  end

  class InstanceBuilder
    def initialize(protocol, type, block)
      @protocol, @type, @block = protocol, type, block
      @instance = Class.new(@protocol::Protocol)
    end

    def build
      @instance.class_exec(&@block)
      protocol  = @protocol::Protocol
      methods   = protocol.methods(false)
      inst_type = @type

      @instance.instance_exec {
        methods.each { |name|
          if method_defined?(name)
            meth        = instance_method(name)
            signature   = protocol.send(name)
            params      = signature.params
            expect_type = inst_type[signature.return_type]

            define_method(name) { |*args|
              args.each_with_index { |arg, i|
                name     = params.keys[i]
                arg_type = params.fetch(name)
                expect_arg_type = inst_type.fetch(arg_type)

                raise TypeError, "Expected arg #{name} to be a #{expect_arg_type}, got #<#{arg.class}: #{arg.inspect}>" unless arg.is_a? expect_arg_type
              }

              result = meth.bind(self).call(*args)
              raise TypeError, "Expected #{name}(#{args.join(', ')}) to return a #{expect_type}, got #<#{result.class}: #{result.inspect}>" unless result.is_a? expect_type
              result
            }
          end
        }
      }

      missing = methods.detect { |m| !@instance.instance_methods(false).include?(m) }

      raise NotImplementedError, "`#{missing}` has no default implementation for #{@protocol} #{@type.to_s}" unless missing.nil?

      @instance
    end
  end

module_function
  def protocol(typevar, &block)
    protocol = ProtocolBuilder.new(typevar, block).build
    p_module = block.binding.eval('self')
    p_module.const_set(:Protocol, protocol)
  end

  def instance(protocol, type, &block)
    InstanceBuilder.new(protocol, type, block).build
  end

  module Protocol
    def const_missing(c)
      c
    end
  end
end
