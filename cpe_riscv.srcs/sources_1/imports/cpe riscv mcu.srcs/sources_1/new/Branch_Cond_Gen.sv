`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Jack Marshall

//////////////////////////////////////////////////////////////////////////////////



module Branch_Cond_Gen(
    input [31:0] rs1,
    input [31:0] rs2,
    output logic br_eq,
    output logic br_lt,
    output logic br_ltu
    );
        
    assign br_eq = (rs1 == rs2);
    assign br_lt = $signed(rs1) < $signed(rs2); 
    assign br_ltu = rs1 < rs2;
    
endmodule
