class AdminController < ShopifyApp::AuthenticatedController





  # Page Render Function
  # --------------------
  # Renders the Admin Panel for MailFunnels App
  # If user is an Admin, they can disable users from
  # using the app on this page
  #
  def admin_dashboard

    # Get the Current App
    @app = MailfunnelsUtil.get_app

    # If the User is not an admin redirect to error page
    if !@app.is_admin or @app.is_admin === 0
      redirect_to '/error_page'
    end

    # Get Number of Users
    @num_users = 0

    # Get App Statistics
    @num_apps = 0
    @num_disabled_apps =0
    @num_active_apps = 0


    # Get Subscriber Statistics
    @num_subs = 0
    @num_unsubs = 0

    # Get Number of Captured Hooks
    @num_captured_hooks = 0

    # Get Number of Funnels
    @num_funnels = 0


    @subs_left = 0

    @num_email_sent = 0

    @num_email_opened = 0

    @num_email_clicked = 0


    # Calculate the the total revenue for the user
    @total_revenue = 0.0

    # Loop through all funnels and sum up the total revenue
    funnels = Funnel.where(app_id: @app.id)
    funnels.each do |funnel|
      @total_revenue += funnel.num_revenue.to_f
    end

  end

  # PAGE RENDER FUNCTION
  # --------------------
  # Renders the admin all users panel
  # which displays all the users
  #
  #
  def admin_all_users

    # Get the Current App
    @app = MailfunnelsUtil.get_app

    # If the User is not an admin redirect to error page
    if !@app.is_admin or @app.is_admin === 0
      redirect_to '/error_page'
    end


    # Otherwise get list of all Users
    @users = User.all

  end


  # PAGE RENDER FUNCTION
  # --------------------
  # Renders the admin user profile page
  # This allows an admin to view and edit a user
  #
  #
  def admin_user_profile

    # Get the Current App
    @app = MailfunnelsUtil.get_app

    # If the User is not an admin redirect to error page
    if !@app.is_admin or @app.is_admin === 0
      redirect_to '/error_page'
    end

    # Get User from DB
    @user = User.find(params[:user_id])

    # Get Apps for that user
    @user_apps = App.where(user_id: @user.id)

    # Get Subs Remaining
    @subs_left = MailFunnelsUser.get_remaining_subs(@user.clientid)

  end


  # USED WITH AJAX
  # --------------
  # Deletes an App
  #
  def admin_delete_app

    # Get Current App
    app = MailfunnelsUtil.get_app

    # If the User is not an admin redirect to error page
    if !app.is_admin or app.is_admin === 0
      response = {
          success: false
      }

      render json: response and return
    end

    # Get App to be deleted
    del_app = App.find(params[:app_id])

    unless del_app
      response = {
          success: false
      }

      render json: response and return
    end


    # Delete App
    del_app.destroy


    response = {
        success: true
    }

    render json: response and return


  end

end
