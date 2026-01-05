# frozen_string_literal: true

require "json"
require "set"
require_relative "shell"
require_relative "rules_rm"
require_relative "rules_git"

module SafetyNetImpl
  module Hook
    MAX_RECURSION_DEPTH = 5

    STRICT_SUFFIX = " [strict mode - disable with: unset SAFETY_NET_STRICT]"
    PARANOID_INTERPRETERS_SUFFIX = " [paranoid mode - disable with: unset SAFETY_NET_PARANOID SAFETY_NET_PARANOID_INTERPRETERS]"

    REASON_FIND_DELETE = "find -delete permanently deletes matched files. Use -print first."
    REASON_XARGS_RM_RF = "xargs can feed arbitrary input to rm -rf. List files first, then delete individually."
    REASON_PARALLEL_RM_RF = "parallel can feed arbitrary input to rm -rf. List files first, then delete individually."
    REASON_INTERPRETER_ONE_LINER = "Interpreter one-liners can hide destructive commands. Write the code to a file instead."

    DANGEROUS_PATTERNS = [
      /\brm\s+.*-[^\s]*r[^\s]*f/,
      /\brm\s+.*-[^\s]*f[^\s]*r/,
      />\s*\/dev\/[sh]d[a-z]/,
      /\bdd\b.*\bof=/,
      /\bmkfs\b/,
      /\bshred\b/
    ].freeze

    FIND_CONSUMES_ONE = Set.new(%w[
      -name -iname -path -ipath -wholename -iwholename
      -regex -iregex -lname -ilname -samefile -newer
      -newerxy -perm -user -group -printf -fprintf
      -fprint -fprint0 -fls
    ]).freeze

    FIND_EXEC_LIKE = Set.new(%w[-exec -execdir -ok -okdir]).freeze

    SHELLS = Set.new(%w[sh bash zsh fish dash ksh tcsh csh]).freeze

    INTERPRETERS = Set.new(%w[python python3 node ruby perl]).freeze

    XARGS_CONSUMES_VALUE = Set.new(%w[
      -a -I -J -L -l -n -R -S -s -P -d -E
      --arg-file --delimiter --eof --max-args --max-lines
      --max-procs --max-chars --process-slot-var
    ]).freeze

    PARALLEL_CONSUMES_VALUE = Set.new(%w[
      -j --jobs -S --sshlogin --sshloginfile -a --arg-file
      --arg-sep --col-sep -I --replace -U --delay --retries
      --timeout --progress-char -n --max-args -N --max-replace-args
      -L --max-lines -E --eof -s --max-chars
    ]).freeze

    module_function

    def dangerous_in_text(text)
      DANGEROUS_PATTERNS.each do |pattern|
        return "Dangerous pattern detected: #{pattern.source}" if text.match?(pattern)
      end
      nil
    end

    def strip_token_wrappers(token)
      tok = token.strip
      while tok.start_with?("$(")
        tok = tok[2..]
      end
      tok = tok.sub(/\A[\\`(\{\[]+/, "")
      tok = tok.sub(/[`\)\}\]]+\z/, "")
      tok
    end

    def find_has_delete?(args)
      i = 0
      while i < args.length
        tok = strip_token_wrappers(args[i]).downcase

        if FIND_EXEC_LIKE.include?(tok)
          i += 1
          while i < args.length
            end_tok = strip_token_wrappers(args[i])
            if [";", "+"].include?(end_tok)
              i += 1
              break
            end
            i += 1
          end
          next
        end

        if FIND_CONSUMES_ONE.include?(tok)
          i += 2
          next
        end

        return true if tok == "-delete"

        i += 1
      end

      false
    end

    def env_truthy?(name)
      val = (ENV[name] || "").strip.downcase
      %w[1 true yes on].include?(val)
    end

    def env_falsy?(name)
      val = (ENV[name] || "").strip.downcase
      %w[0 false no off].include?(val)
    end

    def strict_mode?
      env_truthy?("SAFETY_NET_STRICT")
    end

    def paranoid_mode?
      env_truthy?("SAFETY_NET_PARANOID")
    end

    def paranoid_rm_mode?
      paranoid_mode? || env_truthy?("SAFETY_NET_PARANOID_RM")
    end

    def paranoid_interpreters_mode?
      paranoid_mode? || env_truthy?("SAFETY_NET_PARANOID_INTERPRETERS")
    end

    def allow_tmp_rm?
      !env_falsy?("SAFETY_NET_ALLOW_TMP_RM")
    end

    def normalize_cmd_token(token)
      tok = strip_token_wrappers(token)
      tok = tok.chomp(";")
      tok = tok.downcase
      File.basename(tok)
    end

    def extract_dash_c_arg(tokens)
      (1...tokens.length).each do |i|
        tok = tokens[i]
        return nil if tok == "--"

        if tok == "-c"
          return tokens[i + 1] if i + 1 < tokens.length

          return nil
        end

        if tok.start_with?("-") && tok.length > 1 && tok[1..].chars.all? { |c| c.match?(/[a-zA-Z]/) }
          letters = Set.new(tok[1..].chars)
          if letters.include?("c") && letters.subset?(Set.new(%w[c l i s]))
            return tokens[i + 1] if i + 1 < tokens.length

            return nil
          end
        end
      end
      nil
    end

    def has_shell_dash_c?(tokens)
      (1...tokens.length).each do |i|
        tok = tokens[i]
        break if tok == "--"

        return true if tok == "-c"

        if tok.start_with?("-") && tok.length > 1 && tok[1..].chars.all? { |c| c.match?(/[a-zA-Z]/) }
          letters = Set.new(tok[1..].chars)
          return true if letters.include?("c") && letters.subset?(Set.new(%w[c l i s]))
        end
      end
      false
    end

    def extract_pythonish_code_arg(tokens)
      (1...tokens.length).each do |i|
        tok = tokens[i]
        return nil if tok == "--"

        if ["-c", "-e"].include?(tok)
          return tokens[i + 1] if i + 1 < tokens.length

          return nil
        end
      end
      nil
    end

    def rm_has_recursive_force?(tokens)
      return false if tokens.empty?

      opts = []
      (tokens[1..] || []).each do |tok|
        break if tok == "--"

        opts << tok
      end

      opts_lower = opts.map(&:downcase)
      short = Shell.short_opts(opts)
      recursive = opts_lower.include?("--recursive") || short.include?("r") || short.include?("R")
      force = opts_lower.include?("--force") || short.include?("f")
      recursive && force
    end

    def extract_xargs_child_command(tokens)
      return nil if tokens.empty? || normalize_cmd_token(tokens[0]) != "xargs"

      i = 1
      while i < tokens.length
        tok = tokens[i]
        if tok == "--"
          i += 1
          break
        end
        break unless tok.start_with?("-")

        if XARGS_CONSUMES_VALUE.include?(tok)
          i += 2
          next
        end
        if tok.start_with?("--") && tok.include?("=")
          i += 1
          next
        end
        i += 1
      end

      return nil if i >= tokens.length

      tokens[i..]
    end

    def extract_parallel_child_command(tokens)
      return nil if tokens.empty? || normalize_cmd_token(tokens[0]) != "parallel"

      i = 1
      while i < tokens.length
        tok = tokens[i]
        if tok == "--"
          i += 1
          break
        end
        break unless tok.start_with?("-")

        if tok == ":::" || tok == "::::"
          return nil
        end
        if PARALLEL_CONSUMES_VALUE.include?(tok)
          i += 2
          next
        end
        if tok.start_with?("--") && tok.include?("=")
          i += 1
          next
        end
        i += 1
      end

      return nil if i >= tokens.length

      tokens[i..]
    end

    def analyze_segment(segment, depth:, cwd:, strict:, paranoid_rm:, paranoid_interpreters:, allow_tmp: true)
      return nil if depth > MAX_RECURSION_DEPTH

      tokens = Shell.shlex_split(segment)
      if tokens.nil?
        if strict
          return [segment, "Unparseable command#{STRICT_SUFFIX}"]
        end

        warn "Safety Net: unparseable segment (allowed due to non-strict mode)"
        return nil
      end

      tokens = Shell.strip_wrappers(tokens)
      return nil if tokens.empty?

      allow_tmpdir_var = true
      head = normalize_cmd_token(tokens[0])

      if SHELLS.include?(head)
        inner = extract_dash_c_arg(tokens)
        if inner
          result = analyze_command(
            inner,
            depth: depth + 1,
            cwd: cwd,
            strict: strict,
            paranoid_rm: paranoid_rm,
            paranoid_interpreters: paranoid_interpreters,
            allow_tmp: allow_tmp
          )
          return result if result
        end

        if has_shell_dash_c?(tokens) && !inner
          return [segment, "Unable to extract -c argument#{STRICT_SUFFIX}"] if strict

          return nil
        end
      end

      if INTERPRETERS.include?(head)
        code = extract_pythonish_code_arg(tokens)
        if code
          if paranoid_interpreters
            return [segment, REASON_INTERPRETER_ONE_LINER + PARANOID_INTERPRETERS_SUFFIX]
          end

          danger = dangerous_in_text(code)
          return [segment, danger] if danger
        end
      end

      if head == "xargs"
        child = extract_xargs_child_command(tokens)
        if child
          child_head = child.any? ? normalize_cmd_token(child[0]) : nil
          if child_head == "rm" && rm_has_recursive_force?(child)
            return [segment, REASON_XARGS_RM_RF]
          end
          if SHELLS.include?(child_head) && has_shell_dash_c?(child)
            return [segment, "xargs with shell -c can execute arbitrary commands."]
          end
        end
      end

      if head == "parallel"
        child = extract_parallel_child_command(tokens)
        if child
          child_head = child.any? ? normalize_cmd_token(child[0]) : nil
          if child_head == "rm" && rm_has_recursive_force?(child)
            return [segment, REASON_PARALLEL_RM_RF]
          end
          if SHELLS.include?(child_head) && has_shell_dash_c?(child)
            return [segment, "parallel with shell -c can execute arbitrary commands."]
          end
        end
      end

      if head == "git"
        reason = RulesGit.analyze_git(["git"] + (tokens[1..] || []))
        return [segment, reason] if reason
      end

      if head == "rm"
        reason = RulesRm.analyze_rm(
          ["rm"] + (tokens[1..] || []),
          allow_tmpdir_var: allow_tmpdir_var,
          allow_tmp: allow_tmp,
          cwd: cwd,
          paranoid: paranoid_rm
        )
        return [segment, reason] if reason
      end

      if head == "find" && find_has_delete?(tokens[1..] || [])
        return [segment, REASON_FIND_DELETE]
      end

      (1...tokens.length).each do |idx|
        cmd = normalize_cmd_token(tokens[idx])

        if cmd == "rm"
          reason = RulesRm.analyze_rm(
            ["rm"] + (tokens[(idx + 1)..] || []),
            allow_tmpdir_var: allow_tmpdir_var,
            allow_tmp: allow_tmp,
            cwd: cwd,
            paranoid: paranoid_rm
          )
          return [segment, reason] if reason
        end

        if cmd == "git"
          reason = RulesGit.analyze_git(["git"] + (tokens[(idx + 1)..] || []))
          return [segment, reason] if reason
        end

        if cmd == "find" && find_has_delete?(tokens[(idx + 1)..] || [])
          return [segment, REASON_FIND_DELETE]
        end
      end

      reason = dangerous_in_text(segment)
      return [segment, reason] if reason

      nil
    end

    def analyze_command(command, depth:, cwd:, strict:, paranoid_rm:, paranoid_interpreters:, allow_tmp: true)
      effective_cwd = cwd

      Shell.split_shell_commands(command).each do |segment|
        analyzed = analyze_segment(
          segment,
          depth: depth,
          cwd: effective_cwd,
          strict: strict,
          paranoid_rm: paranoid_rm,
          paranoid_interpreters: paranoid_interpreters,
          allow_tmp: allow_tmp
        )
        return analyzed if analyzed

        effective_cwd = nil if effective_cwd && segment_changes_cwd?(segment)
      end

      nil
    end

    def segment_changes_cwd?(segment)
      tokens = Shell.shlex_split(segment)
      if tokens
        tokens.shift while tokens.any? && ["{", "(", "$("].include?(tokens[0])
        tokens = Shell.strip_wrappers(tokens)
        tokens.shift if tokens.any? && tokens[0].downcase == "builtin"

        if tokens.any?
          return %w[cd pushd popd].include?(normalize_cmd_token(tokens[0]))
        end
      end

      segment.match?(/^\s*(?:\$\(\s*)?[({]*\s*(?:command\s+|builtin\s+)?(?:cd|pushd|popd)(?:\s|$)/i)
    end

    def redact_secrets(text)
      patterns = [
        /(password|passwd|pwd|secret|token|api[_-]?key|auth)[\s:=]+\S+/i,
        /bearer\s+\S+/i,
        /ghp_[a-zA-Z0-9]{36}/,
        /gho_[a-zA-Z0-9]{36}/,
        /github_pat_[a-zA-Z0-9]{22}_[a-zA-Z0-9]{59}/,
        /sk-[a-zA-Z0-9]{48}/,
        /xox[baprs]-[a-zA-Z0-9-]+/
      ]

      result = text
      patterns.each do |pattern|
        result = result.gsub(pattern, "[REDACTED]")
      end
      result
    end

    def format_block_message(command, segment, reason)
      safe_command = redact_secrets(command)[0, 300]
      safe_segment = redact_secrets(segment)[0, 300]

      <<~MSG
        Safety Net: BLOCKED

        Reason: #{reason}

        Command: #{safe_command}

        Segment: #{safe_segment}

        If this operation is truly needed, ask the user for explicit permission and have them run the command manually.
      MSG
    end

    def run
      tool_name = ENV["AGENT_TOOL_NAME"] || ""
      return 0 unless tool_name == "Bash"

      strict = strict_mode?
      paranoid_rm = paranoid_rm_mode?
      paranoid_interpreters = paranoid_interpreters_mode?
      allow_tmp = allow_tmp_rm?

      begin
        input_data = JSON.parse($stdin.read)
      rescue JSON::ParserError
        if strict
          warn "Safety Net: invalid JSON input"
          return 2
        end
        return 0
      end

      unless input_data.is_a?(Hash)
        if strict
          warn "Safety Net: invalid input structure"
          return 2
        end
        return 0
      end

      command = input_data["cmd"]
      return 0 unless command.is_a?(String) && !command.strip.empty?

      cwd_val = input_data["cwd"]
      if !cwd_val.nil? && !cwd_val.is_a?(String)
        if strict
          warn "Safety Net: invalid cwd type"
          return 2
        end
        cwd = nil
      else
        cwd = cwd_val
      end

      analyzed = analyze_command(
        command,
        depth: 0,
        cwd: cwd,
        strict: strict,
        paranoid_rm: paranoid_rm,
        paranoid_interpreters: paranoid_interpreters,
        allow_tmp: allow_tmp
      )

      if analyzed
        segment, reason = analyzed
        message = format_block_message(command, segment, reason)
        warn message
        return 2
      end

      0
    end
  end
end
