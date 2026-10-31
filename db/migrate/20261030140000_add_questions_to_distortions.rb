# Questions that help someone test a thought caught in this trap, one per line, offered on the Weigh it up step.
# Fills them in for the starter traps; ones added through the admin form start empty.
class AddQuestionsToDistortions < ActiveRecord::Migration[8.1]
  QUESTIONS = {
    "All-or-nothing thinking" => [ "Is there a middle ground between total success and total failure?", "What went partly right?" ],
    "Overgeneralization" => [ "Is it really always, or was it this time?", "Can you think of a time it went differently?" ],
    "Mental filter" => [ "What else happened that you might be leaving out?", "Zoom out on the whole day. What do you see?" ],
    "Disqualifying the positive" => [ "Would you dismiss this if it happened to a friend?", "What good thing aren't you counting?" ],
    "Mind reading" => [ "What do you actually know about what they were thinking?", "Is there another reason they might have acted that way?" ],
    "Fortune telling" => [ "Has a prediction like this come true before?", "What's another way this could turn out?" ],
    "Catastrophizing" => [ "What's the most likely outcome, not the worst one?", "If the worst did happen, how would you cope?", "Will this matter a year from now?" ],
    "Emotional reasoning" => [ "Is this a feeling or a fact?", "What would you think about it if you felt calm?" ],
    "Should statements" => [ "Whose rule is this, and is it a fair one?", "How would it sound as \"it would be nice if\"?" ],
    "Labeling" => [ "What did you actually do, rather than what you are?", "Would you call a friend that for the same thing?" ],
    "Personalization" => [ "What else played a part in this?", "How much of it was really in your control?" ]
  }.freeze

  def up
    add_column :distortions, :questions, :text
    QUESTIONS.each do |title, questions|
      execute "UPDATE distortions SET questions = #{connection.quote(questions.join("\n"))} WHERE title = #{connection.quote(title)}"
    end
  end

  def down
    remove_column :distortions, :questions
  end
end
