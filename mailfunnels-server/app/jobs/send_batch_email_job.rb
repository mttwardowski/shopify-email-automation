require "erb"

class SendBatchEmailJob < ApplicationJob
  queue_as :default

  def perform(job)
    job = EmailJob.where(id: job.id).first
    template = EmailTemplate.find(job.email_template_id)
    subscriber = Subscriber.find(job.subscriber_id)
    app = App.find(job.app_id);
    if job.sent == 1
      puts"Email Already Sent to Subscriber"
    else
      @template = template
      @email_job = job
      @subscriber = subscriber
      html = File.open("app/views/email/template.html.erb").read
      @renderedhtml = "1"
      ERB.new(html, 0, "", "@renderedhtml").result(binding)
      puts "Template rendered!"
      puts"Creating Postmark Client"
      if app.from_name.nil?
        name = "Shop Admin"
      else
        name = app.from_name
      end

      if app.from_email.nil?
        email = "noreply@custprotection.com"
      else
        email = app.from_email
      end

      client = Postmark::ApiClient.new('b650bfe2-d2c6-4714-aa2d-e148e1313e37', http_open_timeout: 60)
      response = client.deliver(
          :subject     => template.email_subject,
          :to          => subscriber.email,
          :from        => name+' '+email,
          :html_body   => @renderedhtml,
          :track_opens => 'true')

      job.executed = true
      job.postmark_id = response[:message_id]
      job.sent = 1
      job.save!
    end
  end
end
