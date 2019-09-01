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
          print " '#{token.value}'"
        when ";", "+", "-", "*", "/"
          token = Token.new(kind: "punct", value: char)
          @tokens = @tokens << token
          print " '#{token.value}'"
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
          raise StandardError, "generator_expr: Unknown unary expr.operator: #{expr.operator}"
        end
      when "binary"
        puts "  movq $#{expr.left.intval}, %rax"
        puts "  movq $#{expr.right.intval}, %rcx"

        case expr.operator
        when "+"
          puts "  addq %rcx, %rax"
        when "-"
          puts "  subq %rcx, %rax"
        when "*"
          puts "  imulq %rcx, %rax"
        when "/"
          puts "  movq $0, %rdx"
          puts "  idiv %rcx"
        else
          raise StandardError, "generator_expr: Unknown binary expr.operator: #{expr.operator}"
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
      expr = parse_unary_expr

      loop do
        token = get_token

        if token == nil || token.value == ";"
          return expr
        end

        case token.value
        when "+", "-", "*", "/"
          left = expr
          right = parse_unary_expr

          return Expr.new(
            kind: "binary",
            operator: token.value,
            left: left,
            right: right
          )
        else
          return expr
        end
      end
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
        raise StandardError, "Token#new: Invalid token kind: #{kind}"
      end

      @kind = kind
      @value = value
    end
  end

  class Expr
    attr_accessor :kind, :intval, :operator, :operand, :left, :right

    def initialize(kind:, intval: nil, operator: nil, operand: nil, left: nil, right: nil)
      if !["literal_int", "unary", "binary"].include? kind
        raise StandardError, "Expr#new: Invalid token kind: #{kind}"
      end

      @kind = kind
      @intval = intval
      @operator = operator # "+", "-"
      @operand = operand   # for unary expression
      @left = left         # for binary expression
      @right = right       # for binary expression
    end
  end
end

source = ARGV[0]
if source.nil?
  raise StandardError, "Nothing was input"
end

Compiler::Runner.new(source).run
