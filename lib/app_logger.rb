module AppLogger
  class << self
    attr_reader :output

    extend Forwardable

    def configure(output = nil)
      @logger = Logger.new(output ? @output = output : STDOUT)

      @logger.datetime_format = '%Y-%m-%d %H:%M:%S'

      self
    end

    def_delegators :@logger, :info, :error, :warning
  end
end