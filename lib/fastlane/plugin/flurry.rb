#  Created by Akash Duseja 11/16/2016
#  Copyright (c) 2016 Yahoo, Inc.
#  Licensed under the terms of the MIT License. See LICENSE file in the project root.

require 'fastlane/plugin/flurry/version'

module Fastlane
  module Flurry
    # Return all .rb files inside the "actions" and "helper" directory
    def self.all_classes
      Dir[File.expand_path('**/{actions,helper}/*.rb', File.dirname(__FILE__))]
    end
  end
end

# By default we want to import all available actions and helpers
# A plugin can contain any number of actions and plugins
Fastlane::Flurry.all_classes.each do |current|
  require current
end
