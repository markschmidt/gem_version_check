# -*- coding: UTF-8 -*-
module GemVersionCheck
  module Formatter
    class PrettyPrint

      def initialize(report_result)
        @report_result = Array(report_result)
      end

      def format
        result = ""
        @report_result.each do |project|
          result << "#{project_title(project)}\n#{format_project(project)}"
        end
        result
      end

      private

      def format_project(project)
        str = ""
        project.report.each do |dependency|
          str << dependency_listitem(dependency) do |dep|
            dep.used? ? format_dependency(dependency) : "not used"
          end
        end
        str
      end

      def project_title(project)
        "Project: #{project.check_failed? ? red : green}#{project.name}#{black}" 
      end

      def dependency_listitem(dependency)
        " * #{dependency.name}: #{ yield dependency }\n"
      end

      def format_dependency(dependency)
        result = dependency.valid? ? valid_dependency(dependency) : invalid_dependency(dependency)
      end

      def valid_dependency(dependency)
        "#{green}#{dependency.expected_version} ✓#{black}"
      end

      def invalid_dependency(dependency)
        "#{dependency.expected_version} != #{red}#{dependency.version}#{black}"
      end

      def black
        "\033[30m"
      end

      def green
        "\033[32m"
      end

      def red
        "\033[31m"
      end

    end
  end
end