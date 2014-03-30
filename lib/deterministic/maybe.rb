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
