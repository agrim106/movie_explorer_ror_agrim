ActiveAdmin.register Movie do
  permit_params :title, :genre, :release_year, :rating, :director, :duration, :streaming_platform, :main_lead, :description, :premium, :poster, :banner

  # Index page configuration
  index do
    selectable_column
    id_column
    column :title
    column :genre
    column :release_year
    column :rating
    column :director
    column :duration
    column :streaming_platform
    column :main_lead
    column :description
    column :premium
    column :poster do |movie|
      image_tag(movie.poster.url, width: 100) if movie.poster.attached?
    end
    column :banner do |movie|
      image_tag(movie.banner.url, width: 100) if movie.banner.attached?
    end
    column :created_at
    actions
  end

  # Filters
  filter :title
  filter :genre, as: :select, collection: %w[action horror comedy romance]
  filter :release_year
  filter :rating
  filter :premium
  filter :created_at

  # Form configuration
  form do |f|
    f.inputs do
      f.input :title
      f.input :genre, as: :select, collection: %w[action horror comedy romance]
      f.input :release_year
      f.input :rating
      f.input :director
      f.input :duration
      f.input :streaming_platform
      f.input :main_lead
      f.input :description
      f.input :premium
      f.input :poster, as: :file
      f.input :banner, as: :file
    end
    f.actions
  end
end