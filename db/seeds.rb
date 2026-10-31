# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Common cognitive distortions (Beck / Burns), with questions that help test a thought caught in each.
[
  [ "All-or-nothing thinking", "Seeing things in black-and-white categories; if a situation falls short of perfect, it is seen as a total failure.",
    [ "Is there a middle ground between total success and total failure?", "What went partly right?" ] ],
  [ "Overgeneralization", "Viewing a single negative event as a never-ending pattern of defeat, often using words like \"always\" or \"never\".",
    [ "Is it really always, or was it this time?", "Can you think of a time it went differently?" ] ],
  [ "Mental filter", "Dwelling on a single negative detail so that it colors the perception of the whole situation.",
    [ "What else happened that you might be leaving out?", "Zoom out on the whole day. What do you see?" ] ],
  [ "Disqualifying the positive", "Rejecting positive experiences by insisting they \"don't count\" for some reason.",
    [ "Would you dismiss this if it happened to a friend?", "What good thing aren't you counting?" ] ],
  [ "Mind reading", "Concluding that someone is reacting negatively to you without checking it out.",
    [ "What do you actually know about what they were thinking?", "Is there another reason they might have acted that way?" ] ],
  [ "Fortune telling", "Anticipating that things will turn out badly and treating the prediction as an established fact.",
    [ "Has a prediction like this come true before?", "What's another way this could turn out?" ] ],
  [ "Catastrophizing", "Exaggerating the importance or likely consequences of problems, or expecting the worst possible outcome.",
    [ "What's the most likely outcome, not the worst one?", "If the worst did happen, how would you cope?", "Will this matter a year from now?" ] ],
  [ "Emotional reasoning", "Assuming that negative emotions reflect the way things really are: \"I feel it, so it must be true.\"",
    [ "Is this a feeling or a fact?", "What would you think about it if you felt calm?" ] ],
  [ "Should statements", "Motivating yourself or judging others with rigid rules about what \"should\" or \"must\" happen.",
    [ "Whose rule is this, and is it a fair one?", "How would it sound as \"it would be nice if\"?" ] ],
  [ "Labeling", "Attaching a global negative label to yourself or others instead of describing the specific behavior.",
    [ "What did you actually do, rather than what you are?", "Would you call a friend that for the same thing?" ] ],
  [ "Personalization", "Seeing yourself as the cause of a negative external event for which you were not primarily responsible.",
    [ "What else played a part in this?", "How much of it was really in your control?" ] ]
].each do |title, description, questions|
  distortion = Distortion.find_or_create_by!(title: title) { |d| d.description = description }
  distortion.update!(questions: questions.join("\n")) if distortion.questions.blank?
end

# Starter photos for each trap, and the social cards built from them. The cards are built inline because
# the jobs a photo swap enqueues are lost when seeding exits under the async adapter.
Distortion.find_each(&:refresh_starter_photo)
Distortion.find_each(&:refresh_og_image)

# Sample journal entries for local development. Skipped once they exist, so
# re-running db:seed does not add duplicates.
if Rails.env.development? && (user = User.find_by(admin: true) || User.first)
  scenarios = [
    { title: "Presentation at work", location: "Office", who: "My team", thought: "Everyone could tell I was nervous.", for: "My voice shook during the first slide.", against: "Two people said it was clear and asked follow-up questions.", balanced: "I was nervous, and the presentation still landed. Nerves are not the same as failure.", distortions: [ "Mind reading", "Mental filter" ] },
    { title: "Friend didn't text back", location: "Home", who: "Sam", thought: "They're annoyed with me.", for: "It's been two days since I messaged.", against: "Sam mentioned a busy week at work. We had a good time last weekend.", balanced: "There are many reasons someone might not reply. I can check in without assuming the worst.", distortions: [ "Mind reading", "Personalization" ] },
    { title: "Missed a deadline", location: "Home office", who: "My manager", thought: "I'm going to get fired.", for: "The report was a day late.", against: "My reviews have been good. My manager said thanks for flagging it early.", balanced: "One late report is a setback, not a pattern. I communicated and I'll plan better next time.", distortions: [ "Catastrophizing", "Fortune telling" ] },
    { title: "Critical comment in a meeting", location: "Conference room", who: "A colleague", thought: "My idea was stupid.", for: "Alex pointed out a flaw in the timeline.", against: "Two other parts of the proposal were adopted.", balanced: "Feedback on one part doesn't make the whole idea bad. The critique made it stronger.", distortions: [ "All-or-nothing thinking", "Labeling" ] },
    { title: "Skipped the gym again", location: "Home", who: "Just me", thought: "I have no discipline. I always quit.", for: "I've missed three sessions this week.", against: "I went consistently for two months before this busy stretch.", balanced: "A rough week doesn't erase two months of progress. I can start again tomorrow.", distortions: [ "Overgeneralization", "Labeling", "Should statements" ] },
    { title: "Awkward moment at a party", location: "Jordan's apartment", who: "People I'd just met", thought: "They all thought I was weird.", for: "There was a long pause after my joke.", against: "Someone asked for my number at the end of the night.", balanced: "One quiet moment doesn't define the evening. Most people are focused on themselves.", distortions: [ "Mind reading", "Mental filter" ] },
    { title: "Partner seemed distant", location: "Kitchen", who: "My partner", thought: "Something is wrong between us.", for: "They were quiet through dinner.", against: "They mentioned a headache earlier and hugged me before bed.", balanced: "Quiet doesn't mean upset. I can ask how they're doing instead of guessing.", distortions: [ "Mind reading", "Emotional reasoning" ] },
    { title: "Unexpected bill", location: "Home", who: "Just me", thought: "I'll never get ahead financially.", for: "The car repair was more than I budgeted.", against: "I have an emergency fund for exactly this, and I've paid off two cards this year.", balanced: "This is a setback I planned for. My overall direction is still good.", distortions: [ "Catastrophizing", "Overgeneralization" ] },
    { title: "Compliment on my work", location: "Office", who: "My manager", thought: "They're just being nice. It wasn't that good.", for: "I found a typo after I sent it.", against: "They shared it with the leadership team.", balanced: "I can accept the compliment. A small typo doesn't cancel good work.", distortions: [ "Disqualifying the positive" ] },
    { title: "Kid's school meeting", location: "School", who: "Teacher", thought: "I'm a bad parent.", for: "The teacher said homework has been missed.", against: "The teacher also said my kid is kind and engaged in class.", balanced: "We have something to work on together. That's normal parenting, not failure.", distortions: [ "Labeling", "Personalization" ] },
    { title: "Job application rejection", location: "Home", who: "Recruiter", thought: "Nobody will ever hire me.", for: "This is the third rejection this month.", against: "I made it to the final round twice. The market is competitive right now.", balanced: "Getting to the final rounds shows I'm close. Each one is practice.", distortions: [ "Overgeneralization", "Fortune telling" ] },
    { title: "Forgot a friend's birthday", location: "Home", who: "Riley", thought: "I should have remembered. I'm a terrible friend.", for: "I missed the date completely.", against: "I've shown up for Riley many times, and they've forgotten mine before too.", balanced: "I made a mistake and I can make it right. One missed date doesn't define the friendship.", distortions: [ "Should statements", "Labeling" ] },
    { title: "Traffic made me late", location: "Highway", who: "Just me", thought: "Today is ruined.", for: "I missed the first ten minutes of the meeting.", against: "Nobody seemed bothered, and the rest of the meeting went fine.", balanced: "A late start is frustrating, but the rest of the day is still open.", distortions: [ "All-or-nothing thinking", "Catastrophizing" ] },
    { title: "Doctor ordered more tests", location: "Clinic", who: "My doctor", thought: "It must be something serious.", for: "They want bloodwork and a scan.", against: "The doctor said it's routine to rule things out.", balanced: "More tests mean being thorough. I don't have results yet, so I'll wait for facts.", distortions: [ "Catastrophizing", "Fortune telling", "Emotional reasoning" ] },
    { title: "Felt anxious before a call", location: "Home office", who: "A client", thought: "I feel anxious, so it's going to go badly.", for: "My heart was racing beforehand.", against: "The last five calls with this client went well.", balanced: "Anxiety is a feeling, not a forecast. I'm prepared for this call.", distortions: [ "Emotional reasoning", "Fortune telling" ] }
  ]
  locations_extra = [ "Coffee shop", "Car", "Park", "Grocery store", "Train" ]

  sample_titles = scenarios.map { |scenario| scenario[:title] }
  rng = Random.new(42)
  distortions = Distortion.all.index_by(&:title)

  unless user.situations.exists?(title: sample_titles)
    50.times do |i|
      scenario = scenarios[i % scenarios.size]

      user.situations.create!(
        title: scenario[:title],
        date: Time.use_zone(user.time_zone) { rng.rand(1..180).days.ago.change(hour: rng.rand(7..21), min: [ 0, 15, 30, 45 ].sample(random: rng)) },
        location: rng.rand < 0.8 ? scenario[:location] : locations_extra.sample(random: rng),
        who_was_involved: scenario[:who],
        thought_imagery: scenario[:thought],
        emotion_level: rng.rand < 0.9 ? rng.rand(3..10) : nil,
        evidence_for: scenario[:for],
        evidence_against: scenario[:against],
        balanced_thought: rng.rand < 0.85 ? scenario[:balanced] : nil,
        distortions: distortions.values_at(*scenario[:distortions]).compact
      )
    end
  end
end
