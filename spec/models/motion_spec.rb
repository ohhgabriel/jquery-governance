require 'spec_helper'

describe Motion do
  before do
    RSpec::Mocks::setup(self)

    @motion = Factory.create(:motion)
  end

  describe "vote counting", :database => true do
    it "knows how many yea votes have been cast for the motion" do
      2.times { Factory.create(:yes_vote, :motion => @motion) }
      @motion.yeas.should == 2
    end

    it "knows how many nea votes have been cast for the motion" do
      1.times { Factory.create(:no_vote, :motion => @motion) }
      @motion.nays.should == 1
    end
  end

  describe "state_name=" do
    it "updates the motion's state name" do
      @motion.state_name = 'waitingsecond'
      @motion.state_name.should == 'waitingsecond'
    end

    it "updates the motion's state" do
      # NOTE this isn't a good spec, but I don't expect it to live long
      @motion.state_name = 'voting'
      @motion.state.should be_instance_of MotionState::Voting
    end
  end

  describe 'voting requirements' do
    before do
      # This represents all of the members who currently have the right to vote
      membership_scope = double('active membership scope', :count => 4)
      Membership.stub!(:active_at).and_return( membership_scope )
    end

    describe 'required_votes' do
      it "knows how many votes are required to pass the motion" do
        @motion.required_votes.should == 3
      end
    end

    describe 'has_met_requirement?' do

      describe "when there more than half of the possible votes are yeas" do
        before do
          @motion.stub(:yeas => 3)
        end

        it "knows the requirment for passage has been met" do
          @motion.should be_has_met_requirement
        end
      end

      describe "when exactly half of the possible votes are yeas" do
        before do
          @motion.stub(:yeas => 2)
        end

        it "knows that the requirement for passage hasn't been met" do
          @motion.should_not be_has_met_requirement
        end
      end

      describe "when less than half the possible votes are yeas" do
        before do
          @motion.stub(:yeas => 1)
        end

        it "knows that the requirement for passage hasn't been met" do
          @motion.should_not be_has_met_requirement
        end
      end
    end

    describe 'seconds_for_expedition' do
      it "knows how many seconds are needed to expedite the measure" do
        @motion.seconds_for_expedition.should == 2
      end
    end
  end

  describe "voting actions", :database => true do
    describe "vote" do
      it "creates a new vote with the given member and value" do
        current_motion = Factory.create(:motion)
        voting_member  = Factory.create(:membership).member

        current_motion.vote(voting_member, true)
        Event.votes.last.member.should eql voting_member
        Event.votes.last.value.should be_true
      end
    end

    describe 'second(member)' do
      it "creates a new second for the member" do
        current_motion   = Factory.create(:motion)
        seconding_member = Factory.create(:membership).member

        lambda do
          current_motion.second(seconding_member)
        end.should change { current_motion.seconds.count }
      end
    end

  end

  describe 'conflicts_with_member?', :database => true do
    before :each do
      @member   = Factory.build(:membership).member
      @conflict = Factory.build(:conflict)
    end

    describe "when a member has a conflict unrelated to this motion" do
      it "knows that it doesn't conflict with the member" do
        @member.conflicts << @conflict
        @motion.should_not be_conflicts_with_member(@member)
      end
    end

    describe "when a motion has conflict unrelated to this member" do
      it "knows that it doesn't conflict with the member" do
        @motion.conflicts << @conflict
        @member.conflicts.clear
        @motion.should_not be_conflicts_with_member(@member)
      end
    end

    describe "when a motion and a member share the same conflict" do
      it "knows that it conflicts with the member" do
        @motion.conflicts << @conflict
        @member.conflicts << @conflict
        @motion.should be_conflicts_with_member(@member)
      end
    end
  end

  describe 'schedule_updates' do
    describe "when a motion is created" do
      it "should ask the MotionState to schedule updates" do
        @motion = Factory.build(:motion)
        @motion.state.should_receive(:schedule_updates)
        @motion.save
      end
    end

    describe "when a motion is saved with a state change" do
      it "should ask the MotionState to schedule updates" do
        @motion = Factory.create(:motion)
        @motion.state_name = "discussing"
        @motion.state.should_receive(:schedule_updates)
        @motion.save
      end
    end
  end

  describe "email notifications" do
    before :all do
      @motion = Factory.create(:motion)
    end

    it "should send a notification to all active members when a motion is created" do
      motion = Factory.build(:motion)
      ActiveMemberNotifier.should_receive(:deliver).with(:motion_created, motion)
      motion.save
    end

    it "should send a notification to all active members when a motion enters the discussing state" do
      ActiveMemberNotifier.should_receive(:deliver).with(:motion_state_changed, @motion)
      @motion.discussing!
    end

    describe "when a motion passes" do
      # state_name == closed && passed?
      it "should send a notification to all members"
    end

    describe "when a motion fails" do
      # state_name == closed && !passed?
      it "should send a notification to all members"
    end

    describe "when a motion fails to reach the voting state" do
      # state_name == closed && failed?
      it "should send a notification to all members"
    end

    describe "notify_members_of_outcome_of_voting" do
      it "should send an email to all members that the motion has closed" do
       @motion.should_receive(:send_email_after_closing)
       @motion.notify_members_of_outcome_of_voting
      end
    end

  end
end
