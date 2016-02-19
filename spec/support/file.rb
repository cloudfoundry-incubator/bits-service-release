module FileHelpers
  def write_to_file(file_path, size_in_bytes: 1024)
    tf = File.open(file_path, 'w')
    tf.write('A' * size_in_bytes)
    tf.close
  end
end
