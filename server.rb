require_relative 'config/boot'

EM.run do
  trap('INT') do
    EM.add_timer(0) do
      App.close
      EM.stop
    end
  end

  trap('TERM') do
    EM.add_timer(0) do
      App.close
      EM.stop
    end
  end

  App.init
end