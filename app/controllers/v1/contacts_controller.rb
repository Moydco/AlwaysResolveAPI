class V1::ContactsController < ApplicationController
  before_filter :restrict_access

  before_filter :authorize_resource

  def index
    begin
      contacts = User.find(params[:user_id]).contacts
      render json: contacts
    rescue => e
      render json: {error: "#{e.message}"}, status: 500
    end
  end

  def create
    #begin
      user = User.find(params[:user_id])
      logger.debug(contact_params)
      contact = user.contacts.create!(contact_params)
      render json: contact.to_json
    #rescue => e
    #  render json: {error: "#{e.message}"}, status: 500
    #end
  end

  def update
    begin
      contact = User.find(params[:user_id]).contacts.find(params[:id]).update!(contact_params)
      render json: contact.to_json
    rescue => e
      render json: {error: "#{e.message}"}, status: 500
    end
  end

  def show
    begin
      contact = User.find(params[:user_id]).contacts.find(params[:id])
      render json: contact.to_json
    rescue => e
      render json: {error: "#{e.message}"}, status: 500
    end
  end

  private

  def contact_params
    params.require(:contact).permit(
        :registrant_organization_name,
        :registrant_job_title,
        :registrant_first_name,
        :registrant_last_name,
        :registrant_address1,
        :registrant_address2,
        :registrant_city,
        :registrant_postal_code,
        :registrant_state_province,
        :registrant_state_province_choice,
        :registrant_country,
        :registrant_phone,
        :registrant_fax,
        :registrant_email_address
    )
  end
end
