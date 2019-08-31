num = ARGV[0].to_i
if num.nil?
  raise StandardError "Nothing was input"
end

puts "  .global main"
puts "main:"
puts "  movq $#{num}, %rax"
puts "  ret"
