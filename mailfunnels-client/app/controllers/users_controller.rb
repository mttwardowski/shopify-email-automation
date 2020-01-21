require 'xmlrpc'

class UsersController < ActionController::Base

  # PAGE RENDER FUNCTION
  # --------------------
  # Renders the Login Page for MailFunnels
  #
  def login_page

  end


  # PAGE RENDER FUNCTION
  # --------------------
  # Renders the account disabled page
  #
  def access_denied

  end

  # PAGE RENDER FUNCTION
  # --------------------
  # Renders the server error page
  #
  def server_error

  end


  # POST ROUTE
  # ----------
  # Creates a new App Instance
  # Used with infusionsoft to create new account
  # upon app order form submit
  #
  # PARAMETERS
  # ----------
  # client_id: Infusionsoft Client ID
  # email: Email Address of the User
  # first_name: First Name of the User
  # last_name: Last Name of the User
  #
  def mf_api_user_create

    # Look for
    current_users = User.where(email: params[:email])

    unless current_users.empty?
      response = {
          success: false,
          message: 'User with email already exists'
      }

      render json: response and return
    end

    # Generate a password for user
    seed = "--#{rand(10000000)}--#{Time.now}--#{rand(10000000)}"
    secure_password = Digest::SHA1.hexdigest(seed)[0,8]

    user = User.new

    user.clientid = params[:client_id]
    user.email = params[:email]
    user.password = secure_password
    user.first_name = params[:first_name]
    user.last_name = params[:last_name]

    user.save

    # Update Infusionsoft Contact ------THIS LINE OF CODE IS WHERE IT FUCKS UP
    Infusionsoft.contact_update(params[:client_id], {:Password => secure_password})

    # Return Success Response
    response = {
        success: true,
        user_id: user.id,
        password: user.password,
        message: 'User Created'
    }

    render json: response


  end

  # POST ROUTE
  # ----------
  # Retrieves user's password and sends them an email
  # with their password
  #
  # PARAMETERS
  # ----------
  # email: Email Address of the User
  #
  def mf_user_reset_password

    # Look for
    contact = Infusionsoft.contact_find_by_email(params[:email], [:ID, :Password])

    if !contact.first['Password'].nil?

      user = User.where(clientid: contact.first['ID']).first

      unless user
        # Return Error Response
        response = {
            success: false,
            message: 'User Not Found'
        }

        render json: response
      end

      user.put('', {
          :password => contact.first['Password']
      })

      response = {
          success: true,
          message: 'Your password has been sent to your email..'
      }

      render json: response

    else
      puts "final else"
      # Return Error Response
      response = {
          success: false,
          message: 'Sorry, we could not find an account with this email.'
      }

      render json: response

    end


  end


  # USED WITH AJAX
  # --------------
  # Authenticates the user and redirects to shopify auth
  #
  # PARAMETERS
  # ----------
  # mf_auth_username: Username of the user
  # mf_auth_password: Password of the user
  #
  def ajax_mf_user_auth

    # Get User Information from Infusionsoft
    contact = Infusionsoft.contact_find_by_email(params[:mf_auth_username], [:ID, :Password])
    puts "found contact"
    puts "1"

    if contact.first['Password'] === params[:mf_auth_password]
      puts "----------1----------"

      user = User.where(clientid: contact.first['ID']).first
      puts "------------2------------"

      unless user
        # Return Error Response
        response = {
            success: false,
            message: 'Authentication Failed'
        }

        render json: response
        puts "-----------3-----------"
      end

      # Look for App for the User
      app = App.where(user_id: user.id).first
      puts "----------4------------"

      logger.info app
      puts "------------5------------"


      if app

        # Return Json Response with shopify domain
        response = {
            success: true,
            type: 2,
            url: app.name,
            message: 'Authentication Passed'
        }

        render json: response

      else

        response = {
            success: true,
            type: 1,
            user_id: user.id,
            url: 'none',
            message: 'User has not configured Shopify Domain yet.'
        }
        render json: response
      end



    else
      puts "final else"
      # Return Error Response
      response = {
          success: false,
          message: 'Authentication Failed'
      }

      render json: response

    end
  end


  # USED WITH AJAX
  # --------------
  # Creates a new App for the User
  #
  # PARAMETERS
  # ----------
  # user_id: ID of the User to create App For
  # domain: Shopify Domain to install the App with
  #
  def ajax_mf_app_create

    domain = params[:domain] + ".myshopify.com"
    from_email = params[:domain] + "@custprotection.com"

    digest = OpenSSL::Digest.new('sha256')
    token = Base64.encode64(OpenSSL::HMAC.digest(digest, ENV['SECRET_KEY_BASE'], params[:domain])).strip
    app = App.create(user_id: params[:user_id], name: domain, auth_token: token, from_email: from_email)

    response = {
        success: true,
        url: app.name,
        message: 'App Created!'
    }

    render json: response

  end


  # USED WITH AJAX
  # --------------
  # Updates the Users tags
  #
  # PARAMETERS
  # ----------
  # client_id: ID of the Infusionsoft contact
  #
  def mf_api_user_update_tags

    # Get User From DB with client_id
    user = User.where(clientid: params[:client_id]).first

    # If user not found, return error response
    if user.empty?
      response = {
          success: false,
          message: 'User with ClientID not found'
      }

      render json: response
    end

    # Get the Infusionsoft contact info
    contact = Infusionsoft.data_load('Contact', user.clientid, [:Groups])

    # Update User Tags
    user.put('', {
        :client_tags => contact['Groups']
    })


    response = {
        success: true,
        message: 'User Tags Updated'
    }

    render json: response

  end


  # USED WITH AJAX
  # --------------
  # Retrieves user info given a user id
  #
  # PARAMETERS
  # ----------
  # user_id: ID of the user
  #
  def mf_api_get_user_info

    # Get the user from the DB
    user = User.find(params[:user_id])

    # If no user, return error response
    unless user
      response = {
          success: false,
          message: 'User not found'
      }

      render json: response and return
    end

    # Create User Info Response
    response = {
        success: true,
        message: 'User Info successfully retrieved',
        user_id: user.id,
        user_infusionsoft_id: user.clientid,
        user_first_name: user.first_name,
        user_last_name: user.last_name,
        user_email: user.email,
    }

    # Return success response
    render json: response

  end


  # USED WITH AJAX
  # --------------
  # Manually Adds a new User
  #
  # PARAMETERS
  # ----------
  # client_id: Infusionsoft ID of the client
  # email: Email of the user
  #
  def mf_api_manually_add_user

    # Create new User
    user = User.new

    # Populate User
    user.clientid = params[:client_id]
    user.email = params[:email]

    user.save

    response = {
        success: true,
        message: 'New User Created!'
    }

    render json: response

  end


end
