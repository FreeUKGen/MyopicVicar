class SoftwareVersion
  include Mongoid::Document
  include Mongoid::Timestamps
  require 'app'

  field :date_of_update, type: DateTime
  field :version, type: String
  field :type, type: String
  field :last_search_record_version, type: String
  field :server
  field :app
  field :action, type: Array
  embeds_many :commitments

  class << self
    def id(id)
      where(id: id)
    end

    def type(type)
      where(type: type)
    end

    def date(date)
      where(date_of_update: date)
    end

    def control
      where(type: 'Control')
    end

    def server(server)
      where(server: server)
    end

    def app(app)
      where(app: app)
    end

    def extract_server(hostname)
      hostname_parts = hostname.split('.')
      server = hostname_parts[0]
      server
    end

    def selection_options
      servers = MyopicVicar::Servers::ALL_SERVERS
      this_server = SoftwareVersion.extract_server(Socket.gethostname)
      options = []
      options[0] = 'This application and server'
      app = App.name_downcase
      if servers.include?(this_server)
        servers.each do |server|
          option = app.to_s + '-' + server.to_s
          options << option
        end
      end

      options
    end

    def update_version(version)
      version_parts = version.split('.')
      case version_parts.length
      when 3
        version_new_part = (version_parts[2].to_i + 1).to_s
        new_version = version_parts[0] + '.' + version_parts[1] + '.' + version_new_part
      when 2
        version_new_part = (version_parts[1].to_i + 1).to_s
        new_version = version_parts[0] + '.' + version_new_part
      when 1
        new_version = (version_parts[0].to_i + 1).to_s
      end
      new_version
    end

    def version_information(option)
      if option == 'This application and server'
        server = SoftwareVersion.extract_server(Socket.gethostname)
        application = App.name_downcase
      else
        server_selected = option.split('-')
        server = server_selected[1]
        application = server_selected[0]
      end
      versions = SoftwareVersion.app(application).server(server).all.order_by(date_of_update: -1)
      [versions, application, server]
    end
  end
end
