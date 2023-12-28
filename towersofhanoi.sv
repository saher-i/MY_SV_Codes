module towersofhanoi(clk, rst, from_rod, to_rod);
   
parameter
  NUMBER_OF_RODS = 3;
   
parameter
  NUMBER_OF_DISKS = 3;  

localparam 
  RODS_LOG2 = $clog2(NUMBER_OF_RODS);
   
localparam    
  DISKS_LOG2 = $clog2(NUMBER_OF_DISKS); 

   
   input logic clk;
   input logic rst;
   input logic [(RODS_LOG2-1):0] from_rod; 
   input logic [(RODS_LOG2-1):0] to_rod;  
   
   logic [(NUMBER_OF_RODS-1):0] [(DISKS_LOG2-1):0] top_of_rod; 
   logic [(NUMBER_OF_RODS-1):0] [(NUMBER_OF_DISKS-1):0] [(DISKS_LOG2-1):0] rod_data;     
   
   always_ff @(posedge clk) begin

      if (rst) begin
         foreach (top_of_rod[i]) begin
            top_of_rod[i] <= 0;
         end    
         top_of_rod[0] <= NUMBER_OF_DISKS;
         foreach (rod_data[i, j]) begin
            rod_data[i][j] <= 0;
         end
         foreach (rod_data[i, j]) begin 
            if (i==0) rod_data[i][j] <= NUMBER_OF_DISKS - j;
            else rod_data[i][j] <= 0;
         end 
      end 
      else 
         if (from_rod < NUMBER_OF_RODS 
             && to_rod < NUMBER_OF_RODS 
             && top_of_rod[from_rod]>=1 
             && (top_of_rod[to_rod]==0 || 
                 rod_data[from_rod][top_of_rod[from_rod]-1] <  rod_data[to_rod][top_of_rod[to_rod]-1] )) begin
            rod_data[to_rod][top_of_rod[to_rod]] <=  rod_data[from_rod][top_of_rod[from_rod]-1];
            top_of_rod[from_rod] <= top_of_rod[from_rod] - 1;
            top_of_rod[to_rod] <= top_of_rod[to_rod] + 1;            
         end
   end 
    
    //Assertions
 
    // To ensure that on reset, all disks are on one rod  
	assert_no_movement_on_reset: assert property (@(posedge clk)
	    if (rst) (top_of_rod[from_rod] == NUMBER_OF_DISKS));

    // To ensure that the total number of disks across rods is same
	assert_disk_count_consistency: assert property (
	    @(posedge clk) (top_of_rod[0] + top_of_rod[1] + top_of_rod[2] == NUMBER_OF_DISKS)
	);

    // To ensure that the disk being moved from the from_rod to the to_rod is not the same during any point in the game
	  assert_different_disk_move: assert property (
            @(posedge clk)
            if ((from_rod < NUMBER_OF_RODS) && (to_rod < NUMBER_OF_RODS) &&
                (from_rod != to_rod) && (top_of_rod[from_rod] > 0) &&
                (top_of_rod[from_rod] <= NUMBER_OF_DISKS) &&
                ((top_of_rod[to_rod] == 0) || (top_of_rod[to_rod] <= NUMBER_OF_DISKS)))
                ((top_of_rod[to_rod] == 0) ||
                 (rod_data[from_rod][top_of_rod[from_rod] - 1] != rod_data[to_rod][top_of_rod[to_rod] - 1]))
        );

    //To ensure a valid move to to_rod
	  assert_valid_move: assert property (
    		@(posedge clk)
        	((top_of_rod[to_rod] == 0) || (top_of_rod[to_rod] <= NUMBER_OF_DISKS))
        );


	// Assumptions
	
	//On reset, all disks are on the first rod
	assume_all_disks_on_first_rod: assume property (
	@(posedge clk)
	if (rst) (top_of_rod[0] == NUMBER_OF_DISKS) &&
	     (top_of_rod[1] == 0) &&
	     (top_of_rod[2] == 0)
	);

	//  Ignore the combinations - 11 in binary for number of disks and rods 
	assume_ignore_combination_3: assume property (
	  @(posedge clk)
	  if (!rst) (
	    (from_rod != 2'b11) && (to_rod != 2'b11) && (DISKS_LOG2 != 2'b11)
	  )
	);

	// Source rod always has at least one disk
	assume_source_rod_not_empty: assume property (
	  @(posedge clk)
	  if (!rst) (
	    (from_rod < NUMBER_OF_RODS) &&
	    (top_of_rod[from_rod] > 0)
	  )
	);

    //To assume constrains on the number of disks on a rod
	assume_top_lessthan3: assume property(
		@(posedge clk)
		if(!rst) (
		top_of_rod[from_rod] <= NUMBER_OF_DISKS && top_of_rod[to_rod] <= NUMBER_OF_DISKS && top_of_rod[from_rod] >= 0 && top_of_rod[to_rod] >= 0)
		);
	
	// Cover property for successful completion of the game
	cover_successful_completion: cover property (
	  @(posedge clk)
	  if (!rst) (
	    ((top_of_rod[1] == NUMBER_OF_DISKS || top_of_rod[2] == NUMBER_OF_DISKS))
	  )
	);
    
    //Cover properties to check if all the rods were used 
	cover_regular: cover property (@(posedge clk) from_rod == 0 && to_rod == 1);

	cover_regular2: cover property(@(posedge clk) from_rod == 1 && to_rod == 2);	 

endmodule // move_disk

