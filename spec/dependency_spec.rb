# encoding: utf-8
require 'spec_helper'

module GemVersionCheck
  describe Dependency do

    context "#check" do
      let(:lock_file) { Lockfile.new(lock_file_content("rails_app_example.lock")) }

      let(:dependency) { Dependency.new("activesupport", "3.2.8") }
      let(:invalid_dependency) { Dependency.new("activesupport", "3.2.9") }
      let(:not_used_dependency) { Dependency.new("exceptionist", "3.2.8") }

      context "#valid?" do
        it "is valid if current version == expected version" do
          dependency.check(lock_file)
          dependency.should be_valid
        end

        it "is invalid if current version != expected version" do
          invalid_dependency.check(lock_file)
          invalid_dependency.should_not be_valid
        end

        context "remote dependency" do
          it "is valid when using the latest spec" do
            dependency = Dependency.new("activesupport", nil)
            dependency.expects(:retrieve_latest_spec).returns(Gem::Specification.new('activesupport', '3.2.8'))

            dependency.check(lock_file)
            dependency.should be_valid
          end

          it "is invalid when using the latest spec" do
            dependency = Dependency.new("activesupport", nil)
            dependency.expects(:retrieve_latest_spec).returns(Gem::Specification.new('activesupport', '3.2.9'))

            dependency.check(lock_file)
            dependency.should_not be_valid
          end

          it "is valid when ignoring the major version" do
            dependency = Dependency.new("activesupport", nil, :ignore_major_version_change => true)
            dependency.expects(:retrieve_latest_spec).returns(Gem::Specification.new('activesupport', '3.2.8'))

            dependency.check(lock_file)
            dependency.should be_valid
          end

          it "is invalid when ignoring the major version" do
            dependency = Dependency.new("activesupport", nil, :ignore_major_version_change => true)
            dependency.expects(:retrieve_latest_spec).returns(Gem::Specification.new('activesupport', '3.2.17'))

            dependency.check(lock_file)
            dependency.should_not be_valid
          end

          context "latest available dependency version is a prerelease" do
            before :each do
              Gem::SpecFetcher.any_instance.stubs(:spec_for_dependency).returns([ spec_tuples ])
            end

            context "when not ignoring the major version" do
            let(:spec_tuples) { %w(3.2.21 4.0.0.rc1).map { |v| [ Gem::Specification.new('activesupport', v) ] } }

              it "retrieves prerelease as the latest version available" do
                dependency = Dependency.new("activesupport", nil, :allow_prerelease_dependencies => true, :ignore_major_version_change => false)

                dependency.check(lock_file)
                dependency.should_not be_valid

                expect(dependency.latest_version).to eq("4.0.0.rc1")
              end
            end

            context "when ignoring the major version" do
            let(:spec_tuples) { %w(3.2.17 3.3.0.rc1).map { |v| [ Gem::Specification.new('activesupport', v) ] } }

              it "retrieves prerelease as the latest major version available" do
                dependency = Dependency.new("activesupport", nil, :allow_prerelease_dependencies => true, :ignore_major_version_change => true)

                dependency.check(lock_file)
                dependency.should_not be_valid

                expect(dependency.latest_version).to eq("3.3.0.rc1")
              end
            end
          end
        end
      end

      context "#used?" do
        it "returns true if found in lock file" do
          dependency.check(lock_file)
          dependency.should be_used
        end

        it "return false if not found in lock file" do
          not_used_dependency.check(lock_file)
          not_used_dependency.should_not be_used
        end
      end

      context "#gem_not_found?" do
        it "returns false if gem was found on gems server" do
          dependency.check(lock_file)
          dependency.should_not be_gem_not_found
        end

        it "returns true if gem was not found on gems server" do
          dep = Dependency.new("non_existing_gem")
          dep.expects(:retrieve_spec).returns(nil)
          dep.check(lock_file)

          dep.should be_gem_not_found
        end
      end
    end
  end
end
