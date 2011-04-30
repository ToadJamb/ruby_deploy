# This file contains a module for returning output from console commands.

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

# Contains methods for returning output from console commands.
module BacktickText
  # Returns output from a console command.
  # ==== Input
  # [command : String] The command to be run.
  def backtick_output(command)
    output = nil
    success = nil

    # Run the command and wait for it to execute.
    result = Open4::popen4('bash') do |pid, std_in, std_out, std_err|
      # Set up the command.
      std_in.puts command

      # Run it.
      std_in.close

      # Get the output.
      out = std_out.read.strip
      err = std_err.read.strip

      # Format the output.
      output = out + "\n" + err

      # Success is determined by lack of error text.
      success = err.empty?
    end

    return output.strip, success
  end
end
