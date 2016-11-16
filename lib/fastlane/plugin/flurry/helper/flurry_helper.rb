#  Created by Akash Duseja 11/16/2016
#  Copyright (c) 2016 Yahoo, Inc.
#  Licensed under the terms of the MIT License. See LICENSE file in the project root.

module Fastlane
  module Helper
    class FlurryHelper
      # class methods that you define here become available in your action
      # as `Helper::FlurryHelper.your_method`
      #
      def self.show_message
        UI.message("Hello from the flurry plugin helper!")
      end
    end
  end
end
