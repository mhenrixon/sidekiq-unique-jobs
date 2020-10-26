# frozen_string_literal: true

# @see SimpleCov https://github.com/colszowka/simplecov
module SimpleCov
  # @see SimpleCov::Formatter https://github.com/colszowka/simplecov
  module Formatter
    #
    # Formats Simplecov Results into a json file `coverage.json`
    #
    # @author Mikael Henriksson <mikael@mhenrixon.se>
    #
    class OjFormatter
      #
      # @return [String] name of the file with coverage.json data
      FILE_NAME = 'coverage.json'

      #
      # Formats the result as a hash, dump it to json with Oj and then save it to disk
      #
      # @param [SimpleCov::Result] result
      #
      # @return [<type>] <description>
      #
      def format(result)
        json = dump_json(result)
        puts SimpleCov::Oj::OutputMessage.new(result, output_filepath)

        json
      end

      private

      # @private
      def dump_json(result)
        data = SimpleCov::Oj::ResultToHash.new(result).to_h
        json = ::Oj.dump(data, mode: :compat)

        File.open(output_filepath, 'w+') do |file|
          file.puts json
        end

        json
      end

      # @private
      def output_filepath
        File.join(SimpleCov.coverage_path, FILE_NAME)
      end
    end
  end
end
