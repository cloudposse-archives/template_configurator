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
        if @options[:template][:commit] && !@options[:template][:output_file].nil?
          TemplateConfigurator.log.debug("writing new configuation (#{new_output.length} bytes)")
          output_fh.truncate
          output_fh.write(new_output)
          reload
        else
          TemplateConfigurator.log.debug("Not attemptig service reload due to missing output file parameter")
          output_fh.write new_output
        end
      end

      def reload
        if @options[:service][:name].nil?
          TemplateConfigurator.log.info("service not specified; skipping reload")
        else
          begin
            @service.conditional_reload
          rescue ServiceException => e
            TemplateConfigurator.log.error(e.message)
            TemplateConfigurator.log.error(e.output)
          end
        end
      end
    end
  end
end
