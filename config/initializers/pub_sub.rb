configs = App.parse_configs('config/pub_sub.yml')

begin
  PubSub.configure(configs)
rescue ArgumentError => e
  App.stop(e.message)
end