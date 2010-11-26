class TwilioController < ApplicationController
  # This breaks Twilio applications.
  before_filter :verify_authenticity_token, :only => []

  helper_method :give_user_choices
  include ActionView::Helpers::DateHelper

  def index
    say_message_and_redirect(
      "Welcome to Teletimer.",
      url_for(:action => "wait_for_contraction_to_start"))
  end

  def wait_for_contraction_to_start
    if request.get?
      @message = "Press any key when the contraction starts."
      render_xml :action => :pause
    else
      # Have we already had any contractions?
      old_start = session[:start]
      session[:start] = Time.now
      if old_start

        # The wait_seconds is measured since the last contraction started, not
        # since the last contraction stopped.
        if params[:wait_seconds]
          new_start = old_start + params[:wait_seconds].to_i
        else
          new_start = session[:start]
        end

        distance = distance_of_time_in_words(old_start, new_start, true)
        say_message_and_redirect(
          "#{distance} have passed since the last contraction.",
          url_for(:action => :wait_for_contraction_to_stop))
      else
        redirect_to :action => :wait_for_contraction_to_stop
      end
    end
  end

  def wait_for_contraction_to_stop
    if request.get?
      @message = "Press any key when the contraction stops."
      render_xml :action => :pause
    else
      if params[:wait_seconds]
        stop = session[:start] + params[:wait_seconds].to_i
      else
        stop = Time.now
      end
      distance = distance_of_time_in_words(session[:start], stop, true)
      say_message_and_redirect(
        "The contraction lasted #{distance}.",
        url_for(:action => :wait_for_contraction_to_start)
      )
    end
  end

  private

  # This is a little DSL for choices:
  #
  #   Choice.new(label(:action_name),
  #              digits("*2"),
  #              view_block { @xml... },
  #              controller_block { redirect_to... })
  Choice = Struct.new(:label, :digits, :view_block, :controller_block)

  def label(value)
    value.to_s
  end

  def digits(value)
    value.to_s
  end

  def view_block(&block)
    block
  end

  alias :controller_block :view_block

  # Tell the user his choices.
  def give_user_choices
    @choices.each do |choice|
      @xml.Say("Press #{choice.digits} if you would like to ")
      choice.view_block.call
    end
  end

  # If we received params[:Digits], return true.
  #
  # Otherwise, render a response (redirecting to the current URL) and return false.
  def received_digits?
    if params[:Digits]
      true
    else
      say_message_and_redirect("I'm sorry.  I didn't get a response.  Let's try again.", url_for)
      false
    end
  end

  # If this is a GET, call render_xml.  Otherwise, call handle_choice.
  #
  # options are passed to render_xml so that you can override the action.
  def get_and_handle_choice(options = {})
    if request.post?
      handle_choice
    else
      render_xml(options)
    end
  end

  # Respond to the user's choice.
  def handle_choice
    return unless received_digits?

    digits = params[:Digits]
    choice = @choices.find { |c| [c.label, c.digits].include?(digits) }
    unless choice
      return say_message_and_redirect("#{digits} is not a valid entry.  Let's try again.", url_for)
    end

    choice.controller_block.call
  end

  # Render a TwiML response to the user.
  def say_message_and_redirect(message, url)
    @message = message
    @redirect = url
    render_xml(:action => :say_message_and_redirect)
  end

  # Render an XML response to the user.  Pass options to render.
  def render_xml(options = {})
    options[:layout] ||= false
    respond_to do |format|
      format.xml { render options }
    end
  end

  # This is an "action macro" to confirm something.
  #
  # Pass two options, :correct and :incorrect.  These are the actions to go to if
  # the user says the value is correct or incorrect.
  #
  # The method that calls this method shouldn't do anything else.  You must
  # take care of saying or playing the thing the user is confirming before the
  # user gets to the action that invokes this method.
  def confirm(options)
    raise ArgumentError unless options[:correct]
    raise ArgumentError unless options[:incorrect]

    @choices = [
      Choice.new(
        label(:continue),
        digits(1),
        view_block { @xml.Say("continue.") },
        controller_block { redirect_to :action => options[:correct] }
      ),

      Choice.new(
        label(:try_again),
        digits(3),
        view_block { @xml.Say("try again.") },
        controller_block { redirect_to :action => options[:incorrect] }
      )
    ]
    get_and_handle_choice :action => :gather_one_digit_choice
  end

  # Add spaces between all the letters in a string.
  #
  # This makes the text-to-speech engine speak phone numbers one digit at a time.
  def space_out(s)
    s.split(//).join(' ')
  end
end