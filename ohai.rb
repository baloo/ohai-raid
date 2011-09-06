require 'ohai'


Ohai::Config[:plugin_path] = './plugins'
Ohai::Config[:log_level] = :debug
# Puts Logger on
Ohai::Log.init(Ohai::Config[:log_location])
Ohai::Log.level = Ohai::Config[:log_level]


o = Ohai::System.new
o.configure_logging
o.all_plugins
puts o.json_pretty_print()
