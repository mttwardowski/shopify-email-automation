class JobLocal
	include ActiveModel::Serializers::JSON

	@@array = Array.new
	attr_accessor :id, :job_id, :local_identifier,
	              :name, :hook_identifier,
	              :email_list_id, :subject,
	              :content, :execute_frequency,
	              :executed, :execute_time,
	              :app_id, :client_campaign,
	              :campaign_id, :hook_id,
	              :another_one, :created_at,
	              :updated_at, :execute_set_time,
	              :total_revenue


	def attributes
		{
			 'job_id' => job_id,
			 'local_identifier' => local_identifier,
			 'name' => name,
			 'hook_identifier' => hook_identifier,
			 'hook_id' => hook_id,
			 'email_list_id' => email_list_id,
			 'subject' => subject,
		   'content' => content,
		   'execute_frequency' => execute_frequency,
		   'executed' => executed,
		   'execute_set_time' => execute_set_time,
		   'executed_at'  => executed_at,
		   'app_id' => app_id,
		   'client_campaign' => client_campaign,
			 'campaign_id' => campaign_id,
		   'created_at' => created_at,
		   'updated_at' => updated_at,
		   'total_revenue' => total_revenue
		}
	end


	def self.all_instances
		@@array
	end

	def all
		ObjectSpace.each_object(self).entries
	end

	# def initialize
	# 	@id = id,
	# 	@name = name
	# end

end