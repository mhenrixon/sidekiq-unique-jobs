require "spec_helper"
require "active_support/core_ext/kernel/reporting"
require "appraisal/travis_ci_helper"

describe "Travis CI integration" do
  before do
    build_appraisal_file <<-Appraisals.strip_heredoc
      appraise "1.0.0" do
        gem "dummy", "1.0.0"
      end

      appraise "1.1.0" do
        gem "dummy", "1.1.0"
      end
    Appraisals
  end

  context "when user runs `appraisal generate --travis`" do
    it "displays a correct Gemfile directive" do
      output = run("appraisal generate --travis")

      expect(output).to include <<-stdout.strip_heredoc
        # Put this in your .travis.yml
        gemfile:
          - gemfiles/1.0.0.gemfile
          - gemfiles/1.1.0.gemfile
      stdout
    end
  end

  context "When user has .travis.yml" do
    context "with no gemfiles directive" do
      before do
        write_file ".travis.yml", ""
      end

      it "displays a warning message when run `appraisal generate`" do
        warning = run "appraisal generate 2>&1"

        expect(warning).to include no_configuration_warning
      end
    end

    context "with incorrect gemfiles directive" do
      before do
        write_file ".travis.yml", <<-travis_yml
          gemfile:
            - gemfiles/1.0.0.gemfile
            - gemfiles/1.0.1.gemfile
        travis_yml
      end

      it "displays a warning message when run `appraisal generate`" do
        warning = run "appraisal generate 2>&1"

        expect(warning).to include invalid_configuration_warning
      end
    end

    context "with correct gemfiles directive" do
      before do
        write_file ".travis.yml", <<-travis_yml
          gemfile:
            - gemfiles/1.0.0.gemfile
            - gemfiles/1.1.0.gemfile
        travis_yml
      end

      it "does not display any warning when run `appraisal generate`" do
        warning = run "appraisal generate 2>&1"

        expect(warning).not_to include no_configuration_warning
        expect(warning).not_to include invalid_configuration_warning
      end
    end
  end

  context "when user does not have .travis.yml" do
    it "does not display any warning when run `appraisal generate`" do
      warning = run "appraisal generate 2>&1"

      expect(warning).not_to include no_configuration_warning
      expect(warning).not_to include invalid_configuration_warning
    end
  end

  def no_configuration_warning
    Appraisal::TravisCIHelper::NO_CONFIGURATION_WARNING
  end

  def invalid_configuration_warning
   Appraisal::TravisCIHelper::INVALID_CONFIGURATION_WARNING
  end
end
