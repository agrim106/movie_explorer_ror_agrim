# db/migrate/[TIMESTAMP]_remove_poster_and_banner_url_from_movies.rb
class RemovePosterAndBannerUrlFromMovies < ActiveRecord::Migration[7.1]
  def change
    remove_column :movies, :poster_url, :string
    remove_column :movies, :banner_url, :string
  end
end