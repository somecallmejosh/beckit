namespace :distortions do
  desc "Swap in updated starter photos from db/seeds/traps (photos uploaded through the admin form are kept)"
  task refresh_starter_photos: :environment do
    Distortion.find_each(&:refresh_starter_photo)
  end
end
