#!/usr/bin/perl
# s2_WritePlateApps

package s2_WritePlateApps;

our $VERSION = 0.9;

push(@Inc, 'pwd');

use warnings;
use strict;
use Readonly;
use Text::ParseWords;
use Switch;
use DBI;
use DBI qw(:sql_types);
use List::Util qw(min max);

Readonly my $ERR => -1;
Readonly my $TRUE =>  1;
Readonly my $FALSE =>  0;
Readonly my $SrcDir => <replace with path to source files>;

Readonly my $db_name => <replace with MySQL database name>;
Readonly my $user_name => <replace with MySQL database user name>;
Readonly my $password => <replace with MySQL database user password>;
Readonly my $PitchLineTable => <replace with MySQL database destination table name>;

my $Write2DB = $TRUE;
my $RunAll = $TRUE;
my $NumFiles = 400;
#$RunAll = $FALSE;

#---------------------------------------------------------------------;
# Create connection
my $dbh;
my $sql;
my $sth;


if ($Write2DB == $TRUE) {
	$dbh = DBI->connect("dbi:mysql:$db_name","$user_name","$password")
		or die "Connection Error: $DBI::errstr\n";
	$dbh->{RaiseError} = 1;
	$sth = PreLoadSQL ($dbh);
	}

#---------------------------------------------------------------------;
# Read all files in directory
# Write out all game final to res.txt
# Write out unclear plays to UnparsedEvents.txt

print "Date\tHome\tHomeRuns\tAway\tAwayRuns\tPlays\tPlayers\n";

my $WriteAllPAs;
my $WriteAllPlays;
my $OutFileHandle;

if ($RunAll == $TRUE){
	#$WriteAllPAs = $TRUE;
	#$WriteAllPlays = $TRUE;
	$WriteAllPAs = $FALSE;
	$WriteAllPlays = $FALSE;

	my $OutFileName = 'UnparsedEvents.txt';
	my $OutFileFullPath = $SrcDir . $OutFileName;

	open($OutFileHandle, '>', $OutFileFullPath) or die "Could not open file '$OutFileFullPath' $!";
	print $OutFileHandle "Event\tOutcome\tClarity\tBatter\tPitcher\tInning\tCount\tPitcherLead\tOuts\tB1Occ\tB2Occ\tB3Occ\tCurBatterInOrder\tOnDeckBatterID\tPitches\tPitchCount\tPitcherLead\tGameDate\tGameSeq\tStadium\tLineCount\n";
	#print $OutFileHandle "$Event\t$Outcome\t$Clarity\t$Batter\t$Pitcher\t$Inning\t$Count\t$PitcherLead\t$Outs\t$B1Occ\t$B2Occ\t$B3Occ\t$CurBatterInOrder\t$OnDeckBatterId\t$Pitches\t$PitchCount\t$PitcherLead\t$GameDate\t$GameSeq\t$Stadium\t$LineCount\n";

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

	close $OutFileHandle;
	}

#---------------------------------------------------------------------;
# Read one file
# Write out all game final to res.txt
# Write out all PAs

if ($RunAll == $FALSE){
	#my $InFileName = '2010CLE.EVA';
	#my $InFileName = '2010WAS.EVN';
	my $InFileName = '2011CIN.EVN';
	#my $InFileName = '2012SLN.EVN';
	#my $InFileName = '2012HOU.EVN';
	#my $InFileName = '2013OAK.EVA';
	#my $InFileName = '2013WAS.EVN';
	#my $InFileName = '2014PIT.EVN';
	#my $InFileName = '2014SLN.EVN';

	my $OutFileName = substr($InFileName,0,7) . '.txt';
	my $InFileFullPath = $SrcDir . $InFileName;
	my $OutFileFullPath = $SrcDir . $OutFileName;

	open($OutFileHandle, '>', $OutFileFullPath) or die "Could not open file '$OutFileFullPath' $!";
	print $OutFileHandle "Event\tOutcome\tClarity\tBatter\tPitcher\tInning\tCount\tPitcherLead\tOuts\tB1Occ\tB2Occ\tB3Occ\tCurBatterInOrder\tOnDeckBatterID\tPitches\tPitchCount\tPitcherLead\tGameDate\tGameSeq\tStadium\tLineCount\n";	

	$WriteAllPAs = $TRUE;
	$WriteAllPlays = $TRUE;

	ProcessFile($InFileFullPath);

	close $OutFileHandle;
	}

#---------------------------------------------------------------------;
# Close database connection

if ($Write2DB = $TRUE) {
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

my $LineCount = 0;
my $GameStatus_hash_ref = ResetGame();

#Game info;
my $PrevInningHalf = 0;
my $InningHalf;
my @Pitchers = ('HNULL','ANULL');
my @PitchCounts = (0, 0);
my @BattingOrders;

while (my $row = <$InFileHandle>) {
	my $Player_hash_ref;

	chomp $row;
	if ($row =~ /^id/) {
		if ($LineCount>0) {ReportGame($GameStatus_hash_ref);}; #report previous game;
		$GameStatus_hash_ref = ResetGame();
		$GameStatus_hash_ref -> {GameDate} = substr $row, 6, 8;
		$GameStatus_hash_ref -> {GameSeq} = substr $row, 14, 1;
		}
	if ($row =~ /^info,site/) {$GameStatus_hash_ref -> {Stadium} = substr $row, 10, 5;}
	if ($row =~ /^info,visteam/) {$GameStatus_hash_ref -> {AwayTeam} = substr $row, 13, 3;}
	if ($row =~ /^info,hometeam/) {$GameStatus_hash_ref -> {HomeTeam} = substr $row, 14, 3;}
	if ($row =~ /^play/) {
		my $Play_hash_ref = ParsePlay($row);
		$InningHalf = $Play_hash_ref -> {Half};
		if ($InningHalf != $PrevInningHalf) {$GameStatus_hash_ref = ResetInning($GameStatus_hash_ref);}
		$PrevInningHalf = $InningHalf;
		my $PreGameStatus_hash_ref = { %$GameStatus_hash_ref };
		my ($GameStatus_hash_ref, $PAFlag, $Pitches, $Outcome, $Clarity) = InterpretEvent($Play_hash_ref, $GameStatus_hash_ref);
		my $Prob = $FALSE;
		if (($GameStatus_hash_ref -> {Outs} >3) || 
			($GameStatus_hash_ref -> {B1Occ} <0) || ($GameStatus_hash_ref -> {B1Occ} >1) ||
			($GameStatus_hash_ref -> {B2Occ} <0) || ($GameStatus_hash_ref -> {B2Occ} >1) ||
			($GameStatus_hash_ref -> {B3Occ} <0) || ($GameStatus_hash_ref -> {B3Occ} >1))
				{$Prob = $TRUE;}
		my $WriteThisPlay = (($WriteAllPAs == $TRUE) || ($Clarity == $FALSE) || ($WriteAllPlays == $TRUE) || ($Prob == $TRUE));
		my $CurBatterInOrder;
		my $OnDeck;
		my $OnDeckBatterId;
		if (($WriteThisPlay == $TRUE) || ($Write2DB == $TRUE)){
			$CurBatterInOrder = FindSpotInOrder(($Play_hash_ref -> {PlayerID}), @{ $BattingOrders[$InningHalf] });
			$OnDeck = 1 + ($CurBatterInOrder % 9);
			$OnDeckBatterId = $BattingOrders[$InningHalf][$OnDeck];
			}
		if ($WriteThisPlay == $TRUE) {WritePA2File($Play_hash_ref, $PreGameStatus_hash_ref, $Pitchers[1-$InningHalf], $Pitches, $PitchCounts[1-$InningHalf], $OnDeckBatterId, $Outcome, $CurBatterInOrder, $Clarity, $PAFlag, $LineCount);}
		if ($Prob == $TRUE) {WritePA2File($Play_hash_ref, $GameStatus_hash_ref, $Pitchers[1-$InningHalf], $Pitches, $PitchCounts[1-$InningHalf], $OnDeckBatterId, $Outcome, $CurBatterInOrder, $Clarity, $LineCount);}
		if ($Write2DB == $TRUE) {WritePA2DB($Play_hash_ref, $PreGameStatus_hash_ref, $Pitchers[1-$InningHalf], $Pitches, $PitchCounts[1-$InningHalf], $OnDeckBatterId, $Outcome, $CurBatterInOrder, $Clarity, $PAFlag, $LineCount, $sth);}
		$PitchCounts[1-$InningHalf] = $PitchCounts[1-$InningHalf] + $Pitches;
		$GameStatus_hash_ref -> {PlayCount} ++;
		}
	if (($row =~ /^start/) || ($row =~ /^sub/)) {
		$Player_hash_ref = ParsePlayer($row);
		$BattingOrders[($Player_hash_ref -> {HomeFlag})][($Player_hash_ref -> {BatOrder})] = $Player_hash_ref -> {PlayerID};
		if (($Player_hash_ref -> {FieldPos}) == 1){
			$Pitchers[($Player_hash_ref -> {HomeFlag})] = $Player_hash_ref -> {PlayerID};
			$PitchCounts[($Player_hash_ref -> {HomeFlag})] = 0;
			}
		$GameStatus_hash_ref -> {PlayerCount}++;
		}
	$LineCount++;
	}
ReportGame($GameStatus_hash_ref);
;
}

#---------------------------------------------------------------------;
sub ParsePlay{
# $PlayText = play,1,0,gardb001,11,BCX,3/G

my $PlayText = $_[0];

my @chunks = quotewords(",", 0, $PlayText);

my $RecType = $chunks[0];
my $Inning = $chunks[1];
my $Half = $chunks[2];
my $PlayerID = $chunks[3];
my $Count = $chunks[4];
my $PitchSeq = $chunks[5];
my $Event = $chunks[6];

my $Play_hash_ref = {
	RecType => $RecType
	, Inning => $Inning
	, Half => $Half
	, PlayerID => $PlayerID
	, Count => $Count
	, PitchSeq => $PitchSeq
	, Event => $Event
	};

return $Play_hash_ref;

}

#---------------------------------------------------------------------;
sub ParsePlayer{

# $PlayerText = 'start,calhk001,"Kole Calhoun",0,1,9';

my $PlayerText = $_[0];

my @chunks = quotewords(",", 0, $PlayerText);

my $RecType = $chunks[0];
my $PlayerID = $chunks[1];
my $PlayerName = $chunks[2];
my $HomeFlag = $chunks[3];
my $BatOrder = $chunks[4];
my $FieldPos = $chunks[5];

my $Player_hash_ref = {RecType => $RecType, PlayerID => $PlayerID, PlayerName => $PlayerName, HomeFlag => $HomeFlag, BatOrder => $BatOrder, FieldPos => $FieldPos};

return $Player_hash_ref;

}

#---------------------------------------------------------------------;
sub ResetGame{

my $GameStatus_hash_ref = {
	BatterInInning => 0
	, Outs => 0
	, B1Occ => $FALSE
	, B2Occ => $FALSE
	, B3Occ => 0
	, PlayCount => 0
	, PlayerCount => 0
	, PrevInningHalf => 0
	, HomeRuns => 0
	, AwayRuns => 0
	, GameDate => $ERR
	, GameSeq => $ERR
	, Stadium => 'NULL'
	, AwayTeam => 'NULL'
	, HomeTeam => 'NULL'
	};

return ($GameStatus_hash_ref);
}

#---------------------------------------------------------------------;
sub ResetInning{

my $GameStatus_hash_ref = $_[0];

$GameStatus_hash_ref -> {BatterInInning} = 0;
$GameStatus_hash_ref -> {Outs} = 0;
$GameStatus_hash_ref -> {B1Occ} = 0;
$GameStatus_hash_ref -> {B2Occ} = 0;
$GameStatus_hash_ref -> {B3Occ} = 0;

return ($GameStatus_hash_ref);
}

#---------------------------------------------------------------------;
sub WritePA2File{
#WritePA2File($Play_hash_ref, $GameStatus_hash_ref, $Pitcher, $Pitches, $PitchCount, $OnDeckBatterId, $Outcome, $CurBatterInOrder, $Clarity, $PAFlag, $LineCount);
my ($Play_hash_ref, $GameStatus_hash_ref, $Pitcher, $Pitches, $PitchCount, $OnDeckBatterId, $Outcome, $CurBatterInOrder, $Clarity, $PAFlag, $LineCount) = (@_);

my $Event = $Play_hash_ref -> {Event};
my $Batter = $Play_hash_ref -> {PlayerID};
my $Inning = $Play_hash_ref -> {Inning};
my $Count = $Play_hash_ref -> {Count};
my $Half =  $Play_hash_ref -> {Half};
my $PitcherLead = $GameStatus_hash_ref -> {HomeRuns} - $GameStatus_hash_ref -> {AwayRuns};
if ($Half == 1) {$PitcherLead = -$PitcherLead;}

my $Outs = $GameStatus_hash_ref -> {Outs};
my $B1Occ = $GameStatus_hash_ref -> {B1Occ};
my $B2Occ = $GameStatus_hash_ref -> {B2Occ};
my $B3Occ = $GameStatus_hash_ref -> {B3Occ};
my $GameDate = $GameStatus_hash_ref -> {GameDate};
my $GameSeq = $GameStatus_hash_ref -> {GameSeq};
my $Stadium = $GameStatus_hash_ref -> {Stadium};

print $OutFileHandle "$Event\t$Outcome\t$Clarity\t$Batter\t$Pitcher\t$Inning\t$Count\t$PitcherLead\t$Outs\t$B1Occ\t$B2Occ\t$B3Occ\t$CurBatterInOrder\t$OnDeckBatterId\t$Pitches\t$PitchCount\t$PitcherLead\t$GameDate\t$GameSeq\t$Stadium\t$LineCount\n";

return 1;
}

#---------------------------------------------------------------------;
sub WritePA2DB{
#WritePA2DB($Play_hash_ref, $GameStatus_hash_ref, $Pitchers[1-$InningHalf], $Pitches, $PitchCounts[1-$InningHalf], $OnDeckBatterId, $Outcome, $CurBatterInOrder, $Clarity, $PAFlag, $LineCount, $sth);
my ($Play_hash_ref, $GameStatus_hash_ref, $sPitcherID, $iPitches, $iPitchCount, $sOnDeckBatterId, $sOutcome, $iCurBatterInOrder, $iClarity, $PAFlag, $iLineCount, $sth) = (@_);

my $sEvent = $Play_hash_ref -> {Event};
my $sBatterID = $Play_hash_ref -> {PlayerID};
my $iInning = $Play_hash_ref -> {Inning};
my $iCount = $Play_hash_ref -> {Count};
my $Half = $Play_hash_ref -> {Half};

my $iOuts = $GameStatus_hash_ref -> {Outs};
my $iB1Occ = $GameStatus_hash_ref -> {B1Occ};
my $iB2Occ = $GameStatus_hash_ref -> {B2Occ};
my $iB3Occ = $GameStatus_hash_ref -> {B3Occ};
my $iGameSeq = $GameStatus_hash_ref -> {GameSeq};
my $sStadium = $GameStatus_hash_ref -> {Stadium};
my $GameDate = $GameStatus_hash_ref -> {GameDate};

my $iPitcherLead = $GameStatus_hash_ref -> {HomeRuns} - $GameStatus_hash_ref -> {AwayRuns};
if ($Half == 1) {$iPitcherLead = -$iPitcherLead;}

my $iYear = substr($GameDate, 0, 4);
my $dGameDate = $iYear . "-" . substr($GameDate, 4, 2) . "-" . substr($GameDate, 6, 2);

my $iHit = 0;
my $iBB = 0;
my $iHBP = 0;
my $iSF = 0;
my $iSH = 0;
my $iTB = 0;
my $iPA = 0;

if ($sOutcome ~~ ['S','D','T','HR']) {
	$iHit=1;
	if ($sOutcome eq 'HR') {$iTB=4;}
	elsif ($sOutcome eq 'T') {$iTB=3;}
	elsif ($sOutcome eq 'D') {$iTB=2;}
	elsif ($sOutcome eq 'S') {$iTB=1;}
	}
if ($sOutcome ~~ ['BB','IBB']) {$iBB=1;}
if ($sOutcome eq 'HBP') {$iHBP=1;}
if ($sOutcome eq 'SF') {$iSF=1;}
if ($sOutcome eq 'SH') {$iSH=1;}
if ($PAFlag == $TRUE) {$iPA=1;}
my $iAB = $iPA - max(($iBB, $iHBP, $iSF, $iSH));
if ($sOutcome ~~ ['CI']) {$iAB=0;}

$sth->execute(
$iYear
, $dGameDate
, $iGameSeq
, $sBatterID
, $sPitcherID
, $sEvent
, $sOutcome
, $iClarity
, $iInning
, $iCount
, $iOuts
, $iB1Occ
, $iB2Occ
, $iB3Occ
, $iCurBatterInOrder
, $sOnDeckBatterId
, $iPitches
, $iPitchCount
, $iPitcherLead
, $sStadium
, $iLineCount
, $iHit
, $iBB
, $iHBP
, $iSH
, $iSF
, $iTB
, $iAB
, $iPA
)
	or die "SQL Error: $DBI::errstr\n";

return 1;
}

#---------------------------------------------------------------------;
sub ReportGame{
my ($GameStatus_hash_ref) = ($_[0]);

my $ResVar;

$ResVar = $GameStatus_hash_ref -> {GameDate};
print "$ResVar\t";

$ResVar = $GameStatus_hash_ref -> {HomeTeam};
print "$ResVar\t";

$ResVar = $GameStatus_hash_ref -> {HomeRuns};
print "$ResVar\t";

$ResVar = $GameStatus_hash_ref -> {AwayTeam};
print "$ResVar\t";

$ResVar = $GameStatus_hash_ref -> {AwayRuns};
print "$ResVar\t";

$ResVar = $GameStatus_hash_ref -> {PlayCount};
print "$ResVar\t";

$ResVar = $GameStatus_hash_ref -> {PlayerCount};
print "$ResVar\n";

return 1;
}

#---------------------------------------------------------------------;
sub InterpretEvent{

my ($Play_hash_ref, $lpGameStatus_hash_ref) = ($_[0], $_[1]);

my $Half = $Play_hash_ref -> {Half}; #0 = top, 1 = bottom;
my $PitchSeq = $Play_hash_ref -> {PitchSeq};
my $PitchCount = $PitchSeq =~ tr/[A-Z]//;
my $Pitches = 0;
if ($PitchCount>0) {$Pitches = $PitchCount;}

my $PAFlag = $TRUE;
my $Outcome = "OTH";
my $Clarity = $FALSE;
my @NoRunRec = ($TRUE,$TRUE,$TRUE,$TRUE);
my $Runs = 0;
my $Outs_pre = $lpGameStatus_hash_ref -> {Outs};

# Process EventRun
# Deal with base-runners advancing and caught, in arbitrary order

my $Event = $Play_hash_ref -> {Event};

my ($EventBat, @EventRuns) = ParseEvent($Event);

foreach my $EventRun(@EventRuns) {
	my $StartBase = substr $EventRun, 0, 1;
	my $EndBase = substr $EventRun, 2, 1;
	
	if (($EventRun =~ /\dX/) || ($EventRun =~ /\d-/)) {
		DecBase($StartBase, $lpGameStatus_hash_ref);
		$NoRunRec[$StartBase] = $FALSE;
		}
	if ($StartBase eq "B") {$NoRunRec[0] = $FALSE;}
	if ($EventRun =~ /-\d/) {IncBase($EndBase, $lpGameStatus_hash_ref);}
	if ($EventRun =~ /-H/) {$Runs ++;}
	if ($EventRun =~ /X/) {
		my $Out = $TRUE;
		if ($EventRun =~ /E/) {
			if ($EventRun =~ /XH\([1-9]{1,3}2\)/) {$Out = $TRUE;}
			elsif ($EventRun =~ /X3\([1-9]{1,3}5\)/) {$Out = $TRUE;}
			else {$Out = $FALSE;}
			}
		if ($Out == $TRUE) {$lpGameStatus_hash_ref -> {Outs} ++;}
		else {
			if ($EventRun =~ /X\d/) {IncBase($EndBase, $lpGameStatus_hash_ref);}
			elsif ($EventRun =~ /XH/) {$Runs ++;}}
			}
		}

switch ($EventBat) {
	case "NP"		{$Outcome = "NP";$PAFlag = $FALSE;$Clarity = $TRUE;} #No play; used to mark substitutions;
	case /^WP/		{$Outcome = "WP";$PAFlag = $FALSE;$Clarity = $TRUE;} #Wild pitch; relevant info in $EventRun;
	case /^DI/		{$Outcome = "DI";$PAFlag = $FALSE;$Clarity = $TRUE;} #Defensive indifference; relevant info in $EventRun;
	case /^PB/		{$Outcome = "PB";$PAFlag = $FALSE;$Clarity = $TRUE;} #Pass ball; relevant info in $EventRun;
	case /^BK/		{$Outcome = "BK";$PAFlag = $FALSE;$Clarity = $TRUE;} #Balk; relevant info in $EventRun;
	case /^OA/		{$Outcome = "OA";$PAFlag = $FALSE;$Clarity = $TRUE;} #Other advance; relevant info in $EventRun;
	case /^FLE/		{$Outcome = "E";$PAFlag = $FALSE;$Clarity = $TRUE;} #Error on foul ball;
	case /^SB/ {
		$Outcome = "SB";
		$PAFlag = $FALSE;
		$Clarity = $TRUE;
		if (($EventBat =~ /SBH/) && ($NoRunRec[3] == $TRUE)) {
			$Runs ++;
			$lpGameStatus_hash_ref -> {B3Occ}--;
			}
		if (($EventBat =~ /SB3/) && ($NoRunRec[2] == $TRUE)) {
			$lpGameStatus_hash_ref -> {B2Occ}--;
			$lpGameStatus_hash_ref -> {B3Occ}++;
			}
		if (($EventBat =~ /SB2/) && ($NoRunRec[1] == $TRUE)) {
			$lpGameStatus_hash_ref -> {B1Occ}--;
			$lpGameStatus_hash_ref -> {B2Occ}++;
			}
		}
	case /^CS/ {
		$Outcome = "CS";
		$PAFlag = $FALSE;
		$Clarity = $TRUE;
		if (($EventBat =~ /CSH/) && ($NoRunRec[3] == $TRUE)) {$lpGameStatus_hash_ref -> {B3Occ} --;}
		if (($EventBat =~ /CS3/) && ($NoRunRec[2] == $TRUE)) {$lpGameStatus_hash_ref -> {B2Occ} --;}
		if (($EventBat =~ /CS2/) && ($NoRunRec[1] == $TRUE)) {$lpGameStatus_hash_ref -> {B1Occ} --;}
		if ($EventBat =~ /E/) {
			if (($EventBat =~ /CSH/) && ($NoRunRec[3] == $TRUE)) {$Runs ++;}
			if (($EventBat =~ /CS3/) && ($NoRunRec[2] == $TRUE)) {$lpGameStatus_hash_ref -> {B3Occ} ++;}
			if (($EventBat =~ /CS2/) && ($NoRunRec[1] == $TRUE)) {$lpGameStatus_hash_ref -> {B2Occ} ++;}
			}
		else {
			$lpGameStatus_hash_ref -> {Outs} ++;
			}
		}
	case /^PO/ {
		$Outcome = "CS";
		$PAFlag = $FALSE;
		$Clarity = $TRUE;
		if (($EventBat =~ /POCSH/) && ($NoRunRec[3] == $TRUE)) {$lpGameStatus_hash_ref -> {B3Occ} --;}
		if (($EventBat =~ /POCS3/) && ($NoRunRec[2] == $TRUE)) {$lpGameStatus_hash_ref -> {B2Occ} --;}
		if (($EventBat =~ /POCS2/) && ($NoRunRec[1] == $TRUE)) {$lpGameStatus_hash_ref -> {B1Occ} --;}
		if ($EventBat =~ /E/) {
			if (($EventBat =~ /POCSH/) && ($NoRunRec[3] == $TRUE)) {$Runs ++;}
			if (($EventBat =~ /POCS3/) && ($NoRunRec[2] == $TRUE)) {$lpGameStatus_hash_ref -> {B3Occ} ++;}
			if (($EventBat =~ /POCS2/) && ($NoRunRec[1] == $TRUE)) {$lpGameStatus_hash_ref -> {B2Occ} ++;}
			}
		else {
			$lpGameStatus_hash_ref -> {Outs} ++;
			if (($EventBat =~ /PO3/) && ($NoRunRec[3] == $TRUE)) {$lpGameStatus_hash_ref -> {B3Occ}--;}
			if (($EventBat =~ /PO2/) && ($NoRunRec[2] == $TRUE)) {$lpGameStatus_hash_ref -> {B2Occ}--;}
			if (($EventBat =~ /PO1/) && ($NoRunRec[1] == $TRUE)) {$lpGameStatus_hash_ref -> {B1Occ}--;}
			}
		}

	# Need to catch E/SH, E/SF, FC/SH here and not in SH or SF
	# May not be sifting line-outs and ground-outs properly
	case /^E\d/ {
		# Assume B-1, catch other outcomes below
		$Clarity = $TRUE;
		$lpGameStatus_hash_ref -> {BatterInInning} ++;
		if ($EventBat =~ /\/G/){$Outcome = "GO";}
		elsif ($EventBat =~ /\/SF/){$Outcome = "SF";}
		elsif ($EventBat =~ /\/SH/){$Outcome = "SH";}
		else {$Outcome = "FO";}
		if ($NoRunRec[0] == $TRUE){$lpGameStatus_hash_ref -> {B1Occ} ++;}
		}
	case /^\dE\d/ {
		# Assume B-1, catch other outcomes below
		$Clarity = $TRUE;
		$lpGameStatus_hash_ref -> {BatterInInning} ++;
		if ($EventBat =~ /\/G/){$Outcome = "GO";}
		elsif ($EventBat =~ /\/SF/){$Outcome = "SF";}
		elsif ($EventBat =~ /\/SH/){$Outcome = "SH";}
		else {$Outcome = "FO";}
		if ($NoRunRec[0] == $TRUE){$lpGameStatus_hash_ref -> {B1Occ} ++;}
		}
	case /^FC[1-9]{1,3}/ {
		# This form records outs in EventRuns
		$Outcome = "FC";
		$Clarity = $TRUE;
		$lpGameStatus_hash_ref -> {BatterInInning} ++;
		if ($NoRunRec[0] == $TRUE){$lpGameStatus_hash_ref -> {B1Occ} ++;}
		}
	case /^FC[1-9]{0,3}\// {
		# This form records outs in EventRuns
		$Outcome = "FC";
		$Clarity = $TRUE;
		$lpGameStatus_hash_ref -> {BatterInInning} ++;
		if ($NoRunRec[0] == $TRUE){$lpGameStatus_hash_ref -> {B1Occ} ++;}
		}
	case /^HP/ {
		$Outcome = "HBP";
		$Clarity = $TRUE;
		$lpGameStatus_hash_ref -> {BatterInInning} ++;
		if ($NoRunRec[0] == $TRUE){$lpGameStatus_hash_ref -> {B1Occ} ++;}
		}
	case /^W/ {
		$Outcome = "BB";
		$Clarity = $TRUE;
		$lpGameStatus_hash_ref -> {BatterInInning} ++;
		if ($NoRunRec[0] == $TRUE){$lpGameStatus_hash_ref -> {B1Occ} ++;}
		}
	case /^IW/ {
		$Outcome = "IBB";
		$Clarity = $TRUE;
		$lpGameStatus_hash_ref -> {BatterInInning} ++;
		if ($NoRunRec[0] == $TRUE){$lpGameStatus_hash_ref -> {B1Occ} ++;}
		}
	case /^C\// {
		$Outcome = "CI";
		$Clarity = $TRUE;
		$lpGameStatus_hash_ref -> {BatterInInning} ++;
		if ($NoRunRec[0] == $TRUE){$lpGameStatus_hash_ref -> {B1Occ} ++;}
		}
	# Infield fly
	case /\/IF\// {
		$Outcome = "PO";
		$Clarity = $TRUE;
		$lpGameStatus_hash_ref -> {BatterInInning} ++;
		if ($NoRunRec[0] == $TRUE){$lpGameStatus_hash_ref -> {Outs} ++;}
		}
	case /^K/ {
		$Outcome = "K";
		$Clarity = $TRUE;
		$lpGameStatus_hash_ref -> {BatterInInning} ++;
		if ($NoRunRec[0] == $TRUE){$lpGameStatus_hash_ref -> {Outs} ++;}
		}
	# Singles: typically Sd/.., but may also be Sd.. or S/..; need to avoid pulling in SBs
	case /^S[1-9]{0,3}\// {
		$Outcome = "S";
		$Clarity = $TRUE;
		$lpGameStatus_hash_ref -> {BatterInInning} ++;
		if ($NoRunRec[0] == $TRUE){$lpGameStatus_hash_ref -> {B1Occ} ++;}
		}
	# Deal with Sdd, e.g. S48.1-2 from 2014STL.EVN, line 10189
	case /^S[1-9]{1,3}/ {
		$Outcome = "S";
		$Clarity = $TRUE;
		$lpGameStatus_hash_ref -> {BatterInInning} ++;
		if ($NoRunRec[0] == $TRUE){$lpGameStatus_hash_ref -> {B1Occ} ++;}
		}
	case /^D[G\d]/ {
		$Outcome = "D";
		$Clarity = $TRUE;
		$lpGameStatus_hash_ref -> {BatterInInning} ++;
		if ($NoRunRec[0] == $TRUE) {$lpGameStatus_hash_ref -> {B2Occ}++;}
		}
	case /^T[1-9]{1,3}/ {
		$Outcome = "T";
		$Clarity = $TRUE;
		$lpGameStatus_hash_ref -> {BatterInInning} ++;
		if ($NoRunRec[0] == $TRUE) {$lpGameStatus_hash_ref -> {B3Occ}++;}
		}
	case /^HR/ {
		$Outcome = "HR";
		$Clarity = $TRUE;
		$lpGameStatus_hash_ref -> {BatterInInning} ++;
		if ($NoRunRec[0] == $TRUE) {$Runs ++}
		}
	case /\/SF/ {
		$Outcome = "SF";
		$Clarity = $TRUE;
		$lpGameStatus_hash_ref -> {BatterInInning} ++;
		if ($NoRunRec[0] == $TRUE) {$lpGameStatus_hash_ref -> {Outs} ++;}
		}
	case /\/SH/ {
		$Outcome = "SH";
		$Clarity = $TRUE;
		$lpGameStatus_hash_ref -> {BatterInInning} ++;
		if ($NoRunRec[0] == $TRUE) {$lpGameStatus_hash_ref -> {Outs} ++;}
		}
	case /^[1-9]{1,3}\/[GLB]/	{
		$Outcome = "GO";
		$Clarity = $TRUE;
		$lpGameStatus_hash_ref -> {BatterInInning} ++;
		if ($NoRunRec[0] == $TRUE) {$lpGameStatus_hash_ref -> {Outs} ++;}
		}
	case /^[1-9]{1,3}\/BG/	{
		$Outcome = "GO";
		$Clarity = $TRUE;
		$lpGameStatus_hash_ref -> {BatterInInning} ++;
		if ($NoRunRec[0] == $TRUE) {$lpGameStatus_hash_ref -> {Outs} ++;}
		}
	case /^\d\/B[PL]/	{
		$Outcome = "FO";
		$Clarity = $TRUE;
		$lpGameStatus_hash_ref -> {BatterInInning} ++;
		if ($NoRunRec[0] == $TRUE) {$lpGameStatus_hash_ref -> {Outs} ++;}
		}
	case /^[1-9]{1,3}\/[LPF]/ {
		$Outcome = "FO";
		$Clarity = $TRUE;
		$lpGameStatus_hash_ref -> {BatterInInning} ++;
		if ($NoRunRec[0] == $TRUE) {$lpGameStatus_hash_ref -> {Outs} ++;}
		}
	case /GTP/ {
		$Outcome = "GTP";
		$Clarity = $TRUE;
		$lpGameStatus_hash_ref -> {BatterInInning} ++;
		$lpGameStatus_hash_ref -> {Outs} = 3; # fixx - worry about LOB?
		}
	case /\/TP/ {
		$Outcome = "OTP";
		$Clarity = $TRUE;
		$lpGameStatus_hash_ref -> {BatterInInning} ++;
		$lpGameStatus_hash_ref -> {Outs} = 3; # fixx - worry about LOB?
		}
	# Simple GDP of form 64(1)3/GDP
	case /GDP/ {
		$Outcome = "GDP";
		$lpGameStatus_hash_ref -> {BatterInInning} ++;
		$Clarity = $TRUE;
		if ($lpGameStatus_hash_ref -> {Outs} == 1) {$lpGameStatus_hash_ref -> {Outs} = 3;} # fixx - worry about LOB?
		elsif (!($EventBat =~ /\(/)) {$Clarity = $FALSE;}
		else {
			$lpGameStatus_hash_ref -> {Outs} = 2;
			my $OutsRecd = 0;
			if ($EventBat =~ /\(1/) {$lpGameStatus_hash_ref -> {B1Occ} --;$OutsRecd ++;}
			if ($EventBat =~ /\(2/) {$lpGameStatus_hash_ref -> {B2Occ} --;$OutsRecd ++;}
			if ($EventBat =~ /\(3/) {$lpGameStatus_hash_ref -> {B3Occ} --;$OutsRecd ++;}
			if ($OutsRecd == 2) {if ($NoRunRec[0] == $TRUE){$lpGameStatus_hash_ref -> {B1Occ} ++;}}
			}
		}
	# Complicated double plays
	# Put batter on first as default, then put out all indicated runners, including the batter if specified
	case /\/DP/ {
		$Outcome = "ODP";
		$lpGameStatus_hash_ref -> {BatterInInning} ++;
		$lpGameStatus_hash_ref -> {B1Occ} ++;
		if ($EventBat =~ /\(B/) {$lpGameStatus_hash_ref -> {B1Occ} --;$lpGameStatus_hash_ref -> {Outs} ++;}
		if ($EventBat =~ /RINT/) {$lpGameStatus_hash_ref -> {B1Occ} --;$lpGameStatus_hash_ref -> {Outs} ++;}
		if ($EventBat =~ /BINT/) {$lpGameStatus_hash_ref -> {B1Occ} --;$lpGameStatus_hash_ref -> {Outs} ++;}
		if ($EventBat =~ /\(1/) {$lpGameStatus_hash_ref -> {B1Occ} --;$lpGameStatus_hash_ref -> {Outs} ++;}
		if ($EventBat =~ /\(2/) {$lpGameStatus_hash_ref -> {B2Occ} --;$lpGameStatus_hash_ref -> {Outs} ++;}
		if ($EventBat =~ /\(3/) {$lpGameStatus_hash_ref -> {B3Occ} --;$lpGameStatus_hash_ref -> {Outs} ++;}
		my $OutsRecd = $lpGameStatus_hash_ref -> {Outs} - $Outs_pre;
		if ($OutsRecd == 2) {$Clarity = $TRUE;}
			else {$Clarity = $FALSE;}
		}
	case /\/FO/ {
		# This form records outs in EventBat
		$Outcome = "FC";
		if  (!($EventBat =~ /\(/)) {$Clarity = $FALSE;}
		else {
			$Clarity = $TRUE;
			$lpGameStatus_hash_ref -> {BatterInInning} ++;
			$lpGameStatus_hash_ref -> {Outs} ++;
			if ($NoRunRec[0] == $TRUE){$lpGameStatus_hash_ref -> {B1Occ} ++;}
			my $OpenParentPos = index($EventBat, "(");
			my $StartBase = substr $EventBat, $OpenParentPos+1, 1;
			DecBase($StartBase, $lpGameStatus_hash_ref);
			}
		}
	else {
		$Clarity = $FALSE;
		}
	}

# Deal with running codings embedded in EventBat that are not the primary coding
# Check for duplicative EventRun coding
# Example: K+CS2(26)
if (!($EventBat =~ /^CS/) && !($EventBat =~ /^PO/)){
	if ($EventBat =~ /E/){
		}
	else {
		if ((($EventBat =~ /CS2/) || ($EventBat =~ /PO1/)) && ($NoRunRec[1] == $TRUE)) {
			$lpGameStatus_hash_ref -> {B1Occ}--;
			$lpGameStatus_hash_ref -> {Outs} ++;
			}
		if ((($EventBat =~ /CS3/) || ($EventBat =~ /PO2/)) && ($NoRunRec[2] == $TRUE)) {
			$lpGameStatus_hash_ref -> {B2Occ}--;
			$lpGameStatus_hash_ref -> {Outs} ++;
			}
		if ((($EventBat =~ /CSH/) || ($EventBat =~ /PO3/)) && ($NoRunRec[3] == $TRUE)) {
			$lpGameStatus_hash_ref -> {B3Occ}--;
			$lpGameStatus_hash_ref -> {Outs} ++;
			}
		}
	}
# Example: K+SB2 or K+SB2;SB3
# Check for duplicative EventRun coding
if (!($EventBat =~ /^SB/)) {
	if (($EventBat =~ /SB2/) && ($NoRunRec[1] == $TRUE)) {
		$lpGameStatus_hash_ref -> {B1Occ}--;
		$lpGameStatus_hash_ref -> {B2Occ}++;
		}
	if (($EventBat =~ /SB3/) && ($NoRunRec[2] == $TRUE)) {
		$lpGameStatus_hash_ref -> {B2Occ}--;
		$lpGameStatus_hash_ref -> {B3Occ}++;
		}
	if (($EventBat =~ /SBH/) && ($NoRunRec[3] == $TRUE)) {
		$lpGameStatus_hash_ref -> {B3Occ}--;
		$Runs ++;
		}
	}

if ($Runs > 0) {
	if ($Half==0){$lpGameStatus_hash_ref -> {AwayRuns} = $lpGameStatus_hash_ref -> {AwayRuns} + $Runs;}
		else {$lpGameStatus_hash_ref -> {HomeRuns} = $lpGameStatus_hash_ref -> {HomeRuns} + $Runs;}
	}

return ($lpGameStatus_hash_ref, $PAFlag, $Pitches, $Outcome, $Clarity);

}

#---------------------------------------------------------------------;
sub FindSpotInOrder{
my ($BatterId, @BattingOrder) = (@_);

my $SpotInOrder = $ERR;
for (my $cntr=0; $cntr <=$#BattingOrder; $cntr++) {
	if (defined($BattingOrder[$cntr]) && defined($BatterId)) {
		if ((length $BattingOrder[$cntr]>0) && ($BatterId eq $BattingOrder[$cntr])) {$SpotInOrder = $cntr;}
		}
	}

return $SpotInOrder;
}

#---------------------------------------------------------------------;
sub ParseEvent{
my $Event = $_[0];
$Event =~s/MREV/MRV/s;
$Event =~s/UREV/URV/s;
$Event =~s/[!]//s;
$Event =~s/[!]//s;
$Event =~s/[?]//s;
$Event =~s/[?]//s;

my $EventBat = $Event;
my @EventRuns;

if ($Event =~ /\./) {
	($EventBat, my $EventRun) = split /\./, $Event;
	if ($EventRun =~ /\;/) {@EventRuns = split /\;/, $EventRun;}
		else {$EventRuns[0] = $EventRun;}
	}

return ($EventBat, @EventRuns);
}

#---------------------------------------------------------------------;
sub IncBase{
my ($BaseNumber, $lpGameStatus_hash_ref) = ($_[0], $_[1]);

if ($BaseNumber == 1){$lpGameStatus_hash_ref -> {B1Occ}++;}
if ($BaseNumber == 2){$lpGameStatus_hash_ref -> {B2Occ}++;}
if ($BaseNumber == 3){$lpGameStatus_hash_ref -> {B3Occ}++;}

return 1;
}

#---------------------------------------------------------------------;
sub DecBase{
my ($BaseNumber, $lpGameStatus_hash_ref) = ($_[0], $_[1]);

if ($BaseNumber == 1){$lpGameStatus_hash_ref -> {B1Occ}--;}
if ($BaseNumber == 2){$lpGameStatus_hash_ref -> {B2Occ}--;}
if ($BaseNumber == 3){$lpGameStatus_hash_ref -> {B3Occ}--;}

return 1;
}

#---------------------------------------------------------------------;
sub PreLoadSQL {
# Use existing table
# use truncate command, which resets the auto_increment counter to 0
# https://dev.mysql.com/doc/refman/5.0/en/truncate-table.html

my $dbh = $_[0];

# Clean out existing PA table
my $sql_prep = "truncate table $PA_TABLE";
my $sth_prep = $dbh->prepare($sql_prep);
$sth_prep->execute
	or die "SQL Error: $DBI::errstr\n";

my $sql = qq{
	insert into $PA_TABLE (
iYear
, dGameDate
, iGameSeq
, sBatterID
, sPitcherID
, sEvent
, sOutcome
, iClarity
, iInning
, iCount
, iOuts
, iB1Occ
, iB2Occ
, iB3Occ
, iCurBatterInOrder
, sOnDeckBatterId
, iPitches
, iPitchCount
, iPitcherLead
, sStadium
, iLineCount
, iHit
, iBB
, iHBP
, iSH
, iSF
, iTB
, iAB
, iPA
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
, ?
, ?
, ?
, ?
, ?
, ?
, ?
, ?
, ?
, ?
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

#debug print "<$sql>\n";
my $sth = $dbh->prepare($sql);

return ($sth);
}

#---------------------------------------------------------------------;
;