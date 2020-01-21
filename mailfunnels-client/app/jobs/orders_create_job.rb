require "erb"

class OrdersCreateJob < ApplicationJob
  queue_as :default

  def perform(shop_domain:, webhook:)
    logger.info("Starting Order Created Job")

    shop = Shop.find_by(shopify_domain: shop_domain)

    shop.with_shopify_session do



      app = MailfunnelsUtil.get_app

      subs_remaining = MailFunnelsUser.get_remaining_subs(app.user.clientid)

      # If no more subscribers left in plan, return error response
      if subs_remaining < 1
        return
      end

      if app.is_disabled === 1
        logger.info("App Disabled!")
        return
      end

      logger.info("Looking for subscriber...")
      subscriber = EmailUtil.get_subscriber(webhook[:email], app.id)

      if subscriber
        logger.info("Subscriber found!")
        logger.info("Incrementing Subscriber revenue...")
        subscriber = EmailUtil.increase_subscriber_revenue(subscriber, webhook[:subtotal_price].to_f)
        if subscriber
          logger.info("Subscriber updated!")
        else
          logger.debug("Error updating subsriber revenue!")
          return
        end
      else
        logger.info("Subscriber does not exist, creating now")
        subscriber = EmailUtil.add_new_subscriber(webhook[:email],
                                                  app.id,
                                                  webhook[:billing_address]['first_name'],
                                                  webhook[:billing_address]['last_name'],
                                                    1
        )
        if subscriber
          logger.info("Subscriber added")
          logger.info("Incrementing Subscriber revenue...")

          if EmailUtil.should_capture_hook(subscriber.id, app.id)
            # for calculating revenue
            subscriber = EmailUtil.increase_subscriber_revenue(subscriber, webhook[:subtotal_price].to_f)
          end

          if subscriber
            logger.info("Subscriber updated!")
          else
            logger.debug("Error updating subsriber revenue!")
            return
          end
        else
          logger.debug("Error adding new subscriber!")
          return
        end
      end

      logger.info("Looking for corresponding hook...")
      hook = EmailUtil.get_hook('order_create')

      if hook
        logger.info("Hook found!")
      else
        logger.debug("Hook not found!")
        return
      end

      logger.info("Looking for trigger with product first")
      trigger = nil
      price = 0.0
      webhook[:line_items].each do |product|
        price = price + product['price'].to_f
        trigger = EmailUtil.get_trigger_product(app.id, hook.id, product[:product_id])
        if trigger
          break
        end
      end

      if EmailUtil.should_capture_hook(subscriber.id, app.id)
        # for calculating daily revenue
        CapturedHook.create(hook_id:hook.id, subscriber_id: subscriber.id, app_id:app.id, revenue: price)
      end


      if trigger
        logger.info("Trigger found!")
        trigger = EmailUtil.increment_trigger_hit_count(trigger)
        if trigger
          logger.info("Trigger updated!")
        else
          logger.debug("Error incrementing trigger hit count")
        end

      else
        logger.debug("Trigger not found - Looking for trigger without product")
        trigger = EmailUtil.get_trigger(app.id, hook.id)
        if trigger
          logger.info("Trigger found!")
          trigger_test = EmailUtil.increment_trigger_hit_count(trigger)
          if trigger_test
            logger.info("Trigger updated!")
          else
            logger.debug("Error updating trigger!")
          end
        else
          logger.info("Trigger not found")
          return
        end
      end

      logger.info("Looking for funnel")
      funnel = EmailUtil.get_funnel(app.id, trigger.id)
      if funnel
        logger.info("Funnel found!")
        logger.info("Incrementing Funnel revenue...")

        if EmailUtil.should_capture_hook(subscriber.id, app.id)
          # for calculating Revenue
          funnel = EmailUtil.increase_funnel_revenue(funnel, webhook[:subtotal_price].to_f)
        end

        if funnel
          logger.info("Funnel updated!")
        else
          logger.debug("Error increasing funnel revenue")
        end

      else
        logger.debug("Funnel not found!")
        return
      end


      emailsub = EmailUtil.get_email_list_subscription(app.id,
                                                       funnel.email_list_id,
                                                       subscriber.id)
      if emailsub
        logger.info("Email list subscription found!")
      else
        logger.info("No Email list subscription found!")
        emailsub = EmailUtil.add_subscriber_to_list(app.id,
                                                    funnel.email_list_id,
                                                    subscriber.id)
        if emailsub
          logger.info("Subscriber added to list")
        else
          logger.debug("Error adding subscriber to list!")
          return
        end
      end

      logger.info("Looking for start link")
      link = EmailUtil.get_start_link(funnel.id)

      if link
        logger.info("Start link found!")
      else
        logger.debug("Start link not found!")
        return
      end

      logger.info("looking for Node")
      node = EmailUtil.get_node(link.to_node_id)

      if node
        logger.info("Node found!")
      else
        logger.debug("Node not found!")
        return
      end

      logger.info ("Checking if job already exists")
      if EmailUtil.does_job_exist(app.id,
                                  funnel.id,
                                  node.id,
                                  subscriber.id)
        logger.info("Jobs Already Exists")
      else
        job = EmailUtil.create_new_email_job(app.id,
                                             funnel.id,
                                             subscriber.id,
                                             node.id,
                                             node.email_template_id,
                                             funnel.email_list_id
        )
        if job
          logger.info("New Email Job Created!")
        else
          logger.debug("Error creating email job")
          return
        end
      end
    end
    logger.info("---JOB EXECUTED PROPERLY---")
  end
end

