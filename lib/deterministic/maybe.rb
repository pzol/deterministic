class Object
  def null?
    false
  end

  def some?
    true
  end
end

def Maybe(obj)
  obj.nil? ? Null.instance : obj
end
