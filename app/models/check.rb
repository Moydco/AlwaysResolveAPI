# Attributes:
# - id: String, the local Check Record ID
# - ip: String, thi IP Address to check
# - check: String, the type of check by nagios-plugins; empty to ping
# - check_args: String, the arguments of nagios plugin check
# - soft_to_hard_to_enable: Integer, the number of consecutive checks OK to consider an host UP
# - soft_to_hard_to_disable: Integer, the number of consecutive checks Error to consider an host Down
# - enabled: Boolean, if is enabled or disabled
# - reports_only: Boolean, check the server but don't act on DNS configuration
# Relations:
# - belongs_to User
# - has_many Record
# - has_many CheckServerLog

class Check
  include Mongoid::Document
  field :ip,    type: String
  field :check, type: String
  field :check_args, type: String
  field :soft_to_hard_to_enable,  type: Integer, default: 3
  field :soft_to_hard_to_disable, type: Integer, default: 3
  field :enabled, type: Boolean, :default => true
  field :reports_only, type: Boolean, :default => false

  field :soft_status, type: Boolean, default: true
  field :hard_status, type: Boolean, default: true

  field :soft_count, type: Integer, default: 0
  field :hard_count, type: Integer, default: 999

  has_many :records
  has_many :check_server_logs, :dependent => :destroy

  belongs_to :user

  attr_accessor :start_day, :end_day, :page, :per_page

  after_save :update_check_servers
  before_destroy :delete_from_check_servers

  validates :ip, :presence => true, :format => { :with => Resolv::IPv4::Regex }

  def update_check_servers
    Region.where(:has_check => true).each do |region|
      logger.debug region.code
      UpdateCheckWorker.perform_async(self.id.to_s,region.id.to_s)
    end
  end

  def delete_from_check_servers
    Region.where(:has_check => true).each do |region|
      logger.debug region.code
      DeleteCheckWorker.perform_async(self.id.to_s,region.id.to_s)
    end
  end

  def choose_status(status)
    if status == 'OK'
      return 'OK'
    elsif status == 'ERROR'
      return 'ERROR'
    elsif status == 'WARNING'
      if self.hard_status
        if Settings.if_im_ok_and_check_return_warning == 'do_nothing'
          return false
        elsif Settings.if_im_ok_and_check_return_warning == 'consider_ok'
          return 'OK'
        else
          return 'CRITICAL'
        end
      else
        if Settings.if_im_error_and_check_return_warning == 'do_nothing'
          return false
        elsif Settings.if_im_error_and_check_return_warning == 'consider_ok'
          return 'OK'
        else
          return 'CRITICAL'
        end
      end
    else
      if self.hard_status
        if Settings.if_im_ok_and_check_return_unknown == 'do_nothing'
          return false
        elsif Settings.if_im_ok_and_check_return_unknown == 'consider_ok'
          return 'OK'
        else
          return 'CRITICAL'
        end
      else
        if Settings.if_im_error_and_check_return_unknown == 'do_nothing'
          return false
        elsif Settings.if_im_error_and_check_return_unknown == 'consider_ok'
          return 'OK'
        else
          return 'CRITICAL'
        end
      end
    end
  end
end
