.data
msg_prompt:      .asciz "Enter a message of 9 to 15 words in the form of a string of characters: "
msg_seed:        .asciz "Enter a number (seed): "
msg_scrambled:   .asciz "Scrambled Output: "
msg_descrambled: .asciz "Descrambled Output: "
msg_invString:   .asciz "Message should contain 9 to 15 words! "
msg_invSeed:     .asciz "Seed should be strictly positive! "
msg_wc:           .asciz "Word Count: "


message:       .space 200
.align 2
word_pointers: .space 60
.align 2
swap_indices:  .space 60


.text
.global main 
.global random_num_gen

j main

# This function is used to generate random numbers, used to swap the words randomly
random_num_gen:
	lui x13, 0xFFFF
	srli x13, x13, 12
	bgt x9, x13, rng_done
	
	srli x10, x9, 15
	srli x11, x9, 11
	xor  x10, x10, x11
	
	srli x11, x9, 2
	xor x11, x9, x11
	
	xor x11, x11, x10
	andi x11, x11, 1
	
	slli x9, x9, 1
	
	li x13, 0xffff
	and x9, x13, x9 
	
	or x9, x9, x11
	
	rng_done:
		ret

main:
	# SECTION 1: Taking input from the user
	
	# Here, we will read the input string from the user
	li a7, 4
	la a0, msg_prompt
	ecall
	
	li a7, 8 
	la a0, message
	li a1, 200
	ecall # the input string adress starts at "message"
	
	# Here, we will tread the input number (seed) from the user
	li a7, 4
	la a0, msg_seed
	ecall
	
	li a7, 5
	ecall
	mv s0, a0   # the seed is stored in s0
	
	
	
	# SECTION 2: Checking input validity ( word count & seed value)
	
	# Part 1: SEED value   
	bgtz s0, word_Count  # if the seed value is not positive, then it is invalid
	
	invalid_seedValue:
		li a7, 4
		la a0, msg_invSeed
		ecall
		
		li a7, 10
		ecall
		
	# Part 2: Word Count
	
	#Step 1: we will count the number of words in the string provided
	word_Count:
		la t0, message  #t0 is a pointer to the input string
		li t2, 0        #t2 is a counter to the number of words in the string
		li t3, 0        #t3 determines wether we are inside or outside a word
		
		loop_wordCount:
			lbu t1, 0(t0)                #t1 contains the loaded character
			beqz t1, done_wordCount      #if character = '\0', then we are done with the string
			
			li t4, 10 
			beq t1,t4,done_wordCount     # if character ='\n', then we are done with the string
			
			li t4, 32
			beq t1, t4, wordEnd          #if character =' ', then we are done with the word
			
			beq t3, x0, newWord          #if we were outside the word, we are again inside
			
			j nextChar
			
			newWord:  #if we enter a new word: t3 is set to 1 & word count is incremented.
				addi t2, t2, 1
				li t3, 1
				j nextChar
				
			wordEnd:  #if we exit a word, t3 is set t0 0.
				li t3, 0 
				j nextChar
			
			nextChar: #we move on to the next character by incrementing the pointer t0.
				addi t0, t0, 1
				j loop_wordCount
		
		done_wordCount: #When we are done witht the word count, we check that the string is valid (word count should be between 9 and 15)
			li t3, 9 
			li t4, 15
			
			blt t2, t3, invalid_wordCount
			bgt t2, t4, invalid_wordCount
			
			j valid_wordCount
			
		invalid_wordCount: #if word count is not valid, we terminate the program with an error message.
			li a7, 4
			la a0, msg_invString
			ecall
			
			li a7, 10 
			ecall
			
		valid_wordCount: #if word count is valid, we print word count, and continue the program.
			li a7, 4
			la a0, msg_wc
			ecall
			
			li a7, 1
			mv a0, t2
			ecall
			
			li a7, 11
			li a0, 10 
			ecall 
			
	#SECTION 3: Splitting string into different words to be scrambled
		
	split_string:
		la t0, message        #t0 is a pointer to the input string
		la t5, word_pointers  #t5 is a pointer to the array where we store the address of the word start
		
		li t3, 0              #t3 indicates wether we are inside or outside a word, just like the wordcount
		
		loop_split:
			lbu t1, 0(t0)              #we load the character from the string in t1
			
			beqz t1, done_split        #if the character is '/0', we are done with the string
			
			li t4, 10
			beq t1, t4, split_newLine  #if the character is a new line, then the input has ended
			
			li t4, 32
			beq t1, t4, split_space    #if we reach a space, then the word has ended
			
			beq t3, x0, store_word     #since we reached here, then we are inside a new word, so we must update t3 to 1.
			
			j split_next               #continue scanning the input
		
			
			split_newLine: #replace '\n' with '\0' for consistency
				sb x0, 0(t0)
				j done_split
			
			store_word:    #store the address of the beginning of the word in the pointers, then move on to the next slot, and mark that we are inside a word
				sw t0, 0(t5)
				addi t5, t5, 4
				li t3, 1
				j split_next
				
			split_space:   #replace ' ' with '\0' to separate words ; and mark that we are outside a word.
				sb x0, 0(t0)
				li t3, 0 
				j split_next
				
			split_next:    #move to the next character in the string
				addi t0, t0, 1
				j loop_split
			
	done_split:
		
	# SECTION 4: GENERATING RANDOM NUMBERS AND SCRAMBLING THE WORDS
	
	mv x9, s0    # setting input argument to the rng 
	li t0, 0     # loop index
	
		loop_scrambling:
			bge t0, t2, done_scrambling  #if we exceeded the word count, then we are done
			  
			jal random_num_gen           # generate random number 
			rem t1, x9, t2               # index j should be between 0 and word_count -1
			
			#Here, we store the random index j in swap_index[i], because we will use it later for descrambling
			la s1, swap_indices
			slli s2, t0, 2 
			add s3, s1, s2
			sw t1, 0(s3)
			
			#Here, we are computing the adress of the word_pointer[i]
			la t3, word_pointers
			slli t4, t0, 2
			add t5, t3, t4
			
			#Here, we are computing the address of the word_pointer[j]
			slli t4, t1, 2
			add t6, t4, t3
			
			#Here, we swap the two word pointers
			lw a0, 0(t5)
			lw a1, 0(t6)
			
			sw a1, 0(t5)
			sw a0, 0(t6)
			
			addi t0, t0, 1
			j loop_scrambling
		
		done_scrambling: # We are done scrambling so we need to print the scrambled word
			li a7, 4 
			la a0, msg_scrambled
			ecall
			
			la t5, word_pointers  # pointer to the first scrambled word
			li t6, 0              # word counter
			 
			print_scrambled:	
				bge t6, t2, done_print_scrambled   # all the words are printed so we stop
				
				lw a0, 0(t5)
				li a7, 4
				ecall
				
				li a7, 11
				li a0, 32
				ecall
				
				addi t5, t5, 4   # we are moving to the next pointer
				addi t6, t6, 1   # we increment the word counter
				j print_scrambled
			
			done_print_scrambled:  # we print a new line and move on to the descrambling part
				li a7, 11
				li a0, 10
				ecall
	
	# SECTION 5: DESCRAMBLING SECTION
	
	addi t0, t2, -1    #t0 here represents the word_count -1, so that we will begin starting from the last swap we did 
	
	loop_descramble:
		blt t0, x0, done_descramble   #if i becomes negative, then we did all the swaps so we are done
		
		#Here, we load j = swap_indices[i], so it represents the index used during scrambling
		la s1, swap_indices
		slli s2, t0, 2
		add s3, s1, s2
		lw t1, 0(s3)
		
		la t3, word_pointers
		
		#Here, we compute the address of word_pointers[i]
		slli t4, t0, 2
		add t5, t3, t4
		
		#Here, we compute the address of word_pointers[j]
		slli t4, t1, 2
		add t6, t3, t4
		
		#Here, we swap word_pointers[i] and word_pointers[j] to reverse the scrambling step we did earlier
		lw a0, 0(t5)
		lw a1, 0(t6)
		
		sw a1, 0(t5)
		sw a0, 0(t6)
		
		addi t0, t0, -1
		j loop_descramble
	
	done_descramble: # Since we are done with descrambling, we print the descrambled output
		li a7, 4
		la a0, msg_descrambled
		ecall
		
		la t5, word_pointers
		li t6, 0  #t6 is tracking the number of words printed
		
		print_descrambled: 
			bge t6, t2, done_print_descrambled  #if all the words are printed then we are done
			
			lw a0, 0(t5)
			li a7, 4
			ecall   # print the word
			
			li a7, 11
			li a0, 32
			ecall  # print a space
			
			addi t5, t5, 4  # we increment the pointer t5, so are moving on to a new word
			addi t6, t6, 1  # we increment the printed word tracker
			j print_descrambled
			
		
		done_print_descrambled:
			li a7, 10    # we are done with everything so we now exit the program.
			ecall  
		
		
	
	