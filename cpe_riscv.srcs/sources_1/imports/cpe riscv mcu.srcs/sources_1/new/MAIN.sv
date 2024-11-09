`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: Cameron Young and Jack Marshall
// Module Name: OTTER_MCU
// Target Devices: Basys 3 Board
// Description:
// limited version of the RISC-V OTTER MCU which can perform a subset of the instructions
//////////////////////////////////////////////////////////////////////////////////


module OTTER_MCU(
    input RST,
    input INTR,
    input [31:0] IOBUS_IN,
    input CLK,
    output IOBUS_WR,
    output [31:0] IOBUS_OUT,
    output [31:0] IOBUS_ADDR
    );
   
    // MUX and PC Wires
    wire [31:0] BAG_JALR, BAG_BRANCH, BAG_JAL, MUX_OUT, PC;  
    wire [2:0] PC_SEL;
    wire PC_WE;
    wire reset;
   
    // Memory Module Wires
    wire [31:0] REG_RS2;
    wire [31:0] ALU_OUT;
    wire memRDEN1, memRDEN2, memWE2;
    wire [31:0] ir;
    wire [31:0] MEMORY_DOUT2;
    
    // Reg file mux wires
    wire [31:0] REG_MUX_OUT;
    wire [1:0]  RF_SEL;
    wire [31:0] csr_RD;
    
    // Reg file wires
    wire RF_WE;
    wire [31:0] REG_RS1;
 
    //define I/O output from Reg file
    assign IOBUS_OUT = REG_RS2;
    
    // ALU wires
    wire [1:0] srcA_SEL;
    wire [31:0] IG_UTYPE;
    wire [31:0] ALU_srcA;
    wire [2:0] srcB_SEL;
    wire [31:0] IG_ITYPE;
    wire [31:0] IG_STYPE;
    wire [31:0] ALU_srcB;
    wire [3:0] ALU_FUN;
    reg [31:0] RESULT;
    assign ALU_OUT = RESULT;
    
    //define inputs signals for ALU
    wire [31:0] OP1, OP2;
    assign OP1 = ALU_srcA;
    assign OP2 = ALU_srcB;
    assign IOBUS_ADDR = ALU_OUT;
            
    // Immediate generator wires
    wire [31:0] IG_JTYPE;
    wire [31:0] IG_BTYPE;
   
    //Immediate Generator 
    assign IG_UTYPE = {ir[31:12], 12'h000};
    assign IG_ITYPE = {{21{ir[31]}}, ir[30:25], ir[24:20]};
    assign IG_STYPE = {{21{ir[31]}}, ir[30:25], ir[11:7]};
    assign IG_JTYPE = {{12{ir[31]}}, ir[19:12], ir[20], ir[30:21], 1'b0};
    assign IG_BTYPE = {{20{ir[31]}}, ir[7], ir[30:25], ir[11:8], 1'b0};  

    //Branch Address Generator
    assign BAG_JAL = (PC) + IG_JTYPE;
    assign BAG_BRANCH = (PC) + IG_BTYPE;
    assign BAG_JALR = REG_RS1 + IG_ITYPE;
   
    // CSR module
    wire CSR_mstatus;
    wire INT_taken;   
    wire mret_EXEC;
    wire csr_WE;
    wire [31:0] mepc, mtvec;
     
    // branch conditional generator module wires
    wire BR_EQ;
    wire BR_LT;
    wire BR_LTU;
   
   
    // PC instantiation
    reg_nb_sclr #(.n(32)) OTTER_PC ( // PC
        .data_in  (MUX_OUT),
        .ld       (PC_WE),
        .clk      (CLK),
        .clr      (reset),
        .data_out (PC)
    );  
  
    
    // PC Load MUX
    mux_8t1_nb #(.n(32)) PC_MUX(
        .SEL   (PC_SEL),
        .D0    (PC+4), //next instruction address
        .D1    (BAG_JALR), // jalr address
        .D2    (BAG_BRANCH), // branch address
        .D3    (BAG_JAL), // jal address
        .D4    (mtvec),
        .D5    (mepc),
        .D6(),
        .D7(),
        .D_OUT (MUX_OUT)
    );
   
   
   // Memory Module Instantiation
   Memory OTTER_MEMORY (
       .MEM_CLK   (CLK),
       .MEM_RDEN1 (memRDEN1),
       .MEM_RDEN2 (memRDEN2),
       .MEM_WE2   (memWE2),
       .MEM_ADDR1 (PC [15:2]),  // 14-bit signal
       .MEM_ADDR2 (ALU_OUT),
       .MEM_DIN2  (REG_RS2),  
       .MEM_SIZE  (ir [13:12]),
       .MEM_SIGN  (ir [14]),
       .IO_IN     (IOBUS_IN),
       .IO_WR     (IOBUS_WR),
       .MEM_DOUT1 (ir),
       .MEM_DOUT2 (MEMORY_DOUT2)  
   );
     
 
    // Reg file mux instantiation
    mux_4t1_nb  #(.n(32)) REG_MUX  ( 
        .SEL   (RF_SEL),
        .D0    (PC + 4), 
        .D1    (csr_RD),    // CSR reg - not yet implemented
        .D2    (MEMORY_DOUT2), 
        .D3    (ALU_OUT),    
        .D_OUT (REG_MUX_OUT)
    );  
   
  
    // REG FILE  instantiation  
    RegFile OTTER_regfile (
        .w_data (REG_MUX_OUT),
        .clk    (CLK),
        .en     (RF_WE),
        .adr1   (ir [19:15]),
        .adr2   (ir [24:20]),
        .w_adr  (ir [11:7]),
        .rs1    (REG_RS1),
        .rs2    (REG_RS2)  
    );


    // ALU source A Mux instantiation
    mux_4t1_nb #(.n(32)) MUX_A(
        .SEL   (srcA_SEL),
        .D0    (REG_RS1),
        .D1    (IG_UTYPE),
        .D2    (~REG_RS1),
        .D3    (0),
        .D_OUT (ALU_srcA) );  
   
   
    // ALU source B Mux instantiation
    mux_8t1_nb #(.n(32)) MUX_B(
        .SEL   (srcB_SEL),
        .D0    (REG_RS2),
        .D1    (IG_ITYPE),  
        .D2    (IG_STYPE),
        .D3    (PC),
        .D4    (csr_RD),
        .D5(),
        .D6(),
        .D7(),
        .D_OUT (ALU_srcB)
    );  

    
    // ALU implemented as always block
    always_comb begin
        case(ALU_FUN)
            4'b0000: begin //add
                    RESULT = OP1 + OP2;
                  end 
            4'b1000: begin //sub
                    RESULT = OP1 - OP2;
                  end 
            4'b0110: begin //or
                    RESULT = OP1 | OP2;
                  end  
            4'b0111: begin //and
                    RESULT = OP1 & OP2;
                  end
            4'b0100: begin //xor
                    RESULT = OP1 ^ OP2;
                  end 
            4'b0101: begin //srl - logical shift right for all shift operations
                           //limit shift amount to lower 5 bits of shift signal
                    RESULT = OP1 >> OP2[4:0];
                  end 
            4'b0001: begin // sll- logical shift left
                    RESULT = OP1 << OP2[4:0];
                  end
            4'b1101: begin //sra - arithmetic shift right
                    RESULT = $signed(OP1) >>> OP2[4:0];
                  end
            4'b0010: begin //slt - set if less than
                    if ($signed(OP1) < $signed(OP2))
                        RESULT = 1;
                    else
                        RESULT = 0;
                  end
            4'b0011: begin //sltu - set if less than unsigned
                    if (OP1 < OP2)
                        RESULT = 1;
                    else
                        RESULT = 0;
                  end                
            4'b1001: begin //lui - load upper immediate
                    RESULT = OP1; //another module in MCU takes care of shifting
                  end  
            default: 
                    RESULT = 0;                                         
        endcase
    end
       
       
    // CU FSM instantiation
    CU_FSM my_fsm(
        .intr     (INTR & CSR_mstatus),
        .clk      (CLK),
        .RST      (RST),
        .opcode   (ir [6:0]),   // ir[6:0]
        .func3     (ir [14:12]),  
        .PC_WE    (PC_WE),
        .RF_WE    (RF_WE),
        .memWE2   (memWE2),
        .memRDEN1 (memRDEN1),
        .memRDEN2 (memRDEN2),
        .reset    (reset),
        .CSR_WE   (csr_WE),
        .mret_exec(mret_EXEC),
        .int_taken(INT_taken)  
    );
   
   
   // branch conditional generator instantiation
   Branch_Cond_Gen Branch_Cond_Gen (
        .rs1(REG_RS1),
        .rs2(REG_RS2),
        .br_eq(BR_EQ),
        .br_lt(BR_LT),
        .br_ltu(BR_LTU)
   );
   
   
    // CU DCDR instantiation
    CU_DCDR my_cu_dcdr(
        .br_eq     (BR_EQ),
        .br_lt     (BR_LT),
        .br_ltu    (BR_LTU),
        .opcode    (ir [6:0]),    
        .func7     (ir [30]),    
        .func3     (ir [14:12]),   
        .int_taken (INT_taken), 
        .ALU_FUN   (ALU_FUN),
        .PC_SEL    (PC_SEL),
        .srcA_SEL  (srcA_SEL),
        .srcB_SEL  (srcB_SEL),
        .RF_SEL    (RF_SEL)  
    );


    CSR CSR_v1_05 (
        .CLK(CLK),
        .RST(reset),
        .MRET_EXEC(mret_EXEC),
        .INT_TAKEN(INT_taken),
        .ADDR(ir[31:20]),
        .PC(PC),
        .WD(ALU_OUT),
        .WR_EN(csr_WE),
        .RD(csr_RD),
        .CSR_MEPC(mepc),
        .CSR_MTVEC(mtvec),
        .CSR_MSTATUS_MIE(CSR_mstatus)
    );
   
endmodule
