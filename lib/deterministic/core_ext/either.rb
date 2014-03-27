include Deterministic

module Deterministic
  module CoreExt
    module Either
      def success?
        self.is_a? Success
      end

      def failure?
        self.is_a? Failure
      end

      def either?
        success? || failure?
      end

      def attempt_all(context=self, &block)
        Deterministic::Either::AttemptAll.new(context, &block).call(self)
      end
    end
  end
end
