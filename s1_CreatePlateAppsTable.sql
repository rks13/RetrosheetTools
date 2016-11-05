/*
Program Name:	s1_CreatePlateAppsTable
Creation Date:	2015.04.22
Notes:
 - ver 0.9 creates only PlateApps
 - ignore foreign keys
Changes:
*/

use <replace with MySQL database name>;
set @ProgName := 's1_CreatePlateAppsTable';
select concat('Begin: ',@ProgName), curtime();
set @LogFile := concat(@ProgName,'_log');

call RunUDVCode(concat('drop table if exists ',@LogFile,';'));
call RunUDVCode(concat('create table ', @LogFile, ' (StepDesc char(60), StepTime datetime);'));

set @step = concat('Begin ',@ProgName);
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));

#=========================================
#-----------------------------------------
# Create table
set @step = 'Create PlateApps table';
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));

drop table if exists PlateApps;
create table PlateApps(
	iPAID int unsigned auto_increment primary key
	, iYear smallint unsigned
	, dGameDate date
	, iGameSeq tinyint unsigned
	, sBatterID char(8)
	, sPitcherID char(8)
	, sEvent char(60)
	, sOutcome char(4)
	, iClarity tinyint unsigned
	, iInning tinyint unsigned
	, iCount tinyint unsigned
	, iOuts tinyint unsigned
	, iB1Occ tinyint unsigned
	, iB2Occ tinyint unsigned
	, iB3Occ tinyint unsigned
	, iCurBatterInOrder tinyint unsigned
	, sOnDeckBatterId char(8)
	, iPitches tinyint unsigned
	, iPitchCount smallint unsigned
	, iPitcherLead tinyint
	, sStadium char(8)
	, iLineCount int unsigned
	, iHit tinyint unsigned
	, iBB tinyint unsigned
	, iHBP tinyint unsigned
	, iSH tinyint unsigned
	, iSF tinyint unsigned
	, iTB tinyint unsigned
	, iAB tinyint unsigned
	, iPA tinyint unsigned
	, index sBatterID (sBatterID, iYear)
	, index sPitcherID (sPitcherID, iYear)
	)
	engine=InnoDB;

describe PlateApps;

#-----------------------------------------
# Add key constraints

/*
alter table PlateApps
	add constraint fkPlateApps_BatterID
	foreign key (sBatterID) references Teams(iTeamID)
	on update cascade
	on delete cascade;

alter table PlateApps
	add constraint fkPlateApps_Team_H
	foreign key (iTeamID_H) references Teams(iTeamID)
	on update cascade
	on delete cascade;

alter table PlateApps
	add constraint fkPlateApps_Team_A
	foreign key (iTeamID_A) references Teams(iTeamID)
	on update cascade
	on delete cascade;
	
alter table Teams_NameMap
	add constraint fkTeamNameMap
	foreign key (iTeamID) references Teams(iTeamID)
	on update cascade
	on delete cascade;
*/
	
/* For next run, add the following
# =========================================

# View <PlateApps_TeamName>
set @step = 'create PlateApps_TeamName';
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));

drop view if exists PlateApps_TeamName_H;
create view PlateApps_TeamName_H as
	select
		g.iGameID
		, g.dGameDate
		, t.cTeamName as cTeamName_H
		, g.iGF_Team_H
		, g.iGF_Team_A
		, g.fRating_Pre_H
		, g.fRating_Pre_A
		, g.fRating_Inc_H
		, g.fEGD
	from PlateApps g inner join Teams t
	on g.iTeamID_H = t.iTeamID
	where g.iCompID=1 and g.iSeasonYE=2014
	;

drop view if exists PlateApps_TeamName_A;
create view PlateApps_TeamName_A as
	select
		g.iGameID
		, t.cTeamName as cTeamName_A
	from PlateApps g inner join Teams t
	on g.iTeamID_A = t.iTeamID
	;

drop view if exists PlateApps_TeamName;
create view PlateApps_TeamName as
	select
		h.dGameDate
		, h.cTeamName_H
		, a.cTeamName_A
		, h.iGF_Team_H
		, h.iGF_Team_A
		, h.fRating_Pre_H
		, h.fRating_Pre_A
		, h.fRating_Inc_H
		, h.fEGD
	from PlateApps_TeamName_H h inner join PlateApps_TeamName_A a
	on h.iGameID = a.iGameID
	;
*/

#=========================================
# Last Step: Tidy up

set @step = 'Tidy Up';
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));

#=========================================

set @step = concat('End ',@ProgName);
select @step;
call RunUDVCode(concat('insert into ', @LogFile, '(StepDesc, StepTime) value ("',@step, '", current_timestamp());'));
