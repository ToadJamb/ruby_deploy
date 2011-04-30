#--
################################################################################
#                      Copyright (C) 2011 Travis Herrick                       #
################################################################################
#                                                                              #
#                                 \v^V,^!v\^/                                  #
#                                 ~%       %~                                  #
#                                 {  _   _  }                                  #
#                                 (  *   -  )                                  #
#                                 |    /    |                                  #
#                                  \   _,  /                                   #
#                                   \__.__/                                    #
#                                                                              #
################################################################################
# This program is free software: you can redistribute it                       #
# and/or modify it under the terms of the GNU General Public License           #
# as published by the Free Software Foundation,                                #
# either version 3 of the License, or (at your option) any later version.      #
#                                                                              #
# Commercial licensing may be available for a fee under a different license.   #
################################################################################
# This program is distributed in the hope that it will be useful,              #
# but WITHOUT ANY WARRANTY;                                                    #
# without even the implied warranty of MERCHANTABILITY                         #
# or FITNESS FOR A PARTICULAR PURPOSE.                                         #
# See the GNU General Public License for more details.                         #
#                                                                              #
# You should have received a copy of the GNU General Public License            #
# along with this program.  If not, see <http://www.gnu.org/licenses/>.        #
################################################################################
#++

require 'bundler'
Bundler.require(:test)
require 'test/unit'
require 'stringio'
require File.join(File.dirname(__FILE__), '..', 'lib', 'script_env')
ScriptEnv.testing = true
require File.join(File.dirname(__FILE__), '..', 'deploy')
require File.join(File.dirname(__FILE__), 'lib', 'deploy_support')
require File.join(File.dirname(__FILE__), 'lib', 'deploy_result')
require File.join(File.dirname(__FILE__), 'lib', 'build_config')
require File.join(File.dirname(__FILE__), 'lib', 'deploy')
require File.join(File.dirname(__FILE__), 'lib', 'test_case')
require File.join(File.dirname(__FILE__), 'lib', 'application_state')
require File.join(File.dirname(__FILE__), 'lib', 'kernel')
require File.join(File.dirname(__FILE__), 'lib', 'rsync')
require File.join(File.dirname(__FILE__), 'lib', 'db_yaml')
