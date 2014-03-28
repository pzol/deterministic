# The simplest NullObject there can be
class None
  class << self
    def method_missing(m, *args)
      if m == :new
        super
      else
        None.instance.send(m, *args)
      end
    end

    def instance
      @instance ||= new([])
    end

    def mimic(klas)
      new(klas.instance_methods(false))
    end
  end
  private_class_method :new

  def initialize(methods)
    @methods = methods
  end

  # implicit conversions
  def to_str
    ''
  end

  def to_ary
    []
  end

  def method_missing(m, *args)
    return self if respond_to?(m)
    super
  end

  def none?
    true
  end

  def some?
    false
  end

  def respond_to?(m)
    return true if @methods.empty? || @methods.include?(m)
    super
  end
end

class Object
  def none?
    false
  end

  def some?
    true
  end
end

def Maybe(obj)
  obj.nil? ? None.instance : obj
end
