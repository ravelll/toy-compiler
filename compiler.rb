class Compiler
  class Runner
    def initialize(source)
      @source = source
      @source_index = 0
    end

    def read_number(char)
      number_chars = [char]
      loop do
        char = get_char
        break unless char

        if '0' <= char && char <= '9'
          number_chars << char
        else
          unget_char
          break
        end
      end

      number_chars.join
    end

    def tokenize
      tokens = []
      print "# Tokens :"

      loop do
        char = get_char
        break unless char

        case char
        when " ", "\t", "\n"
          next
        when "0".."9"
          literal_int = read_number(char)
          token = Token.new(kind: "literal_int", value: literal_int)
          tokens = tokens << token
          print token.value
        else
          raise StandardError, "Tokenizer: Invalid char: '#{char}'"
        end
      end

      print "\n"
      tokens
    end

    def get_char
      if @source_index == @source.size
        return nil
      end

      char = @source[@source_index]
      @source_index += 1
      char
    end

    def unget_char
      @source_index -= 1
    end

    def run
      tokens = tokenize
      num = tokens[0].value

      puts "  .global main"
      puts "main:"
      puts "  movq $#{num}, %rax"
      puts "  ret"
    end
  end

  class Token
    def initialize(kind:, value:)
      @kind = kind
      @value = value
    end

    attr_accessor :kind, :value
  end
end

source = ARGV[0]
if source.nil?
  raise StandardError, "Nothing was input"
end

Compiler::Runner.new(source).run
