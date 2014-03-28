# The simplest NullObject there can be
class Nothing
  def self.instance
    @instance ||= Nothing.new
  end

  # def respond_to_missing

  def method_missing(*args)
    self
  end

  def nothing?
    true
  end

  def respond_to?(m)
    true
  end
end

class Object
  def nothing?
    false
  end
end

def maybe(obj)
  obj.nil? ? Nothing.instance : obj
end
