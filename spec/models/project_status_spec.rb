require File.expand_path(File.join(File.dirname(__FILE__),'..','spec_helper'))

describe ProjectStatus do
  before(:each) do
    @project_status = ProjectStatus.new
  end

  it "should default to not online" do
    @project_status.should_not be_online
  end

  describe "in_words" do
    it "returns success for a successful status" do
      status = project_statuses(:socialitis_status_green_01)
      status.in_words.should == 'success'
    end
    it "returns offline for an offline status" do
      status = project_statuses(:offline_status)
      status.in_words.should == 'offline'
    end

    it "returns failure for a failed status" do
      status = project_statuses(:socialitis_status_old_red_00)
      status.in_words.should == 'failure'
    end

  end

  describe "#match?" do
    describe "for an offline status" do
      it "should be true as long as the status is online false, regardless of other characteristics" do
        ProjectStatus.new(:error => "error1", :online => false).match?(
            ProjectStatus.new(:error => "error2", :online => false)).should be_true
      end
    end

    describe "urls" do
      before(:each) do
        @project = HudsonProject.create(:name => "my_hudson_project", :feed_url => "http://foo.bar.com:3434/job/example_project/rssAll")
        @project_status = ProjectStatus.new(:project => @project)
      end
      it "should include the project's base_path in the url if set" do
        @project.update_attributes(:feed_url => "http://foo.bar.com:3434/hudson/job/example_project/rssAll")
        @project_status.update_attributes(:url => "http://int-builds.prvt.nytimes.com/job/election%202010/464/")
        @project_status.url.should == "http://int-builds.prvt.nytimes.com/hudson/job/election%202010/464/"
      end
      it "should not include a base path if the project's feed url doesn't have one" do
        @project.update_attributes(:feed_url => "http://foo.bar.com:3434/job/example_project/rssAll")
        @project_status.update_attributes(:url => "http://int-builds.prvt.nytimes.com/job/election%202010/464/")
        @project_status.url.should == "http://int-builds.prvt.nytimes.com/job/election%202010/464/"
      end
    end
  
    describe "for an online status" do
      it "should return false for a hash with :online => false" do
        ProjectStatus.new(online_status_hash).match?(ProjectStatus.new(online_status_hash(:online => false))).should be_false
      end

      it "should return true for a hash that with the same value as self for success, published_at, and url" do
        ProjectStatus.new(online_status_hash).match?(ProjectStatus.new(online_status_hash)).should be_true
      end

      it "should return false for a hash with a different value for success" do
        ProjectStatus.new(online_status_hash).match?(ProjectStatus.new(:success => false)).should be_false
      end

      it "should return false for a hash with a different value for published_at" do
        different_published_at = Time.now - 10.minutes
        ProjectStatus.new(online_status_hash).match?(ProjectStatus.new(:published_at => different_published_at)).should be_false
      end

      it "should return false for a hash with a different value for url" do
        different_url = "http://your/mother.rss"
        ProjectStatus.new(online_status_hash).match?(ProjectStatus.new(:url => different_url)).should be_false
      end

      private

      def online_status_hash(options = {})
        {
          :online => true,
          :success => true,
          :url => "http://foo/bar.rss",
          :published_at => Time.utc(2007, 1, 4)
        }.merge(options)
      end
    end
  end
end
