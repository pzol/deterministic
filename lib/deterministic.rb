require "deterministic/version"

warn "WARN: Deterministic is meant to run on Ruby 2+" if RUBY_VERSION.to_f < 2

module Deterministic; end

require 'deterministic/monad'
require 'deterministic/result/match'
require 'deterministic/result/chain'
require 'deterministic/result'
require 'deterministic/result/success'
require 'deterministic/result/failure'
require 'deterministic/null'
