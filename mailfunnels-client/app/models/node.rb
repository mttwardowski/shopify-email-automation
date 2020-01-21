class Node < RestModel

  belongs_to :app, :class_name => 'App', :foreign_key => 'app_id'
  belongs_to :funnel, :class_name => 'Funnel', :foreign_key => 'funnel_id'
  belongs_to :email_template, :class_name => 'EmailTemplate', :foreign_key => 'email_template_id'

  has_many :links
  has_many :email_jobs

end
