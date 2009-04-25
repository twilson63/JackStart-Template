gem 'haml'
gem 'rspec', :lib => false, :version => ">=1.2.2"
gem "rspec-rails", :lib => false, :version => ">=1.2.2"
gem "webrat", :lib => false, :version => ">=0.4.3"
gem "cucumber", :lib => false, :version => ">=0.3"
gem "thoughtbot-factory_girl", :lib => "factory_girl", :source => "http://gems.github.com"

rake("gems:install", :sudo => true)

inside() do
  run "sudo gem install twilson63-nifty-generators --no-rdoc --no-ri"
  run "haml --rails ."
  run "rm public/index.html"
  run "rm public/javascripts/control.js"
  run "rm public/javascripts/effect.js"
  run "rm public/javascripts/dragdrop.js"
  run "rm public/javascripts/prototype.js"
  
end

rake "db:create"

generate(:nifty_layout, "--haml")

generate(:rspec)
generate(:cucumber)

if yes?("Do you want to build a blog?") 
  generate(:nifty_scaffold, "post", "subject:string", "body:text", "--haml")

  generate(:nifty_scaffold, "comment", "email:string", "body:text", "post_id:integer", "--haml", "--ajaxify") 

  generate(:nifty_authentication, "--haml")

  rake "db:migrate"
  
  rake "db:test:clone"

  file 'spec/factories.rb', <<-CODE
Factory.define :post do |p|
  p.subject "Hello World"
  p.body "Welcome to My Blog"
end

Factory.define :comment do |c|
  c.email "my@email.com"
  c.body "this blog rocks!"
  c.post Post.first
end

  CODE
  
  file 'features/support/env.rb', <<-ENVFILE
# Sets up the Rails environment for Cucumber
ENV["RAILS_ENV"] ||= "test"
require File.expand_path(File.dirname(__FILE__) + '/../../config/environment')
require 'cucumber/rails/world'
require 'cucumber/formatters/unicode' # Comment out this line if you don't want Cucumber Unicode support
Cucumber::Rails.use_transactional_fixtures

require 'webrat'

Webrat.configure do |config|
  config.mode = :rails
  #config.mode = :selenium

end

require 'cucumber/rails/rspec'
require 'webrat/core/matchers'
require 'factory_girl'
require 'spec/factories'
  ENVFILE
    
  
  file 'features/manage_posts.feature', <<-CODE
Feature: Manage Posts
  In order to manage posts
  As a user
  I want to list, create, update, and show posts

  Scenario: List Posts
    Given I have posts titled Post1, Post2
    When I go to the list of posts
    Then I should see 2 posts
    And I should see "Post1"
    And I should see "Post2"

  Scenario: Create New Post
    Given I have no posts
    And I go to the list of posts
    And I follow "New Post"
    And I fill in "Subject" with "Hello World"
    And I fill in "Body" with "This is a new post message."
    When I press "Create Post"
    Then I should see 1 post
    And I should see "Successfully created post."
    And I should see "Hello World"
    And I should see "This is a new post message."

  Scenario: Edit Post
    Given I have post titled TestPost1
    And I go to the list of posts
    And I follow "Edit"
    And I fill in "Subject" with "Hello World"
    And I fill in "Body" with "This is a edit post message."
    When I press "Update Post"
    And I should see "Successfully updated post."
    And I should see "Hello World"
    And I should see "This is a edit post message."


  Scenario: Delete Post
    Given I have post titled TestPost1
    And I go to the list of posts
    When I follow "Remove"
    Then I have no posts
    And I should see "Successfully removed post." 
  CODE
  
  file 'features/step_definitions/posts_steps.rb', <<-CODE
Given /^I have posts? titled (.*)$/ do |posts|
  posts.split(', ').each do |post|
    Factory(:post, :subject => post)
  end

end

Then /^I should see (.*) posts?$/ do |count|
  Post.count.should == count.to_i
end

Given /^I have no posts$/ do
  Post.delete_all
end  
  CODE
  
  page_name = '#{page_name}'
  
    
  file 'features/support/paths.rb', <<-CODE
module NavigationHelpers
  # Maps a static name to a static route.
  #
  # This method is *not* designed to map from a dynamic name to a 
  # dynamic route like <tt>post_comments_path(post)</tt>. For dynamic 
  # routes like this you should *not* rely on #path_to, but write 
  # your own step definitions instead. Example:
  #
  #   Given /I am on the comments page for the "(.+)" post/ |name|
  #     post = Post.find_by_name(name)
  #     visit post_comments_path(post)
  #   end
  #
  def path_to(page_name)
    case page_name

    when /the homepage/
      root_path

    when /list of posts/
      posts_path
    # Add more page name => path mappings here

    else
      raise "Can't find mapping from \\"#{page_name}\\" to a path.\n" +
        "Now, go and add a mapping in features/support/paths.rb"
    end
  end
end  

World(NavigationHelpers)

  CODE
    

  
end