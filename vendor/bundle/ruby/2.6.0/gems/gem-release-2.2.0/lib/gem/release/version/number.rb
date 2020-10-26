module Gem
  module Release
    module Version
      class Number < Struct.new(:number, :target)
        NUMBER = /^(\d+)\.?(\d+)?\.?(\d+)?(\-|\.)?(\w+)?\.?(\d+)?$/
        PRE_RELEASE  = /^(\d+)\.(\d+)\.(\d+)\.?(.*)(\d+)$/

        STAGES = %i(alpha beta pre rc)

        def bump
          return target if specific?
          validate_stage
          parts = [[major, minor, patch].compact.join('.')]
          parts << [stage, num].join('.') if stage
          parts.join(stage_delim)
        end

        def pre?
          !!parts[4]
        end

        private

          def specific?
            target =~ NUMBER || target =~ PRE_RELEASE
          end

          def major
            part = parts[0]
            part += 1 if to?(:major)
            part
          end

          def minor
            part = parts[1].to_i
            part = 0 if to?(:major)
            part += 1 if to?(:minor) || fresh_pre_release?
            part
          end

          def patch
            part = parts[2].to_i
            part = 0 if to?(:major, :minor) || fresh_pre_release?
            part += 1 if to?(:patch) && from_release?
            part
          end

          def stage
            target unless to_release?
          end

          def stage_delim
            # Use what's being used or default to dot (`.`)
            # dot is preferred due to rubygems issue
            # https://github.com/rubygems/rubygems/issues/592
            parts[3] || '.'
          end

          def num
            return if to_release?
            same_stage? ? parts[5].to_i + 1 : 1
          end

          def to?(*targets)
            targets.include?(target)
          end

          def to_release?
            to?(:major, :minor, :patch)
          end

          def fresh_pre_release?
            from_release? && to?(:pre, :rc)
          end

          def from_release?
            !from_pre_release?
          end

          def from_pre_release?
            !!from_stage
          end

          def same_stage?
            from_stage == target
          end

          def from_stage
            parts[4]
          end

          def target
            super || (from_pre_release? ? from_stage : :patch)
          end

          def validate_stage
            from, to = STAGES.index(from_stage), STAGES.index(target)
            return unless from && to && from > to
            raise Abort, "Cannot go from an #{from_stage} version to a #{target} version"
          end

          def parts
            @parts ||= matches.compact.map(&:to_i).tap do |parts|
              parts[3] = matches[3]
              parts[4] = matches[4].to_sym if matches[4]
            end
          end

          def matches
            @matches ||= parse.to_a[1..-1]
          end

          def parse
            matches = number.match(NUMBER)
            raise Abort, "Cannot parse version number #{number}" unless matches
            matches
          end
      end
    end
  end
end
