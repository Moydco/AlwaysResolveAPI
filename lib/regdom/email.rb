module Regdom
  module Email
    def self.create_contact(domain,contact)
      puts "Create new contact for #{domain.to_yaml}"
      puts "Contact #{contact}"
    end

    def self.update_contact(domain,registrant_contact,contact)
      puts "Update contact #{registrant_contact} for #{domain.to_yaml}"
      puts "Contact #{contact}"
    end

    def self.search_domain(domain,tld)
      w = Whois::Client.new
      !w.lookup("#{domain}.#{tld}").to_s.include?('AVAILABLE')
    end

    def self.register_domain(domain)
      puts "Register #{domain.to_yaml}"
    end

    def self.update_domain(domain)
      puts "Update #{domain.to_yaml}"
    end

    def self.destroy_domain(domain)
      puts "Destroy #{domain.to_yaml}"
    end

    def self.renew_domain(domain)
      puts "Renew #{domain.to_yaml}"
    end

    def self.transfer_domain(domain)
      puts "Transfer #{domain.to_yaml}"
    end

    def self.lock_domain(domain)
      puts "Lock #{domain.to_yaml}"
    end

    def self.unlock_domain(domain)
      puts "Unlock #{domain.to_yaml}"
    end

    def self.epp_key_domain(domain)
      puts "Epp_key #{domain.to_yaml}"
    end
  end

end