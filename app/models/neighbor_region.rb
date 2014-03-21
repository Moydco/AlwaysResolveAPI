# Attributes:
# - proximity: the distance from region-to-region
# Relations
# - belongs :owner (region)
# - belongs :neighbor (region)

class NeighborRegion
  include Mongoid::Document
  belongs_to :owner, :class_name => "Region"
  belongs_to :neighbor, :class_name => "Region"

  attr_accessor :neighbor_region

  before_save :set_neighbor

  field :proximity, :type => String, :default => 10

  def set_neighbor
    self.neighbor = Region.find(self.neighbor_region)
  end
end
