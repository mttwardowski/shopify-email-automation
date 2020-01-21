FactoryGirl.define do
  factory :email_template do
    name "MyString"
    description "MyText"
    email_subject "MyString"
    email_content "MyText"
    app nil
  end
end
