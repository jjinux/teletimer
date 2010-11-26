# Return "get" or "post" based on method which may be nil.
#
# "post" is the default.
def sanitize_method(method)
  method = (method || "post").to_s.downcase
  %w(get post).should include(method)
  method
end

When /^I follow the redirect$/ do
  redirect = @doc.xpath("/Response/Redirect").first
  redirect.should_not be_nil
  request_via_redirect(sanitize_method(redirect[:method]), redirect.content)
end

When /^I enter "([^"]*)"$/ do |digits|
  gather = @doc.xpath("/Response/Gather").first
  gather.should_not be_nil
  request_via_redirect(sanitize_method(gather[:method]), gather[:action], {:Digits => digits})
end

When /^I record something with the URL "([^"]*)"$/ do |url|
  record = @doc.xpath("/Response/Record").first
  record.should_not be_nil
  request_via_redirect(sanitize_method(record[:method]), record[:action], {:RecordingUrl => url})
end

Then /^I should get a valid TwiML response$/ do
  assert_response :success
  @doc = Nokogiri::XML(response.body)
  @doc.xpath("/Response").size.should == 1
end

Then /^it should (not |)(say|play) "([^"]*)"$/ do |not_present, verb, msg|
  @doc.xpath("//#{verb.titlecase}").any? { |e| e.content.include?(msg) }.should == (not_present == "")
end

Then /^it should record something$/ do
  @doc.xpath("/Response/Record").should_not be_empty
end

Then /^it should redirect me if I time out$/ do
  @doc.xpath("/Response/Redirect").should_not be_empty
end

When /^I call the service$/ do
  get url_for(:controller => :twilio)
end

When /^I enter "([^"]*)" after (\d+) seconds$/ do |digits, wait_seconds|
  gather = @doc.xpath("/Response/Gather").first
  gather.should_not be_nil
  request_via_redirect(sanitize_method(gather[:method]), gather[:action], {:Digits => digits, :wait_seconds => wait_seconds})
end