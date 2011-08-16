source "http://rubygems.org"

gem 'trollop',  '~> 1.16.2', :group => [:default, :test]
gem 'open4',    '~> 1.0.1',  :group => [:default, :test, :rake]
gem 'net-ssh',  '~> 2.1.0',  :group => [:default, :rake],
  :require => 'net/ssh'
gem 'highline', '~> 1.6.1',  :group => [:default, :rake],
  :require => 'highline/import'
gem 'app_mode', '~> 1.0.0'

group :rake do
  gem 'rake',          '0.8.7'
  gem 'rake_tasks', '~> 0.0.1'
end

group :test do
  gem 'test_internals', '~> 1.0.0'
end
