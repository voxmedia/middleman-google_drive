require 'middleman-core'
require 'middleman/google_drive/extension'

::Middleman::Extensions.register(
  :google_drive, Middleman::GoogleDrive::Extension)
