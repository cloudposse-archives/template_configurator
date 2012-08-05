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
require 'shellwords'

module TemplateConfigurator
  class ServiceException < Exception
    attr_accessor :code, :output
    def initialize(msg, code, output = nil)
      @code = code
      @output = output
      super(msg)
    end
  end

  class Service
    attr_accessor :options
    def initialize options
      @options = options
    end

    def command action
      args = []
      args << @options[:command]
      args << @options[:name]
      args << action
      TemplateConfigurator.log.debug("command args: #{args.inspect}")
      Shellwords.join(args)
    end

    def execute command
      TemplateConfigurator.log.debug("command: #{command}")
      begin
        output = %x{#{command}}
        exit_code = $?.exitstatus
        raise ServiceException.new("execution failed; #{command} exited with status #{exit_code}", exit_code, output) unless exit_code == 0
      rescue Errno::ENOENT => e
        raise ServiceException.new(e.message, 1)
      end
      return output
    end

    def status
      execute command(@options[:status])
    end

    def restart
      execute command(@options[:restart])
    end

    def reload
      execute command(@options[:reload])
    end

    def start
      execute command(@options[:start])
    end

    def stop
      execute command(@options[:stop])
    end

    def conditional_reload
      # Attempt to reload service if it's running, otherwise start it.
      @options[:retries].times do 
        begin
          status_output = self.status
          TemplateConfigurator.log.debug("#{@options[:name]} is running")
          # If the configuration has changed, reload config
          begin 
            reload_output = self.reload
            TemplateConfigurator.log.debug("Reload command succeeded")
            return reload_output
          rescue ServiceException => e
            TemplateConfigurator.log.error(e.message)
            TemplateConfigurator.log.error(e.output) unless e.output.nil?
          end
        rescue ServiceException => e
          # service is not running
          TemplateConfigurator.log.error(e.message)
          TemplateConfigurator.log.error(e.output) unless e.output.nil?
          begin
            start_output = self.start
            TemplateConfigurator.log.debug("Start command succeeded")
            return start_output
          rescue ServiceException => e
            TemplateConfigurator.log.error(e.message)
            TemplateConfigurator.log.error(e.output) unless e.output.nil?
          end
        end
        sleep(@options[:retry_delay])
      end
      # Everything else failed. Try a restart
      return self.restart
    end
  end
end
