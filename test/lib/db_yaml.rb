# This file contains a class to replicate sample database.yml text.

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

# This class replicates sample database.yml text.
class DbYaml
  # Basic database.yml file. It includes all three environments
  # with no substitute sections and includes comments.
  BASIC =<<-EOT
# MySQL.  Versions 4.1 and 5.0 are recommended.
#
# Install the MySQL driver:
#   gem install mysql
# On Mac OS X:
#   sudo gem install mysql -- --with-mysql-dir=/usr/local/mysql
# On Mac OS X Leopard:
#   sudo env ARCHFLAGS="-arch i386" gem install mysql -- --with-mysql-config=/usr/local/mysql/bin/mysql_config
#       This sets the ARCHFLAGS environment variable to your native architecture
# On Windows:
#   gem install mysql
#       Choose the win32 build.
#       Install MySQL and put its /bin directory on your path.
#
# And be sure to use new-style password hashing:
#   http://dev.mysql.com/doc/refman/5.0/en/old-client.html
production:
  adapter:  mysql
  host: <%= `cat /var/cred/logger.host`.chomp %>
  socket: /tmp/mysql.sock
  encoding: utf8
  database: <%= `cat /var/cred/logger.prod.database`.chomp %>
  username: <%= `cat /var/cred/logger.prod.username`.chomp %>
  password: <%= `cat /var/cred/logger.prod.password`.chomp %>

development:
  adapter:  mysql
  host: <%= `cat /var/cred/logger.host`.chomp %>
  socket: /tmp/mysql.sock
  encoding: utf8
  database: <%= `cat /var/cred/logger.dev.database`.chomp %>
  username: <%= `cat /var/cred/logger.dev.username`.chomp %>
  password: <%= `cat /var/cred/logger.dev.password`.chomp %>

# Warning: The database defined as "test" will be erased and
# re-generated from your development database when you run "rake".
# Do not set this db to the same as development or production.
test:
  adapter:  mysql
  host: <%= `cat /var/cred/logger.host`.chomp %>
  socket: /tmp/mysql.sock
  encoding: utf8
  database: <%= `cat /var/cred/logger.test.database`.chomp %>
  username: <%= `cat /var/cred/logger.test.username`.chomp %>
  password: <%= `cat /var/cred/logger.test.password`.chomp %>
  EOT

  # Production section from both basic and (expanded) complex file.
  BASIC_PRODUCTION =<<-EOT
production:
  adapter:  mysql
  host: <%= `cat /var/cred/logger.host`.chomp %>
  socket: /tmp/mysql.sock
  encoding: utf8
  database: <%= `cat /var/cred/logger.prod.database`.chomp %>
  username: <%= `cat /var/cred/logger.prod.username`.chomp %>
  password: <%= `cat /var/cred/logger.prod.password`.chomp %>
  EOT

  # Development section from both basic and (expanded) complex file.
  BASIC_DEVELOPMENT =<<-EOT
development:
  adapter:  mysql
  host: <%= `cat /var/cred/logger.host`.chomp %>
  socket: /tmp/mysql.sock
  encoding: utf8
  database: <%= `cat /var/cred/logger.dev.database`.chomp %>
  username: <%= `cat /var/cred/logger.dev.username`.chomp %>
  password: <%= `cat /var/cred/logger.dev.password`.chomp %>
  EOT

  # Test section from both basic and (expanded) complex file.
  BASIC_TEST =<<-EOT
test:
  adapter:  mysql
  host: <%= `cat /var/cred/logger.host`.chomp %>
  socket: /tmp/mysql.sock
  encoding: utf8
  database: <%= `cat /var/cred/logger.test.database`.chomp %>
  username: <%= `cat /var/cred/logger.test.username`.chomp %>
  password: <%= `cat /var/cred/logger.test.password`.chomp %>
  EOT

  # Complex database.yml file. It includes all three environments
  # with substitute sections and comments.
  COMPLEX =<<-EOT
# MySQL.  Versions 4.1 and 5.0 are recommended.
#
# Install the MySQL driver:
#   gem install mysql
# On Mac OS X:
#   sudo gem install mysql -- --with-mysql-dir=/usr/local/mysql
# On Mac OS X Leopard:
#   sudo env ARCHFLAGS="-arch i386" gem install mysql -- --with-mysql-config=/usr/local/mysql/bin/mysql_config
#       This sets the ARCHFLAGS environment variable to your native architecture
# On Windows:
#   gem install mysql
#       Choose the win32 build.
#       Install MySQL and put its /bin directory on your path.
#
# And be sure to use new-style password hashing:
#   http://dev.mysql.com/doc/refman/5.0/en/old-client.html
common: &common
  encoding: utf8

mysql: &mysql
  adapter:  mysql
  host: <%= `cat /var/cred/logger.host`.chomp %>
  socket: /tmp/mysql.sock

production:
  <<: *mysql
  <<: *common
  database: <%= `cat /var/cred/logger.prod.database`.chomp %>
  username: <%= `cat /var/cred/logger.prod.username`.chomp %>
  password: <%= `cat /var/cred/logger.prod.password`.chomp %>

development:
  <<: *mysql
  <<: *common
  database: <%= `cat /var/cred/logger.dev.database`.chomp %>
  username: <%= `cat /var/cred/logger.dev.username`.chomp %>
  password: <%= `cat /var/cred/logger.dev.password`.chomp %>

# Warning: The database defined as "test" will be erased and
# re-generated from your development database when you run "rake".
# Do not set this db to the same as development or production.
test:
  <<: *mysql
  <<: *common
  database: <%= `cat /var/cred/logger.test.database`.chomp %>
  username: <%= `cat /var/cred/logger.test.username`.chomp %>
  password: <%= `cat /var/cred/logger.test.password`.chomp %>
  EOT

  class << self
    # Returns the specified form of the database.yml.
    # ==== Input
    # [item : String,Symbol] The item to return.
    #
    #                        This should be the name of one of the contants
    #                        in this class and may be either a String or Symbol.
    def parse_yaml(item)
      const_get(item.to_s.upcase)
    end
  end
end
