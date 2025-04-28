FactoryBot.define do
  factory :movie do
    title { "Inception" }
    genre { "action" }
    release_year { 2010 }
    rating { 8.5 }
    director { "Christopher Nolan" }
    duration { 148 }
    main_lead { "Leonardo DiCaprio" }
    description { "A mind-bending thriller" }
    premium { false }

    # Add dummy images for testing
  
    transient do
      poster_file { Rails.root.join("spec/support/interstellar.jpg") }
      banner_file { Rails.root.join("spec/support/interstellarbanner.jpg") }
    end

    after(:build) do |movie, evaluator|
      movie.poster.attach(io: File.open(evaluator.poster_file), filename: "interstellar.jpg", content_type: "image/jpg")
      movie.banner.attach(io: File.open(evaluator.banner_file), filename: "interstellarbanner.jpg", content_type: "image/jpg")
    end
  end
end