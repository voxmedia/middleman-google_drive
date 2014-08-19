require 'middleman-core'

Middleman::Extensions.register :google_drive do
  require 'middleman-google_drive/extension'
  Middleman::GoogleDrive::Extension
end
