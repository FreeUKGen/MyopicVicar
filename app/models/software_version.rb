class SoftwareVersion

  include Mongoid::Document
  include Mongoid::Timestamps

  field :date_of_update, type: DateTime
  field :version, type: String
  field :type, type: String
  field :last_search_record_version, type: String
  field :server
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

    def extract_server(hostname)
      hostname_parts = hostname.split('.')
      server = hostname_parts[0]
      server
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
  end
end
