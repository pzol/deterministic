module Functor
  def fmap(&fn)
    self.class.new(*value.map { |e| fn.(e) })
  end
end
