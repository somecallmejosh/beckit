require "test_helper"

class DistortionTest < ActiveSupport::TestCase
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
end
