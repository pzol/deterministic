module Deterministic
  class Result
    module Chain
      def map(proc=nil, &block)
        return self if failure?
        bind(proc || block)
      end

      alias :>> :map

      def try(proc=nil, &block)
        map(proc, &block)
      rescue => err
        Failure(err)
      end

      alias :>= :try

    end
  end
end

