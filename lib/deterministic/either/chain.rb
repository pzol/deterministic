module Deterministic
  class Either
    module Chain
      def chain(proc=nil, &block)
        return self if failure?
        bind { (proc || block).call(@value) }
      end

      alias :>> :chain

      def try(proc=nil, &block)
        return self if failure?
        bind { (proc || block).call(@value) }
      rescue => err
        Failure(err)
      end

      alias :>= :try
    end
  end
end

