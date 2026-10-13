namespace :distortions do
  desc "Swap in updated starter photos from db/seeds/traps (photos uploaded through the admin form are kept)"
  task refresh_starter_photos: :environment do
    Distortion.find_each(&:refresh_starter_photo)
    Rake::Task["distortions:refresh_og_images"].invoke
  end

  # Builds the cards inline: the jobs a photo swap enqueues are lost when the task exits under the async adapter.
  desc "Rebuild every thinking trap's social share card"
  task refresh_og_images: :environment do
    Distortion.find_each(&:refresh_og_image)
  end
end
