configs = App.parse_configs('config/db.yml')

begin
  DB.configure(configs)
rescue ArgumentError => e
  App.stop(e.message)
end