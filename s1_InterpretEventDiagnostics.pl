#!/usr/bin/perl
# s1_InterpretEventDiagnostics

# Read event files, interpret all contained events, optionally write events to database
# Use to create diagnostic database to investigate problems with event interpretation
# Need to fix code that creates sEventRun 

package s1_InterpretEventDiagnostics;

our $VERSION = 0.9;

push(@Inc, 'pwd');

use warnings;
use strict;
use Readonly;
use Data::Dumper;
use Text::ParseWords;
use Switch;
use DBI;
use DBI qw(:sql_types);
use List::Util qw(min max);

use user::RetrosheetUserModules qw(ParseGL);
use user::RetrosheetUserModules qw(ParsePxP_IDRec);
use user::RetrosheetUserModules qw(ParsePxP_PlayRec);
use user::RetrosheetUserModules qw(ParsePxP_PlayerRec);
use user::RetrosheetUserModules qw(ParsePxP_DataRec);
use user::RetrosheetUserModules qw(ParsePxP_InfoRec);
use user::RetrosheetUserModules qw(InterpretEvent);
use user::RetrosheetUserModules qw(ResetGame);
use user::RetrosheetUserModules qw(ResetInning);
use user::RetrosheetUserModules qw(ParsePxP_Event);
use user::RetrosheetUserModules qw(CheckGameStatus);

Readonly my $ERR => -1;
Readonly my $TRUE =>  1;
Readonly my $FALSE =>  0;
Readonly my $SrcDir => <replace with path to source files>;

Readonly my $db_name => <replace with MySQL database name>;
Readonly my $user_name => <replace with MySQL database user name>;
Readonly my $password => <replace with MySQL database user password>;
Readonly my $PitchLineTable => <replace with MySQL database destination table name>;

Readonly my $MaxSrcLen => 80;

my $Write2DB;
my $PrintAllEvents;
my $PrintUnclearEvents;
my $RunAll;
my $CleanOutTables;
my $PickMe = $FALSE;
my $NumFiles;
$NumFiles = 2000; # 1970 - 2015 plus all post-season contains about 1500 files, about 9M records

$PickMe = $TRUE;
# All files, limited by NumFiles, erase and rewrite database table, print problems;
if ($PickMe == $TRUE) {
	$Write2DB = $TRUE;
	$PrintAllEvents = $FALSE;
	$PrintUnclearEvents = $TRUE;
	$RunAll = $TRUE;
	$CleanOutTables = $TRUE;
	$PickMe = $FALSE;
	}

# All files, limited by NumFiles, do not erase and rewrite database table, print problems;
if ($PickMe == $TRUE) {
	$Write2DB = $FALSE;
	$PrintAllEvents = $FALSE;
	$PrintUnclearEvents = $TRUE;
	$RunAll = $TRUE;
	$CleanOutTables = $FALSE;
	$PickMe = $FALSE;
	}

# One file, do not erase or write to database, print problems;
if ($PickMe == $TRUE) {
	$Write2DB = $FALSE;
	$PrintAllEvents = $FALSE;
	$PrintUnclearEvents = $TRUE;
	$RunAll = $FALSE;
	$CleanOutTables = $FALSE;
	$PickMe = $FALSE;
	}

# One file, erase and write database table, print problems;
if ($PickMe == $TRUE) {
	$Write2DB = $TRUE;
	$PrintAllEvents = $FALSE;
	$PrintUnclearEvents = $TRUE;
	$RunAll = $FALSE;
	$CleanOutTables = $TRUE;
	$PickMe = $FALSE;
	}

# Definition of data structures
# BatEvent_hash_ref
# $BatEvent_hash_ref -> {SrcText};
# $BatEvent_hash_ref -> {EventBat}
# $BatEvent_hash_ref -> {PAFlag};
# $BatEvent_hash_ref -> {Pitches};
# $BatEvent_hash_ref -> {Outcome};
# $BatEvent_hash_ref -> {Clarity};
# $BatEvent_hash_ref -> {EventBucket};

#---------------------------------------------------------------------;
# Create connection
my $dbh;
my $sth_EventBat;

if ($Write2DB == $TRUE) {
	$dbh = DBI->connect("dbi:mysql:$db_name","$user_name","$password")
		or die "Connection Error: $DBI::errstr\n";
	$dbh->{RaiseError} = 1;
	if ($CleanOutTables == $TRUE) {CleanOutTables($dbh);};
	$sth_EventBat = PrepIns_EventBat ($dbh);
	}

#---------------------------------------------------------------------;
# Read all files in directory
# Write out all game final to res.txt
# Write out unclear plays to UnparsedEvents.txt

print "GameID\tLineCount\tSrcText\tPAFlag\tPitches\tOutcome\tClarity\tEventBucket\n";

if ($RunAll == $TRUE){

	my $FileCnt = 1;
	opendir RSDIR, $SrcDir or die "can't open directory .: $!\n";
	while (readdir RSDIR) {
		if (( $_ =~ /\.EV/ ) and ($FileCnt <=$NumFiles)) {
			my $InFileFullPath = $SrcDir . $_;
			ProcessFile($InFileFullPath);
			$FileCnt ++;
			}
		}

	close RSDIR;
	}

#---------------------------------------------------------------------;
# Read one file
# Write out all game final to res.txt
# Write out all PAs

if ($RunAll == $FALSE){
	#my $InFileName = '1930BOS.EVA';
	my $InFileName = '1960WS.EVE';
	#my $InFileName = '1980CLE.EVA';
	#my $InFileName = '2010CLE.EVA';
	#my $InFileName = '2010WAS.EVN';
	#my $InFileName = '2011CIN.EVN';
	#my $InFileName = '2012SLN.EVN';
	#my $InFileName = '2012HOU.EVN';
	#my $InFileName = '2013OAK.EVA';
	#my $InFileName = '2013WAS.EVN';
	#my $InFileName = '2014PIT.EVN';
	#my $InFileName = '2014SLN.EVN';

	my $InFileFullPath = $SrcDir . $InFileName;
	ProcessFile($InFileFullPath);
	}

#---------------------------------------------------------------------;
# Close database connection

if ($Write2DB == $TRUE) {
	$dbh->disconnect;
	}

#---------------------------------------------------------------------;
;

#=====================================================================;
#---------------------------------------------------------------------;
sub ProcessFile{
my $InFileFullPath = $_[0];

#print "Input file: $InFileFullPath\n";

open(my $InFileHandle, '<:encoding(UTF-8)', $InFileFullPath)
	or die "Could not open file '$InFileFullPath' $!";

my $BatEvent_hash_ref = ();
my $GameStatus_hash_ref = ResetGame();
my $GameID = 'NULL';
my $LineCount = 0;

my $PrevInningHalf = 1;
my $InningHalf = 0;
while (my $row = <$InFileHandle>) {

	chomp $row;
	if ($row =~ /^id/) {
		$GameStatus_hash_ref = ResetGame();
		$BatEvent_hash_ref = ();
		my $GameID_hash_ref = ParsePxP_IDRec($row);
		$GameID = $GameID_hash_ref -> {GameID};
		$PrevInningHalf = 1;
		$InningHalf = 0;
		}
	if ($row =~ /^play/) {
		my $Play_hash_ref = ParsePxP_PlayRec($row);
		my $Event = $Play_hash_ref -> {Event};
		if (defined $Event) {
			$BatEvent_hash_ref -> {SrcText} = $row;
			my ($EventBat, @EventRuns) = ParsePxP_Event($Event);
			$BatEvent_hash_ref -> {EventBat} = $EventBat;
			$InningHalf = $Play_hash_ref -> {Half};
			if ($InningHalf != $PrevInningHalf) {$GameStatus_hash_ref = ResetInning($GameStatus_hash_ref);}
			$PrevInningHalf = $InningHalf;
			my $TotRuns_prev = $GameStatus_hash_ref -> {AwayRuns} + $GameStatus_hash_ref -> {HomeRuns};
			my $Outs_prev = $GameStatus_hash_ref -> {Outs};
			my $OnBaseCount_prev = $GameStatus_hash_ref -> {B1Occ} + $GameStatus_hash_ref -> {B2Occ} + $GameStatus_hash_ref -> {B3Occ};

			($GameStatus_hash_ref, my $PAFlag, my $Pitches, my $Outcome, my $Clarity, my $EventBucket, my $StatusProblems) = InterpretEvent($Play_hash_ref, $GameStatus_hash_ref, $TRUE);
			$BatEvent_hash_ref -> {PAFlag} = $PAFlag;
			$BatEvent_hash_ref -> {Pitches} = $Pitches;
			$BatEvent_hash_ref -> {Outcome} = $Outcome;
			$BatEvent_hash_ref -> {Clarity} = $Clarity;
			$BatEvent_hash_ref -> {EventBucket} = $EventBucket;
			#if ((1202<$LineCount) and ($LineCount<1368)){my $Outs = $GameStatus_hash_ref -> {Outs};print "$row, $Outcome, $Outs\n";}#debug;
			WriteEventDiags($BatEvent_hash_ref, $GameID, $LineCount, $Event);
			if ($StatusProblems == $TRUE) {WriteGameStatus($GameStatus_hash_ref, $BatEvent_hash_ref, $GameID, $LineCount);}
			}
		else {die "Undefined event value, $GameID, $LineCount";}
		
		}
	$LineCount++;
	}
}

#---------------------------------------------------------------------;
sub WriteGameStatus{
# example call: WriteGameStatus($GameStatus_hash_ref, $BatEvent_hash_ref, $GameID, $LineCount);
my ($GameStatus_hash_ref, $BatEvent_hash_ref, $GameID, $LineCount) = ($_[0], $_[1], $_[2], $_[3]);

my $SrcText = substr($BatEvent_hash_ref -> {SrcText}, 0, $MaxSrcLen);
my $EventBat = substr($BatEvent_hash_ref -> {EventBat}, 0, $MaxSrcLen);
my $PAFlag = $BatEvent_hash_ref -> {PAFlag};
my $Pitches = $BatEvent_hash_ref -> {Pitches};
my $Outcome = $BatEvent_hash_ref -> {Outcome};
my $Clarity = $BatEvent_hash_ref -> {Clarity};
my $EventBucket = $BatEvent_hash_ref -> {EventBucket};
my $Outs = $GameStatus_hash_ref -> {Outs};
my $B1Occ = $GameStatus_hash_ref -> {B1Occ};
my $B2Occ = $GameStatus_hash_ref -> {B2Occ};
my $B3Occ = $GameStatus_hash_ref -> {B3Occ};
print "game status problem\n";
print "$GameID\t$LineCount\t$SrcText\t$EventBat\t$PAFlag\t$Pitches\t$Outcome\t$Clarity\t$EventBucket\t$Outs\t$B1Occ\t$B2Occ\t$B3Occ\n";

return 1;
}

#---------------------------------------------------------------------;
sub WriteEventDiags{
# example call: WriteEventDiags($BatEvent_hash_ref, $GameID, $LineCount, $Event);
my ($BatEvent_hash_ref, $GameID, $LineCount, $Event) = ($_[0], $_[1], $_[2], $_[3]);

my $SrcText = substr($BatEvent_hash_ref -> {SrcText}, 0, $MaxSrcLen);
my $PlayDesc = $Event;
my $EventBat = substr($BatEvent_hash_ref -> {EventBat}, 0, $MaxSrcLen);
my $PAFlag = $BatEvent_hash_ref -> {PAFlag};
my $Pitches = $BatEvent_hash_ref -> {Pitches};
my $Outcome = $BatEvent_hash_ref -> {Outcome};
my $Clarity = $BatEvent_hash_ref -> {Clarity};
my $EventBucket = $BatEvent_hash_ref -> {EventBucket};

if (($PrintAllEvents == $TRUE) or (($PrintUnclearEvents == $TRUE) and ($Clarity == $FALSE))){
	print "$GameID\t$LineCount\t$SrcText\t$EventBat\t$PAFlag\t$Pitches\t$Outcome\t$Clarity\t$EventBucket\n";
	}

if ($Write2DB == $TRUE) {
	$sth_EventBat->execute(
		$GameID
		, $LineCount
		, $SrcText
		, $PlayDesc
		, $EventBat
		, $PAFlag
		, $Pitches
		, $Outcome
		, $Clarity
		, $EventBucket
		)
		or die "SQL Error: $DBI::errstr\n";
	}

return 1;
}

#---------------------------------------------------------------------;
sub CleanOutTables{
# example call: CleanOutTables($dbh);
# Use existing table
# use truncate command, which resets the auto_increment counter to 0
# https://dev.mysql.com/doc/refman/5.0/en/truncate-table.html

my $dbh = $_[0];

# Clean out existing Pitching Line table
my $sql = "truncate table $EventDiagTable_Bat";
my $sth = $dbh->prepare($sql);
$sth->execute
	or die "SQL Error: $DBI::errstr\n";

return 1;
}

#---------------------------------------------------------------------;
sub PrepIns_EventBat {
# example call: $sth_EventBat = PrepIns_EventBat ($dbh);

my $dbh = $_[0];
my $sql = qq{
	insert into $EventDiagTable_Bat (
		sGameID
		, iLineCount
		, sSrcText
		, sPlayDesc
		, sEventBat
		, iPAFlag
		, iPitches
		, sOutcome
		, iClarity
		, sEventBucket
		)
	values(
		?
		, ?
		, ?
		, ?
		, ?
		, ?
		, ?
		, ?
		, ?
		, ?
		)
	};

my $sth_EventBat = $dbh->prepare($sql);

return ($sth_EventBat);
}

#---------------------------------------------------------------------;
;