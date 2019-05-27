module AppLogger
  class << self
    extend Forwardable

    attr_reader :output

    def configure(output = nil)
      @logger = Logger.new(output ? @output = output : STDOUT)

      @logger.datetime_format = '%Y-%m-%d %H:%M:%S'

      self
    end

    def_delegators :@logger, :info, :error, :fatal, :warn
  end
end
