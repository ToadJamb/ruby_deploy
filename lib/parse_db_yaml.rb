# This file contains the ParseDbYaml class.

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

# This class handles the parsing of the database.yml
# file for rails applications.
class ParseDbYaml
  class << self
    # Parses the text of the database.yml file and returns only the section
    # for the specified environment.
    # ==== Parameters
    # [stream : StringIO] The contents of the original database.yml file.
    # [env : String,Symbol] The environment settings that will be returned.
    # ==== Output
    # [String] A string that contains only the specified environment's settings.
    # ==== Example
    #  ParseDbYaml.yaml(file, :test)  # => The file with only test settings.
    #  ParseDbYaml.yaml(file, 'test') # => The file with only test settings.
    def yaml(stream, env)
      env = env.to_s
      out = []

      # title and record are mutually exclusive.
      # record means that we are recording lines for the specified environment.
      # title means that we are recording lines for possible replacement.

      record   = false # Whether to record subsequent lines.
      sections = {}    # Hash containing sections that will get substituted in.
      title    = nil   # The title of a substitute section.

      # Loop through the file line by line.
      stream.each do |line|
        next if line =~ /^#/ or line.gsub(/\s/, '') =~ /^#/

        record = false if line =~ /^[^ ]/ and record
        title = nil if line =~ /^[^ ]/ and title

        if line =~ /^#{env}:/
          # Environment sections.
          record = true
          title = nil
          out << line
          next
        elsif line =~ /^\w+: &/
          # Possible replacement section.
          record = false
          title = line.match(/.*:/).to_s[0..-2]
          sections[title] = []
          next
        end

        if record
          # Record a line from the specified environment.
          out << line
          next
        elsif title
          # Record a line from a section that may be substituted.
          sections[title] << line
        end
      end

      # Replace substitute sections.
      unless sections.empty?
        new_out = []

        out.each do |line|
          if line =~ /^  <<: \*/
            title = line.gsub(/^  <<: \*|\n$/, '')
            new_out << sections[title]
          else
            new_out << line
          end
        end

        out = new_out
      end

      out.join
    end
  end
end
