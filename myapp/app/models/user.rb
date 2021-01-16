# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  #
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable, :trackable # , :omniauthable
end
