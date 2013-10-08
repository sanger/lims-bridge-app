source "http://www.rubygems.org"
 
gemspec

gem 'lims-core', '~>2.5.1.rc1', :git => 'http://github.com/sanger/lims-core.git' , :branch => 'uat'
gem 'lims-laboratory-app', '~>2.5.13.rc1', :git => 'http://github.com/sanger/lims-laboratory-app.git' , :branch => 'uat'
gem 'lims-busclient', '~>0.4.0.rc1', :git => 'https://github.com/sanger/lims-busclient.git' , :branch => 'uat'
gem 'lims-management-app', '~>1.8.2.rc1', :git => 'https://github.com/sanger/lims-management-app.git', :branch => 'uat'

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
