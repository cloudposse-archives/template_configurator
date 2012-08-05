#
# Template Configurator - A utility to generate configuration files from ERB templates and restart
# services when configuration changes.
#
# Copyright (C) 2012 Erik Osterman <e@osterman.com>
# 
# This file is part of Template Configurator.
# 
# Template Configurator is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# Template Configurator is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with Template Configurator.  If not, see <http://www.gnu.org/licenses/>.
#
require 'optparse'
require 'logger'

module TemplateConfigurator
  class CommandLine
    def initialize
      @logger = Logger.new STDERR

      @options = {}
      @options[:log] = {}
      @options[:template] = {}
      @options[:service] = {}

      args = OptionParser.new do |opts|
        opts.banner = "Usage: #{$0}"

        #
        # Service options
        #
        @options[:service][:command] = '/sbin/service'
        opts.on("--service:command EXECUTABLE", "action to execute to command service (default: #{@options[:service][:command]})") do |executable|
          @options[:service][:command] = executable
        end

        @options[:service][:name] = nil
        opts.on("--service:name INITRC", "initrc used to control service (default: #{@options[:service][:name]})") do |initrc|
          @options[:service][:name] = initrc
        end

        @options[:service][:status] = 'status'
        opts.on("--service:status ACTION", "action to execute to get status of service (default: #{@options[:service][:status]})") do |action|
          @options[:service][:status] = action
        end

        @options[:service][:reload] = 'reload'
        opts.on("--service:reload ACTION", "action to execute to reload service (default: #{@options[:service][:reload]})") do |action|
          @options[:service][:reload] = action
        end

        @options[:service][:restart] = 'restart'
        opts.on("--service:restart ACTION", "action to execute to restart service (default: #{@options[:service][:restart]})") do |action|
          @options[:service][:restart] = action
        end

        @options[:service][:start] = 'start'
        opts.on("--service:start ACTION", "action to execute to start service (default: #{@options[:service][:start]})") do |action|
          @options[:service][:start] = action
        end

        @options[:service][:stop] = 'stop'
        opts.on("--service:stop ACTION", "action to execute to stop service (default: #{@options[:service][:stop]})") do |action|
          @options[:service][:stop] = action
        end


        @options[:service][:retries] = 5
        opts.on("--service:retries NUMBER", "number of attempts to reload service (default: #{@options[:service][:retries]})") do |number|
          @options[:service][:retries] = number.to_i
        end

        @options[:service][:retry_delay] = 2
        opts.on("--service:retry-delay SECS", "seconds to sleep between retries (default: #{@options[:service][:retry_delay]})") do |seconds|
          @options[:service][:retry_delay] = seconds.to_i
        end

        #
        # Template options
        #

        @options[:template][:input_file] = nil
        opts.on("--template:input-file FILE", "Where to read ERB template") do |file|
          @options[:template][:input_file] = file
        end

        @options[:template][:output_file] = nil
        opts.on("--template:output-file FILE", "Where to write the output of the template") do |file|
          @options[:template][:output_file] = file
        end

        @options[:template][:json_file] = nil
        opts.on("--template:json-file FILE", "Base port to initialize haproxy listening for mysql clusters") do |file|
          @options[:template][:json_file] = file
        end

        #
        # Logging
        #

        @options[:log][:level] = Logger::INFO
        opts.on( '--log:level LEVEL', 'Logging level' ) do|level|
          @options[:log][:level] = Logger.const_get level.upcase
        end

        @options[:log][:file] = STDERR
        opts.on( '--log:file FILE', 'Write logs to FILE (default: STDERR)' ) do|file|
          @options[:log][:file] = File.open(file, File::WRONLY | File::APPEND | File::CREAT)
        end

        @options[:log][:age] = 7
        opts.on( '--log:age DAYS', "Rotate logs after DAYS pass (default: #{@options[:log][:age]})" ) do|days|
          @options[:log][:age] = days.to_i
        end

        @options[:log][:size] = 1024*1024*10
        opts.on( '--log:size SIZE', 'Rotate logs after the grow past SIZE bytes' ) do |size|
          @options[:log][:size] = size.to_i
        end


        #
        # General options
        #

        @options[:dry_run] = false
        opts.on("--dry-run", "Dry run (do not commit changes to disk)") do 
          @options[:dry_run] = true
        end


        opts.on( '-V', '--version', 'Display version information' ) do
          puts "Template Configurator #{TemplateConfigurator::VERSION}"
          puts "Copyright (C) 2012 Erik Osterman <e@osterman.com>"
          puts "License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>"
          puts "This is free software: you are free to change and redistribute it."
          puts "There is NO WARRANTY, to the extent permitted by law."
          exit
        end

        opts.on( '-h', '--help', 'Display this screen' ) do
          puts opts
          exit
        end

      end

      begin
        args.parse!
        raise OptionParser::MissingArgument.new("--template:input-file") if @options[:template][:input_file].nil?
      rescue OptionParser::MissingArgument => e
        puts e.message
        puts args
        exit 1
      rescue OptionParser::InvalidOption => e
        puts e.message
        puts args
        exit 1
      end
    end

    def execute
      @processor = Processor.new(@options)
      TemplateConfigurator.log = Logger.new(@options[:log][:file], @options[:log][:age], @options[:log][:size])
      TemplateConfigurator.log.level = @options[:log][:level]
      begin
        @processor.render
      rescue Interrupt => e
        TemplateConfigurator.log.info("Aborting")
      rescue NameError, ArgumentError => e
        TemplateConfigurator.log.fatal(e.message)
        TemplateConfigurator.log.debug(e.backtrace.join("\n"))
        exit(1)
      rescue Exception => e
        TemplateConfigurator.log.fatal("#{e.class}: #{e.message}")
        TemplateConfigurator.log.debug(e.backtrace.join("\n"))
        exit(1)
      end
      exit(0)
    end
  end
end
