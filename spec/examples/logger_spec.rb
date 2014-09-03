require 'spec_helper'

class Logger
    alias :m :method

    def initialize(repository)
      @repository = repository
    end

    def log(item)
      validate(item) >> m(:transform) >= m(:save)
    end

  private
    attr_reader :repository

    def validate(item)
      return Failure(["Item cannot be empty"]) if item.blank?
      return Failure(["Item must be a Hash"]) unless item.is_a?(Hash)
 
      validate_required_params(item).match {
         none { Success(item) }
         some { |errors| Failure(errors) }
      }
    end

    def transform(params)
      ttl = params.delete(:ttl)
      params.merge!(_ttl: ttl) unless ttl.nil?
      Success(params)
    end

    def save(item)
      Success(repository.bulk_insert([item]))
    end

    def validate_required_params(params)
      required_params = %w(date tenant contract user facility short data)
      Option.any?(required_params
                  .select{|key| Option.some?(params[key.to_sym]).none? }
                  .map{|key| "#{key} is required"}
      )
    end
  end

class Ensure
  include Deterministic
  include Deterministic::Monad

  None = Deterministic::Option::None.new
  def Some(value)
    Option::Some.new(value)
  end

  attr_accessor :value

  def method_missing(m, *args)
    validator_m = "#{m}!".to_sym
    super unless respond_to? validator_m
    send(validator_m, *args).map { |v| Some([Error.new(m, v)])}
  end

  class Error
    attr_accessor :name, :value
    def initialize(name, value)
      @name, @value = name, value
    end

    def inspect
      "#{@name}(#{@value.inspect})"
    end
  end

  def not_empty!
    value.nil? || value.empty?  ? Some(value) : None
  end

  def is_a!(type)
    value.is_a?(type) ? None : Some({obj: value, actual: value.class, expected: type})
  end

  def has_key!(key)
    value.has_key?(key) ? None : Some(key)
  end
end

class Validator < Ensure
  
  def date_is_one!
    value[:date] == 1 ? None : Some({actual: value[:date], expected: 1})
  end

  def required_params!
    params = %w(date tenant contract user facility short data)
    params.inject(None) { |errors, param| 
      errors + (value[:param].nil? || value[:param].empty? ? Some([param]) : None)
    }
  end

  def call
    not_empty + is_a(Array) + None + has_key(:tenant) + Some(["error"]) #+ date_is_one + required_params
  end

end

describe Ensure do
  None = Deterministic::Option::None.new
  Some = Deterministic::Option::Some
  
  it "Ensure" do
    params = {date: 2}

    v = Validator.new(params)

    errors = v.call
    expect(errors).to be_a Some
    expect(errors.value).not_to be_empty
  end
end
