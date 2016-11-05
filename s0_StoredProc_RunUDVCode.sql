#s0_StoredProc_RunUDVCode
use <replace with MySQL database name>;

drop procedure if exists RunUDVCode;
delimiter //
create procedure RunUDVCode(in RunText varchar(255))
begin
  set @sql := RunText;
  prepare mySt from @sql;
  execute mySt;
  end//
  
delimiter ;
set @sql := 'select "Hi Bob";';
call RunUDVCode(@sql);

show procedure status;
show create procedure RunUDVCode;
