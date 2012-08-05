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
require "template_configurator/version"
require 'template_configurator/service'
require 'template_configurator/processor'
require 'template_configurator/command_line'

module TemplateConfigurator
  @@logger = nil
  
  def self.log=(logger)
    @@logger=logger
  end

  def self.log
    @@logger
  end
end