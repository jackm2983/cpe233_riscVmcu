`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////
// Company: Ratner Surf Designs
// Engineer: James Ratner
//
// Create Date: 01/29/2019 04:56:13 PM
// Design Name:
// Module Name: CU_DCDR
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Instantiation Template:
//
// CU_DCDR my_cu_dcdr(
//   .br_eq     (xxxx),
//   .br_lt     (xxxx),
//   .br_ltu    (xxxx),
//   .opcode    (xxxx),    
//   .func7     (xxxx),    
//   .func3     (xxxx),    
//   .ALU_FUN   (xxxx),
//   .PC_SEL    (xxxx),
//   .srcA_SEL  (xxxx),
//   .srcB_SEL  (xxxx),
//   .RF_SEL    (xxxx)   );
//
//
// Revision:
// Revision 1.00 - Created (02-01-2020) - from Paul, Joseph, & Celina
//          1.01 - (02-08-2020) - removed  else's; fixed assignments
//          1.02 - (02-25-2020) - made all assignments blocking
//          1.03 - (05-12-2020) - reduced func7 to one bit
//          1.04 - (05-31-2020) - removed misleading code
//          1.05 - (12-10-2020) - added comments
//          1.06 - (02-11-2021) - fixed formatting issues
//          1.07 - (12-26-2023) - changed signal names
//
// Additional Comments:
//
///////////////////////////////////////////////////////////////////////////

module CU_DCDR(
   input br_eq,
   input br_lt,
   input br_ltu,
   input [6:0] opcode,   //-  ir[6:0]
   input func7,          //-  ir[30]
   input [2:0] func3,    //-  ir[14:12]
   input int_taken,
   output logic [3:0] ALU_FUN,
   output logic [2:0] PC_SEL,
   output logic [1:0] srcA_SEL,
   output logic [2:0] srcB_SEL,
   output logic [1:0] RF_SEL   
   );
   
   //- datatypes for RISC-V opcode types
   typedef enum logic [6:0] {
        LUI    = 7'b0110111,
        AUIPC  = 7'b0010111,
        JAL    = 7'b1101111,
        JALR   = 7'b1100111,
        BRANCH = 7'b1100011,
        LOAD   = 7'b0000011,
        STORE  = 7'b0100011,
        OP_IMM = 7'b0010011,
        OP_RG3 = 7'b0110011,
        SYS    = 7'b1110011
   } opcode_t;
   opcode_t OPCODE; //- define variable of new opcode type
   
   assign OPCODE = opcode_t'(opcode); //- Cast input enum

   //- datatype for func3Symbols tied to values
   typedef enum logic [2:0] {
//        //BRANCH labels
        BEQ = 3'b000,
        BNE = 3'b001,
        BLT = 3'b100,
        BGE = 3'b101,
        BLTU = 3'b110,
        BGEU = 3'b111
   } func3_t;    
   func3_t FUNC3; //- define variable of new opcode type
   
   assign FUNC3 = func3_t'(func3); //- Cast input enum
   
   
   
   //- datatype for func7 Symbols tied to values
   typedef enum logic {
       ONE = 1'b1,
       ZERO = 1'b0
   } func7_t;    
    
   func7_t FUNC7; //- define variable of new opcode type
    
   assign FUNC7 = func7_t'(func7); //- Cast input enum 

   
   
       
   always_comb
   begin
      //- schedule all values to avoid latch
      PC_SEL = 3'b000;  srcB_SEL = 3'b000;     RF_SEL = 2'b00;
      srcA_SEL = 2'b00;   ALU_FUN  = 4'b0000; 
      
      if (int_taken == 1)
        PC_SEL = 3'b100;
      else
 
      case(OPCODE)
      
      
         LUI:
             begin
                ALU_FUN = 4'b1001;
                srcA_SEL = 2'b01; // U type instruction
                srcB_SEL = 3'b000; 
                PC_SEL = 3'b000;
                RF_SEL = 2'b11;
             end

         AUIPC:
            begin
                ALU_FUN = 4'b0000;
                srcA_SEL = 2'b01;
                srcB_SEL = 3'b011;
                PC_SEL = 3'b000;
                RF_SEL = 2'b11;
            end
         
         JAL:
             begin
                PC_SEL = 3'b011;
                RF_SEL = 2'b00;
             end
         
         JALR:
            begin
                ALU_FUN = 4'b0000;
                srcA_SEL = 2'b00;
                srcB_SEL = 3'b001;
                PC_SEL = 3'b001;
                RF_SEL = 2'b00;
            end


          BRANCH: 
            begin
            
                PC_SEL = 3'b000;                
                
                case(FUNC3)
                    3'b000: 
                    begin
                        if (br_eq) begin
                            PC_SEL = 3'b010;
                        end
                    end
                    
                    3'b001: 
                    begin
                        if (br_eq == 0) begin
                            PC_SEL = 3'b010;
                        end
                    end
                    
                    3'b100: 
                    begin
                        if (br_lt) begin
                            PC_SEL = 3'b010;
                        end
                    end
                   
                    3'b101: 
                    begin
                        if (br_lt==0) begin
                            PC_SEL = 3'b010;
                        end
                    end
                    
                    3'b110: 
                    begin
                        if (br_ltu) begin
                            PC_SEL = 3'b010;
                        end
                    end
                    
                    3'b111: 
                    begin
                        if (br_ltu==0) begin
                            PC_SEL = 3'b010;
                        end
                    end
                    
                    default:
                    begin
                        PC_SEL = 3'b000;
                    end
                endcase
           end
           

         LOAD:
             begin
                ALU_FUN = 4'b0000; //ADD - add immed value to rs1 val
                srcA_SEL = 2'b00;
                srcB_SEL = 3'b001;
                PC_SEL = 3'b000;
                RF_SEL = 2'b10;
             end

         STORE:
             begin
                ALU_FUN = 4'b0000;      // ADD - add immed val to rs1 val
                srcA_SEL = 2'b00;
                srcB_SEL = 3'b010;
                PC_SEL = 3'b000;
                RF_SEL = 2'b00;
             end

         OP_IMM:
         begin
            srcA_SEL = 2'b00;
            srcB_SEL = 3'b001;
            PC_SEL = 3'b000;
            RF_SEL = 2'b11;
            case(FUNC3)
               3'b000: // ADDI
               begin
                  ALU_FUN = 4'b0000;     // ADD - adds a register and immed val
               end
               
               3'b010: // SLTI
               begin
                  ALU_FUN = 4'b0010;     
               end

               3'b011: // SLTIU
               begin
                  ALU_FUN = 4'b0011;    
               end
               
               3'b110: // ORI
               begin
                  ALU_FUN = 4'b0110;    
               end               
               
               3'b100: // XORI
               begin
                  ALU_FUN = 4'b0100;    
               end                  
               
               3'b111: // ANDI
               begin
                  ALU_FUN = 4'b0111;    
               end                
               
               3'b001: // SLLI
               begin
                  ALU_FUN = 4'b0001;    
               end                
               
               3'b101: 
               begin 
                    case(FUNC7)
                        ZERO: 
                        begin //SRLI
                            ALU_FUN = 4'b0101;
                        end
                        ONE: 
                        begin //SRAI
                            ALU_FUN = 4'b1101;
                        end
                        
                        default:
                        begin
                            ALU_FUN = 4'b0000;
                        end
                    endcase                                      
                end
             
               default:
               begin
                  PC_SEL = 3'b000;
                  ALU_FUN = 4'b0000;
                  srcA_SEL = 2'b00;
                  srcB_SEL = 3'b000;
                  RF_SEL = 2'b00;
               end
            endcase
         end
         
         
         OP_RG3: begin  // Basic ALU Stuff
                RF_SEL = 2'b11; 
                PC_SEL = 3'b000;
                ALU_FUN = 4'b0000;
                srcA_SEL = 2'b00;
                srcB_SEL = 3'b000;
                
                case(FUNC3)
                    3'b000: 
                    begin
                        case(FUNC7)
                            ZERO: 
                            begin //ADD
                                ALU_FUN = 4'b0000;
                            end
                            
                            ONE: 
                            begin //SUB
                                ALU_FUN = 4'b1000;
                            end
                            
                            default:
                            begin
                                ALU_FUN = 4'b0000;
                            end
                        endcase
                    end
                    
                    3'b001: 
                    begin //SLL
                        ALU_FUN = 4'b0001;
                    end
                    
                    3'b010: 
                    begin //SLT
                        ALU_FUN = 4'b0010;     
                    end     
                    
                    3'b011: 
                    begin //SLTU       
                        ALU_FUN = 4'b0011;
                    end        
                    
                    3'b100: 
                    begin //XOR
                        ALU_FUN = 4'b0100;
                    end    
                   
                    3'b101: 
                    begin //SRL
                        case(FUNC7)
                            ZERO: 
                            begin //SRL
                                ALU_FUN = 4'b0101;
                            end
                            
                            ONE: 
                            begin //SRA
                                ALU_FUN = 4'b1101;
                            end
                            
                            default:
                            begin
                                ALU_FUN = 4'b0000;
                            end
                        endcase                                      
                    end
                    
                    3'b110: 
                    begin //OR
                        ALU_FUN = 4'b0110;
                    end
                    
                    3'b111: 
                    begin //AND
                        ALU_FUN = 4'b0111;
                    end


                   default:
                   begin
                      PC_SEL = 3'b000;
                      ALU_FUN = 4'b0000;
                      srcA_SEL = 2'b00;
                      srcB_SEL = 3'b000;
                      RF_SEL = 2'b00;
                   end
                endcase
            end        


        SYS:
        begin
            case(FUNC3)
            
                3'b001: //CSRRW
                begin
                    srcA_SEL = 2'b00;
                    ALU_FUN = 4'b1001;  // copy register value straight to CSR
                    RF_SEL = 2'b01;
                    PC_SEL = 3'b000;
                end
                
                3'b011: //CSRRC
                begin
                    srcA_SEL = 2'b10;
                    srcB_SEL = 3'b100;
                    ALU_FUN = 4'b0111; // AND current CSR value with inverted register value
                    RF_SEL = 2'b11;
                    PC_SEL = 3'b000;
                end
                
                3'b010: //CSRRS
                begin
                    srcA_SEL = 2'b00;
                    srcB_SEL = 3'b100;
                    ALU_FUN = 4'b0110;  // OR current CSR value with register value
                    RF_SEL = 2'b11;
                    PC_SEL = 3'b000;
                end
                
                3'b000: //MRET
                begin
                    PC_SEL = 3'b101;  // load mepc (return address)into PC
                    ALU_FUN = 4'b0000;
                    srcA_SEL = 2'b00;
                    srcB_SEL = 3'b100;
                    RF_SEL = 2'b00;
                end

            endcase
        end

         default:
         begin
             PC_SEL = 3'b000;
             srcB_SEL = 3'b000;
             RF_SEL = 2'b00;
             srcA_SEL = 2'b00;
             ALU_FUN = 4'b0000;
         end
      endcase
      
   end

endmodule
