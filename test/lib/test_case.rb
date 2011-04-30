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

Test::Unit::TestCase.class_eval do
	# Indicates whether the class has already been initialized.
	# This prevents duplicate patching.
	# Since this is in a class_eval, instance methods need to be wrapped up
	# in class_variable_set or ruby will throw warnings.
	class_variable_set(:@@initialized, false)

	############################################################################
	#                                initialize                                #
	############################################################################

	#Initializes the class
	#and exposes private methods and variables of the subclass.
	#
	def initialize(*args)
		# Call initialize on the superclass.
		super

		# Get the class that is being tested.
		# Assume that the name of the class is found by removing 'Test'
		# from the test class.
		@class = Kernel.const_get(self.class.name.gsub(/Test$/, ''))

		# Only patch if this code has not yet been run.
		unless @@initialized
			# Expose private class methods.
			# We will only expose the methods we are responsible for creating.
			# (i.e. subtracting the superclass's private methods)
			expose_private_methods(:class,
				@class.private_methods - 
				@class.superclass.private_methods)

			# Expose private instance methods.
			# We will only expose the methods we are responsible for creating.
			# (i.e. subtracting the superclass's private methods)
			expose_private_methods(:instance,
				@class.private_instance_methods -
				@class.superclass.private_instance_methods)

			# Expose variables.
			# Requires that variables are assigned to in the constructor.
			expose_variables(@class.class_variables +
				@class.new([]).instance_variables)

			# Indicate that this code has been run.
			@@initialized = true
		end
	end

	############################################################################
	private
	############################################################################

	############################################################################
	#                          expose_private_methods                          #
	############################################################################

	#Expose the private methods that are passed in.  New methods will be created
	#with the old method name followed by '_public_test'.  If the original
	#method contained a '?', it will be removed in the new method.
	#
	#== Parameters
	#
	#[type] A symbol indicating whether to
	#       handle instance methods or class methods.
	#
	#       Only :class & :instance are supported.
	#
	#[methods] An array of the methods to expose.
	#
	#
	def expose_private_methods(type, methods)
		# Get the text that the method should be wrapped in.
		method_wrapper = wrapper(type)

		# Loop through the methods.
		methods.each do |method|
			# Remove ?s.
			new_method = method.to_s.gsub(/\?/, '')

			# This is the new method.
			new_method = <<DOC
				def #{new_method}_public_test(*args)
					#{method}(*args)
				end
DOC

			# Add the wrapping text.
			new_method = method_wrapper % [new_method]

			# Add the method to the class.
			@class.class_eval do
				eval(new_method)
			end
		end
	end

	############################################################################
	#                             expose_variables                             #
	############################################################################

	#Expose the variables.
	#New methods will be created (a getter and a setter) for each variable.
	#Regardless of the type of variable, these methods are only available
	#via an instance.
	#
	#== Parameters
	#
	#[variables] An array of variables to expose.
	#
	def expose_variables(variables)
		# Get the text that the methods should be wrapped in.
		var_wrapper = wrapper(:instance)

		# Loop through the variables
		variables.each do |var|
			# Remove any @s.
			new_method = var.to_s.gsub(/@/, '')

			# These are the new getter and setters.
			new_method = <<DOC
				def #{new_method}_variable_method
					#{var}
				end

				def #{new_method}_variable_method=(value)
					#{var} = value
				end
DOC

			# Add the wrapping text.
			new_method = var_wrapper % [new_method]

			# Add the methods to the class.
			@class.class_eval do
				eval(new_method)
			end
		end
	end

	############################################################################
	#                                 wrapper                                  #
	############################################################################

	#Returns the wrapping text for the specified type of method.
	#
	#== Parameters
	#
	#[type] A symbol indicating whether to
	#       handle instance methods or class methods.
	#
	#       Only :class & :instance are supported.
	#
	#== Output
	#
	#The text that the specified type of method should be wrapped in.
	#
	def wrapper(type)
		case type
			when :class then 'class << self;%s;end'
			when :instance then '%s'
		end
	end

	def assert_false(value, message = nil)
		assert !value, message
	end

	def assert_true(value, message = nil)
		assert_equal true, value, message
	end
end
