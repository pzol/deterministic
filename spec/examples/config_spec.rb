require 'spec_helper'

include Deterministic

class ElasticSearchConfig
  def initialize(env="development", proc_env=ENV)
    @env, @proc_env = env, proc_env
  end

  attr_reader :env

  def hosts
    Option.any?(env_hosts).match {
      some { |s| { hosts: s.split(/, */) } }
      none { default_hosts }
    }
  end

private
  attr_reader :proc_env
  def env_hosts
    proc_env["RESFINITY_LOG_CLIENT_ES_HOST"]
  end

  def default_hosts
    case env
    when "production"
      { hosts: ["resfinity.net:9200"] }
    when "acceptance" ||  "development"
      { hosts: ["acc.resfinity.net:9200"] }
    else
      { hosts: ["localhost:9200"] }
    end
  end
end

describe ElasticSearchConfig do
  let(:cfg) { ElasticSearchConfig.new(environment, env) }
  context "test" do
    let(:environment) { "test" }
    context "env empty" do
      let(:env) { {} }
      specify { expect(cfg.hosts).to eq({ hosts: ["localhost:9200"] }) }
    end

    context "env empty" do
      let(:env) { { "RESFINITY_LOG_CLIENT_ES_HOST" => "" } }
      specify { expect(cfg.hosts).to eq({ hosts: ["localhost:9200"] }) }
    end

    context "env contains one" do
      let(:env) { { "RESFINITY_LOG_CLIENT_ES_HOST" => "foo:9999"} }
      specify { expect(cfg.hosts).to eq({ hosts: ["foo:9999"] }) }
    end

    context "env contains two" do
      let(:env) { { "RESFINITY_LOG_CLIENT_ES_HOST" => "foo:9999,bar:9200"} }
      specify { expect(cfg.hosts).to eq({ hosts: ["foo:9999", "bar:9200"] }) }
    end
  end

  context "production" do
    let(:environment) { "production" }
    context "env empty" do
      let(:env) { {} }
      specify { expect(cfg.hosts).to eq({ hosts: ["resfinity.net:9200"] }) }
    end
  end

  context "acceptance" do
    let(:environment) { "acceptance" }
    context "env empty" do
      let(:env) { {} }
      specify { expect(cfg.hosts).to eq({ hosts: ["acc.resfinity.net:9200"] }) }
    end
  end
end
