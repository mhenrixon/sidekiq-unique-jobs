# frozen_string_literal: true

FactoryBot.define do
  factory :post do
    title      { 'MyString' }
    body       { 'MyText' }
    excerpt    { 'MyString' }
    read_count { 1 }
  end
end
