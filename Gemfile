source "http://www.rubygems.org"
 
gemspec

gem 'lims-core', '~>3.1.0.pre', :git => 'http://github.com/sanger/lims-core.git' , :branch => 'uat'
gem 'lims-laboratory-app', '~>3.4.0.pre', :git => 'http://github.com/sanger/lims-laboratory-app.git' , :branch => 'uat'
gem 'lims-busclient', '~>0.4.1.rc1', :git => 'https://github.com/sanger/lims-busclient.git' , :branch => 'uat'
gem 'lims-management-app', '~>3.1.0.pre', :git => 'https://github.com/sanger/lims-management-app.git', :branch => 'uat'
gem 'lims-quality-app', '~>0.8.0.pre', :git => 'https://github.com/sanger/lims-quality-app.git', :branch => 'uat'
gem 'lims-exception-notifier-app', '~>0.1.2', :git => 'http://github.com/sanger/lims-exception-notifier-app.git', :branch => 'master'

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
