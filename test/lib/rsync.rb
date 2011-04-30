# Contains a monkey patch of the RSync class for testing.

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

# This class monkey patches the RSync class during testing.
class RSync

  class << self

    ########################################################################
    private
    ########################################################################

    # Returns the destination as the root, replacing /s with _s.
    def get_root
      return @dest[1..-1].gsub(/\//, '_')
    end

    # Indicates whether a file is valid or not (in the eyes of a test).
    def valid_file?(file)
      case file
        when 'exclude.exclude', 'include.include',
            'include_exclude.exclude', 'include_exclude.include',
            'env_exclude.env.exclude', 'env_include.env.include',
            'include_env_exclude.include', 'include_env_exclude.env.exclude',
            'include_exclude_env_include.exclude',
            'include_exclude_env_exclude.include',
            'include_env_include_env_exclude.env.exclude',
            'exclude_env_include.exclude',
            'exclude_env_include.env.include',
            /^include_env_include\..*include$/,
            /^include_exclude_env_include\..*include$/,
            /^include_exclude_env_exclude\..*exclude$/,
            /^include_env_include_env_exclude\..*include$/,
            /^exclude_env_exclude\..*exclude$/,
            /^env_include_env_exclude\.env\./,
            /^exclude_env_include_env_exclude\.(env\.|exclude$)/,
            /^include_exclude_env_include_env_exclude\./,
            /^env_symbol\..*include$/
          return true
        when /^default\./, /^exclude\./, /^include\./,
            /^env_exclude\./, /^env_include\./, /^include_env_include\./,
            /^include_env_exclude\./, /^include_exclude_env_include\./,
            /^include_exclude_env_exclude\./, /^exclude_env_include\./,
            /^include_env_include_env_exclude\./, /^exclude_env_exclude\./,
            /^env_include_env_exclude\./, /^exclude_env_include_env_exclude/,
            /^env_symbol\./
          return false
      end

      # Raise an error if the file was not handled by existing logic.
      raise "Invalid file (#{file}) specified in #{__method__}."
    end
  end
end
