# Middleman::GoogleDrive

This is an extension for Middleman that allows you to load data from a google 
spreadsheet into your template data.

## Installation

Add this line to your application's Gemfile:

    gem 'middleman-google_drive'

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install middleman-google_drive

## Usage

The extension will get loaded automatically, you just need to activate it.

```ruby
activate :google_drive
```

There are two ways to load and use spreadsheets. Most the time you just need a
single document with multiple worksheets. If you only need a single document...

```ruby
activate :google_drive, load_sheets: 'mygoogledocumentkey'
```

------

### WARNING!!!!

You can only reliably load old-style google spreadsheets. These spreadsheets have URLs that look like this: `https://docs.google.com/a/spreadsheet/ccc?key=mygoogledocumentkey#gid=4`. If you create a brand new google spreadsheet, it will load without crashing but the worksheet names and data will be all mixed up.

Click this link to create a new old-style google spreadsheet: [g.co/oldsheets](http://g.co/oldsheets)

------

You can then use the worksheets in your templates (make sure your worksheets
have names that only contain alpha-numeric characters; no spaces or strange things).

```erb
<h1>My spreadsheet is called: <%= data.mysheet['title'] %></h1>
<% data.Sheet1.each do [row] %>
    Column one header: <%= row['Column one header'] %>
    Column two header: <%= row['Column two header'] %>
    My column name: <%= row['My column name'] %>
<% end %>
```

If you would like to load multiple documents from google, you can use a hash when
activating the extension:

```ruby
activate :google_drive, load_sheets: {
    mysheet: google_spreadsheet_key,
    moresheet: another_key
}
```

Then you can use the data from any of the loaded documents in your templates:

```erb
<h1>My spreadsheet is called: <%= data.mysheet['title'] %></h1>
<% data.mysheet['Sheet1'].each do [row] %>
    Column one header: <%= row['Column one header'] %>
    Column two header: <%= row['Column two header'] %>
    My column name: <%= row['My column name'] %>
<% end %>
<% data.moresheet['Sheet1'].each do [row] %>
    Column one header: <%= row['Column one header'] %>
    Column two header: <%= row['Column two header'] %>
    My column name: <%= row['My column name'] %>
<% end %>
```

You can also use a simplified Google Drive interface from inside your project, via the `drive`
variable. In order to use this functionality, you only have to activate the extension; you do
not have to provide a google docs key:

```ruby
# Activate the extension
activate :google_drive

# get metadata for a document
doc_info = drive.find('google_document_key')

# get the same spreadsheet data without using the load_sheets param above
mysheet = drive.prepared_spreadsheet('google_document_key')

# get a fancy spreadsheet object
spreadsheet = drive.spreadsheet('google_document_key')
```

The fancy spreadsheet object comes from the [roo gem](https://github.com/Empact/roo). Unfortunately documentation is slim. Here is an example from the `roo` readme:

```ruby
spreadsheet.sheet('Info').row(1)
spreadsheet.sheet(0).row(1)

# use this to find the sheet with the most data to parse

spreadsheet.longest_sheet

# this file has multiple worksheets, let's iterate through each of them and process

spreadsheet.each_with_pagename do |name, sheet|
  p sheet.row(1)
end

# pull out a hash of exclusive column data (get rid of useless columns and save memory)

spreadsheet.each(:id => 'UPC',:qty => 'ATS') {|hash| arr << hash}
#=> hash will appear like {:upc=>727880013358, :qty => 12}

# NOTE: .parse does the same as .each, except it returns an array (similar to each vs. map)

# not sure exactly what a column will be named? try a wildcard search with the character *
# regex characters are allowed ('^price\s')
# case insensitive

spreadsheet.parse(:id => 'UPC*SKU',:qty => 'ATS*\sATP\s*QTY$')

# if you need to locate the header row and assign the header names themselves,
# use the :header_search option

spreadsheet.parse(:header_search => ['UPC*SKU','ATS*\sATP\s*QTY$'])
#=> each element will appear in this fashion:
#=> {"UPC" => 123456789012, "STYLE" => "987B0", "COLOR" => "blue", "QTY" => 78}

# want to strip out annoying unicode characters and surrounding white space?

spreadsheet.parse(:clean => true)
```

## Setup

The first time you use this extension, you will have to configure the authentication
with Google docs. There are two parts to this. First you will have to register
a client application with Google and get API keys. Tarbell has a [great
explanation](http://tarbell.readthedocs.org/en/latest/install.html#configure-google-spreadsheet-access-optional) on how to do this. You will need to copy the
`client_secrets.json` to `~/.google_client_secrets.json`. The first time you
run middleman, you will be sent to a Google login prompt in order to
associate Middleman with your Google account. You should make sure that the
account that you choose has access to the spreadsheets you want to use in
Middleman.

You need to make sure that the `redirect_urls` setting for the client secrets
is `urn:ietf:wg:oauth:2.0:oob` and not another URL.

Protip: If somebody in your org has used this extension or something like it,
chances are that person has already created a client secrets file that can be
shared with you.

Once you authenticate with Google, a new file `~/.google_drive_oauth2.json`
will be created containing an key for communicating with Google Drive.

You can override the location of the client secrets and oauth2 JSON files with
the environment variables `GOOGLE_CLIENT_SECRETS` and `GOOGLE_DRIVE_OAUTH`.

If you plan to run Middleman on a server, you can use Google's server to server
authentication. This will kick in if you define the environment variables
`GOOGLE_OAUTH_PERSON`, `GOOGLE_OAUTH_ISSUER` and either `GOOGLE_OAUTH_KEYFILE`
or `GOOGLE_OAUTH_PRIVATE_KEY`.

## Contributing

1. Fork it ( https://github.com/voxmedia/middleman-google_drive/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
