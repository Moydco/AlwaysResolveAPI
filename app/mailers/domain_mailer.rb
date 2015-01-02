class DomainMailer < ActionMailer::Base
  default from: "domain_registration_service@entercloudsuite.com"

  def new_operation(subject,text)
    @subject = subject
    @text = text
    mail(to: Settings.domainmaster_email,
         subject: @subject,
         body: @text )
  end
end
