# The simplest NullObject there can be
class None
  def self.instance
    @instance ||= None.new
  end

  # def respond_to_missing

  def method_missing(*args)
    self
  end

  def none?
    true
  end

  def some?
    false
  end

  def respond_to?(m)
    true
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

def maybe(obj)
  obj.nil? ? None.instance : obj
end
