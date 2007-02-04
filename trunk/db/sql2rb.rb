#!/usr/local/bin/ruby
####################################################################
#
# sql2rb.rb
# @authors levpopov@mit.edu
# Script converting sql batch file into rails migration format
#
###################################################################

in_statement = false
while line = STDIN.gets
	ls = line.strip
	if ls == ''
		puts ''
		next
	end
	
	if ls[0..1]=='--' #comment
		puts (in_statement ? '	':' ')+'	#'+line.strip[2..-1]
		next
	end 
	
	
	eos = false
	if ls[-1..-1]==';' #end of statement
		eos = true
		ls = ls[0..-2] #kill the ;
	end
	
	if in_statement
		if eos
			in_statement = false
		end
		puts '		"'+ls+(eos ? '"':'" +')
	else #new statement
		puts '	execute "'+ls+(eos ? '"':'" +')
		in_statement = true unless eos
	end
end