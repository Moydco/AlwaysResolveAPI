# Attributes:
# - id: String, the local CNAME Record ID
# - mname: String, the primary DNS Server
# - rname: String, the Email Address
# - at: String, Zone TTL, Default 1 minute (1M)
# - serial: Integer, zone serial, auomatically updated
# - refresh: String, Zone refresh, Default 1 minute (1M)
# - retry: String, Zone Retry, Default 1 minute (1M)
# - expire: String, Zone Expire, Default 1 minute (1M)
# - minimum: String, Zone Minimum, Default 1 minute (1M)
# Relations:
# - belongs_to Domain

class SoaRecord
  include Mongoid::Document

  before_create :create_serial

  field :mname, type: String                            # Primary DNS
  field :rname, type: String                            # Email
  field :at, type: String,      :default => '1M'        # TTL
  field :serial, type: Integer
  field :refresh, type: String, :default => '1M'
  field :retry, type: String,   :default => '1M'
  field :expire, type: String,  :default => '1M'
  field :minimum, type: String, :default => '1M'

  belongs_to :domain

  # Set the serial to today date + 00
  def create_serial
    self.serial = Date.today.strftime('%Y%m%d00')
  end

  # If the serial date is in the past, set the serial to today date + 00
  #
  # If the serial date is in today date, increment the serial by 1
  #
  # ATTENTION: if the zone had more than 99 daily updates, the serial switch to next day date
  def update_serial
    if Date.parse(self.serial.to_s) < Date.today
      self.serial = Date.today.strftime('%Y%m%d00')
    else
      self.serial = self.serial.to_i + 1
    end
    self.save
  end
end
