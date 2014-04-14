class Answer
  include Mongoid::Document
  require 'resolv'

  # For CNAME, MX, NS, PTR, SRV, TXT
  field :data,     type: String
  # For MX, SRV
  field :priority, type: Integer, :default => 10
  # For A, AAAA
  field :ip,       type: String
  # For SOA
  field :mname, type: String                            # Primary DNS
  field :rname, type: String                            # Email
  field :at, type: String,      :default => '1M'        # TTL
  field :serial, type: Integer
  field :refresh, type: String, :default => '1M'
  field :retry, type: String,   :default => '1M'
  field :expire, type: String,  :default => '1M'
  field :minimum, type: String, :default => '1M'
  # For SRV
  field :weight, type: Integer, :default => 0
  field :port, type: Integer, :default => 80

  #belongs_to :record
  embedded_in :record

  before_validation :downcase_data

  validate :unique_record?
  validate :correct_alias_destination?

  validates :ip, :presence => true, :format => { :with => Resolv::IPv4::Regex }, :if => :is_record_a?

  validates :ip, :presence => true, :format => { :with => Resolv::IPv6::Regex }, :if => :is_record_aaaa?

  validates :data, :presence => true, :format => { :with => /\A[a-zA-Z0-9\-\_\.]+\Z/ }, :if => :is_record_cname?

  validates :data, :presence => true, :format => { :with => /\A[a-zA-Z0-9\-\_\.]+\Z/ }, :if => :is_record_mx?
  validates :priority, :presence => true, :if => :is_record_mx?

  validates :data, :presence => true, :format => { :with => /\A[a-zA-Z0-9\-\_\.]+\Z/ }, :if => :is_record_ns?

  validates :data, :presence => true, :format => { :with => /\A[a-zA-Z0-9\-\_\.]+\Z/ }, :if => :is_record_ptr?

  validates :mname, :presence => true, :if => :is_record_soa?
  validates :rname, :presence => true, :if => :is_record_soa?

  validates :data, :presence => true, :format => { :with => /\A[a-zA-Z0-9\-\_\.]+\Z/ }, :if => :is_record_srv?

  validates :data, :presence => true, :if => :is_record_txt?

  def downcase_data
    self.data.downcase
  end

  def unique_record?
    if self.record.type == 'CNAME' or self.record.type == 'PTR' or self.record.type == 'SOA' or self.record.type == 'SRV'
      errors.add(:data, 'Multiple answers are not allowed') unless self.record.answers.first == self or self.record.answers.count == 0
    end
  end

  def is_record_a?
    self.record.type == 'A' and !self.record.alias
  end

  def is_record_aaaa?
    self.record.type == 'AAAA' and !self.record.alias
  end

  def is_record_cname?
    self.record.type == 'CNAME' and !self.record.alias
  end

  def is_record_mx?
    self.record.type == 'MX' and !self.record.alias
  end

  def is_record_ns?
    self.record.type == 'NS'
  end

  def is_record_ptr?
    self.record.type == 'PTR' and !self.record.alias
  end

  def is_record_soa?
    self.record.type == 'SOA' and !self.record.alias
  end

  def is_record_srv?
    self.record.type == 'SRV'
  end

  def is_record_txt?
    self.record.type == 'TXT'
  end

  def correct_alias_destination?
    if self.record.alias
      errors.add(:data, 'Alias destination not present') if self.record.domain.records.where(name: self.data) == 0
    end
  end

  # If the serial date is in the past, set the serial to today date + 00
  #
  # If the serial date is in today date, increment the serial by 1
  #
  # ATTENTION: if the zone had more than 99 daily updates, the serial switch to next day date
  def update_serial
    if self.serial.nil? or Date.parse(self.serial.to_s) < Date.today
      self.serial = Date.today.strftime('%Y%m%d00')
    else
      self.serial = self.serial.to_i + 1
    end
    self.save
  end
end
