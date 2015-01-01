class V1::DomainRegistrationsController < ApplicationController
  def index
    begin
      domains = User.find(params[:user_id]).domain_registrations
      render json: domains
    rescue => e
      render json: {error: "#{e.message}"}, status: 500
    end
  end

  def create
    begin
      domain_to_register = User.find(params[:user_id]).domain_registrations.new(domain_registration_params)

      domain_to_register.registrant_contact = User.find(params[:user_id]).contacts.find(params[:registrant_contact])
      domain_to_register.tech_contact = User.find(params[:user_id]).contacts.find(params[:tech_contact])
      domain_to_register.admin_contact = User.find(params[:user_id]).contacts.find(params[:admin_contact])

      domain_to_register.save

      domain_to_register.save

      render json: domain_to_register.to_json
    rescue => e
      render json: {error: "#{e.message}"}, status: 500
    end
  end

  def update
    begin
      domain_to_register = User.find(params[:user_id]).domain_registrations.find(params[:id])

      domain_to_register.registrant_contact = User.find(params[:user_id]).contacts.find(params[:registrant_contact])
      domain_to_register.tech_contact = User.find(params[:user_id]).contacts.find(params[:tech_contact])
      domain_to_register.admin_contact = User.find(params[:user_id]).contacts.find(params[:admin_contact])

      domain_to_register.update(domain_registration_params)

      render json: domain_to_register.to_json
    rescue => e
      render json: {error: "#{e.message}"}, status: 500
    end
  end

  def show
    begin
      domain_to_register = User.find(params[:user_id]).domain_registrations.find(params[:id])

      render json: domain_to_register.to_json
    rescue => e
      render json: {error: "#{e.message}"}, status: 500
    end
  end

  def destroy
    begin
      domain_to_register = User.find(params[:user_id]).domain_registrations.find(params[:id])
      domain_to_register.destroy

      render json: domain_to_register.to_json
    rescue => e
      render json: {error: "#{e.message}"}, status: 500
    end
  end

  def transfer
    begin
      domain_to_register = User.find(params[:user_id]).domain_registrations.new(domain_registration_params)

      domain_to_register.registrant_contact = User.find(params[:user_id]).contacts.find(params[:registrant_contact])
      domain_to_register.tech_contact = User.find(params[:user_id]).contacts.find(params[:tech_contact])
      domain_to_register.admin_contact = User.find(params[:user_id]).contacts.find(params[:admin_contact])

      domain_to_register.transfer

      render json: domain_to_register.to_json
    rescue => e
      render json: {error: "#{e.message}"}, status: 500
    end
  end

  def renew
    begin
      domain_to_register = User.find(params[:user_id]).domain_registrations.find(params[:id])
      domain_to_register.renew

      render json: domain_to_register.to_json
    rescue => e
      render json: {error: "#{e.message}"}, status: 500
    end
  end

  def lock
    begin
      domain_to_register = User.find(params[:user_id]).domain_registrations.find(params[:id])
      domain_to_register.lock

      render json: domain_to_register.to_json
    rescue => e
      render json: {error: "#{e.message}"}, status: 500
    end
  end

  def unlock
    begin
      domain_to_register = User.find(params[:user_id]).domain_registrations.find(params[:id])
      domain_to_register.unlock

      render json: domain_to_register.to_json
    rescue => e
      render json: {error: "#{e.message}"}, status: 500
    end
  end

  def epp_key
    begin
      domain_to_register = User.find(params[:user_id]).domain_registrations.find(params[:id])

      render json: domain_to_register.epp_key
    rescue => e
      render json: {error: "#{e.message}"}, status: 500
    end
  end

  private

  def domain_registration_params
    params.require(:domain_registration).permit( :tld,
                                                 :domain,
                                                 :ns1,
                                                 :ns2,
                                                 :ns3,
                                                 :ns4,
                                                 :ns5,
                                                 :registrant_contact,
                                                 :tech_contact,
                                                 :admin_contact,
                                                 :auth_code
    )
  end
end
