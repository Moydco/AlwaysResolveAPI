class Contact
  require "lib/regdom/dummy"
  require "lib/regdom/email"
  require "lib/regdom/resellerclub"
  require "lib/regdom/enom"

  include Mongoid::Document
  include Mongoid::Timestamps

  field :registrant_organization_name,     type: String, default: "qwerty ltd"
  field :registrant_job_title,             type: String, default: "CEO"
  field :registrant_first_name,            type: String, default: "Jon"
  field :registrant_last_name,             type: String, default: "Smith"
  field :registrant_address1,              type: String, default: "12 station road"
  field :registrant_address2,              type: String, default: ""
  field :registrant_city,                  type: String, default: "London"
  field :registrant_postal_code,           type: String, default: "CM2198J"
  field :registrant_state_province,        type: String, default: "London"
  field :registrant_state_province_choice, type: String, default: "P"
  field :registrant_country,               type: String, default: "UK"
  field :registrant_phone,                 type: String, default: "%2B44.234567890"
  field :registrant_fax,                   type: String, default: "%2B44.234567891"
  field :registrant_email_address,         type: String, default: "jon@qwerty.ltd"

  belongs_to :user

  has_many :domain_registration_registrant_contact, inverse_of: :registrant_contact, class_name: "DomainRegistration"
  has_many :domain_registration_tech_contact,       inverse_of: :tech_contact, class_name: "DomainRegistration"
  has_many :domain_registration_admin_contact,      inverse_of: :admin_contact, class_name: "DomainRegistration"

  before_create :new_contact_callback
  before_update :update_contact_callback

  def new_contact_callback

  end

  def update_contact_callback
    self.domain_registration_registrant_contact.each do |domain|
      m = eval "Settings.domain_registers_#{domain.tld}"
      m = Settings.domain_default_register if m.nil?
      regdom = eval "Regdom::#{m.humanize}"
      regdom.update_contact(domain,domain.registrant_contact,self)
    end

    self.domain_registration_tech_contact.each do |domain|
      m = eval "Settings.domain_registers_#{domain.tld}"
      m = Settings.domain_default_register if m.nil?
      regdom = eval "Regdom::#{m.humanize}"
      regdom.update_contact(domain,domain.tech_contact,self)
    end

    self.domain_registration_admin_contact.each do |domain|
      m = eval "Settings.domain_registers_#{domain.tld}"
      m = Settings.domain_default_register if m.nil?
      regdom = eval "Regdom::#{m.humanize}"
      regdom.update_contact(domain,domain.admin_contact,self)
    end
  end

end
