class ChildDns
  include Mongoid::Document

  field :cns, type: String
  field :ip, type: String

  belongs_to :domain_registration

  before_create :create_dns_callback
  before_update :update_dns_callback
  before_destroy :destroy_dns_callback

  def create_dns_callback
    m = eval "Settings.domain_registers_#{self.domain_registration.tld}"
    m = Settings.domain_default_register if m.nil?
    regdom = eval "Regdom::#{m.humanize}"
    self.domain_registration.reseller_service = m
    response = regdom.create_child_dns(self)
    if response.include?('error')
      false
    else
      response
    end
  end

  def update_dns_callback
    m = eval "Settings.domain_registers_#{self.domain_registration.tld}"
    m = Settings.domain_default_register if m.nil?
    regdom = eval "Regdom::#{m.humanize}"
    self.domain_registration.reseller_service = m
    response = regdom.update_child_dns(self)
    if response.include?('error')
      false
    else
      response
    end
  end

  def destroy_dns_callback
    m = eval "Settings.domain_registers_#{self.domain_registration.tld}"
    m = Settings.domain_default_register if m.nil?
    regdom = eval "Regdom::#{m.humanize}"
    self.domain_registration.reseller_service = m
    response = regdom.destroy_child_dns(self)
    if response.include?('error')
      false
    else
      response
    end
  end
end
