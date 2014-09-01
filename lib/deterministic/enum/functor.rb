module Functor
  def fmap(&fn)
    match {
      Some(a) { Some.new(fn.(a)) }
      None() { |n| n }
    }
  end
end
