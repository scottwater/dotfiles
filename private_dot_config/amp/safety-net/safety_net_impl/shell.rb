# frozen_string_literal: true

require "shellwords"

module SafetyNetImpl
  module Shell
    module_function

    def split_shell_commands(command)
      parts = []
      buf = []
      in_single = false
      in_double = false
      escape = false

      i = 0
      while i < command.length
        ch = command[i]

        if escape
          buf << ch
          escape = false
          i += 1
          next
        end

        if ch == "\\" && !in_single
          buf << ch
          escape = true
          i += 1
          next
        end

        if ch == "'" && !in_double
          in_single = !in_single
          buf << ch
          i += 1
          next
        end

        if ch == '"' && !in_single
          in_double = !in_double
          buf << ch
          i += 1
          next
        end

        if !in_single && !in_double
          if command[i, 2] == "&&" || command[i, 2] == "||"
            part = buf.join.strip
            parts << part unless part.empty?
            buf = []
            i += 2
            next
          end

          if command[i, 2] == "|&"
            part = buf.join.strip
            parts << part unless part.empty?
            buf = []
            i += 2
            next
          end

          if ch == "|"
            part = buf.join.strip
            parts << part unless part.empty?
            buf = []
            i += 1
            next
          end

          if ch == "&"
            prev = i > 0 ? command[i - 1] : ""
            nxt = i + 1 < command.length ? command[i + 1] : ""
            if [">", "<"].include?(prev) || nxt == ">"
              buf << ch
              i += 1
              next
            end

            part = buf.join.strip
            parts << part unless part.empty?
            buf = []
            i += 1
            next
          end

          if ch == ";" || ch == "\n"
            part = buf.join.strip
            parts << part unless part.empty?
            buf = []
            i += 1
            next
          end
        end

        buf << ch
        i += 1
      end

      part = buf.join.strip
      parts << part unless part.empty?
      parts
    end

    def shlex_split(segment)
      Shellwords.split(segment)
    rescue ArgumentError
      nil
    end

    def strip_env_assignments(tokens)
      i = 0
      while i < tokens.length
        tok = tokens[i]
        break unless tok.include?("=")

        key, _value = tok.split("=", 2)
        break if key.nil? || key.empty?
        break unless key[0].match?(/[a-zA-Z_]/)
        break unless key[1..].chars.all? { |c| c.match?(/[a-zA-Z0-9_]/) }

        i += 1
      end
      tokens[i..] || []
    end

    def strip_wrappers(tokens)
      previous = nil
      depth = 0

      while tokens.any? && tokens != previous && depth < 20
        previous = tokens.dup
        depth += 1

        tokens = strip_env_assignments(tokens)
        return tokens if tokens.empty?

        head = tokens[0].downcase

        if head == "sudo"
          i = 1
          while i < tokens.length && tokens[i].start_with?("-") && tokens[i] != "--"
            i += 1
          end
          i += 1 if i < tokens.length && tokens[i] == "--"
          tokens = tokens[i..] || []
          next
        end

        if head == "env"
          i = 1
          while i < tokens.length
            tok = tokens[i]
            if tok == "--"
              i += 1
              break
            end
            if ["-u", "--unset", "-C", "-P", "-S"].include?(tok)
              i += 2
              next
            end
            if tok.start_with?("--unset=")
              i += 1
              next
            end
            if tok.start_with?("-u") && tok.length > 2
              i += 1
              next
            end
            if tok.start_with?("-C") && tok.length > 2
              i += 1
              next
            end
            if tok.start_with?("-P") && tok.length > 2
              i += 1
              next
            end
            if tok.start_with?("-S") && tok.length > 2
              i += 1
              next
            end
            if tok.start_with?("-") && tok != "-"
              i += 1
              next
            end
            break
          end

          tokens = tokens[i..] || []
          next
        end

        if head == "command"
          i = 1
          while i < tokens.length
            tok = tokens[i]
            if tok == "--"
              i += 1
              break
            end
            if ["-p", "-v", "-V"].include?(tok)
              i += 1
              next
            end
            if tok.start_with?("-") && tok != "-" && !tok.start_with?("--")
              chars = tok[1..]
              if chars && !chars.empty? && chars.chars.all? { |c| ["p", "v", "V"].include?(c) }
                i += 1
                next
              end
            end
            break
          end

          tokens = tokens[i..] || []
          next
        end

        break
      end

      strip_env_assignments(tokens)
    end

    def short_opts(tokens)
      opts = Set.new
      tokens.each do |tok|
        next if tok.start_with?("--") || !tok.start_with?("-") || tok == "-"

        opts.merge(tok[1..].chars)
      end
      opts
    end
  end
end
