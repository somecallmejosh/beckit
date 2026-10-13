require "test_helper"

class DistortionTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "requires title and description" do
    distortion = Distortion.new
    assert_not distortion.valid?
    assert_includes distortion.errors[:title], "can't be blank"
    assert_includes distortion.errors[:description], "can't be blank"
  end

  test "requires a unique title" do
    distortion = Distortion.new(title: distortions(:catastrophizing).title.downcase, description: "Dup")
    assert_not distortion.valid?
    assert_includes distortion.errors[:title], "has already been taken"
  end

  test "destroying a distortion keeps its situations" do
    situation = situations(:one)
    distortions(:catastrophizing).destroy

    assert Situation.exists?(situation.id)
    assert_equal [ distortions(:mind_reading) ], situation.reload.distortions
  end

  test "builds a 1200x630 social card from the photo" do
    distortion = distortions(:catastrophizing)
    perform_enqueued_jobs { distortion.update!(image: photo) }

    assert distortion.og_image.attached?
    card = Vips::Image.new_from_buffer(distortion.og_image.download, "")
    assert_equal [ 1200, 630 ], [ card.width, card.height ]
  end

  test "rebuilds the card when the text changes, and drops it with the photo" do
    distortion = distortions(:catastrophizing)
    perform_enqueued_jobs { distortion.update!(image: photo) }

    assert_enqueued_with(job: Distortion::RefreshOgImageJob) { distortion.update!(description: "New words.") }
    assert_no_enqueued_jobs(only: Distortion::RefreshOgImageJob) { distortion.update!(details: "<p>Only details.</p>") }

    distortion.image.purge
    distortion.refresh_og_image
    assert_not distortion.reload.og_image.attached?
  end

  test "attaches the starter photo, updates an older one, and keeps an uploaded one" do
    distortion = distortions(:catastrophizing)
    starter = Distortion::STARTER_PHOTOS.join("catastrophizing.webp")

    distortion.refresh_starter_photo
    assert_equal Digest::MD5.file(starter).base64digest, distortion.reload.image.checksum

    distortion.update!(image: photo.merge(filename: "catastrophizing.webp"))
    distortion.refresh_starter_photo
    assert_equal Digest::MD5.file(starter).base64digest, distortion.reload.image.checksum

    distortion.update!(image: photo)
    assert_no_changes(-> { distortion.reload.image.blob_id }) { distortion.refresh_starter_photo }
  end

  test "shows the drawing while the starter image is attached, and an uploaded image instead" do
    distortion = distortions(:catastrophizing)
    assert_nil distortion.illustration

    distortion.refresh_starter_photo
    assert_equal "traps/catastrophizing.svg", distortion.reload.illustration

    distortion.update!(image: photo)
    assert_nil distortion.reload.illustration
  end

  private
    def photo = { io: file_fixture("trap.webp").open, filename: "trap.webp", content_type: "image/webp" }
end
