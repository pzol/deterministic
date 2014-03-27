require "deterministic/core_ext/either"

include Deterministic
class Object
  include Deterministic::CoreExt::Either
end
