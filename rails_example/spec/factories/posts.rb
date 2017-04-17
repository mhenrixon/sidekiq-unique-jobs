# frozen_string_literal: true

FactoryGirl.define do
  factory :post do
    title 'MyString'
    body 'MyText'
    excerpt 'MyString'
    read_count 1
  end
end
