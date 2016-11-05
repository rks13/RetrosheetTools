/*
Program Name:	s1_CreatePitchingLinesDataStructures
Creation Date:	2018.08.24
Notes:
Changes:
*/

use <replace with MySQL database name>;
set @ProgName := 's1_CreatePitchingLinesDataStructures';
select concat('Begin: ',@ProgName), curtime();
set @LogFile := concat(@ProgName,'_log');

call RunUDVCode(concat('drop table if exists ',@LogFile,';'));
call RunUDVCode(concat('create table ', @LogFile, ' (StepDesc char(60), StepTime datetime);'));

set @step = concat('Begin ',@ProgName);
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));

#=========================================
#-----------------------------------------
# Create table PitchingLines
set @step = 'Create PitchingLines table';
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));

drop table if exists PitchingLines;
create table PitchingLines (
	sGameID CHAR(12)
	, sPitcherID CHAR(8)
	, iHomeFlag smallint
	, iGSFlag smallint
	, iOuts smallint
	, iK smallint
	, iH smallint
	, iHR smallint
	, iBB smallint
	, iR smallint
	, iER smallint
	, sDecision char(1)
	, iGameScore smallint
	, iH_Win smallint
	, iTeamWin smallint
	, iTie smallint
	, iTeam2WpT smallint
	, iYear smallint
	);

describe PitchingLines;
#select count(*), avg(iER), avg(iGameScore) from PitchingLines;

#=========================================
# Last Step: Tidy up

set @step = 'Tidy Up';
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));

#=========================================

set @step = concat('End ',@ProgName);
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));
