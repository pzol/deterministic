class Either
	def chain(&callee)
		return self if @value.failure?
		value = callee.call
		raise "value must be either Success or Failure" unless Either::Abstract === value
		@value = value
		return self
	end
	
	def self.success(value)
		Success.new(value)
	end
	
	def self.failure(value)
		Failure.new(value)
	end
	
	class Abstract
		def initialize(value)
			@value = value
		end
	end
	
	class Success < Abstract
		def <<(value)
			@value = value
		end
			
		def or(*args)
			self
		end
		
		def success?
			true
		end
		
		def failure?
			false
		end
	end
	
	class Failure < Abstract
		def <<(value)
			@value = value
		end

		def or(value)
			value
		end

		def success?
			false
		end
		
		def failure?
			true
		end
	end
end

# a container for storing intermediate state
class Builder
	def initialize(deps)
		@settings_adapter = deps.fetch(:settings)
	end
	
	def build
		Either.new do
			on_failure do |result|
				p result
			end

			chain { @settings = @settings_adapter.call(a, b) }
		end
	end
	
end

module SettingsAdapter
	def self.call(contract, facility)
		begin
			client = ResfinitySettingsClient::Client.new
			auth = self.auth
			Either.success(client.settings(auth))
		rescue => ex
			Either.failure(["Could not get settings: #{ex.message}", ex])
		end
	end
	
	def self.auth
		{ 
			# config to external
			api_user: 	ENV['SETTINGS_USER'],
			api_token:	ENV['SETTINGS_TOKEN']
		}
	end
end