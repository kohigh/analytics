module App
  module Initializer
    class << self
      include EM::Deferrable

      def load_app
        succeed
      end
    end
  end

  module Destructor
    class << self
      include EM::Deferrable

      def release_resources
        succeed
      end
    end
  end

  class << self
    extend Forwardable

    def parse_configs(path)
      YAML.load(File.read("#{root}/#{path}"))[env]
    end

    def stop(error = nil)
      App.error "#{error}!" if error

      EM.add_timer(1) { Process.kill('INT', 0) }
    end

    def root
      @root ||= File.dirname(File.expand_path('..', __FILE__))
    end

    def environment
      @environment = ENV['ANALYTICS_ENV'] || 'development'
    end
    alias env environment

    def_delegator Initializer, :load_app, :init
    def_delegator Destructor, :release_resources, :close

    private

    def_delegators AppLogger, :info, :error, :warning
  end
end