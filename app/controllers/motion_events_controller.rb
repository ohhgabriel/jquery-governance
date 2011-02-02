class MotionEventsController < ApplicationController

  before_filter :authenticate_member!, :except => [:show]

  # Show an Event for a given Motion
  # @option params [Fixnum] :motion_id The id of the motion in question
  # @option params [String] :event_id The id of the event to be viewed
  def show
    @motion = Motion.find(params[:motion_id])
    @event  = @motion.events.where :event_id => params[:event_id]
  end

  def create
    @motion = Motion.find(params[:motion_id])
    @event  = current_member.events.new(params[:event].merge(:motion => @motion))

    if @event.save
      flash[:notice] = "You have successfully objected the motion."
      redirect_to motion_url(@motion)
    else
      # TODO
    end
  end

  # Create a Seconding Event for a Motion
  # @option params [Fixnum] :motion_id The id of the motion in question
  def second
    @motion = Motion.find(params[:motion_id])
    if MotionSeconding.do(current_member, @motion)
      flash[:notice] = "You have successfully seconded the motion."
    else
      flash[:alert] =  "Something went wrong when seconding the motion"
    end

    redirect_to motion_url(@motion)
  end

  # Create an Objection Event for a Motion
  # @option params [Fixnum] :motion_id The id of the motion in question
  def object
    @motion = Motion.find(params[:motion_id])

    if current_member.object(@motion)
      flash[:notice] = "You have successfully objected the motion."
    else
      flash[:alert] =  "Something went wrong when objecting the motion"
    end

    redirect_to motion_url(@motion)
  end

  # Create a Voting Event for a Motion
  # @option params [Fixnum] :motion_id The id of the motion in question
  # @option params [Fixnum] :vote The vote cast by the member, can be "aye" or "nay"
  def vote
    @motion = Motion.find(params[:motion_id])

    if current_member.vote(@motion, params[:vote] == "aye")
      flash[:notice] = "You have successfully voted the motion."
    else
      flash[:alert] =  "Something went wrong when voting the motion"
    end

    redirect_to motion_url(@motion)
  end
end
