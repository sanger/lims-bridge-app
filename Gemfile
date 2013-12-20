source "http://www.rubygems.org"
 
gemspec

gem 'lims-core', '~>3.1.0', :git => 'http://github.com/sanger/lims-core.git' , :branch => 'development'
gem 'lims-laboratory-app', '~>3.4.0', :git => 'http://github.com/sanger/lims-laboratory-app.git' , :branch => 'development'
gem 'lims-busclient', '~>0.4.1', :git => 'https://github.com/sanger/lims-busclient.git' , :branch => 'development'
gem 'lims-management-app', '~>3.2.0', :git => 'https://github.com/sanger/lims-management-app.git', :branch => 'development'
gem 'lims-quality-app', '~>0.7.0', :git => 'https://github.com/sanger/lims-quality-app.git', :branch => 'development'


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
