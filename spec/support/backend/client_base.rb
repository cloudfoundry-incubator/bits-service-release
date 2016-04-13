module Backend
  class ClientBase
    private

    def path_for_guid(guid)
      File.join(@path_prefix.to_s, guid[0..1], guid[2..3], guid).gsub(%r{^/}, '')
    end
  end
end
