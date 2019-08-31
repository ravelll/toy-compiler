num = ARGV[0].to_i
if num.nil?
  raise StandardError "Nothing was input"
end

source = []
source_index = 0

def get_char
  if source_index == source.size
    return nil
  end

  char = source[source_index]
  source_index += 1
  char
end

def unget_char
  source_index -= 1
end

puts "  .global main"
puts "main:"
puts "  movq $#{num}, %rax"
puts "  ret"
