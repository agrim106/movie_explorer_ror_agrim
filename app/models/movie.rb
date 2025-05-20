require 'open-uri'

class Movie < ApplicationRecord
  VALID_GENRES = %w[action horror comedy romance sci-fi].freeze
  VALID_STREAMING_PLATFORMS = ['Netflix', 'Amazon Prime', 'Disney+'].freeze

  # Associations
  has_many :reviews, dependent: :destroy
  has_many :orders, dependent: :destroy

  # Attachments for Active Storage (Cloudinary)
  has_one_attached :poster
  has_one_attached :banner

  # Validations for Create
  validates :title, presence: true, on: :create
  validates :genre, presence: true, inclusion: { in: VALID_GENRES }, on: :create
  validates :release_year, presence: true, numericality: { only_integer: true }, inclusion: { in: 1900..Time.current.year }, on: :create
  validates :rating, presence: true, numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 10.0 }, on: :create
  validates :director, presence: true, on: :create
  validates :duration, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 30 }
  validates :main_lead, presence: true, on: :create
  validates :streaming_platform, presence: true, inclusion: { in: VALID_STREAMING_PLATFORMS }, on: :create
  validates :description, presence: true, length: { maximum: 1000 }, on: :create
  validates :premium, inclusion: { in: [true, false] }, on: :create

  # Validations for Update
  validates :title, length: { minimum: 1 }, allow_blank: true, on: :update
  validates :genre, inclusion: { in: VALID_GENRES }, allow_blank: true, on: :update
  validates :release_year, numericality: { only_integer: true }, inclusion: { in: 1900..Time.current.year }, allow_nil: true, on: :update
  validates :rating, numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 10.0 }, allow_nil: true, on: :update
  validates :director, length: { minimum: 1 }, allow_blank: true, on: :update
  validates :duration, numericality: { only_integer: true, greater_than_or_equal_to: 30 }, allow_nil: true, on: :update
  validates :main_lead, length: { minimum: 1 }, allow_blank: true, on: :update
  validates :streaming_platform, inclusion: { in: VALID_STREAMING_PLATFORMS }, allow_blank: true, on: :update
  validates :description, length: { maximum: 1000 }, allow_blank: true, on: :update
  validates :premium, inclusion: { in: [true, false] }, allow_nil: true, on: :update

  # Attachment Validations
  validates :poster, content_type: ['image/png', 'image/jpg', 'image/jpeg'], size: { less_than: 5.megabytes }, allow_blank: true, on: :create
  validates :banner, content_type: ['image/png', 'image/jpg', 'image/jpeg'], size: { less_than: 5.megabytes }, allow_blank: true, on: :create
  validates :poster, content_type: ['image/png', 'image/jpg', 'image/jpeg'], size: { less_than: 5.megabytes }, allow_blank: true, on: :update
  validates :banner, content_type: ['image/png', 'image/jpg', 'image/jpeg'], size: { less_than: 5.megabytes }, allow_blank: true, on: :update

  # Custom validation for release_year
  validate :release_year_cannot_be_future

  # Debug callbacks
  before_validation do
    Rails.logger.info "Before validation: title = #{title}, changes = #{changes}"
  end

  before_save do
    Rails.logger.info "Before save (callback): title = #{title}, changes = #{changes}"
  end

  after_save do
    Rails.logger.info "After save (callback): title = #{title}, changes = #{changes}"
  end

  # Custom title= setter
  def title=(value)
    Rails.logger.info "Custom title= setter called with value: #{value}"
    write_attribute(:title, value)
  end

  # Scope
  scope :premium_movies, -> { where(premium: true) }

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    %w[title genre release_year rating director duration main_lead streaming_platform description premium]
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
    poster.attached? ? poster.url : nil
  end

  def banner_url
    banner.attached? ? banner.url : nil
  end

  def plan
    premium? ? "premium" : "basic"
  end

  def self.create_movie(params)
    movie = Movie.new(params.except(:poster, :banner))
    movie.poster.attach(params[:poster]) if params[:poster].present? && (params[:poster].is_a?(ActionDispatch::Http::UploadedFile) || (params[:poster].is_a?(String) && params[:poster].start_with?('http')))
    movie.banner.attach(params[:banner]) if params[:banner].present? && (params[:banner].is_a?(ActionDispatch::Http::UploadedFile) || (params[:banner].is_a?(String) && params[:banner].start_with?('http')))

    if movie.save
      { success: true, movie: movie }
    else
      { success: false, errors: movie.errors.full_messages }
    end
  end

  def update_movie(params)
    Rails.logger.info "Before update_movie: title = #{title}, changes = #{changes}, params = #{params.inspect}"
    params = params.transform_keys(&:to_sym) if params.respond_to?(:transform_keys)
    permitted_params = params.slice(:title, :genre, :release_year, :rating, :director, :duration, :main_lead, :streaming_platform, :description, :premium)
    Rails.logger.info "Permitted params in update_movie: #{permitted_params.inspect}"

    Rails.logger.info "Attempting assign_attributes with: #{permitted_params.inspect}"
    assign_attributes(permitted_params)
    Rails.logger.info "After assign_attributes: title = #{title}, changes = #{changes}"

    # Handle poster attachment
    if params[:poster].present?
      begin
        if params[:poster].is_a?(ActionDispatch::Http::UploadedFile)
          Rails.logger.info "Attaching poster file upload"
          self.poster.attach(params[:poster])
        elsif params[:poster].is_a?(String) && params[:poster].start_with?('http')
          Rails.logger.info "Downloading and attaching poster from URL: #{params[:poster]}"
          attach_from_url(params[:poster], 'poster.jpg', :poster)
        else
          Rails.logger.error "Invalid poster format: #{params[:poster].inspect}"
          errors.add(:poster, "Invalid format: must be a file or valid URL")
        end
      rescue StandardError => e
        Rails.logger.error "Error attaching poster: #{e.message}"
        errors.add(:poster, "Failed to attach: #{e.message}")
      end
    end

    # Handle banner attachment
    if params[:banner].present?
      begin
        if params[:banner].is_a?(ActionDispatch::Http::UploadedFile)
          Rails.logger.info "Attaching banner file upload"
          self.banner.attach(params[:banner])
        elsif params[:banner].is_a?(String) && params[:banner].start_with?('http')
          Rails.logger.info "Downloading and attaching banner from URL: #{params[:banner]}"
          attach_from_url(params[:banner], 'banner.jpg', :banner)
        else
          Rails.logger.error "Invalid banner format: #{params[:banner].inspect}"
          errors.add(:banner, "Invalid format: must be a file or valid URL")
        end
      rescue StandardError => e
        Rails.logger.error "Error attaching banner: #{e.message}"
        errors.add(:banner, "Failed to attach: #{e.message}")
      end
    end

    Rails.logger.info "Before save: title = #{title}, changes = #{changes}"
    begin
      if save
        Rails.logger.info "Update successful: title = #{title}, changes = #{changes}"
        { success: true, movie: self }
      else
        Rails.logger.info "Update failed: errors = #{errors.full_messages}"
        { success: false, errors: errors.full_messages }
      end
    rescue ActiveSupport::MessageVerifier::InvalidSignature => e
      Rails.logger.error "InvalidSignature error during save: #{e.message}"
      { success: false, errors: ["Failed to update movie due to an internal error: #{e.message}"] }
    rescue StandardError => e
      Rails.logger.error "Unexpected error during save: #{e.message}"
      { success: false, errors: ["Unexpected error: #{e.message}"] }
    end
  end

  private

  def attach_from_url(url, filename, attachment_name)
    unless url.start_with?('https://res.cloudinary.com', 'https://res-1.cloudinary.com', 'https://res-2.cloudinary.com', 'https://res-3.cloudinary.com', 'https://res-4.cloudinary.com')
      errors.add(attachment_name, "URL must be from Cloudinary")
      return
    end

    uri = URI.parse(url)
    file = URI.open(url)
    content_type = file.content_type || 'image/jpeg' # Fallback to JPEG if content_type is not detected
    attachment = { io: file, filename: filename, content_type: content_type }
    send(attachment_name).attach(attachment)
  rescue URI::InvalidURIError
    Rails.logger.error "Invalid URL for #{attachment_name}: #{url}"
    errors.add(attachment_name, "Invalid URL")
  rescue OpenURI::HTTPError => e
    Rails.logger.error "Failed to download #{attachment_name} from URL: #{url}, error: #{e.message}"
    errors.add(attachment_name, "Failed to download image: #{e.message}")
  ensure
    file&.close
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