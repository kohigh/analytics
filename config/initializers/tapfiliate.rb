configs = App.parse_configs('config/tapfiliate.yml')

begin
  Tapfiliate.configure(configs)
rescue ArgumentError => e
  App.stop(e.message)
end
