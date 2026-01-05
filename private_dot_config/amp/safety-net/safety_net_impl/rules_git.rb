# frozen_string_literal: true

require "set"
require_relative "shell"

module SafetyNetImpl
  module RulesGit
    REASON_GIT_CHECKOUT_DOUBLE_DASH = "git checkout -- discards uncommitted changes permanently. Use 'git stash' first."
    REASON_GIT_CHECKOUT_REF_DOUBLE_DASH = "git checkout <ref> -- <path> overwrites working tree. Use 'git stash' first."
    REASON_GIT_CHECKOUT_REF_PATHSPEC = "git checkout <ref> <path> overwrites working tree. Use 'git stash' first."
    REASON_GIT_CHECKOUT_PATHSPEC_FROM_FILE = "git checkout --pathspec-from-file overwrites working tree. Use 'git stash' first."
    REASON_GIT_RESTORE = "git restore discards uncommitted changes. Use 'git stash' or 'git diff' first."
    REASON_GIT_RESTORE_WORKTREE = "git restore --worktree discards uncommitted changes permanently."
    REASON_GIT_RESET_HARD = "git reset --hard destroys uncommitted changes. Use 'git stash' first."
    REASON_GIT_RESET_MERGE = "git reset --merge can lose uncommitted changes."
    REASON_GIT_CLEAN_FORCE = "git clean -f removes untracked files permanently. Review with 'git clean -n' first."
    REASON_GIT_PUSH_FORCE = "Force push can destroy remote history. Use --force-with-lease if necessary."
    REASON_GIT_WORKTREE_REMOVE_FORCE = "git worktree remove --force can delete worktree files. Verify the path first."
    REASON_GIT_BRANCH_DELETE_FORCE = "git branch -D force-deletes without merge check. Use -d for safety."
    REASON_GIT_STASH_DROP = "git stash drop permanently deletes stashed changes. List stashes first with 'git stash list'."
    REASON_GIT_STASH_CLEAR = "git stash clear permanently deletes ALL stashed changes."

    GIT_OPTS_WITH_VALUE = Set.new(%w[-c -C --exec-path --git-dir --namespace --super-prefix --work-tree]).freeze
    GIT_OPTS_NO_VALUE = Set.new(%w[-p -P -h --help --no-pager --paginate --version --bare
      --no-replace-objects --literal-pathspecs --noglob-pathspecs --icase-pathspecs]).freeze

    CHECKOUT_OPTS_WITH_VALUE = Set.new(%w[-b -B --orphan --conflict -U --unified --inter-hunk-context --pathspec-from-file]).freeze
    CHECKOUT_OPTS_NO_VALUE = Set.new(%w[-f --force -m --merge -q --quiet --detach --ignore-skip-worktree-bits
      --overwrite-ignore --no-overlay --overlay --progress --no-progress --guess --no-guess --pathspec-file-nul]).freeze

    module_function

    def analyze_git(tokens)
      sub, rest = git_subcommand_and_rest(tokens)
      return nil unless sub

      sub = sub.downcase
      rest_lower = rest.map(&:downcase)
      short = Shell.short_opts(rest)

      case sub
      when "checkout"
        analyze_checkout(rest, rest_lower, short)
      when "restore"
        analyze_restore(rest_lower)
      when "reset"
        analyze_reset(rest_lower)
      when "clean"
        analyze_clean(rest_lower, short)
      when "push"
        analyze_push(rest_lower, short)
      when "worktree"
        analyze_worktree(rest, rest_lower)
      when "branch"
        analyze_branch(rest, short)
      when "stash"
        analyze_stash(rest_lower)
      end
    end

    def analyze_checkout(rest, rest_lower, short)
      if rest.include?("--")
        idx = rest.index("--")
        return idx.zero? ? REASON_GIT_CHECKOUT_DOUBLE_DASH : REASON_GIT_CHECKOUT_REF_DOUBLE_DASH
      end

      return nil if rest.include?("-b") || short.include?("b")
      return nil if rest.include?("-B") || short.include?("B")
      return nil if rest_lower.include?("--orphan")

      has_pathspec_from_file = rest_lower.any? do |t|
        t == "--pathspec-from-file" || t.start_with?("--pathspec-from-file=")
      end
      return REASON_GIT_CHECKOUT_PATHSPEC_FROM_FILE if has_pathspec_from_file

      positional = checkout_positional_args(rest)
      return REASON_GIT_CHECKOUT_REF_PATHSPEC if positional.length >= 2

      nil
    end

    def analyze_restore(rest_lower)
      return nil if rest_lower.include?("-h") || rest_lower.include?("--help") || rest_lower.include?("--version")
      return REASON_GIT_RESTORE_WORKTREE if rest_lower.include?("--worktree")
      return nil if rest_lower.include?("--staged")

      REASON_GIT_RESTORE
    end

    def analyze_reset(rest_lower)
      return REASON_GIT_RESET_HARD if rest_lower.include?("--hard")
      return REASON_GIT_RESET_MERGE if rest_lower.include?("--merge")

      nil
    end

    def analyze_clean(rest_lower, short)
      has_force = rest_lower.include?("--force") || short.include?("f")
      return REASON_GIT_CLEAN_FORCE if has_force

      nil
    end

    def analyze_push(rest_lower, short)
      has_force_with_lease = rest_lower.any? { |t| t.start_with?("--force-with-lease") }
      has_force = rest_lower.include?("--force") || short.include?("f")

      return REASON_GIT_PUSH_FORCE if has_force && !has_force_with_lease
      return REASON_GIT_PUSH_FORCE if rest_lower.include?("--force") && has_force_with_lease
      return REASON_GIT_PUSH_FORCE if short.include?("f") && has_force_with_lease

      nil
    end

    def analyze_worktree(rest, rest_lower)
      return nil if rest_lower.empty?
      return nil unless rest_lower[0] == "remove"

      rest_for_opts = rest.dup
      if rest_for_opts.include?("--")
        rest_for_opts = rest_for_opts[0...rest_for_opts.index("--")]
      end

      rest_for_opts_lower = rest_for_opts.map(&:downcase)
      short_for_opts = Shell.short_opts(rest_for_opts)
      has_force = rest_for_opts_lower.include?("--force") || short_for_opts.include?("f")

      return REASON_GIT_WORKTREE_REMOVE_FORCE if has_force

      nil
    end

    def analyze_branch(rest, short)
      return REASON_GIT_BRANCH_DELETE_FORCE if rest.include?("-D") || short.include?("D")

      nil
    end

    def analyze_stash(rest_lower)
      return nil if rest_lower.empty?
      return REASON_GIT_STASH_DROP if rest_lower[0] == "drop"
      return REASON_GIT_STASH_CLEAR if rest_lower[0] == "clear"

      nil
    end

    def git_subcommand_and_rest(tokens)
      return [nil, []] if tokens.empty? || tokens[0].downcase != "git"

      i = 1
      while i < tokens.length
        tok = tokens[i]
        if tok == "--"
          i += 1
          break
        end

        if !tok.start_with?("-") || tok == "-"
          break
        end

        if GIT_OPTS_NO_VALUE.include?(tok)
          i += 1
          next
        end

        if GIT_OPTS_WITH_VALUE.include?(tok)
          i += 2
          next
        end

        if tok.start_with?("--")
          if tok.include?("=")
            opt, _value = tok.split("=", 2)
            if GIT_OPTS_WITH_VALUE.include?(opt)
              i += 1
              next
            end
          end
          i += 1
          next
        end

        if tok.start_with?("-C") && tok.length > 2
          i += 1
          next
        end
        if tok.start_with?("-c") && tok.length > 2
          i += 1
          next
        end

        i += 1
      end

      return [nil, []] if i >= tokens.length

      [tokens[i], tokens[(i + 1)..] || []]
    end

    def checkout_positional_args(rest)
      positionals = []
      i = 0

      while i < rest.length
        tok = rest[i]
        break if tok == "--"

        if tok == "-"
          positionals << tok
          i += 1
          next
        end

        if tok.start_with?("-")
          if CHECKOUT_OPTS_NO_VALUE.include?(tok)
            i += 1
            next
          end

          if tok.start_with?("--") && tok.include?("=")
            opt, _value = tok.split("=", 2)
            if CHECKOUT_OPTS_WITH_VALUE.include?(opt)
              i += 1
              next
            end
            i += 1
            next
          end

          if tok.start_with?("-U") && tok.length > 2
            i += 1
            next
          end
          if tok.start_with?("-b") && tok.length > 2
            i += 1
            next
          end
          if tok.start_with?("-B") && tok.length > 2
            i += 1
            next
          end

          if CHECKOUT_OPTS_WITH_VALUE.include?(tok)
            i += 2
            next
          end

          if tok == "--recurse-submodules"
            if i + 1 < rest.length && %w[checkout on-demand].include?(rest[i + 1])
              i += 2
              next
            end
            i += 1
            next
          end

          if ["-t", "--track"].include?(tok)
            if i + 1 < rest.length && %w[direct inherit].include?(rest[i + 1])
              i += 2
              next
            end
            i += 1
            next
          end

          if tok.start_with?("--")
            if i + 1 < rest.length && !rest[i + 1].start_with?("-")
              i += 2
              next
            end
            i += 1
            next
          end

          i += 1
          next
        end

        positionals << tok
        i += 1
      end

      positionals
    end
  end
end
