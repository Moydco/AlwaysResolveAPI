class DomainMonthlyStat
  include Mongoid::Document

  field :count, type: Integer
  field :month, type: Integer
  field :year, type: Integer

  belongs_to :domain

  before_update :add_to_count

  def add_to_count
    self.count = self.count_was + self.count
  end
end
