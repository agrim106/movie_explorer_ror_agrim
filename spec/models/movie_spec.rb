require 'rails_helper'

RSpec.describe Movie, type: :model do
  describe "validations" do
    # FactoryBot setup
    let(:movie) { FactoryBot.build(:movie) }

    # Validations tests
    it "is valid with valid attributes and attachments" do
      expect(movie).to be_valid
    end

    it "is not valid without a title" do
      movie = FactoryBot.build(:movie, title: nil)
      expect(movie).not_to be_valid
      expect(movie.errors[:title]).to include("can't be blank")
    end

    it "is not valid without a poster" do
      movie = FactoryBot.build(:movie)
      movie.poster.purge # Remove poster
      expect(movie).not_to be_valid
      expect(movie.errors[:poster]).to include("must be attached")
    end

    it "is not valid without a banner" do
      movie = FactoryBot.build(:movie)
      movie.banner.purge # Remove banner
      expect(movie).not_to be_valid
      expect(movie.errors[:banner]).to include("must be attached")
    end

    it "is not valid with an invalid genre" do
      movie = FactoryBot.build(:movie, genre: "sci-fi")
      expect(movie).not_to be_valid
      expect(movie.errors[:genre]).to include("is not included in the list")
    end

    it "is not valid with a future release_year" do
      movie = FactoryBot.build(:movie, release_year: Time.current.year + 1)
      expect(movie).not_to be_valid
      expect(movie.errors[:release_year]).to include("cannot be in the future")
    end

    it "is not valid with a rating outside range" do
      movie = FactoryBot.build(:movie, rating: 11.0)
      expect(movie).not_to be_valid
      expect(movie.errors[:rating]).to include("must be less than or equal to 10.0")
    end

    it "is not valid with a duration less than 30" do
      movie = FactoryBot.build(:movie, duration: 20)
      expect(movie).not_to be_valid
      expect(movie.errors[:duration]).to include("must be greater than or equal to 30")
    end
  end

  describe "associations" do
    # Associations tests (basic)
    it "has many reviews" do
      association = Movie.reflect_on_association(:reviews)
      expect(association.macro).to eq(:has_many)
    end

    it "has many orders" do
      association = Movie.reflect_on_association(:orders)
      expect(association.macro).to eq(:has_many)
    end
  end

  describe "scopes" do
    it "returns premium movies" do
      premium_movie = FactoryBot.create(:movie, premium: true)
      non_premium_movie = FactoryBot.create(:movie, premium: false)
      expect(Movie.premium_movies).to include(premium_movie)
      expect(Movie.premium_movies).not_to include(non_premium_movie)
    end
  end
end