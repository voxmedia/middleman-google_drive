require 'middleman-core'
require 'google_drive/extension'

::Middleman::Extensions.register(:google_drive, Middleman::GoogleDrive)
