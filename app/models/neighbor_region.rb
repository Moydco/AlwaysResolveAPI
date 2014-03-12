# Attributes:
# - proximity: the distance from region-to-region
# Relations
# - belongs :owner (region)
# - belongs :neighbor (region)

class NeighborRegion
  include Mongoid::Document
  belongs_to :owner, :class_name => "Region"
  belongs_to :neighbor, :class_name => "Region"

  field :proximity, :type => String, :default => 10
end
