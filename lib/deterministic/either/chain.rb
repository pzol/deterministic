module Deterministic
  class Either
    module Chain
      def chain(proc=nil, &block)
        return self if failure?
        bind { (proc || block).call(@value) }
      end

      alias :>> :chain
      end
  end
end

