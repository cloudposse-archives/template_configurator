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
require 'erb'
require 'digest/sha1'
require 'json'

module TemplateConfigurator
  class Processor
    attr_accessor :service, :options, :locks

    def lock file
      @locks[:file] = File.open(file, File::RDWR|File::CREAT, 0644) 
      @locks[:file].flock(File::LOCK_EX)
      @locks[:file]
    end

    def unlock
      @locks[:file].flock(File::LOCK_UN)
      @locks[:file]
    end

    def initialize(options)
      @options = options
      @locks = {}
      @service = Service.new(@options[:service])
    end

    def reload
      if @options[:service][:name].nil?
        TemplateConfigurator.log.info("service not specified; skipping reload")
      else
        begin
          @service.conditional_reload
        rescue ServiceException => e
          TemplateConfigurator.log.error(e.message)
          TemplateConfigurator.log.error(e.output) unless e.output.nil?
        end
      end
    end

    def render
      @data = {}
      unless @options[:template][:json_file].nil?
        json_fh = lock(@options[:template][:json_file])
        @data = JSON.parse(json_fh.read)
      end
      TemplateConfigurator.log.debug("json:[#{@data.inspect}]")
      template = ERB.new(File.read(@options[:template][:input_file]), 0, '%<>')

      if @options[:template][:output_file].nil?
        output_fh = STDOUT
        old_output = ""
      else
        output_fh = lock(@options[:template][:output_file])
        old_output = output_fh.read
      end
      
      new_output = template.result(binding)

      new_sha1 = Digest::SHA1.hexdigest(new_output)
      old_sha1 = Digest::SHA1.hexdigest(old_output)

      TemplateConfigurator.log.debug("old_sha1:#{old_sha1} new_sha1:#{new_sha1}")

      if new_sha1 == old_sha1
        TemplateConfigurator.log.debug("SHA1 checksum unchanged")
      else
        TemplateConfigurator.log.info "SHA1 checksum changed"
        # Write the new configuration
        if @options[:dry_run] && !@options[:template][:output_file].nil?
          TemplateConfigurator.log.debug("writing new configuation (#{new_output.length} bytes)")
          output_fh.truncate(0)
          output_fh.write(new_output)
          output_fh.flush
          reload()
        else
          TemplateConfigurator.log.debug("Not attemptig service reload due to missing output file parameter")
          output_fh.write new_output
        end
      end

    end
  end
end
