class Movie < ApplicationRecord
  # Associations
  has_many :reviews, dependent: :destroy
  has_many :orders, dependent: :destroy

  # Attachments for Active Storage
  has_one_attached :poster
  has_one_attached :banner

  # Basic validations
  validates :title, presence: true
  validates :genre, presence: true, inclusion: { in: %w[action horror comedy romance] }
  validates :release_year, presence: true, numericality: { only_integer: true }, inclusion: { in: 1900..Time.current.year }
  validates :rating, presence: true, numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 10.0 }
  validates :director, presence: true
  validates :duration, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 30 }
  validates :main_lead, presence: true
  validates :description, presence: true, length: { maximum: 1000 }
  validates :premium, inclusion: { in: [true, false] }

  # Custom validation for attachments
  validate :poster_attached
  validate :banner_attached

  # Custom validation for release_year (no future dates)
  validate :release_year_cannot_be_future

  # Scope for premium movies
  scope :premium_movies, -> { where(premium: true) }

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    %w[title genre release_year rating director duration main_lead description premium]
  end

  def self.search_and_filter(params)
    movies = all
    movies = movies.where("title ILIKE ?", "%#{params[:title]}%") if params[:title].present?
    movies = movies.where(genre: params[:genre]) if params[:genre].present?
    movies = movies.where("release_year = ?", params[:release_year]) if params[:release_year].present?
    movies = movies.where("rating >= ?", params[:min_rating]) if params[:min_rating].present?
    movies = movies.where(premium: params[:premium]) if params[:premium].present?
    movies.order(created_at: :desc)
  end

  def poster_url
    poster.attached? ? Rails.application.routes.url_helpers.rails_blob_path(poster, only_path: true) : nil
  end

  def banner_url
    banner.attached? ? Rails.application.routes.url_helpers.rails_blob_path(banner, only_path: true) : nil
  end

  # Class method to create a movie with file uploads
  def self.create_movie(params)
    movie = Movie.new(params.except(:poster, :banner))
    movie.poster.attach(params[:poster]) if params[:poster].present?
    movie.banner.attach(params[:banner]) if params[:banner].present?

    if movie.save
      { success: true, movie: movie }
    else
      { success: false, errors: movie.errors.full_messages }
    end
  end

  # Instance method to update a movie with file uploads
  def update_movie(params)
    self.attributes = params.except(:poster, :banner)
    self.poster.attach(params[:poster]) if params[:poster].present?
    self.banner.attach(params[:banner]) if params[:banner].present?

    if save
      { success: true, movie: self }
    else
      { success: false, errors: errors.full_messages }
    end
  end

  private

  def poster_attached
    unless poster.attached?
      errors.add(:poster, "must be attached")
    end
  end

  def banner_attached
    unless banner.attached?
      errors.add(:banner, "must be attached")
    end
  end

  def release_year_cannot_be_future
    if release_year.present? && release_year > Time.current.year
      errors.add(:release_year, "cannot be in the future")
    end
  end
  def self.ransackable_associations(auth_object = nil)
    ["banner_attachment", "banner_blob", "orders", "poster_attachment", "poster_blob", "reviews"]
  end
end