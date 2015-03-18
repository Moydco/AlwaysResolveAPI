FactoryGirl.define do
  factory :user do |f|
    f.user_reference { Faker::Code.ean }
  end
end