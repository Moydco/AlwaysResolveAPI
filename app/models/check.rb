# Attributes:
# - id: String, the local Check Record ID
# - ip: String, thi IP Address to check
# - check: String, the type of check by nagios-plugins; empty to ping
# - check_args: String, the arguments of nagios plugin check
# - soft_to_hard_to_enable: Integer, the number of consecutive checks OK to consider an host UP - Default: 3
# - soft_to_hard_to_disable: Integer, the number of consecutive checks Error to consider an host Down - Default: 3
# - enabled: Boolean, if is enabled or disabled - Default: true
# - reports_only: Boolean, check the server but don't act on DNS configuration - Default: false
# - soft_status: Boolean, only for internal use - Default: true
# - hard_status: Boolean, only for internal use - Default: true
# - soft_count: Integer, only for internal use - Default: 0
# - hard_count: Integer, only for internal use - Default: 999
# Relations:
# - belongs_to User
# - has_many Record
# - has_many CheckServerLog

class Check
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name,  type: String
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

  field :last_bill, type: Date, default: Date.today
  field :admin_enabled, type: Boolean, default: true

  has_many :records
  has_many :check_server_logs, :dependent => :destroy

  has_one :api_account

  belongs_to :user

  attr_accessor :start_day, :end_day, :page, :per_page

  before_create :new_check_callback
  after_save :update_check_servers
  before_destroy :delete_from_check_servers

  validates :ip, :presence => true, :format => { :with => Resolv::IPv4::Regex }, :unless => Proc.new {|check| check.check == 'PASSIVE'}

  after_create :create_linked_api_account

  def create_linked_api_account
    if self.check == 'PASSIVE'
      self.api_account = self.user.api_accounts.create(rights:['check'])
      self.save
    end
  end

  def new_check_callback

    unless Settings.callback_new_check == '' or Settings.callback_new_check.nil?
      url_to_call = Settings.callback_new_check + '/?format=json'
      url_to_call.sub!(':user', self.user.user_reference.partition('-').first) if url_to_call.include? ':user'
      url = URI.parse(url_to_call)

      amount = (Date.today.end_of_month - Date.today).to_i * (Settings.check_monthly_amount.to_f / 30)

      if Settings.callback_method == 'POST'
        req = Net::HTTP::Post.new(url.path)
      else
        req = Net::HTTP::Get.new(url.path)
      end

      if Settings.auth_method == 'oauth2'
        req.set_form_data({amount: amount, client_id: Settings.oauth2_id, client_secret: Settings.oauth2_secret})
      else
        req.set_form_data({amount: amount})
      end
      sock = Net::HTTP.new(url.host, url.port)
      if Settings.callback_new_domain.starts_with? 'https'
        sock.use_ssl = true
        sock.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      response=sock.start {|http| http.request(req) }

      response.code.to_i == 200
    end
  end

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

  def passive_choose_status(status)
    if self.hard_status == 'OK'
      if status.to_i > self.soft_to_hard_to_disable
        return 'CRITICAL'
      else
        return 'OK'
      end
    else
      if status.to_i <>> self.soft_to_hard_to_enable
        return 'OK'
      else
        return 'CRITICAL'
      end
    end
  end
end
