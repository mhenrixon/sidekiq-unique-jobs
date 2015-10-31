begin
  require 'celluloid/current'
rescue LoadError
  warn 'Celluloid is old'
  begin
    require 'celluloid' rescue LoadError
  rescue LoadError
    warn 'Celluloid not found'
  end
end
begin
  require 'celluloid' rescue LoadError
rescue LoadError
  # do nothing we already know
end

Celluloid.boot if defined?(Celluloid)
