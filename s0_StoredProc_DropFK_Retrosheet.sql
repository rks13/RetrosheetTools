#s0_StoredProc_DropFK_Retrosheet
use <replace with MySQL database name>;

DELIMITER // 
DROP PROCEDURE IF EXISTS DropFK_Retrosheet // 
CREATE PROCEDURE DropFK_Retrosheet ( 
IN parm_table_name VARCHAR(100), 
IN parm_key_name VARCHAR(100) 
) 
BEGIN 
-- Verify the foreign key exists 
IF EXISTS (SELECT NULL FROM information_schema.TABLE_CONSTRAINTS WHERE table_schema=<replace with MySQL database name> and CONSTRAINT_type='FOREIGN KEY' AND CONSTRAINT_NAME = parm_key_name) THEN 
	-- Turn the parameters into local variables 
	set @ParmTable = parm_table_name ; 
	set @ParmKey = parm_key_name ; 
	-- Create the full statement to execute 
	set @StatementToExecute = concat('ALTER TABLE ',@ParmTable,' DROP FOREIGN KEY ',@ParmKey); 
	-- Prepare and execute the statement that was built 
	prepare DynamicStatement from @StatementToExecute ; 
	execute DynamicStatement ; 
	-- Cleanup the prepared statement 
	deallocate prepare DynamicStatement ; 
	END IF; 
END // 
DELIMITER ;

