class DomainStatistic
  include Mongoid::Document
  include Mongoid::Timestamps

  field :count, type: Integer
  field :serverID, type: String

  belongs_to :domain
  belongs_to :region
end
