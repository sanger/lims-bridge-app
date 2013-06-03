source "http://www.rubygems.org"
 
gemspec

gem 'lims-core', '~>2.1', :git => 'http://github.com/sanger/lims-core.git' , :branch => 'development'
gem 'lims-laboratory-app', '~>1.2', :git => 'http://github.com/sanger/lims-laboratory-app.git' , :branch => 'development'
gem 'lims-busclient', '~>0.1.0', :git => 'https://github.com/sanger/lims-busclient.git' , :branch => 'master'
gem 'lims-management-app', '~>1.2', :git => 'https://github.com/sanger/lims-management-app.git', :branch => 'development'

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
