# generate refraction_rules.rb

  init_dir = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "config", "initializers"))
  if test(?d, init_dir)
    rules_file = File.join(init_dir, "refraction_rules.rb")
    unless File.exists?(rules_file)
      File.open(rules_file, "w") do |f|
      f.puts(<<'EOF')
Refraction.configure do |req|
  # req.permanent! "http://example.com/"
end
EOF
puts "Generated starter rules file in #{rules_file}"
      end
    end
  end

puts ""
puts "Make sure to add Refraction to your middleware stack in your production environment:"
puts '  config.middleware.insert_before(::Rack::Lock, ::Refraction, {})'
puts ""
