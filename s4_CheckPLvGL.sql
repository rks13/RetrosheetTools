/*
Program Name:	s4_CheckPLvGL
Creation Date:	2018.08.26
Notes:
Changes:
*/

use <replace with MySQL database name>;
set @ProgName := 's4_CheckPLvGL';
select concat('Begin: ',@ProgName), curtime();
set @LogFile := concat(@ProgName,'_log');

call RunUDVCode(concat('drop table if exists ',@LogFile,';'));
call RunUDVCode(concat('create table ', @LogFile, ' (StepDesc char(60), StepTime datetime);'));

set @step = concat('Begin ',@ProgName);
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));

#=========================================
#-----------------------------------------
set @step = 'Aggregate home and away runs allowed';
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));

drop table if exists PitchingLines_Agg;
create table PitchingLines_Agg (primary key (sGameId))
	select
		sGameId
		, sum(iR * (1-iHomeFlag)) as PL_iRS_H
		, sum(iR * iHomeFlag) as PL_iRS_A
		, sum(iK * (1-iHomeFlag)) as PL_iK_H
		, sum(iK * iHomeFlag) as PL_iK_A
		, sum(iOuts * (1-iHomeFlag)) as PL_iOutsP_A
		, sum(iOuts * iHomeFlag) as PL_iOutsP_H
		, sum(iH * (1-iHomeFlag)) as PL_iH_H
		, sum(iH * iHomeFlag) as PL_iH_A
	from PitchingLines
	group by sGameId
	;

select sum(PL_iRS_H), sum(PL_iRS_A), sum(PL_iK_H), sum(PL_iK_A), sum(PL_iOutsP_H), sum(PL_iOutsP_A), sum(PL_iH_H), sum(PL_IH_A), count(*) from PitchingLines_Agg;
select iHomeFlag, sum(iR), count(*) from PitchingLines group by iHomeFlag;

#=========================================
#-----------------------------------------
set @step = 'Compare pitching line aggregates to game logs';
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));

drop table if exists GLxPL;
create table GLxPL (primary key (sGameId2))
	select
		g.sGameId as sGameId2
		, g.iH_RunsScored, p.PL_iRS_H
		, (g.iH_RunsScored=p.PL_iRS_H) as iRunsScored_H_match
		, g.iV_RunsScored, p.PL_iRS_A
		, (g.iV_RunsScored=p.PL_iRS_A) as iRunsScored_A_match
		, g.iH_H, p.PL_IH_H
		, (g.iH_H=p.PL_iH_H) as iBatterHits_H_match
		, g.iV_H, p.PL_IH_A
		, (g.iV_H=p.PL_iH_A) as iBatterHits_A_match
		, g.iH_K, p.PL_iK_H
		, (g.iH_K=p.PL_iK_H) as iBatterK_H_match
		, g.iV_K, p.PL_iK_A
		, (g.iV_K=p.PL_iK_A) as iBatterK_A_match
		, g.iLengthInOuts, p.PL_iOutsP_H, p.PL_iOutsP_A, (p.PL_iOutsP_H + p.PL_iOutsP_A) as PL_TotOuts
		, (g.iLengthInOuts = (p.PL_iOutsP_H + p.PL_iOutsP_A)) as iTotOuts_match
		, 0 as iAllMatch
	from GameLogs as g inner join PitchingLines_Agg as p
	on (g.sGameId = p.sGameId)
	;


update GLxPL
	set iAllMatch = (iRunsScored_H_match * iRunsScored_A_match * iBatterHits_H_match * iBatterHits_A_match * iBatterK_H_match * iBatterK_A_match * iTotOuts_match)
	;

select sum(iH_RunsScored), sum(PL_iRS_H), sum(iV_RunsScored), sum(PL_iRS_A), count(*) from GLxPL;
select iRunsScored_H_match, iRunsScored_A_match, count(*) from GLxPL group by iRunsScored_H_match, iRunsScored_A_match;
select iBatterHits_H_match, iBatterHits_A_match, count(*) from GLxPL group by iBatterHits_H_match, iBatterHits_A_match;
select iBatterK_H_match, iBatterK_A_match, count(*) from GLxPL group by iBatterK_H_match, iBatterK_A_match;
select iTotOuts_match, count(*) from GLxPL group by iTotOuts_match;

#=========================================
#-----------------------------------------
set @step = 'Pull problem games';
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));

drop table if exists GLxPL_prob;
create table GLxPL_prob (primary key (sGameId2))
	select * from GLxPL where (iAllMatch = 0)
	;

drop table if exists GLxPL_prob_Events;
create table GLxPL_prob_Events
	select *
	from EventDiag as e inner join GLxPL_prob as p
	on (e.sGameId = p.sGameId2)
	;

#=========================================
# Last Step: Tidy up

set @step = 'Tidy Up';
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));

drop table if exists PitchingLines_Agg;
drop table if exists ModernStarts;

#=========================================

set @step = concat('End ',@ProgName);
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));
