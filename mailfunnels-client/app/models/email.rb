class Email  < RestModel
	belongs_to :emails_list

	# parse_root_in_json true, format: :active_model_serializers
	# include_root_in_json true # Remove if anything
	# include_root_in_json :email

	# collection_path "/email_lists/:email_list_id/emails"

	has_many :campaign_product_leads
end
