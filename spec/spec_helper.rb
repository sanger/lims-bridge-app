# Fix requirement in lims-core as we don't require
# persistence class in lims-bridge-app. But active_support
# is needed in lims-core/base.rb#initialize
require 'active_support/inflector'
