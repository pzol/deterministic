include Deterministic

module Deterministic
  module CoreExt
    module Result
      def success?
        self.is_a? Deterministic::Result::Success
      end

      def failure?
        self.is_a? Deterministic::Result::Failure
      end

      def result?
        success? || failure?
      end
    end
  end
end
