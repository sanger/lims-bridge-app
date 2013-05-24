source "http://www.rubygems.org"
 
gemspec

gem 'lims-core', '~>2.0', :git => 'http://github.com/sanger/lims-core.git' , :branch => 'version-2'
gem 'lims-laboratory-app', '~>1.0', :git => 'http://github.com/sanger/lims-laboratory-app.git' , :branch => 'master'
gem 'lims-busclient', '~>0.1.0', :git => 'https://github.com/sanger/lims-busclient.git' , :branch => 'master'
gem 'lims-management-app', '~>1.0.1', :git => 'https://github.com/sanger/lims-management-app.git', :branch => 'development'

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
