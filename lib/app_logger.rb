module AppLogger
  class << self
    extend Forwardable

    def configure(output = nil)
      @logger = Logger.new(output ? "#{App.root}/log/#{output}" : STDOUT)

      @logger.datetime_format = '%Y-%m-%d %H:%M:%S'

      self
    end

    def_delegators :@logger, :info, :error, :warn
  end
end