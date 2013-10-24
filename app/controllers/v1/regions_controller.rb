class V1::RegionsController < ApplicationController

  # ==== GET: /v1/regions/
  # Return all regions
  #
  # Return:
  # - an array of regions if success with 200 code
  # - an error string with the error message if error with code 404
  def index
    respond_to do |format|
      format.html {render text: Region.all.to_yaml}
      format.xml {render xml: Region.all}
      format.json {render json: Region.all}
    end
  end

  # ==== GET: /v1/regions/:id
  # Return a regions
  #
  # Params:
  # - id: the id of the region
  # Return:
  # - an array describe selected region if success with 200 code
  # - an error string with the error message if error with code 404
  def show
    respond_to do |format|
      format.html {render text: Region.find(params[:id]).to_yaml}
      format.xml {render xml: Region.find(params[:id])}
      format.json {render json: Region.find(params[:id])}
    end
  end

  # ==== POST: /v1/regions/
  # Create a region
  #
  # Params:
  # - code: String, two-letters country code (ex. IT, US)
  # - ip_address: String, the ip address of local RabbitMQ server
  # Return:
  # - an array describe created region if success with 200 code
  # - an error string with the error message if error with code 404
  def create
    region = Region.create(:code => params[:code], :ip_address => params[:ip_address])
    respond_to do |format|
      format.html {render text: region.to_yaml}
      format.xml {render xml: region}
      format.json {render json: region}
    end
  end

  # ==== PUT: /v1/regions/:id
  # Update a region
  #
  # Params:
  # - id: the id of the region
  # - code: String, two-letters country code (ex. IT, US)
  # - ip_address: String, the ip address of local RabbitMQ server
  # Return:
  # - an array describe updated region if success with 200 code
  # - an error string with the error message if error with code 404
  def update
    region = Region.find(params[:id])
    region.update_attributes(:code => params[:code], :ip_address => params[:ip_address])
    respond_to do |format|
      format.html {render text: region.to_yaml}
      format.xml {render xml: region}
      format.json {render json: region}
    end
  end

  # ==== DELETE: /v1/regions/:id
  # Destroy a region
  #
  # Params:
  # - id: the id of the region
  # Return:
  # - an array describe deleted region if success with 200 code
  # - an error string with the error message if error with code 404
  def destroy
    region = Region.find(params[:id])
    region.destroy
    respond_to do |format|
      format.html {render text: region.to_yaml}
      format.xml {render xml: region}
      format.json {render json: region}
    end
  end
end
