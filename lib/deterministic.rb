require "deterministic/version"

warn "WARN: Deterministic is meant to run on Ruby 2+" if RUBY_VERSION.to_f < 2

module Deterministic; end

require 'deterministic/monad'
require 'deterministic/either/match'
require 'deterministic/either/chain'
require 'deterministic/either'
require 'deterministic/either/attempt_all'
require 'deterministic/either/success'
require 'deterministic/either/failure'
require 'deterministic/none'
