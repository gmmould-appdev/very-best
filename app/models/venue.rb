class Venue < ApplicationRecord
  before_validation :geocode_address

  ransacker :name_case_insensitive, type: :string do
    arel_table[:name].lower
  end
    
  def geocode_address
    if !Rails.env.test? && self.address.present?
      url = "http://maps.googleapis.com/maps/api/geocode/json?address=#{URI.encode(self.address)}"

      raw_data = open(url).read

      parsed_data = JSON.parse(raw_data)

      if parsed_data["results"].present?
        self.address_latitude = parsed_data["results"][0]["geometry"]["location"]["lat"]

        self.address_longitude = parsed_data["results"][0]["geometry"]["location"]["lng"]

        self.address_formatted_address = parsed_data["results"][0]["formatted_address"]
      end
    end
  end
  # Direct associations

  belongs_to :neighborhood,
             :counter_cache => true

  has_many   :bookmarks,
             :dependent => :destroy

  # Indirect associations

  has_many   :specialties,
             :through => :bookmarks,
             :source => :dish

  has_many   :fans,
             :through => :bookmarks,
             :source => :user

  # Validations

  validates :name, :uniqueness => { :scope => [:address_formatted_address], :message => "already exists", :case_sensitive => false }

  validates :name, :presence => true

end
