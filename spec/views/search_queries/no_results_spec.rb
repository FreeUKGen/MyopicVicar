# Render real templates without booting Rails: public_files.rb rewrites public/ at boot.
require 'bundler/setup'
require 'logger'
require 'active_support/all'
require 'action_view'
require 'rspec/core'
require 'rspec/expectations'
require 'rspec/mocks'
require_relative '../../../app/helpers/application_helper'

RSpec.describe 'Search results empty state' do
  let(:site) { 'freepro' }
  let(:view) do
    lookup = ActionView::LookupContext.new([File.expand_path('../../../app/views', __dir__)])
    lookup.prefixes = ['search_queries', 'application']
    ActionView::Base.with_empty_template_cache.new(lookup, {}, nil).tap do |renderer|
      renderer.extend(ApplicationHelper)
    end
  end

  before do
    stub_const('MyopicVicar', Module.new)
    stub_const('MyopicVicar::Application', Class.new)
    allow(MyopicVicar::Application).to receive(:config).and_return(double(template_set: site))
    stub_const('FreeregOptionsConstants', Module.new)
    stub_const('FreeregOptionsConstants::MAXIMUM_NUMBER_OF_RESULTS', 2000)
    allow(view).to receive(:contact_us_path).and_return('/contacts/new')
    allow(view).to receive(:title)
    allow(view).to receive(:show_contents_link)
    allow(view).to receive(:device_type).and_return(:desktop)
    allow(view).to receive(:mh_160_600).and_return('existing advertisement')
    allow(view).to receive(:render).and_call_original
    %w[flash_notice nav_header display_search_criteria].each do |partial|
      allow(view).to receive(:render).with(partial).and_return('')
    end
    allow(view).to receive(:render).with(hash_including(partial: 'desktop_freepro')).and_return('matching records')
    view.assign(search_query: double(inclusive: false, first_name: nil, last_name: nil),
                search_results: [], result_count: 0, ucf_results: [])
  end

  def results
    view.render(template: 'search_queries/show')
  end

  it 'renders the FreePRO heading for zero results' do
    expect(results).to include('We couldn’t find any matching records')
  end

  it 'renders search advice, coverage explanations and verified links' do
    html = results
    ['There are several reasons why your search might not have found a match.',
     'Try changing your search terms', 'Check the spelling', 'broaden the date range',
     'include fewer details', 'We might not have the records you are searching for',
     'may not yet have been processed into the FreePRO database',
     'Other organisations also hold probate records', 'Records are being added regularly',
     'You could also try looking on our sister sites:'].each do |content|
      expect(html).to include(content)
    end
    document = Nokogiri::HTML.fragment(html)
    {
      'FreeCEN' => 'https://www.freecen.org.uk/',
      'FreeREG' => 'https://www.freereg.org.uk/',
      'New FreeBMD' => 'https://www.freebmd2.org.uk/',
      'Original FreeBMD' => 'https://www.freebmd.org.uk/',
      'UK government’s probate search service' => 'https://probatesearch.service.gov.uk/'
    }.each do |label, url|
      expect(document.css('a').find { |link| link.text == label }&.[]('href')).to eq(url)
    end
    expect(html).to include('existing advertisement')
    expect(html).not_to include('href="/help"', 'href="/cms/help"')
  end

  it 'does not render the empty state for positive results' do
    view.assign(result_count: 1)
    expect(results).not_to include('We couldn’t find any matching records', 'No results found')
    expect(view).not_to have_received(:render).with('no_results')
  end

  it 'does not render the empty state for uncertain-only results' do
    view.assign(ucf_results: [double('uncertain record')])
    expect(results).not_to include('We couldn’t find any matching records', 'No results found')
    expect(view).not_to have_received(:render).with('no_results')
  end

  { 'freereg' => 'we have yet to transcribe the register images',
    'freecen' => 'we have yet to transcribe the census images',
    'freebmd' => 'we have yet to transcribe the index images' }.each do |name, content|
    context "on #{name}" do
      let(:site) { name }

      it 'retains the existing empty-state content' do
        html = results
        expect(html).to include('No results found', 'Maybe you need to change your search?', content)
        expect(html).not_to include('We couldn’t find any matching records', 'freepro-no-results')
      end
    end
  end
end
