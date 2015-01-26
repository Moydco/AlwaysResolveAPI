class Host
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug
  include HTTParty

  require 'resolv'

  field :reference, type: String
  slug  :reference

  field :ip_address,  type: String
  field :check,       type: String,  default: 'check_ping'
  field :check_args,  type: String
  field :enabled,     type: Boolean, default: true
  field :on_check,    type: Boolean, default: false

  field :last_status, type: String

  validates :ip_address, :presence => true, :format => { :with => Resolv::IPv4::Regex }

  before_save :add_prefix, :set_default_check

  # Lock service check
  def lockService
    self.on_check = true
    self.save
  end

  # Unlock service check
  def unlockService
    self.on_check = false
    self.save
  end

  def remove_prefix
    self.reference.sub('record_','')
  end

  def add_prefix
    unless self.reference.nil? or self.reference.blank?
      unless self.reference.start_with?('record_')
        self.reference = self.reference.prepend('record_')
      end
    end
  end

  def set_default_check
    if self.check == '' or self.check.nil?
      self.check = 'check_ping'
    end
    if self.check_args == ''
      self.check_args = nil
    end
  end

  # Report a staus change
  def report_status_change_host(new_status)
    if Settings.check_notify_method.upcase == 'GET'
      data = self.class.get("#{Settings.base_url}/#{Settings.api_notify_path}/#{self.remove_prefix}/", :query => {
          :api_key => Settings.api_notify_api_access_id,
          :api_secret => Settings.api_notify_api_secret,
          :status => new_status,
          :check_server_id => Settings.check_server_id,
          :format => 'json'
      })
    elsif Settings.check_notify_method.upcase == 'POST'
      data = self.class.post("#{Settings.base_url}/#{Settings.api_notify_path}/#{self.remove_prefix}/", :body => {
          :api_key => Settings.api_notify_api_access_id,
          :api_secret => Settings.api_notify_api_secret,
          :status => new_status,
          :check_server_id => Settings.check_server_id,
          :format => 'json'
      })

    end

    if Settings.notify_changes_to_check == 'false'
      self.last_status = new_status
      self.save
    end
  end

  # Initialize host
  def initialize_db
    data = self.class.get("#{Settings.base_url}/#{Settings.api_get_check_list_path}", :query => {
        :api_key => Settings.api_notify_api_access_id,
        :api_secret => Settings.api_notify_api_secret
    })
    if data.code == 200
      Host.each do |host|
        host.destroy
      end

      data.each do |host|
        Host.create(:reference => "record_#{host["reference"]}",
                    :ip_address => host["ip_address"],
                    :check => host["check"],
                    :check_args => host["check_args"],
                    :enabled => host["enabled"]
        )
      end
    end
  end
end
