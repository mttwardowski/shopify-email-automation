class LinkSerializer < ActiveModel::Serializer
  attributes :id, :start_link, :funnel_id, :from_node_id, :to_node_id
end
