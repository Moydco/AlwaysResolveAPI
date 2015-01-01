require 'httparty'
HTTParty::Basement.debug_output $stdout
HTTParty::Basement.disable_rails_query_string_format