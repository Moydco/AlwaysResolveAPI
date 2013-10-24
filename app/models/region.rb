# Attributes:
# - code: String, two-letters country code (ex. IT, US)
# - ip_address: String, the ip address of local RabbitMQ server

class Region
  include Mongoid::Document
  field :code, type: String
  field :ip_address, type: String


end

