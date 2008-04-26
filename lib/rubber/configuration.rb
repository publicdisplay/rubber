require 'logger'
require 'rubber/environment'
require 'rubber/instance'
require 'rubber/generator'
require 'rubber/dns/dynamic_dns_base'

module Rubber
  module Configuration

    if defined?(RAILS_DEFAULT_LOGGER) && RAILS_DEFAULT_LOGGER
      LOGGER = RAILS_DEFAULT_LOGGER
    else
      LOGGER = Logger.new($stdout)
      LOGGER.level = Logger::INFO
      LOGGER.formatter = lambda {|severity, time, progname, msg| "Rubber[%s]: %s\n" % [severity, msg.to_s.lstrip]}
    end

    @@configurations = {}

    def self.get_configuration(env=get_rubber_env_var, root=nil)
      key = "#{env}-#{root}"
      @@configurations[key] ||= ConfigHolder.new(env, root)
    end

    def self.get_rubber_env_var
      (defined?(RUBBER_ENV) && RUBBER_ENV) || ENV['RUBBER_ENV'] ||
        (defined?(RAILS_ENV) && RAILS_ENV) || ENV['RAILS_ENV'] || 'development'
    end

    def self.rubber_env()
      cfg = Rubber::Configuration.get_configuration(get_rubber_env_var)
      host = cfg.environment.current_host
      roles = cfg.instance[host].role_names rescue nil
      cfg.environment.bind(roles, host)
    end

    def self.rubber_instances
      Rubber::Configuration.get_configuration(get_rubber_env_var).instance
    end

    def self.init_s3(env)
      require 'aws/s3'
      AWS::S3::Base.establish_connection!(
        :access_key_id     => env.aws_access_key,
        :secret_access_key => env.aws_secret_access_key
      )
    end

    class ConfigHolder
      def initialize(env=nil, root=nil)
        root = "#{RAILS_ROOT}/config/rubber" unless root
        instance_cfg =  "#{root}/instance" + (env ? "-#{env}.yml" : ".yml")
        @environment = Environment.new("#{root}")
        @instance = Instance.new(instance_cfg)
      end

      def environment
        @environment
      end

      def instance
        @instance
      end
    end

  end
end
