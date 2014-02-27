# Attributes:
# - code: String, two-letters country code (ex. IT, US)
# - dns_ip_address: String, the ip address of local RabbitMQ server
# - check_ip_address: String, the ip address of local Check server
# - has_dns: Boolean, if in this region there are DNS server
# - has_check: Boolean, if in this region there are Check server
# Relations
# - has_many :server_statuses
# - has_many :server_logs

class Region
  include Mongoid::Document
  include HTTParty

  field :code, type: String
  field :dns_ip_address, type: String
  field :check_ip_address, type: String
  field :has_dns, type: Boolean, default: true
  field :has_check, type: Boolean, default: true

  has_many :dns_server_statuses
  has_many :dns_server_logs
  has_many :cluster_server_logs

  validates :code, :allow_nil => false, :allow_blank => false, :uniqueness => true
  validates :dns_ip_address, :presence => true, :format => { :with => Resolv::IPv4::Regex }, :if => :should_validate_dns_ip_address?
  validates :check_ip_address, :presence => true, :format => { :with => Resolv::IPv4::Regex }, :if => :should_validate_check_ip_address?

  def should_validate_dns_ip_address?
    self.has_dns
  end

  def should_validate_check_ip_address?
    self.has_check
  end

  def update_check_server(reference, ip_address, check, check_args, enabled)
    data = self.class.put("http://#{self.check_ip_address}:3002/#{Settings.update_path}/#{reference}", :body => {
        :reference => reference,
        :ip_address => ip_address,
        :check => check,
        :check_args => check_args,
        :enabled => enabled,
        :format => 'json'
    })
  end

  def delete_from_check_server(reference)
    data = self.class.delete("http://#{self.check_ip_address}:3002/#{Settings.delete_path}/#{reference}", :query => {
        :reference => reference,
        :format => 'json'
    })
  end
end

