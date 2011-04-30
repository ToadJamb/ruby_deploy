# This file contains the RSync class.

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

# This class is responsible for generating rsync commands.
class RSync
  class << self
    # Returns an rsync command for a project in the current working directory.
    # ==== Input
    # [dest : String] The destination path
    #
    #                 This may take the form of either a local or remote path.
    # [env : String,Symbol] The target environment.
    #
    #                       This determines which, if any,
    #                       environment-specific include/exclude
    #                       files should be included.
    #                       (i.e. project.development.include)
    def get_rsync(dest, env = nil)
      @dest = dest

      # Convert environment to a string.
      # This allows either strings or symbols to be used as the environment.
      @env = env.to_s

      # Base rsync command.
      rsync = [
        'rsync',
        '--recursive',
        '--delete',
        '--delete-excluded',
      ]

      # Get the include/exclude file parameters.
      files = get_file_parameters

      # Build the rest of the rsync command.
      rsync << files if files.length > 0
      rsync << './'
      rsync << @dest

      # Return the rsync command as a string.
      rsync.join(' ')
    end

    ########################################################################
    private
    ########################################################################

    # Returns an array of additional include/exclude parameters.
    def get_file_parameters
      project = File.basename(get_root)

      file_list = []

      # Loop through the extensions.
      ['include', 'exclude'].each do |ext|
        # Add the base include/exclude file if it exists.
        file = project + '.' + ext
        file_list << "--#{ext}-from=#{file}" if valid_file?(file)

        # Add the environment include/exclude file if it exists.
        if @env.length > 0
          file = project + '.' + @env + '.' + ext
          file_list << "--#{ext}-from=#{file}" if valid_file?(file)
        end
      end

      return file_list
    end

    # Get the current working directory.
    # This function serves primarily to be overridden in tests.
    def get_root
      File.expand_path(File.join(Dir.getwd))
    end

    # Check for the existence of a file.
    # This function serves primarily to be overridden in tests.
    def valid_file?(file)
      File.file?(file)
    end
  end
end
