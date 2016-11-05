/*
Program Nm:	s1_CreateEventDiagnosticTable
Creation Date:	2016.09.18
Notes:
Changes:
*/

use <replace with MySQL database name>;
set @ProgNm := 's1_CreateEventDiagnosticTable';
select concat('Begin: ',@ProgNm), curtime();
set @LogFile := concat(@ProgNm,'_log');

call RunUDVCode(concat('drop table if exists ',@LogFile,';'));
call RunUDVCode(concat('create table ', @LogFile, ' (StepDesc char(60), StepTime datetime);'));

set @step = concat('Begin ',@ProgNm);
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));

#=========================================
#-----------------------------------------
# Create table
set @step = 'Create EventDiag Table';
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));

drop table if exists EventDiag;
CREATE TABLE EventDiag (
	EventID INT NOT NULL AUTO_INCREMENT
	, sGameID CHAR(12)
	, iLineCount INT(8)
	, sSrcText CHAR(80)
	, sPlayDesc CHAR(80)
	, sEventBat CHAR(80)
	, iPAFlag SMALLINT(20)
	, iPitches SMALLINT(20)
	, sOutcome CHAR(4)
	, iClarity SMALLINT(2)
	, sEventBucket CHAR(8)
	, primary key (EventID)
	);

describe EventDiag;

#=========================================
# Last Step: Tidy up

set @step = 'Tidy Up';
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));

#=========================================

set @step = concat('End ',@ProgNm);
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));
