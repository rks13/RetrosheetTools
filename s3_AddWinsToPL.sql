/*
Program Name:	s3_AddWinsToPL
Creation Date:	2018.08.24
Notes:
Changes:
*/

use <replace with MySQL database name>;
set @ProgName := 's3_AddWinsToPL';
select concat('Begin: ',@ProgName), curtime();
set @LogFile := concat(@ProgName,'_log');

call RunUDVCode(concat('drop table if exists ',@LogFile,';'));
call RunUDVCode(concat('create table ', @LogFile, ' (StepDesc char(60), StepTime datetime);'));

set @step = concat('Begin ',@ProgName);
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));

#=========================================
#-----------------------------------------
set @step = 'Add index on sGameId';
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));

#alter table PitchingLines add index sGameId (sGameId);

#=========================================
#-----------------------------------------
set @step = 'Add win flags to PitchingLines';
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));

update PitchingLines a
	join GameLogs b ON a.sGameID = b.sGameID
	set
		a.iH_Win = b.iH_Win
		, a.iTie = b.iTie
		, a.iYear = b.iYear
	;

update PitchingLines
	set
		iTeamWin = (not(iTie) and (iH_Win=iHomeFlag))
		, iTeam2WpT = 2 * iTeamWin + iTie
	;

describe PitchingLines;
select count(*), avg(iER), avg(iGameScore), avg(iHomeFlag), avg(iH_Win), avg(iTeamWin) from PitchingLines;
select iH_Win, count(*) from PitchingLines group by iH_Win;

#=========================================
set @step = 'Tidy Up';
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));

#=========================================

set @step = concat('End ',@ProgName);
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));
