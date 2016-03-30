module Backend
  class ClientBase
    private

    def path_for_guid(guid)
      File.join(guid[0..1], guid[2..3], guid)
    end
  end
end
