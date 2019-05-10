configs = App.parse_configs('config/google_analytics.yml')

begin
  GoogleAnalytics.configure(configs)
rescue ArgumentError => e
  App.stop(e.message)
end