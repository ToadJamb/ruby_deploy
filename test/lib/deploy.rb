# This file contains the monkey patch (for testing) for the main class.

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

# Monkey patch the main class.
class Deploy
  include DeploySupport

  alias :orig_deploy :deploy

  # Ensure that only projects specified by the test framework may be "deployed".
  def deploy
    unless ITEMS[:project].has_value? SETTINGS[:project]
      raise "Invalid project: #{SETTINGS[:project]}."
    end

    # Call the original deploy method.
    orig_deploy
  end

  ############################################################################
  private
  ############################################################################

  # Pass this on to the run_external command, which will handle it properly.
  def backtick_output(command)
    success, output = run_external(command, {}, SETTINGS[:project])
    return output, success
  end

  # Do nothing - since we didn't actually write a file in the first place.
  def cleanup_db_yml(*args)
  end

  # Return the contents of a database.yml file.
  def db_yml_contents
    StringIO.new(db_yml)
  end

  # Always return a specific date.
  def get_date
    format_date DateTime.new(2011, 1, 1, 17, 9, 59)
  end

  # Return a path that includes the project name at the end,
  # just like the real path should.
  def get_root
    return File.join('/root/path', SETTINGS[:project])
  end

  # Return an rsync command that includes the destination path.
  def get_rsync(options)
    'rsync ./ ' + options[:full_path]
  end

  # Override this since we don't want to actually create any paths.
  def make_path(*args)
  end

  # Pretend to run an ssh command.
  def run_ssh(options, command)
    return false, '' if options[:user].nil?
    return false, '' if options[:server].nil?
    return false, '' if options[:user].empty?
    return false, '' if options[:server].empty?
    return false, '' if options[:user].match(/^deny/)
    return false, '' if options[:server].match(/^deny/)

    if options[:user].match(/^allow/) and options[:server].match(/^allow/)
      success, output = run_external(command, options, SETTINGS[:project])
      return success, output
    end

    raise ArgumentError.new("Invalid settings or code - this shouldn't happen.")
  end

  alias :orig_trollop_die :trollop_die

  # Override to prevent being called when the application is dead.
  def trollop_die(*args)
    orig_trollop_die(*args) if ApplicationState.alive
  end

  # Get the contents of the config file and send it on.
  def valid_config?(config)
    file = BuildConfig.new(config, SETTINGS[:project]).contents
    set_options(file, config)
  end

  # Check for a valid path based on the paths.
  def valid_dir?(path)
    case path
      when %r|/no_repo/.hg$|, /\.bad$/, %r|/\w+_bad_path/path/\w+$|
        return false
    end
    return true
  end

  # Check for a valid path based on the path and/or file name.
  def valid_file?(path)
    case path
      when %r|/abcdef$|, %r|^\./tmp/db/\w+?/database.yml$|
        return false
    end
    return true
  end

  # Don't actually write anything, fool! We're just TESTING!
  def write_file(*args)
  end

  # Override this method so that yes returns based on a specific string
  # being in the question.
  def yes?(question)
    case question
      when %r|_cancel/path/|
        return false
    end
    return true
  end
end
