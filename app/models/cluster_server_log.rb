class ClusterServerLog
  include Mongoid::Document
  include Mongoid::Timestamps

  field :signal, type: String
  field :log, type: String
  field :server, type: String

  validates :signal, inclusion: { in: %w(OK WARNING ERROR UNKNOWN) }, :allow_nil => false, :allow_blank => false
  validates :server, :presence => true

  belongs_to :a_record
  belongs_to :region
end
