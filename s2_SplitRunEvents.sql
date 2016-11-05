/*
Program Name:	s2_SplitRunEvents
Creation Date:	2018.10.05
Notes:
Changes:
*/

use <replace with MySQL database name>;
set @ProgName := 's2_SplitRunEvents';
select concat('Begin: ',@ProgName), curtime();
set @LogFile := concat(@ProgName,'_log');

call RunUDVCode(concat('drop table if exists ',@LogFile,';'));
call RunUDVCode(concat('create table ', @LogFile, ' (StepDesc char(60), StepTime datetime);'));

set @step = concat('Begin ',@ProgName);
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));

#=========================================
#-----------------------------------------
set @step = 'Create EventDiag_run, non-null values with no semicolons';
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));

drop table if exists EventDiag_run;

select 'A: Values with 0 semicolons';
select count(*) from EventDiag
	where not isnull(sEventRun) and not locate(';', sEventRun)
	;

create table EventDiag_run
	select sGameId, EventId, sSrcText, sPlayDesc, sEventRun from EventDiag
	where not isnull(sEventRun) and not locate(';', sEventRun)
	;

select 'Total records';
select count(*) from EventDiag_run;

#=========================================
#-----------------------------------------
set @step = 'First part of values with at least 1 semicolon';
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));

select 'B: Values with at least 1 semicolon';
select count(*) from EventDiag
	where not isnull(sEventRun) and ((char_length(sEventRun) - char_length(replace(sEventRun, ';', ''))) >= 1)
	;

insert into EventDiag_run (sGameId, EventId, sSrcText, sPlayDesc, sEventRun)
	select sGameId, EventId, sSrcText, sPlayDesc, substring_index(sEventRun, ';', 1) from EventDiag
	where not isnull(sEventRun) and ((char_length(sEventRun) - char_length(replace(sEventRun, ';', ''))) >= 1) 
	;

select 'Total records';
select count(*) from EventDiag_run;

#=========================================
#-----------------------------------------
set @step = 'Last part of values with at least 1 semicolon';
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));

select 'C: Values with at least 1 semicolon';
select count(*) from EventDiag
	where not isnull(sEventRun) and ((char_length(sEventRun) - char_length(replace(sEventRun, ';', ''))) >= 1) 
	;

insert into EventDiag_run (sGameId, EventId, sSrcText, sPlayDesc, sEventRun)
	select sGameId, EventId, sSrcText, sPlayDesc, substring_index(sEventRun, ';', -1) from EventDiag
	where not isnull(sEventRun) and ((char_length(sEventRun) - char_length(replace(sEventRun, ';', ''))) >= 1) 
	;

select 'Total records';
select count(*) from EventDiag_run;

#=========================================
#-----------------------------------------
set @step = 'Second part of values with more than 1 semicolon';
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));

select 'D: Values with more than 1 semicolon';
select count(*) from EventDiag
	where not isnull(sEventRun) and ((char_length(sEventRun) - char_length(replace(sEventRun, ';', ''))) > 1) 
	;

insert into EventDiag_run (sGameId, EventId, sSrcText, sPlayDesc, sEventRun)
	select sGameId, EventId, sSrcText, sPlayDesc, substring_index(substring_index(sEventRun, ';', 2), ';', -1) from EventDiag
	where not isnull(sEventRun) and ((char_length(sEventRun) - char_length(replace(sEventRun, ';', ''))) > 1) 
	;

select 'Total records';
select count(*) from EventDiag_run;

#=========================================
#-----------------------------------------
set @step = 'Third part of values with more than 2 semicolons';
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));

select 'E: Values with more than 2 semicolon';
select count(*) from EventDiag
	where not isnull(sEventRun) and ((char_length(sEventRun) - char_length(replace(sEventRun, ';', ''))) > 2) 
	;

insert into EventDiag_run (sGameId, EventId, sSrcText, sPlayDesc, sEventRun)
	select sGameId, EventId, sSrcText, sPlayDesc, substring_index(substring_index(sEventRun, ';', 3), ';', -1) from EventDiag
	where not isnull(sEventRun) and ((char_length(sEventRun) - char_length(replace(sEventRun, ';', ''))) > 2) 
	;

select 'Total records';
select count(*) from EventDiag_run;

#=========================================
# Last Step: Tidy up

set @step = 'Tidy Up';
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));

#=========================================

set @step = concat('End ',@ProgName);
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));
