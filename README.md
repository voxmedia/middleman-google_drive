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

The extension will get loaded in automatically, you'll just need to activate it.

    activate :google_drive, load_sheets: {
        mysheet: google_spreadsheet_key,
        moresheet: another_key
    }

Then you can use the data in your templates:

    <h1>My spreadsheet is called: <%= data.mysheet['title'] %></h1>
    <% data.mysheet['Sheet1'].each do [row] %>
        Column one header: <%= row['Column one header'] %>
        Column two header: <%= row['Column two header'] %>
        My column name: <%= row['My column name'] %>
    <% end %>

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
