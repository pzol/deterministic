require "deterministic/core_ext/result"

include Deterministic
class Object
  include Deterministic::CoreExt::Result
end
