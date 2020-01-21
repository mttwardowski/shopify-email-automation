class FunnelsController < ShopifyApp::AuthenticatedController
  before_action :set_funnel, only: [:show, :edit, :update, :destroy]


  # Page Render Function
  # --------------------
  # Renders the "Funnels" Page which lists out all
  # the funnels for the current app instance
  #
  def index

    # Get the current app loaded
    @app = MailfunnelsUtil.get_app

    # Get all Funnel models
    @funnels = Funnel.where(app_id: @app.id)

  end


  # Page Render Function
  # --------------------
  # Renders the "Edit Funnel" Page which allows user
  # to edit the funnel using drag and drop funnel builder
  #
  # PARAMETERS
  # ----------
  # funnel_id: ID of the funnel we are editing
  #
  def edit_funnel

    # Get the Current App ID
    @app = MailfunnelsUtil.get_app

    # Find the funnel from the DB
    @funnel = Funnel.find(params[:funnel_id])

    # Get the Trigger from the Funnel
    @trigger = Trigger.find(@funnel.trigger_id)

    # Get Email Templates For User
    @templates = EmailTemplate.where(app_id: @app.id, is_archived: 0)

  end

  # USED WITH AJAX
  # Creates a new Funnel Model
  #
  # PARAMETERS
  # ----------
  # app_id: ID of the current app being used
  # name: Name of the Funnel
  # description: description of the funnel
  # trigger_id: ID of the Trigger for Funnel
  # email_list_id: ID of the EmailList for Funnel
  #
  def ajax_create_funnel

    # Create new Funnel Model
    funnel = Funnel.new

    if params[:email_list_id] == '0'
      email_list = EmailList.new
      email_list.name = params[:name]
      email_list.description = params[:name]+ " Email List"
      email_list.app_id = params[:app_id]
      email_list.active = 0
      email_list.save!

      email_list_id = email_list.id
    else
      email_list_id = params[:email_list_id]
    end

    # Update the Fields of Funnel Model
    funnel.app_id = params[:app_id]
    funnel.trigger_id = params[:trigger_id]
    funnel.name = params[:name]
    funnel.email_list_id = email_list_id
    funnel.description = params[:description]
    funnel.num_emails_sent = 0
    funnel.num_revenue = 0.0
    funnel.active = 0

    # Save and verify Funnel and return correct JSON response
    if funnel.save!
      final_json = JSON.pretty_generate(result = {
          :success => true
      })
    else
      final_json = JSON.pretty_generate(result = {
          :success => false
      })
    end

    # Return JSON response
    render json: final_json
  end

  # USED WITH AJAX
  # --------------
  # Adds a new node to the funnel being edited
  #
  # PARAMETERS
  # ----------
  # app_id: ID of the current App
  # funnel_id: ID of the funnel the node is being added on
  # name: Name of the Node
  # email_template_id: ID of the trigger the node is related to
  # delay_time: The delay time for sending the email
  # delay_unit: The delay unit for sending the email
  #
  def ajax_add_node

    # Create a new Node Instance
    node = Node.new

    # Update the fields of Node Instance
    node.app_id = params[:app_id]
    node.funnel_id = params[:funnel_id]

    if params[:email_template_id] == '0'
      # Create a new Email Template
      template = EmailTemplate.new
      template.app_id = params[:app_id]
      template.name = params[:name] + ' Email Template'
      template.description = ''
      template.email_subject = ''
      template.color = '#3498db'

      # Save blank Email Template
      template.save

      node.email_template_id = template.id

    else
      node.email_template_id = params[:email_template_id]

    end

    node.name = params[:name]
    node.delay_time = params[:delay_time]
    node.delay_unit = params[:delay_unit]
    node.top = 60
    node.left = 500
    node.num_emails = 0
    node.num_emails_sent = 0
    node.num_revenue = 0.0
    node.num_emails_opened = 0
    node.num_emails_clicked = 0



    node.save

    response = {
        success: true,
        message: 'Node Saved',
        id: node.id,
        email_template_id: node.email_template_id

    }

    render json: response



  end

  # USED WITH AJAX
  # --------------
  # Adds a new link to the funnel being edited
  #
  # PARAMETERS
  # ----------
  # funnel_id: ID of the funnel the link is being added on
  # from_operator_id: Operator we are starting link from
  # to_operator_id: Operator we are ending the link on
  #
  def ajax_add_link

    # Create a new Link Instance
    link = Link.new

    # Update the fields of Link Instance
    link.funnel_id = params[:funnel_id]
    link.to_node_id = params[:to_operator_id].to_i

    if params[:from_operator_id].to_i === 0
      # If the link starts at the start node, set slink to 1
      link.start_link = 1
    else
      # Otherwise, set slink to 0 (false) and set from_operator_id
      link.start_link = 0
      link.from_node_id = params[:from_operator_id].to_i
    end

    # Save and verify Link and return correct JSON response
    if link.save!
      final_json = JSON.pretty_generate(result = {
          :success => true
      })
    else
      final_json = JSON.pretty_generate(result = {
          :success => false
      })
    end

    # Return JSON response
    render json: final_json

  end


  # USED WITH AJAX
  # --------------
  # Loads a JSON representation of nodes on funnel builder
  # to be loaded ino flowchart plugin
  #
  # PARAMETERS
  # ----------
  # funnel_id: ID of the Funnel to get nodes for
  #
  def ajax_load_funnel_json

    # Load all the Nodes and Links for the current Funnel
    @nodes = Node.where(funnel_id: params[:funnel_id])
    @links = Link.where(funnel_id: params[:funnel_id])

    # Create a new array to hold the operators
    operators = Hash.new

    # Create start operator
    operators[0] =
        {
            :top => 20,
            :left => 20,
            :properties => {
                :title => 'Start',
                class: 'flowchart-operator-start-node',
                inputs: {},
                outputs: {
                    output_1: {
                        label: ' ',
                    }
                }
            }
        }

    # For every Node we have in the DB, create an operator with its fields
    @nodes.each do |node|

      operators[node.id] =
          {
              :top => node.top,
              :left => node.left,
              :properties => {
                  :title => node.name,
                  class:'flowchart-operator-email-node',
                  :inputs => {
                      :input_1 => {
                          :label => ' '
                      }
                  },
                  :outputs => {
                      :output_1 => {
                          :label => ' '
                      }
                  }
              }
          }


    end

    # Create a new links array
    links = Hash.new

    # For every Link for the funnel, create a flowchart link with its fields
    @links.each do |link|

      if link.start_link === 1
        fromNode = 0
      else
        fromNode = link.from_node_id
      end

      links[link.id] =
          {
              :fromConnector => 'output_1',
              :toConnector => 'input_1',
              :fromOperator => fromNode,
              :toOperator => link.to_node_id,
          }
    end



    # Create data JSON with operators and links
    data = JSON.pretty_generate({
                                    'operators' => operators,
                                    'links' => links
                                })


    # Return JSON array with flowchart data
    render json: data

  end

  def view_template
    # Get the current app loaded
    @app = MailfunnelsUtil.get_app

    # Get all Funnel models
    @template = EmailTemplate.find(params[:template_id])

  end


  # USED WITH AJAX
  # --------------
  # Updates the node on the funnel when moved
  #
  # PARAMETERS
  # ----------
  # node_id: ID of the node that was updated
  # top: Distance from top in pixels
  # left: Distance from left in pixels
  #
  def ajax_save_node

    # Get the Node from the DB
    node = Node.find(params[:node_id])

    # Update the Node
    node.top = params[:top]
    node.left = params[:left]

    # Save and verify Node and return correct JSON response
    if node.save!
      final_json = JSON.pretty_generate(result = {
          :success => true,
          :id => node.id
      })
    else
      final_json = JSON.pretty_generate(result = {
          :success => false
      })
    end

    # Return JSON response
    render json: final_json

  end


  # USED WITH AJAX
  # --------------
  # Returns a JSON array of all info for the node
  # used for the view node info modal
  #
  # PARAMETERS
  # ----------
  # node_id: ID of the node we are getting info for
  #
  #
  def ajax_load_node_info

    # Get the Node from the DB
    node = Node.find(params[:node_id])

    # Get statistics for node
    total_emails_sent = EmailJob.where(node_id: params[:node_id], sent: 1).size
    total_emails_opened = EmailJob.where(node_id: params[:node_id], opened: 1).size
    total_emails_clicked = EmailJob.where(node_id: params[:node_id], clicked: 1).size

    # Populate data Hash with node info
    data = {
        :node_id => node.id,
        :node_name => node.name,
        :node_delay_time => node.delay_time,
        :node_delay_unit => node.delay_unit,
        :node_total_emails => node.email_jobs.size,
        :node_emails_sent => total_emails_sent,
        :node_emails_opened => total_emails_opened,
        :node_emails_clicked => total_emails_clicked,
        :email_template_id => node.email_template_id,
        :email_template_name => node.email_template.name,
        :email_template_description => node.email_template.description,
    }


    # Return data as JSON
    render json: data

  end

  # USED WITH AJAX
  # ---------------
  # Returns a JSON array of node configuration info
  # used for the edit node modal
  #
  # PARAMETERS
  # ---------
  # node_id: ID of the node we are getting info for
  #
  def ajax_load_node_edit_info

    # Get the Node from the DB
    node = Node.find(params[:node_id])

    data = {
        :node_id => node.id,
        :node_name => node.name,
        :node_email_template_name => node.email_template_id,
        :node_delay_time => node.delay_time,
        :node_delay_unit => node.delay_unit,
    }

    # Return data as JSON
    render json: data

  end



  # USED WITH AJAX
  # ---------------
  # Saves edited node info
  #
  # PARAMETERS
  # ---------
  # node_id: ID of the node we are getting info for
  #
  def ajax_save_edit_node

    # Get the Node from the DB
    node = Node.find(params[:id])

    node.name = params[:name]
    node.email_template_id = params[:email_template_id]
    node.delay_unit = params[:delay_unit]
    node.delay_time = params[:delay_time]

    # Save and verify Node and return correct JSON response
    node.put('', {
        :name => node.name,
        :email_template_id => node.email_template_id,
        :delay_unit => node.delay_unit,
        :delay_time => node.delay_time,
    })

    # Return Success Response
    response = {
        success: true,
        message: 'Node Updated!'
    }
    render json: response



  end





  # USED WITH AJAX
  # --------------
  # Returns a JSON array of template info
  # for specific node
  #
  # PARAMETERS
  # ----------
  # node_id: ID of the node we are getting info for
  #


  def ajax_load_email_template_info

    # Get the Current App
    @app = MailfunnelsUtil.get_app

    # Get the Node from the DB
    node = Node.find(params[:node_id])

    # Get the Template related to node
    @template = EmailTemplate.find(node.email_template_id)


    if @template.style_type === 1
      html = File.open("app/views/template/styles/mf-minimal_1.html.erb").read
    else
      html = File.open("app/views/email/template.html.erb").read
    end

    @renderedhtml = "1"
    ERB.new(html, 0, "", "@renderedhtml").result(binding)


    data = {
        :html => @renderedhtml
    }

    # Return data as JSON
    render json: data


  end


  # USED WITH AJAX
  # --------------
  # Removes a Funnel from the DB
  #
  # PARAMETERS
  # ----------
  # funnel_id: ID of the funnel we are removing
  #
  #
  def ajax_delete_funnel

    # Get the funnel from the DB
    funnel = Funnel.find(params[:funnel_id])

    # If funnel exists, then remove the funnel
    if !funnel.nil?
      funnel.destroy
    end

  end


  # USED WITH AJAX
  # --------------
  # Removes a node from the DB
  #
  # PARAMETERS
  # ----------
  # node_id: ID of the node we are removing
  #
  def ajax_delete_node

    # Get the Node from the DB
    node = Node.find(params[:node_id])

    # If node exits, then remove the node
    if !node.nil?
      node.destroy
    end

  end


  # USED WITH AJAX
  # --------------
  # Sets Funnel To Active
  #
  # PARAMETERS
  # ----------
  # funnel_id: ID of the Funnel to set to Active
  #
  #
  def ajax_activate_funnel

    # Get the current funnel
    funnel = Funnel.find(params[:funnel_id])

    # Set Funnel Status To Active
    funnel.active = 1

    funnel.put('', {
        :active => funnel.active,
    })

    # Return Success Response
    response = {
        success: true,
        message: 'Funnel Updated!'
    }
    render json: response

  end

  # USED WITH AJAX
  # --------------
  # Sets Funnel To Not Active
  #
  # PARAMETERS
  # ----------
  # funnel_id: ID of the Funnel to set to Not Active
  #
  #
  def ajax_deactivate_funnel

    # Get the current funnel
    funnel = Funnel.find(params[:funnel_id])

    # Set Funnel Status To Active
    funnel.active = 0

    funnel.put('', {
        :active => funnel.active,
    })

    # Return Success Response
    response = {
        success: true,
        message: 'Funnel Updated!'
    }
    render json: response

  end


  # USED WITH AJAX
  # --------------
  # Updates the Funnel Info
  #
  # PARAMETERS
  # ----------
  # funnel_id: ID of the funnel being updated
  # funnel_name: name of the funnel
  # funnel_description: description of the funnel
  # funnel_trigger_id: ID of the trigger for the funnel
  # funnel_email_list_id: ID of the email list for the funnel
  #
  def ajax_update_funnel_info

    # Get the Funnel by ID
    funnel = Funnel.find(params[:funnel_id])

    # If no funnel found
    if !funnel
      # Return Error Response
      response = {
          success: false,
          message: 'Funnel Not Found!'
      }

      render json: response
    end

    # If Trigger ID is 0
    if params[:funnel_trigger_id] == '0'
      # Return Error Response
      response = {
          success: false,
          message: 'Funnel must have a trigger!'
      }

      render json: response
    end

    # If Email List ID is zero, create new email list
    if params[:funnel_email_list_id] == '0'
      email_list = EmailList.new
      email_list.name = params[:funnel_name] + "Email List"
      email_list.description = "Email list for " + params[:funnel_name]
      email_list.app_id = params[:app_id]
      email_list.save!

      email_list_id = email_list.id
    else
      email_list_id = params[:funnel_email_list_id]
    end

    # Update the Funnel Info
    funnel.put('', {
        name: params[:funnel_name],
        description: params[:funnel_description],
        email_list_id: email_list_id,
        trigger_id: params[:funnel_trigger_id]
    })


    # Return Success Response
    response = {
        success: true,
        message: 'Funnel Updated!'
    }
    render json: response


  end





  private
  # Use callbacks to share common setup or constraints between actions.
  def set_funnel
    @funnel = Funnel.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def funnel_params
    params.require(:funnel).permit(:name, :description, :num_emails_sent, :num_revenue, :app_id, :trigger_id, :email_list_id)
  end
end
