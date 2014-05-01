module Moped
  module BSON
    class ObjectId
      alias :to_json :to_s
    end
  end
end
