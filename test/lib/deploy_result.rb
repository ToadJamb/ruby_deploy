# This file contains the result module.

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

# This module is intended to provide the expected output of the application.
module DeployResult
  include DeploySupport

  # The final output. This is an array that includes both stdin and stderr.
  # ==== Parameters
  # [*args : Array] An array containing the command line parameters.
  #
  #                 These should be the same parameters as those that were
  #                 sent to the object's constructor.
  # ==== Output
  # [Array] Includes the expected results on stdout and stderr.
  def finis(*args)
    std_out = []
    std_err = []

    project_name = get_project
    options, argv = get_options(*args)

    # Get the log and status messages.
    result, hg_log = run_external(
      "hg log --rev #{HG_ID}", options, project_name)
    result, hg_status = run_external('hg status', options, project_name)

    # Append the hg log and hg status messages to stdout.
    std_out << hg_log
    std_out << hg_status unless hg_status.empty?
    std_out[-1] = std_out[-1] + "\n"

    # Build an array of the configuration options hashes.
    config_hash = []
    if options[:dest].is_a?(Array)
      options[:dest].each do |config|
        config_hash << config_options(config, project_name)
      end
    else
      config_hash << config_options(options[:dest], project_name)
    end

    # Loop through the configuration options array to process each hash.
    config_hash.each do |opts|
      next if opts[:path] =~ %r|_cancel/path/\w+?$|

      case opts[:path]
        when %r|/\w+?_status_fail/path/\w+?$|, %r|#{extension[:bad]}$|
          std_err << messages(:user_group, opts[:full_path])
          next
        else
          std_out << messages(:chmod, opts[:full_path], permission(:r_x___rwx))
      end

      if opts[:path] =~ %r|/\w+?_chmod_initial_fail/path/|
        std_err << messages(:chmod_fail, opts[:full_path])
        next
      else
        std_out << messages(:copying, opts[:full_path])
      end

      if opts[:path] =~ %r|^/good/\w+?/\w+?_rsync_fail/path/\w+?$|
        std_err << messages(:rsync_fail, opts[:full_path])
      end

      if project_name =~ /_?rails_?/ and opts[:environment]
        std_out << messages(:copy_db_yml)

        if opts[:path] =~ %r|rsync_\w+?_fail/path/|
          std_err << messages(:rsync_fail, 'database.yml')
        end
      end

      std_out << messages(:chmod, opts[:full_path], opts[:permissions])

      if opts[:path] =~ %r|/\w+?_chmod_final_fail/path/|
        std_err << messages(:chmod_fail, opts[:full_path])
      end

      std_out << messages(:chown, owner_group, opts[:full_path])

      if opts[:path] =~ %r|/\w+?_chown_fail/path/|
        std_err << messages(:chown_fail, owner_group, opts[:full_path])
      end

      if opts[:status] == :success and opts[:tag_it]
        std_out << messages(:tagging, HG_ID)
      end
    end # config_hash.each do |opts|

    # Loop through the configuration options array to process
    # the final standings for each hash.
    std_out << "\nFinal status:"
    config_hash.each do |opts|
      case opts[:status]
        when nil
          std_out << '?? ' + opts[:full_path]
        when :success
          std_out << '=> ' + opts[:full_path]
        when :cancel
          std_out << '=/ ' + opts[:full_path]
        when :fail
          std_out << '=| ' + opts[:full_path]
      end
    end

    # Return the expected result on stdout and stderr.
    # All trailing line feeds are removed.
    return std_out.join("\n").gsub(/\n*\z/, ''),
      std_err.join("\n").gsub(/\n*\z/, '')
  end

  ############################################################################
  private
  ############################################################################

  # Returns the options hash from the specified config file.
  # ==== Input
  # [config : String] The config file for which the options are returned.
  # [project_name : String : nil] The name of the project.
  # ==== Output
  # [Hash] The options hash obtained from the config file settings.
  def config_options(config, project_name = nil)
    BuildConfig.new(config, project_name || get_project).options
  end

  # Returns the current project.
  def get_project
    return @class::SETTINGS[:project]
  end

  # Sets the current project.
  #
  # For some reason, using an assignment method caused problems.
  def set_project(new_project = nil)
    @class::SETTINGS[:project] = new_project
  end

  # Returns the options hash and arguments hash
  # as they would exist in the main application following command line
  # argument parsing.
  #
  # All flags are assumed to be valid at this point.
  # ==== Input
  # [*args : Array] The command line parameters.
  # ==== Output
  # [Hash] The options hash.
  # [Array] The arguments array.
  def get_options(*args)
    # Set version and help to false,
    # as they would be after command line parsing.
    options = { :version => false, :help => false }

    flag = ''
    argv = []

    # Loop through the command line arguments.
    args.each do |arg|
      if arg =~ /^--?/
        flag = arg.gsub(/^--?/, '').gsub(/-/, '_').to_sym
        options["#{flag}_given".to_sym] = true
      elsif options["#{flag}_given".to_sym] and options[flag].nil?
        options[flag] = arg
      elsif options["#{flag}_given".to_sym] and options[flag]
        if options[flag].is_a?(Array)
          options[flag] << arg
        else
          options[flag] = [options[flag], arg]
        end
      else
        argv << arg
      end
    end

    return options, argv
  end
end
