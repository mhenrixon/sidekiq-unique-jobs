# frozen_string_literal: true

require "erb"
require "cgi"
require "fileutils"
require "digest/sha1"

# Ensure we are using a compatible version of SimpleCov
major, minor, patch = SimpleCov::VERSION.scan(/\d+/).first(3).map(&:to_i)
if major.negative? || minor < 9 || patch.negative?
  raise "The version of SimpleCov you are using is too old. "\
  "Please update with `gem install simplecov` or `bundle update simplecov`"
end

module SimpleCov
  module Formatter
    class MaterialFormatter # rubocop:disable Metrics/ClassLength
      def initialize
        @branchable_result = SimpleCov.branch_coverage?
      end

      def format(result) # rubocop:disable Metrics/AbcSize
        Dir[File.join(File.dirname(__FILE__), "../public/*")].each do |path|
          FileUtils.cp_r(path, asset_output_path)
        end

        File.open(File.join(output_path, "index.html"), "wb") do |file|
          file.puts template("main").result(binding)
        end
        puts output_message(result)
      end

      def output_message(result)
        "Coverage report generated for #{result.command_name} to " \
        "#{output_path}. #{result.covered_lines} / #{result.total_lines} LOC" \
        " (#{result.covered_percent.round(2)}%) covered."
      end

      def branchable_result?
        # cached in initialize because we truly look it up a whole bunch of times
        # and it's easier to cache here then in SimpleCov because there we might
        # still enable/disable branch coverage criterion
        @branchable_result
      end

      def line_status?(source_file, line)
        if branchable_result? && source_file.line_with_missed_branch?(line.number)
          "missed-branch"
        else
          line.status
        end
      end

    private

      def template(name)
        ERB.new(File.read(File.join(
          File.dirname(__FILE__), "../views/", "#{name}.erb"
        )))
      end

      def output_path
        SimpleCov.coverage_path
      end

      def asset_output_path
        return @asset_output_path if defined?(@asset_output_path) &&
                                     @asset_output_path

        @asset_output_path = File.join(
          output_path, "dist", SimpleCov::Formatter::MaterialFormatter::VERSION
        )
        FileUtils.mkdir_p(@asset_output_path)
        @asset_output_path
      end

      def assets_path(name)
        File.join(
          "./dist", SimpleCov::Formatter::MaterialFormatter::VERSION, name
        )
      end

      def generate_dialog(file)
        template("dialog").result(binding)
      rescue Encoding::CompatibilityError => e
        puts "Encoding problems with file #{file.filename}. Simplecov/ERB "\
             "can't handle non ASCII characters in filenames. Error: " \
             "#{e.message}."
      end
      
      # rubocop:disable Lint/SelfAssignment, Style/RedundantRegexpEscape
      def generate_group_page(title, files)
        title_id = title.gsub(/^[^a-zA-Z]+/, "").gsub(/[^a-zA-Z0-9\-\_]/, "")
        title_id = title_id
        template("group_page").result(binding)
      end

      def remove_spaces(name)
        name.gsub(/^[^a-zA-Z]+/, "").gsub(/[^a-zA-Z0-9\-\_]/, "")
      end
      # rubocop:enable Lint/SelfAssignment, Style/RedundantRegexpEscape

      def format_number(number)
        whole, decimal = number.to_s.split(".")
        whole_with_commas =
          whole.chars.to_a.reverse.each_slice(3).map(&:join).join(",").reverse
        [whole_with_commas, decimal].compact.join(".")
      end

      def coverage_class(covered_percent)
        if covered_percent > 90
          "green"
        elsif covered_percent > 80
          "yellow"
        else
          "red"
        end
      end

      def strength_class(covered_strength)
        if covered_strength > 1
          "green"
        elsif covered_strength == 1
          "yellow"
        else
          "red"
        end
      end

      def id(source_file)
        Digest::SHA1.hexdigest(source_file.filename)
      end

      def shortened_filename(file)
        file.filename.sub(SimpleCov.root, ".").gsub(/^\.\//, "")
      end

      def hide_show(title)
        if title == "AllFiles"
          "display: '';"
        else
          "display: none;"
        end
      end
    end
  end
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__)))
require "simplecov-material/version"
