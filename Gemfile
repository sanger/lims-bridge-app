source "http://www.rubygems.org"
 
gemspec

gem 'lims-core', '~>3.2.1', :git => 'http://github.com/sanger/lims-core.git' , :branch => 'master'
gem 'lims-laboratory-app', '~>3.7.1', :git => 'http://github.com/sanger/lims-laboratory-app.git' , :branch => 'master'
gem 'lims-busclient', '~>0.4.1', :git => 'https://github.com/sanger/lims-busclient.git' , :branch => 'master'
gem 'lims-management-app', '~>3.2.2', :git => 'https://github.com/sanger/lims-management-app.git', :branch => 'master'
gem 'lims-quality-app', '~>0.9.1', :git => 'https://github.com/sanger/lims-quality-app.git', :branch => 'master'
gem 'lims-exception-notifier-app', '~>0.1', :git => 'http://github.com/sanger/lims-exception-notifier-app.git', :branch => 'master'

group :development do
  gem 'sqlite3', :platforms => :mri
end

group :debugger do
  gem 'debugger'
  gem 'debugger-completion'
  gem 'shotgun'
end

group :deployment do
  gem "psd_logger", :git => "http://github.com/sanger/psd_logger.git"
end
