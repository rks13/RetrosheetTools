/*
Program Nm:	s1_CreateNReadGameLogs
Creation Date:	2016.08.24
Notes:
 - created from Baseball Hacks code
 - data file contains all(ish) MLB regular season games
Changes:
 - 2016.10.09: increased iLengthInOuts from tinint to smallint, because some games go more than 127 outs
*/

use <replace with MySQL database name>;
set @ProgNm := 's1_CreateNReadGameLogs';
select concat('Begin: ',@ProgNm), curtime();
set @LogFile := concat(@ProgNm,'_log');

call RunUDVCode(concat('drop table if exists ',@LogFile,';'));
call RunUDVCode(concat('create table ', @LogFile, ' (StepDesc char(60), StepTime datetime);'));

set @step = concat('Begin ',@ProgNm);
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));

#=========================================
#-----------------------------------------
set @step = 'Create temporary GameLogs_input table';
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));

drop table if exists GameLogs_input;
CREATE TABLE GameLogs_input (
	iGameDate INTEGER(8)
	, iDoubleHeader tinyint(1)
	, sDayOfWeek CHAR(3)
	, sV_Tm CHAR(3)
	, sV_TmLg CHAR(2)
	, iV_TmGameNumber tinyint(3)
	, sH_Tm CHAR(3)
	, sH_TmLg CHAR(2)
	, iH_TmGameNumber tinyint(3)
	, iV_RunsScored tinyint(2)
	, iH_RunsScored tinyint(2)
	, iLengthInOuts smallint(3)
	, sDayNight CHAR(1)
	, iCompletionInfo INTEGER(8)
	, sForfeitInfo CHAR(1)
	, sProtestInfo CHAR(1)
	, sParkID VARCHAR(5)
	, iAttendence INTEGER(6)
	, iDuration SMALLINT(3)
	, sV_LineScore VARCHAR(26)
	, sH_LineScore VARCHAR(26)
	, iV_AB tinyint(2)
	, iV_H tinyint(2)
	, iV_D tinyint(2)
	, iV_T tinyint(2)
	, iV_HR tinyint(2)
	, iV_RBI tinyint(2)
	, iV_SH tinyint(2)
	, iV_SF tinyint(2)
	, iV_HBP tinyint(2)
	, iV_BB tinyint(2)
	, iV_IBB tinyint(2)
	, iV_K tinyint(2)
	, iV_SB tinyint(2)
	, iV_CS tinyint(2)
	, iV_GDP tinyint(2)
	, iV_CI tinyint(2)
	, iV_LOB tinyint(2)
	, iV_Ptcs tinyint(2)
	, iV_ER tinyint(2)
	, iV_TER tinyint(2)
	, iV_WP tinyint(2)
	, iV_Balks tinyint(2)
	, sV_PO tinyint(2)
	, iV_A tinyint(2)
	, iV_E tinyint(2)
	, iV_PasseD tinyint(2)
	, iV_DB tinyint(2)
	, iV_TP tinyint(2)
	, iH_AB tinyint(2)
	, iH_H tinyint(2)
	, iH_D tinyint(2)
	, iH_T tinyint(2)
	, sH_HR tinyint(2)
	, iH_RBI tinyint(2)
	, iH_SH tinyint(2)
	, iH_SF tinyint(2)
	, iH_HBP tinyint(2)
	, iH_BB tinyint(2)
	, iH_IBB tinyint(2)
	, iH_K tinyint(2)
	, iH_SB tinyint(2)
	, iH_CS tinyint(2)
	, iH_GDP tinyint(2)
	, iH_CI tinyint(2)
	, iH_LOB tinyint(2)
	, iH_Ptcs tinyint(2)
	, iH_ER tinyint(2)
	, iH_TER tinyint(2)
	, iH_WP tinyint(2)
	, iH_Balks tinyint(2)
	, sH_PO tinyint(2)
	, iH_A tinyint(2)
	, iH_E tinyint(2)
	, iH_PasseD tinyint(2)
	, iH_DB tinyint(2)
	, iH_TP tinyint(2)
	, sUmpHID CHAR(8)
	, sUmpHNm CHAR(20)
	, sUmp1BID CHAR(8)
	, sUmp1BNm CHAR(20)
	, sUmp2BID CHAR(8)
	, sUmp2BNm CHAR(20)
	, sUmp3BID CHAR(8)
	, sUmp3BNm CHAR(20)
	, sUmpLFID CHAR(8)
	, sUmpLFNm CHAR(20)
	, sUmpRFID CHAR(8)
	, sUmpRFNm CHAR(20)
	, sV_MgrID CHAR(8)
	, sV_MgrNm CHAR(20)
	, sH_MgrID CHAR(8)
	, sH_MgrNm CHAR(20)
	, sW_PtcID CHAR(8)
	, sW_PtcNm CHAR(20)
	, sL_PtcID CHAR(8)
	, sL_PtcNm CHAR(20)
	, sSvgPtcID CHAR(8)
	, sSvgPtcNm CHAR(20)
	, sGameW_RBIID CHAR(8)
	, sGameW_RBINm CHAR(20)
	, sV_StrgPtcID CHAR(8)
	, sV_StrgPtcNm CHAR(20)
	, sH_StrgPtcID CHAR(8)
	, sH_StrgPtcNm CHAR(20)
	, sV_Btg1PlayerID CHAR(8)
	, sV_Btg1Nm CHAR(20)
	, iV_Btg1Pos tinyint(2)
	, sV_Btg2PlayerID CHAR(8)
	, sV_Btg2Nm CHAR(20)
	, iV_Btg2Pos tinyint(2)
	, sV_Btg3PlayerID CHAR(8)
	, sV_Btg3Nm CHAR(20)
	, iV_Btg3Pos tinyint(2)
	, sV_Btg4PlayerID CHAR(8)
	, sV_Btg4Nm CHAR(20)
	, iV_Btg4Pos tinyint(2)
	, sV_Btg5PlayerID CHAR(8)
	, sV_Btg5Nm CHAR(20)
	, iV_Btg5Pos tinyint(2)
	, sV_Btg6PlayerID CHAR(8)
	, sV_Btg6Nm CHAR(20)
	, iV_Btg6Pos tinyint(2)
	, sV_Btg7PlayerID CHAR(8)
	, sV_Btg7Nm CHAR(20)
	, iV_Btg7Pos tinyint(2)
	, sV_Btg8PlayerID CHAR(8)
	, sV_Btg8Nm CHAR(20)
	, iV_Btg8Pos tinyint(2)
	, sV_Btg9PlayerID CHAR(8)
	, sV_Btg9Nm CHAR(20)
	, iV_Btg9Pos tinyint(2)
	, sH_Btg1PlayerID CHAR(8)
	, sH_Btg1Nm CHAR(20)
	, iH_Btg1Pos tinyint(2)
	, sH_Btg2PlayerID CHAR(8)
	, sH_Btg2Nm CHAR(20)
	, iH_Btg2Pos tinyint(2)
	, sH_Btg3PlayerID CHAR(8)
	, sH_Btg3Nm CHAR(20)
	, iH_Btg3Pos tinyint(2)
	, sH_Btg4PlayerID CHAR(8)
	, sH_Btg4Nm CHAR(20)
	, iH_Btg4Pos tinyint(2)
	, sH_Btg5PlayerID CHAR(8)
	, sH_Btg5Nm CHAR(20)
	, iH_Btg5Pos tinyint(2)
	, sH_Btg6PlayerID CHAR(8)
	, sH_Btg6Nm CHAR(20)
	, iH_Btg6Pos tinyint(2)
	, sH_Btg7PlayerID CHAR(8)
	, sH_Btg7Nm CHAR(20)
	, iH_Btg7Pos tinyint(2)
	, sH_Btg8PlayerID CHAR(8)
	, sH_Btg8Nm CHAR(20)
	, iH_Btg8Pos tinyint(2)
	, sH_Btg9PlayerID CHAR(8)
	, sH_Btg9Nm CHAR(20)
	, iH_Btg9Pos tinyint(2)
	, sAdditionalInfo CHAR(40)
	, sAcquisitionInfo CHAR(1)
	);


#=========================================
#-----------------------------------------
set @step = 'Create GameLogs_temp from GameLogs_input';
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));

drop table if exists GameLogs_temp;
CREATE TABLE GameLogs_temp SELECT * FROM GameLogs_input where (1=0);

alter table GameLogs_temp
	add column sGameType char(3)
	;

#=========================================
#-----------------------------------------
# Load regular season games
set @step = 'Load regular season games into GameLogs_input';
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));

TRUNCATE TABLE GameLogs_input;
LOAD DATA LOCAL INFILE 'GameLogs/AllRegs.txt'
	INTO TABLE GameLogs_input
	FIELDS TERMINATED BY ','
	OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\r\n'
	IGNORE 1 LINES
	;

insert into GameLogs_temp select *, 'reg' as sGameType from GameLogs_input;

select count(*), avg(iV_RunsScored), avg(iH_RunsScored) from GameLogs_input;

#=========================================
#-----------------------------------------
set @step = 'Load World Series games into GameLogs_input';
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));

TRUNCATE TABLE GameLogs_input;
LOAD DATA LOCAL INFILE 'GameLogs/GLWS.txt'
	INTO TABLE GameLogs_input
	FIELDS TERMINATED BY ','
	OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\r\n'
	IGNORE 0 LINES
	;

insert into GameLogs_temp select *, 'WS' as sGameType from GameLogs_input;

select count(*), avg(iV_RunsScored), avg(iH_RunsScored) from GameLogs_input;

#=========================================
#-----------------------------------------
# Load league championship games
set @step = 'Load league championship games';
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));

TRUNCATE TABLE GameLogs_input;
LOAD DATA LOCAL INFILE 'GameLogs/GLLC.txt'
	INTO TABLE GameLogs_input
	FIELDS TERMINATED BY ','
	OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\r\n'
	IGNORE 0 LINES
	;

insert into GameLogs_temp select *, 'LCS' as sGameType from GameLogs_input;

select count(*), avg(iV_RunsScored), avg(iH_RunsScored) from GameLogs_input;

#=========================================
#-----------------------------------------
set @step = 'Load league division playoff games';
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));

TRUNCATE TABLE GameLogs_input;
LOAD DATA LOCAL INFILE 'GameLogs/GLDV.txt'
	INTO TABLE GameLogs_input
	FIELDS TERMINATED BY ','
	OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\r\n'
	IGNORE 0 LINES
	;

insert into GameLogs_temp select *, 'LDS' as sGameType from GameLogs_input;

select count(*), avg(iV_RunsScored), avg(iH_RunsScored) from GameLogs_input;

#=========================================
#-----------------------------------------
set @step = 'Load wild card playoff games';
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));

TRUNCATE TABLE GameLogs_input;
LOAD DATA LOCAL INFILE 'GameLogs/GLWC.txt'
	INTO TABLE GameLogs_input
	FIELDS TERMINATED BY ','
	OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\r\n'
	IGNORE 0 LINES
	;

insert into GameLogs_temp select *, 'WC' as sGameType from GameLogs_input;

select count(*), avg(iV_RunsScored), avg(iH_RunsScored) from GameLogs_input;

#=========================================
#-----------------------------------------
set @step = 'Load All-Star games';
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));

TRUNCATE TABLE GameLogs_input;
LOAD DATA LOCAL INFILE 'GameLogs/GLAS.txt'
	INTO TABLE GameLogs_input
	FIELDS TERMINATED BY ','
	OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\r\n'
	IGNORE 0 LINES
	;

insert into GameLogs_temp select *, 'AS' as sGameType from GameLogs_input;

select count(*), avg(iV_RunsScored), avg(iH_RunsScored) from GameLogs_input;

#=========================================
set @step = 'Describe GameLogs_temp';
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));

select sGameType, count(*), avg(iV_RunsScored), avg(iH_RunsScored) from GameLogs_temp group by sGameType;

#=========================================
#-----------------------------------------
set @step = 'Create GameLogs from GameLogs_temp and add variables';
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));

drop table if exists GameLogs;
CREATE TABLE GameLogs SELECT * FROM GameLogs_temp;

alter table GameLogs
	add column sGameID CHAR(12)
	, add column iH_Win tinyint(1)
	, add column iTie tinyint(1)
	, add column iYear smallint(4)
	, add column iRegSeason tinyint(1)
	, add column iModern tinyint(1)
	;

#=========================================
#-----------------------------------------
set @step = 'Finalize GameLogs and describe';
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));

update GameLogs
	set iH_Win = (iH_RunsScored > iV_RunsScored)
	, iTie = (iH_RunsScored = iV_RunsScored)
	, sGameID = concat(trim(sH_Tm), trim(DATE_FORMAT(iGameDate,'%Y%m%d')),trim(cast(iDoubleHeader as char(1))))
	, iYear = floor(iGameDate/10000)
	, iRegSeason = (sGameType = 'reg')
	, iModern = (iYear >= 1900)
	;

alter table GameLogs add primary key(sGameID);

describe GameLogs;
select count(*), avg(iV_RunsScored), avg(iH_RunsScored) from GameLogs;
select iYear, count(*) from GameLogs group by iYear;
select iRegSeason, iModern, sGameType, count(*) from GameLogs group by iRegSeason, iModern, sGameType;
select sAcquisitionInfo, count(*) from GameLogs group by sAcquisitionInfo;

#=========================================
# Last Step: Tidy up

set @step = 'Tidy Up';
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));

drop table if exists GameLogs_input;
drop table if exists GameLogs_temp;

#=========================================

set @step = concat('End ',@ProgNm);
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));
