`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  Ratner Surf Designs
// Engineer: James Ratner
//
// Create Date: 01/07/2020 09:12:54 PM
// Design Name:
// Module Name: top_level
// Project Name:
// Target Devices:
// Tool Versions:
// Description: Control Unit Template/Starter File for RISC-V OTTER
//
//     //- instantiation template
//     CU_FSM my_fsm(
//        .intr     (xxxx),
//        .clk      (xxxx),
//        .RST      (xxxx),
//        .opcode   (xxxx),   // ir[6:0]
//        .PC_WE    (xxxx),
//        .RF_WE    (xxxx),
//        .memWE2   (xxxx),
//        .memRDEN1 (xxxx),
//        .memRDEN2 (xxxx),
//        .reset    (xxxx)   );
//  
// Dependencies:
//
// Revision:
// Revision 1.00 - File Created - 02-01-2020 (from other people's files)
//          1.01 - (02-08-2020) switched states to enum type
//          1.02 - (02-25-2020) made PS assignment blocking
//                              made rst output asynchronous
//          1.03 - (04-24-2020) added "init" state to FSM
//                              changed rst to reset
//          1.04 - (04-29-2020) removed typos to allow synthesis
//          1.05 - (10-14-2020) fixed instantiation comment (thanks AF)
//          1.06 - (12-10-2020) cleared most outputs, added comments
//          1.07 - (12-27-2023) changed signal names
//
//////////////////////////////////////////////////////////////////////////////////


    module CU_FSM(
    input intr,
    input clk,
    input RST,
    input [6:0] opcode,     // ir[6:0]
    input [2:0] func3, 
    output logic PC_WE,
    output logic RF_WE,
    output logic memWE2,
    output logic memRDEN1,
    output logic memRDEN2,
    output logic reset,
    output logic CSR_WE,        
    output logic mret_exec,
    output logic int_taken
  );
   
    typedef  enum logic [2:0] {
       st_INIT,
       st_FET,
       st_EX,
       st_WB,
       st_INTR
    }  state_type;
    state_type  NS,PS;
     
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
   
opcode_t OPCODE;    //- symbolic names for instruction opcodes
     
assign OPCODE = opcode_t'(opcode); //- Cast input as enum


   //- datatype for func3Symbols tied to values
   typedef enum logic [2:0] {
        //BRANCH labels
        MRET  = 3'b000,
        CSRRW = 3'b001,
        CSRRC = 3'b011,
        CSRRS = 3'b010
   } func3_t;    
   func3_t FUNC3; //- define variable of new opcode type
   
   assign FUNC3 = func3_t'(func3); //- Cast input enum
   

//- state registers (PS)
always @ (posedge clk)  
        if (RST == 1)
            PS <= st_INIT;
        else
            PS <= NS;

    always_comb
    begin              
        //- schedule all outputs to avoid latch
        PC_WE = 1'b0;    RF_WE = 1'b0;    reset = 1'b0;  
        memWE2 = 1'b0;     memRDEN1 = 1'b0;    memRDEN2 = 1'b0;
        int_taken = 1'b0;   mret_exec = 1'b0;   CSR_WE = 1'b0;
                   
        case (PS)

            st_INIT: //waiting state  
                begin
                    reset = 1'b1;                    
                    NS = st_FET;
                end

            st_FET: //fetch instruction state  
                begin
                    memRDEN1 = 1'b1;                    
                    NS = st_EX;
                end
             
            st_EX: //decode + execute
            begin
                PC_WE = 1'b1;
                case (OPCODE)
                     LOAD:// DONE
                           begin
                              PC_WE = 1'b0;
                              memRDEN2 = 1'b1; //must read mem to load
                              NS = st_WB;
                           end
                   
                      STORE:
                           begin
                              PC_WE = 1'b1;  
                              memWE2 = 1'b1;    //must write mem to store          
                              if (intr == 1) begin NS = st_INTR;
                              end
                              else begin NS = st_FET;
                              end
                           end
                   
                      BRANCH:
                           begin
                              PC_WE = 1'b1; // must load new address to branch
                              if (intr == 1) begin NS = st_INTR;
                              end
                              else begin NS = st_FET;
                              end
                           end
    
                      LUI:
                          begin
                              PC_WE = 1'b1; 
                              RF_WE = 1'b1;
                              if (intr == 1) begin NS = st_INTR;
                              end
                              else begin NS = st_FET;
                              end
                          end
 
                      OP_IMM:  // addi
                          begin
                             PC_WE = 1'b1;
                             RF_WE = 1'b1;
                             if (intr == 1) begin NS = st_INTR;
                             end
                             else begin NS = st_FET;
                             end
                          end


                     OP_RG3:  // add
                          begin
                             PC_WE = 1'b1;
                             RF_WE = 1'b1;
                             if (intr == 1) begin NS = st_INTR;
                             end
                             else begin NS = st_FET;
                             end
                          end


                     JAL:
                          begin
                             PC_WE = 1'b1;
                             RF_WE = 1'b1;
                             if (intr == 1) begin NS = st_INTR;
                             end
                             else begin NS = st_FET;
                             end
                          end
                      
                     JALR:
                          begin
                             PC_WE = 1'b1;
                             RF_WE = 1'b1;
                             if (intr == 1) begin NS = st_INTR;
                             end
                             else begin NS = st_FET;
                             end
                          end
                        
                     AUIPC:
                          begin
                             PC_WE = 1'b1;
                             RF_WE = 1'b1;
                             if (intr == 1) begin NS = st_INTR;
                             end
                             else begin NS = st_FET;
                             end
                          end
                                    
                     SYS:
                          begin
                            case (FUNC3)
                                3'b000: // MRET
                                begin
                                    RF_WE = 1'b1;
                                    mret_exec = 1'b1;  // swap MPIE and MIE bit
                                    PC_WE = 1'b1; // to move back to main program
                                    if (intr == 1) begin NS = st_INTR;
                                    end
                                    else begin NS = st_FET;
                                    end
                                end
                                3'b001: //CSRRW
                                begin
                                    CSR_WE = 1'b1;  // write to CSR
                                    RF_WE = 1'b1;  // write to register
                                    mret_exec = 1'b0;
                                    PC_WE = 1'b1; // go to next instruction
                                    if (intr == 1) begin NS = st_INTR;
                                    end
                                    else begin NS = st_FET;
                                    end
                                end
                                3'b011: // CSRRC
                                begin
                                    CSR_WE = 1'b1;  // write to CSR
                                    RF_WE = 1'b1;  // write to register
                                    mret_exec = 1'b0;
                                    PC_WE = 1'b1; // go to next instruction
                                    if (intr == 1) begin NS = st_INTR;
                                    end
                                    else begin NS = st_FET;
                                    end
                                end  
                                3'b010: // CSRRS
                                begin
                                    CSR_WE = 1'b1;  // write to CSR
                                    RF_WE = 1'b1;  // write to register
                                    mret_exec = 1'b0;
                                    PC_WE = 1'b1; // go to next instruction
                                               
                                    if (intr == 1) begin NS = st_INTR;
                                    end
                                    else begin NS = st_FET;
                                    end
                                end
                                default:
                                begin
                                NS = st_FET;
                                end  
                                                           
                            endcase
                            end
                            
                   default: 
                   begin
                   NS = st_FET;
                   end
                   
                endcase
                end
          
               
            st_WB: // state only for load instructions to write word after retrieve it from memory address
            begin
               PC_WE = 1'b1;
               RF_WE = 1'b1;
               if (intr==1) 
                   begin
                        NS = st_INTR;
                   end
               else 
                   begin
                        NS = st_FET;
                   end
            end
            
            st_INTR:
            begin
                PC_WE = 1'b1;  // go to next instruction
                int_taken = 1'b1;  // disable future interupts (load mtvec into PC, and swap mie and mpie)
                NS = st_FET;
            end
 
            default: NS = st_FET;
           
        endcase //- case statement for FSM states
    end// end always comb
endmodule 
