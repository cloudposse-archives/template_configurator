require 'shellutils'

module TemplateConfigurator
  class ServiceException < Exception
    attr_accessor :code, :output
    def initialize(msg, code, output)
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
      ShellUtils.join([@options[:service][:command], @options[:service][:name], action])
    end

    def execute command
      output = %x{#{command}}
      exit_code = $?.exitstatus
      raise ServiceException.new("execution failed; #{command} exited with status #{exit_code}", exit_code, output) unless exit_code == 0
      return output
    end

    def status
      execute command @options[:status]
    end

    def restart
      execute command @options[:restart]
    end

    def reload
      execute command @options[:reload]
    end

    def start
      execute command @options[:start]
    end

    def stop
      execute command @options[:stop]
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
            TemplateConfigurator.log.error(e.output)
          end
        rescue ServiceException => e
          # service is not running
          TemplateConfigurator.log.error(e.message)
          TemplateConfigurator.log.error(e.output)
          begin
            start_output = self.start
            TemplateConfigurator.log.debug("Start command succeeded")
            return start_output
          rescue ServiceException => e
            TemplateConfigurator.log.error(e.message)
            TemplateConfigurator.log.error(e.output)
          end
        end
        sleep(@options[:retry_delay])
      end
      # Everything else failed. Try a restart
      return self.restart
    end
  end
end
