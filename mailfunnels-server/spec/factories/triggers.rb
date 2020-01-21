FactoryGirl.define do
  factory :trigger do
    name "MyString"
    description "MyString"
    emailSubject "MyString"
    emailContent "MyString"
    num_times_triggered 1
    num_emails_sent 1
    delayTime 1
  end
end
