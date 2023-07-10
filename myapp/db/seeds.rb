# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
user = User.create_with(
  password: "Abc123!!",
  password_confirmation: "Abc123!!",
  admin: true,
).find_or_create_by!(email: "mikael@mhenrixon.com")

user.confirm unless user.confirmed?
