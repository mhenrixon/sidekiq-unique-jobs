# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "mikael#{n}@mhenrixon.com" }
    password { "Abc123!!" }
    password_confirmation { "Abc123!!" }

    trait :confirmed do
      after(:create) do |instance, _evaluator|
        instance.confirm
      end
    end
  end
end
