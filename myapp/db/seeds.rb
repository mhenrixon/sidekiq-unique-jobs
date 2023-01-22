# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
user = User.create(
  email: "mikael@mhenrixon.com",
  password: "Abc123!!",
  password_confirmation: "Abc123!!",
  admin: true
)

user.confirm
