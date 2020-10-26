# frozen_string_literal: true

module SimpleCov
  module Oj
    #
    # Massage result into a hash that can be dumped to json by OJ
    #
    # @author Mikael Henriksson <mikael@mhenrixon.se>
    #
    class ResultToHash
      #
      # Initialize a new ResultToHash
      #
      # @param [SimpleCov::Result] result the final result from simplecov
      #
      def initialize(result)
        @result = result
        @data = {
          timestamp: result.created_at.to_i,
          command_name: result.command_name,
          files: []
        }
      end

      #
      # Create a hash from the result that can be used for JSON dumping
      #
      #
      # @return [Hash]
      #
      def to_h
        extract_files
        extract_metrics
        data
      end

      private

      attr_reader :result, :data

      # @private
      def extract_files
        data[:files] = source_file_collection
      end

      # @private
      def source_file_collection
        result.files.each_with_object([]) do |source_file, memo|
          next unless result.filenames.include?(source_file.filename)

          memo << SourceFileWrapper.new(source_file).to_h
        end
      end

      # @private
      def extract_metrics
        data[:metrics] = ResultWrapper.new(result).to_h
      end
    end
  end
end
