# Exercise real routes/controller/templates without Rails startup rewriting public/.
require 'bundler/setup'
require 'logger'
require 'active_support/all'
require 'action_controller'
require 'rspec/core'
require 'rspec/expectations'
require 'rspec/mocks'
require 'tmpdir'
require_relative '../../app/helpers/application_helper'

RSpec.describe 'FreePRO placeholder pages' do
  let(:site) { 'freepro' }
  let(:root) { Pathname.new(File.expand_path('../..', __dir__)) }
  let(:routes) { ActionDispatch::Routing::RouteSet.new }

  before do
    stub_const('MyopicVicar', Module.new)
    stub_const('MyopicVicar::Application', Class.new)
    allow(MyopicVicar::Application).to receive(:config).and_return(double(template_set: site))
    allow(MyopicVicar::Application).to receive(:routes).and_return(routes)
    stub_const('Rails', Module.new) unless defined?(Rails)
    allow(Rails).to receive(:root).and_return(root)

    # Unrelated Devise routes and selection constraints are outside this test.
    allow_any_instance_of(ActionDispatch::Routing::Mapper).to receive(:devise_for)
    root.join('config/routes.rb').read.scan(/(?:constraints:|:constraints\s*=>)\s*(\w+)/).flatten.uniq.each do |name|
      stub_const(name, Class.new { def self.matches?(_request); false; end })
    end
    base = Class.new(ActionController::Base) do
      before_action :require_login
      def require_login; end
    end
    stub_const('ApplicationController', base)
    stub_const('PagesController', Class.new(base))
    ActiveSupport::Dependencies::Reference.clear!
    load root.join('app/controllers/pages_controller.rb')
    load root.join('config/routes.rb')
    PagesController.append_view_path(root.join('app/views'))
    page_routes = routes
    PagesController.helper(Module.new do
      define_method(:new_search_query_path) { page_routes.url_helpers.new_search_query_path }
    end)
    PagesController.helper(ApplicationHelper)
  end

  after do
    ActiveSupport::Dependencies::Reference.clear!
  end

  { '/freepro/search-help' => ['search_help', 'Search Help'],
    '/freepro/database-information' => ['database_information', 'Database Information'] }.each do |path, (template, heading)|
    it "routes #{path} to the existing page renderer" do
      expect(routes.recognize_path(path, method: :get)).to include(
        controller: 'pages', action: 'show', path: template
      )
    end

    it "renders #{heading} successfully with the application layout" do
      # Isolate shared layout dependencies (ads, session helpers) with a fixture layout.
      Dir.mktmpdir('freepro-pages-layout') do |directory|
        FileUtils.mkdir_p(File.join(directory, 'layouts'))
        File.write(File.join(directory, 'layouts/application.html.erb'), '<main><%= yield %></main>')
        PagesController.prepend_view_path(directory)
        status, _headers, body = routes.call(Rack::MockRequest.env_for(path))
        html = body.each.to_a.join
        expect(status).to eq(200)
        expect(html).to include('<main>', "FreePRO #{heading}", 'Information coming soon.',
                               'href="/search_queries/new"', 'Back to FreePRO search')
      end
    end
  end

  %w[freepro freereg freecen freebmd].each do |name|
    context "existing page lookup on #{name}" do
      let(:site) { name }

      it 'preserves shared pages and gives site-specific pages precedence' do
        Dir.mktmpdir('existing-pages') do |directory|
          fixture_root = Pathname.new(directory)
          allow(Rails).to receive(:root).and_return(fixture_root)
          views = fixture_root.join('app/views')
          FileUtils.mkdir_p(views.join('pages', site))
          FileUtils.mkdir_p(views.join('layouts'))
          File.write(views.join('layouts/application.html.erb'), '<main><%= yield %></main>')
          File.write(views.join('pages/shared-example.html.erb'), 'Existing shared page')
          File.write(views.join('pages/site-example.html.erb'), 'Shared fallback')
          File.write(views.join('pages', site, 'site-example.html.erb'), 'Existing site-specific page')
          PagesController.prepend_view_path(views)
          { '/shared-example' => 'Existing shared page',
            '/site-example' => 'Existing site-specific page' }.each do |path, content|
            status, _headers, body = routes.call(Rack::MockRequest.env_for(path))
            expect(status).to eq(200)
            expect(body.each.to_a.join).to include(content)
          end
        end
      end
    end
  end

  it 'returns the normal 404 for an unavailable FreePRO page' do
    app = ActionDispatch::ShowExceptions.new(routes, ActionDispatch::PublicExceptions.new(root.join('public')))
    status, = app.call(Rack::MockRequest.env_for('/freepro/unavailable'))
    expect(status).to eq(404)
  end

  %w[freereg freecen freebmd].each do |name|
    context "on #{name}" do
      let(:site) { name }

      %w[/freepro/search-help /freepro/database-information
         /freepro/search_help /freepro/database_information
         /%2e%2e/freepro/search_help /%2e%2e/freepro/database_information].each do |path|
        it "returns the normal 404 for #{path}" do
          env = Rack::MockRequest.env_for(path)
          app = ActionDispatch::ShowExceptions.new(routes, ActionDispatch::PublicExceptions.new(root.join('public')))
          status, _headers, body = app.call(env)
          expect(status).to eq(404)
          expect(body.each.to_a.join).not_to include('Information coming soon.', 'Back to FreePRO search')
        end
      end

      it 'leaves both URLs handled by the existing catch-all, without FreePRO helpers' do
        %w[/freepro/search-help /freepro/database-information].each do |path|
          expect(routes.recognize_path(path, method: :get)).to include(path: path.delete_prefix('/'))
        end
        expect(routes.url_helpers).not_to respond_to(:freepro_search_help_path)
        expect(routes.url_helpers).not_to respond_to(:freepro_database_information_path)
      end
    end
  end
end
