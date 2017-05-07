
#define S3C2440_MPLL_200MHZ     ((0x5c<<12)|(0x01<<4)|(0x02))
#define MEM_CTL_BASE    0x48000000

/* the red represents the variable is constant */
.text 
.global _start

_start:

/*1 close the whatch dog*/
	ldr r0, =0x53000000 /* the ldr instruction is Load addresses
						to a register using LDR Rd, =label
						as far as i know that the address is constant address.
						no  program-relative or register-relative
						http://infocenter.arm.com/help/index.jsp?topic=/com.arm.doc.dui0204j/Babcjaii.html
						*/
	mov r1, #0
	str r1, [r0]

/*2 set up the timer*/
	ldr r0, =0x4c000014
	mov r1, #0x03;            // FCLK:HCLK:PCLK=1:2:4, HDIVN=1,PDIVN=1
	str r1, [r0]

	/* 如果HDIVN非0，CPU的总线模式应该从“fast bus mode”变为“asynchronous bus mode” */
	mrc	p15, 0, r1, c1, c0, 0		/* 读出控制寄存器 */ 
	orr	r1, r1, #0xc0000000			/* 设置为“asynchronous bus mode” */
	mcr	p15, 0, r1, c1, c0, 0		/* 写入控制寄存器 */

	/* MPLLCON = S3C2440_MPLL_200MHZ */
	ldr r0, =0x4c000004
	ldr r1, =S3C2440_MPLL_200MHZ
	str r1, [r0]
	
/*3 initalise the sdram memory */
	ldr r0, =0x48000000 
						   /*ADR produces position-independent code,*/
	adr r1, sdram_config     /* the sdram_config address is program-relative address*/
	add r3, r0, #(13*4)	   /*because the address is program-relative or 
						   register-relative 
						    */
1:
	ldr r2,[r1],#4
	str r2,[r0],#4
	cmp r0,r3
	bne 1b

/*4 cope the nand's code to sdram and go on running the code*/
	ldr sp, =0x34000000

	bl nand_init

	mov r0, #0
	ldr r1, =_start
	ldr r2, =__bss_start
	sub r2, r2, r1
	
	bl copy_code_to_sdram
	bl clear_bss

	
/*5 preform/execute the main function */

  ldr lr, =halt
  ldr pc, =main
halt:
	b halt

sdram_config:
	.long 0x22011110	 //BWSCON
	.long 0x00000700	 //BANKCON0
	.long 0x00000700	 //BANKCON1
	.long 0x00000700	 //BANKCON2
	.long 0x00000700	 //BANKCON3  
	.long 0x00000700	 //BANKCON4
	.long 0x00000700	 //BANKCON5
	.long 0x00018005	 //BANKCON6
	.long 0x00018005	 //BANKCON7
	.long 0x008C04F4	 // REFRESH
	.long 0x000000B1	 //BANKSIZE
	.long 0x00000030	 //MRSRB6
	.long 0x00000030	 //MRSRB7


