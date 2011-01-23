#!/usr/bin/ruby

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

require 'date'
require 'fileutils'
require 'highline/import'

################################################################################
#                                    Deploy                                    #
################################################################################

#This class handles the deployment duties.
#
#The command line parameters indicate which file(s) to use
#in order to determine where to deploy.
#Simply pass in the names of the file(s).
#
#If param is passed in,
#this class will also check for a file named param_extension.
#If param_extension exists, the contents will be used as the suffix
#for the deployment location.  For instance,
#if '.dev' is in the _extension file,
#then .dev will be added to the end of the path.
#
#== Example
#
#myobj = Deploy.new(ARGV)
#myobj.deploy()
#
class Deploy
	# Path to the configuration file(s).
	CONFIG_PATH = '~/.deploy/'

	# Root location to copy files on the server(s).
	SERVER_ROOT = '/var/www'

	# rsync command - the options may or may not need to be in this order.
	@@rsync = [
		'rsync',
		'--recursive',
		'--delete',
		'--delete-excluded',
		'--exclude-from=deploy.exclude',
		'./'
	]

	############################################################################
	#                                initialize                                #
	############################################################################

	#The constructor is simply used to set the parameters variable.
	#
	#== Parameters
	#
	#[params] The command line parameters that were passed in.
	#
	#== Example
	#
	#myobj = Deploy.new(ARGV)
	#
	def initialize(params)
		@params = params

		@project_root = File.basename(File.expand_path(Dir.getwd))
		@project_root = @project_root.downcase
	end

	############################################################################
	#                                  deploy                                  #
	############################################################################

	#This method does the work of deploying the code.
	#
	#== Example
	#
	#Obj.deploy()
	#
	def deploy
		return unless valid_params?
		return unless valid_hg?

		hg_id = `hg id`[0..11]
		hg_log = `hg log --rev #{hg_id}`

		puts hg_log

		@params.each do |param|
			# Get the full path to the config file.
			config_file = File.expand_path(File.join(CONFIG_PATH, param.to_s))

			# Retrieve the contents of the configuration file.
			config_value = `cat #{config_file}`.chomp

			# Deploy to the appropriate location.
			deployed = nil
			if config_value.index('/')
				deployed = deploy_local(param.to_s, config_value)
			else
				deployed = deploy_remote(config_value)
			end

			hg_tag(param) if deployed
		end

		puts 'Done!'
	end

	############################################################################
	private
	############################################################################

	############################################################################
	#                              valid_params?                               #
	############################################################################

	#This method checks to ensure that the specified parameters are valid.
	#
	#== Output
	#
	#<tt>true</tt> if the parameters are valid.
	#
	def valid_params?()
		if (@params.length == 0)
			puts 'At least one deployment location must be specified.'
			return
		end

		@params.each do |param|
			puts "Validating #{param.to_s}..."
			# Get the full path to the config file.
			config_file = File.expand_path(File.join(CONFIG_PATH, param.to_s))

			unless File.exists?(config_file)
				# Notify the user that the config file does not exist.
				puts "The file '#{config_file}' does not exist."
				return
			end

			# Retrieve the contents of the configuration file.
			config_value = `cat #{config_file}`.chomp

			# Check the validity of the configuration settings.
			if config_value.index('/')
				return unless valid_local_path?(config_value)

				# Check for an extension file.
				if File.exists?(config_file + '_extension')
					extension = `cat #{config_file + '_extension'}`.chomp
				end

				# Check that the project folder exists.
				return unless valid_local_path?(
					config_value + @project_root + extension.to_s)
			else
				return unless valid_user_server?(config_value)
				return unless valid_ssh?(config_value)
			end
		end

		return true
	end

	############################################################################
	#                            valid_local_path?                             #
	############################################################################

	#Validates local deployment paths.
	#
	#== Parameters
	#
	#[local_path] This is the path to check.
	#
	#== Output
	#
	#<tt>true</tt> if <tt>local_path</tt> is not an existing path.
	#
	def valid_local_path?(local_path)
		return true unless local_path

		# Check to see if the path exists.
		unless File.directory?(local_path)
			puts "Path '#{local_path}' does not exist.  Please create it first."
			return
		end

		return true
	end

	############################################################################
	#                            valid_user_server?                            #
	############################################################################

	#Validates the specified user/server specification.
	#This check is purely syntax based.
	#Only strings that match the 'user@server' format will pass.
	#
	#== Parameters
	#
	#[user_server] The user/server combination that will be tested.
	#
	#== Output
	#
	#<tt>true</tt> if <tt>user_server</tt> matches the correct format.
	#
	def valid_user_server?(user_server)
		unless (user_server =~ /^\w+\@\w+$/)
			puts "'#{user_server}' is not a valid user/server format."
			return
		end

		return true
	end

	############################################################################
	#                                valid_ssh?                                #
	############################################################################

	#Validates that the specified user/server can connect to the server.
	#
	#== Parameters
	#
	#[user_server] The user/server combination that will be tested.
	#
	#== Output
	#
	#<tt>true</tt> if we can connect to the server.
	#
	def valid_ssh?(user_server)
		puts "Checking ssh connection via #{user_server}..."

		# Attempt to connect to the server via ssh.
		return_value = system("ssh #{user_server} -q exit")

		if (!return_value)
			puts "ssh connection using '#{user_server}' could not be established."
		end

		return return_value
	end

	############################################################################
	#                                valid_hg?                                 #
	############################################################################

	#Validates that all files are checked in.
	#
	#== Output
	#
	#<tt>true</tt> if all files are checked in.
	#
	def valid_hg?()
		unless File.directory?(File.join(File.expand_path(Dir.getwd), '.hg'))
			puts 'The current working directory does not appear to be ' +
				'the project root.'
			return
		end

		hg_status = `hg status`

		if hg_status == ''
			return true
		else
			puts 'The current code cannot be pushed ' +
				'since it has outstanding modifications.'
			return
		end
	end

	############################################################################
	#                               deploy_local                               #
	############################################################################

	#Deploys the files to a local location.
	#
	#== Parameters
	#
	#[platform] This is the command line parameter
	#           that caused this method to be called.
	#
	#[path] The local path that is pulled from the configuration file.
	#
	#== Output
	#
	#<tt>true</tt> if the files are deployed.
	#
	def deploy_local(platform, path)
		# Get the path to deploy to.
		local_path = File.join(path, @project_root)

		return unless
			agree("Are you sure you want to deploy #{@project_root} " +
				"to #{local_path}?")

		# Set up chmod command.
		chmod = "sudo chmod %d #{local_path} --recursive"

		# Get the current user & group.
		user_group = `stat -c %U:%G #{local_path}`.chomp

		# Change permissions.
		system(chmod % [507])

		# Add the deploy location to the rsync command.
		rsync = @@rsync.clone
		rsync << "#{local_path}"

		# Copy the files.
		puts 'Copying files...'
		system(rsync.join(' '))

		# Reset permissions.
		puts 'Cleaning up after deployment...'
		system(chmod % [500])
		`sudo chown #{user_group} #{local_path} --recursive`

		return true
	end

	############################################################################
	#                              deploy_remote                               #
	############################################################################

	#Deploys the files to a remote location.
	#
	#== Parameters
	#
	#[user_server] The user/server combination
	#              that will be used to connect to the server.
	#
	#== Output
	#
	#<tt>true</tt> if the files are deployed.
	#
	def deploy_remote(user_server)
		# Get the path that we will be deploying to.
		remote_path = File.join(SERVER_ROOT, @project_root)

		return unless
			agree("Are you sure you want to deploy #{@project_root} " +
				"to #{user_server + ':' + remote_path}?")

		# Set up ssh commands.
		ssh = "ssh #{user_server}"
		ssh_chmod = "#{ssh} \"sudo chmod %d #{remote_path} --recursive\""

		# Get the user & group that currently owns the root folder.
		user_group = `#{ssh} "stat -c %U:%G #{remote_path}"`.chomp
		system(ssh_chmod % [507])

		# Add the remote location to the rsync command.
		rsync = @@rsync.clone
		rsync << "#{user_server}:#{remote_path}"

		# Copy the files.
		puts 'Copying files to the server...'
		system(rsync.join(' '))

		# Reset permissions.
		puts 'Cleaning up after deployment...'
		system(ssh_chmod % [500])
		`#{ssh} "sudo chown #{user_group} #{remote_path} --recursive"`

		return true
	end

	############################################################################
	#                                  hg_tag                                  #
	############################################################################

	#Tags the changeset that was deployed.
	#
	#== Parameters
	#
	#[platform] This is the command line parameter
	#           that caused this method to be called.
	#
	def hg_tag(platform)
		# Get the id of the current changeset.
		hg_id = `hg id`[0..11]

		puts "Tagging changeset #{hg_id}..."

		# Get the current date/time stamp to include in the tag.
		cur_date = DateTime.now

		date = '%d-%s-%s %s-%s-%s' % [
			cur_date.year,
			cur_date.month.to_s.rjust(2, '0'),
			cur_date.day.to_s.rjust(2, '0'),
			cur_date.hour.to_s.rjust(2, '0'),
			cur_date.minute.to_s.rjust(2, '0'),
			cur_date.second.to_s.rjust(2, '0')
		]

		# Change to the push branch no matter what.
		`hg branch push --force`

		# Tag the changeset.
		`hg tag "#{platform} #{date}"`

		# Merge push branch heads.
		`hg merge`

		# Commit the merge.
		`hg commit --message "Merged push branch."`

		# Update to the changeset we started on.
		`hg update #{hg_id} --clean`
	end
end

unless ARGV.count > 0 and File.exists?(ARGV[0])
	dep = Deploy.new(ARGV)
	dep.deploy()
end
