# Attributes:
# - id: String, the local A Record ID
# - name: String, the local A name, must be unique
# - priority: Integer, default 1, the priority in resolution when used in a HA cluster object (small number = high priority)
# - weight: Integer, default 1, the weight in resolution when used in a LB cluster object (small number = small weight)
# - ip: String, the IP Address which resolves, must be a valid IPv4 address
# - enabled: Boolean, if is enabled or disabled
# - operational: Boolean, if is enabled or disabled (used by check server procedure)
# - on_check: Array, check servers that are checking this host (used by check server procedure)
# - last_check: DateTime, last time this host was checked (used by check server procedure)
# Relations:
# - belongs_to Domain
# - belongs_to GeoDns

class ARecord
  include Mongoid::Document
  require 'resolv'

  field :name, type: String
  field :priority, type: Integer, :default => 1
  field :weight, type: Integer, :default => 1
  field :ip, type: String
  field :enabled, type: Boolean, :default => true
  field :operational, type: Boolean, :default => true
  field :on_check, :type => Array, :default => []
  field :last_check, :type => DateTime

  validates :name,  :uniqueness => { scope: :parent_a_record_id }, :if => :condition_testing?
  validates :ip, :presence => true, :format => { :with => Resolv::IPv4::Regex }

  belongs_to :parent_a_record, :polymorphic => true

  after_save :update_zone
  after_destroy :update_zone

  # Call the update domain procedure when the record is saved or destroyed
  def update_zone
    self.parent_a_record.update_zone  unless self.parent_a_record.nil?
  end

  # Test uniqueness only if parent is a domain
  def condition_testing?
    self.parent_a_record.is_a?(Domain)
  end

  # Reset the locking of current record
  def resetLock(id_server_check)
    self.on_check = self.on_check.select{|x| x != "#{id_server_check}"}
    self.save
  end

  # Chech if i'm currently run the check
  def on_check?(id_server_check)
    self.on_check.include?("#{id_server_check}")
  end

  # Lock service check
  def lockService(id_server_check)
    unless self.on_check.include?("#{id_server_check}")
      self.on_check << "#{id_server_check}"
    end
    self.save
  end

  # Unlock service check
  def unlockService(id_server_check)
    if self.on_check.include?("#{id_server_check}")
      self.on_check = self.on_check.select{|x| x != "#{id_server_check}"}
      self.last_check = Time.now
    end
    self.save
  end

  # Disable a service
  def disable_host
    self.operational = false
    self.save
  end

  # Enable a service
  def enable_host
    self.operational = true
    self.save
  end

  # Check a service
  def check_operational(check,check_data)
    if check.empty?
      check = "#{Settings.nagios_directory}/check_ping -H #{self.ip}"
    else
      check = "#{Settings.nagios_directory}/#{check} -H #{self.ip}"
    end

    unless check_data.empty?
      check = "#{check} #{check_data}"
    end

    Rails.logger.debug "Run the command #{check}\n"
    value = `#{check}`
    Rails.logger.debug "Returned #{value}\n"

    if (value.index 'OK')
      return true
    elsif (value.index 'ERROR')
      return false
    elsif (value.index 'WARNING')
      if Settings.warning_is_ok == 'true'
        return false
      else
        return false
      end
    else
      if Settings.other_is_ok == 'true'
        return false
      else
        return false
      end
    end
  end
end
