require 'rails_helper'

RSpec.describe Movie, type: :model do
  # FactoryBot setup
  let(:valid_attributes) do
    {
      title: "Inception",
      genre: "action",
      release_year: 2010,
      rating: 8.5,
      director: "Christopher Nolan",
      duration: 148,
      main_lead: "Leonardo DiCaprio",
      description: "A mind-bending thriller",
      premium: false
    }
  end

  # Validations tests
  it "is valid with valid attributes" do
    movie = Movie.new(valid_attributes)
    expect(movie).to be_valid
  end

  it "is not valid without a title" do
    movie = Movie.new(valid_attributes.except(:title))
    expect(movie).not_to be_valid
    expect(movie.errors[:title]).to include("can't be blank")
  end

  it "is not valid with an invalid genre" do
    movie = Movie.new(valid_attributes.merge(genre: "sci-fi"))
    expect(movie).not_to be_valid
    expect(movie.errors[:genre]).to include("is not included in the list")
  end

  it "is not valid with a future release_year" do
    movie = Movie.new(valid_attributes.merge(release_year: Time.current.year + 1))
    expect(movie).not_to be_valid
    expect(movie.errors[:release_year]).to include("cannot be in the future")
  end

  it "is not valid with a rating outside range" do
    movie = Movie.new(valid_attributes.merge(rating: 11.0))
    expect(movie).not_to be_valid
    expect(movie.errors[:rating]).to include("must be less than or equal to 10.0")
  end

  it "is not valid with a duration less than 30" do
    movie = Movie.new(valid_attributes.merge(duration: 20))
    expect(movie).not_to be_valid
    expect(movie.errors[:duration]).to include("must be greater than or equal to 30")
  end

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