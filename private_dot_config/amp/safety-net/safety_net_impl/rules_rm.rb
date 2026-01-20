# frozen_string_literal: true

require_relative "shell"

module SafetyNetImpl
  module RulesRm
    REASON_RM_RF = "rm -rf is destructive. Use `trash` instead, or list files first, then delete individually."
    REASON_RM_RF_ROOT_HOME = "rm -rf on root or home paths is extremely dangerous."
    REASON_RM_RF_TMP = "rm -rf in temp directories blocked. " \
      "[allow_tmp disabled - enable with: unset SAFETY_NET_ALLOW_TMP_RM]"
    PARANOID_SUFFIX = " [paranoid mode - disable with: unset SAFETY_NET_PARANOID SAFETY_NET_PARANOID_RM]"

    module_function

    def analyze_rm(tokens, allow_tmpdir_var: true, allow_tmp: true, cwd: nil, paranoid: false)
      rest = tokens[1..] || []

      opts = []
      rest.each do |tok|
        break if tok == "--"

        opts << tok
      end

      opts_lower = opts.map(&:downcase)
      short = Shell.short_opts(opts)
      recursive = opts_lower.include?("--recursive") || short.include?("r") || short.include?("R")
      force = opts_lower.include?("--force") || short.include?("f")

      return nil unless recursive && force

      targets = rm_targets(tokens)
      return REASON_RM_RF_ROOT_HOME if targets.any? { |t| root_or_home_path?(t) }

      return REASON_RM_RF if cwd && targets.any? { |t| cwd_itself?(t, cwd) }

      if targets.any? && targets.all? { |t| temp_path?(t, allow_tmpdir_var: allow_tmpdir_var) }
        return nil if allow_tmp

        return REASON_RM_RF_TMP
      end

      return REASON_RM_RF + PARANOID_SUFFIX if paranoid

      if cwd && targets.any?
        home = ENV["HOME"]
        if home && normalize_path(cwd) == normalize_path(home)
          return REASON_RM_RF_ROOT_HOME
        end

        return nil if targets.all? { |t| path_within_cwd?(t, cwd) }
      end

      REASON_RM_RF
    end

    def cwd_itself?(path, cwd)
      normalized = normalize_path(path)
      return true if normalized == "." || normalized.empty?

      resolved = if path.start_with?("/")
        normalize_path(path)
      else
        normalize_path(File.join(cwd, path))
      end

      resolved == normalize_path(cwd)
    end

    def path_within_cwd?(path, cwd)
      return false if path.start_with?("~", "$HOME", "${HOME}")
      return false if path.include?("$") || path.include?("`")

      normalized = normalize_path(path)
      return false if normalized == "." || normalized.empty?

      resolved = if path.start_with?("/")
        normalize_path(path)
      else
        normalize_path(File.join(cwd, path))
      end

      cwd_normalized = normalize_path(cwd)

      return false if resolved == cwd_normalized

      resolved.start_with?("#{cwd_normalized}/")
    end

    def rm_targets(tokens)
      targets = []
      after_double_dash = false

      (tokens[1..] || []).each do |tok|
        if after_double_dash
          targets << tok
          next
        end
        if tok == "--"
          after_double_dash = true
          next
        end
        next if tok.start_with?("-") && tok != "-"

        targets << tok
      end

      targets
    end

    def temp_path?(path, allow_tmpdir_var:)
      if path.start_with?("/")
        normalized = normalize_path(path)
        return normalized == "/tmp" ||
          normalized.start_with?("/tmp/") ||
          normalized == "/var/tmp" ||
          normalized.start_with?("/var/tmp/")
      end

      return false unless allow_tmpdir_var

      ["$TMPDIR", "${TMPDIR}"].each do |prefix|
        return true if path == prefix

        if path.start_with?("#{prefix}/")
          rest = path[(prefix.length + 1)..]
          return false if rest.split("/").include?("..")

          return true
        end
      end

      false
    end

    def root_or_home_path?(path)
      path == "/" ||
        (path.start_with?("/") && normalize_path(path) == "/") ||
        path == "~" ||
        path.start_with?("~/") ||
        path == "$HOME" ||
        path.start_with?("$HOME/") ||
        path.start_with?("${HOME}")
    end

    def normalize_path(path)
      File.expand_path(path).gsub(%r{/+}, "/").chomp("/")
    rescue ArgumentError
      path
    end
  end
end
