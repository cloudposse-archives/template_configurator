# Template Configurator

Template Configurator is a utility to write configuration files from ERB templates. When the file's content changes, it can then call an init script to intelligently reload the configuration. Through out the entire process exclusive file locks are used on the output file and json file to help ensure they are unmanipulated during the transformation process.

## Use Cases

* Dynamically configure HAProxy to pick up new backends contained in a JSON file. Call "service haproxy reload" when the configuration changes.
* Dynamically configure NGinx to pick up new backends contained in a JSON file. Call "service nginx reload" when the configuration changes.
* Dynamically configure Varnish to pick up new backends contained in a JSON file. Call "service varnish reload" when the configuration changes.

## Installation

Add this line to your application's Gemfile:

    gem 'template_configurator'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install template_configurator

## Usage

    Usage: bin/template_configurator
            --service:command EXECUTABLE action to execute to command service (default: /sbin/service)
            --service:name INITRC        initrc used to control service (default: )
            --service:status ACTION      action to execute to get status of service (default: status)
            --service:reload ACTION      action to execute to reload service (default: reload)
            --service:restart ACTION     action to execute to restart service (default: restart)
            --service:start ACTION       action to execute to start service (default: start)
            --service:stop ACTION        action to execute to stop service (default: stop)
            --service:retries NUMBER     number of attempts to reload service (default: 5)
            --service:retry-delay SECS   seconds to sleep between retries (default: 2)
            --template:input-file FILE   Where to read ERB template
            --template:output-file FILE  Where to write the output of the template
            --template:json-file FILE    Base port to initialize haproxy listening for mysql clusters
            --log:level LEVEL            Logging level
            --log:file FILE              Write logs to FILE (default: STDERR)
            --log:age DAYS               Rotate logs after DAYS pass (default: 7)
            --log:size SIZE              Rotate logs after the grow past SIZE bytes
            --dry-run                    Dry run (do not commit changes to disk)
        -V, --version                    Display version information
        -h, --help                       Display this screen

## Examples

Generate a new configuration file in /tmp/test.cfg using /tmp/test.cfg.erb using JSON data from /tmp/test.js. Reload "test" service when configuration changes.

    template_configurator --template:input-file "/tmp/test.cfg.erb" --template:output-file "/tmp/test.cfg" --template:json-file "/tmp/test.js" --service:name "test"

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
