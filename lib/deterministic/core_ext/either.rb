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
    end
  end
end
