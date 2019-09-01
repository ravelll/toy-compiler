class Compiler
  class Runner
    def initialize(source)
      @source = source
      @source_index = 0
      @tokens = []
      @token_index = 0
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

    def get_token
      if @token_index == @tokens.size
        return nil
      end

      token = @tokens[@token_index]
      @token_index += 1
      token
    end

    def tokenize
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
          @tokens = @tokens << token
          print " #{token.value}"
        when ";", "+", "-"
          token = Token.new(kind: "punct", value: char)
          @tokens = @tokens << token
          print " #{token.value}"
        else
          raise StandardError, "Tokenizer: Invalid char: '#{char}'"
        end
      end

      print "\n"
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

    def generate_expr(expr)
      case expr.kind
      when "literal_int"
        puts "  movq $#{expr.intval}, %rax"
      when "unary"
        case expr.operator
        when "+"
          puts "  movq $#{expr.operand.intval}, %rax"
        when "-"
          puts "  movq $-#{expr.operand.intval}, %rax"
        else
          raise StandardError, "generator_expr: Unknown expr.operator: #{expr.operator}"
        end
      else
        raise StandardError, "generator_expr: Unknown expr.kind: #{expr.kind}"
      end
    end

    def generate_code(expr)
      puts "  .global main"
      puts "main:"
      generate_expr(expr)
      puts "  ret"
    end

    def parse_unary_expr
      token = get_token

      case token.kind
      when "literal_int"
        Expr.new(kind: "literal_int", intval: token.value)
      when "punct"
        operand = parse_unary_expr
        Expr.new(kind: "unary", operator: token.value, operand: operand)
      else
        nil
      end
    end

    def parse
      parse_unary_expr
    end

    def run
      tokenize

      expr = parse
      generate_code(expr)
    end
  end

  class Token
    attr_accessor :kind, :value

    def initialize(kind:, value:)
      if !["literal_int", "punct"].include? kind
        raise StandardError, "Token#new: Invalid token kind"
      end

      @kind = kind
      @value = value
    end
  end

  class Expr
    attr_accessor :kind, :intval, :operator, :operand

    def initialize(kind:, intval: nil, operator: nil, operand: nil)
      @kind = kind
      @intval = intval
      @operator = operator # "+", "-"
      @operand = operand # for unary expression
    end
  end
end

source = ARGV[0]
if source.nil?
  raise StandardError, "Nothing was input"
end

Compiler::Runner.new(source).run
