#!/usr/bin/perl
# s2_CalculatePitcherGameScores

# Read events and aggregate them into one pitching line per pitcher per game
# https://baseballscoring.wordpress.com/scoring-rules/


package s2_CalculatePitcherGameScores;

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

Readonly my $ERR => -1;
Readonly my $TRUE =>  1;
Readonly my $FALSE =>  0;
Readonly my $SrcDir => <replace with path to source files>;

Readonly my $db_name => <replace with MySQL database name>;
Readonly my $user_name => <replace with MySQL database user name>;
Readonly my $password => <replace with MySQL database user password>;
Readonly my $PitchLineTable => <replace with MySQL database destination table name>;

my $Write2DB = $FALSE;
my $PrintAllPL = $FALSE;
my $PrintUnclearEvents = $FALSE;
my $RunAll = $FALSE;
my $CleanOutTables = $FALSE;
my $RunMany = $FALSE;
my $PickMe = $FALSE;
my $HighInfoMode = $FALSE;
my $NumFiles;

$NumFiles = 2000;
#$NumFiles = 400;

$PickMe = $TRUE;
# All files, limited by NumFiles, erase and rewrite database table, print problems;
if ($PickMe == $TRUE) {
	$Write2DB = $TRUE;
	$PrintUnclearEvents = $TRUE;
	$RunAll = $TRUE;
	$CleanOutTables = $TRUE;
	$PickMe = $FALSE;
	}

# Many files, do not erase or write to database, print problems;
if ($PickMe == $TRUE) {
	$PrintAllPL = $TRUE;
	$PrintUnclearEvents = $TRUE;
	$RunMany = $TRUE;
	$PickMe = $FALSE;
	}

# One file, do not erase or write to database, print problems;
if ($PickMe == $TRUE) {
	$PrintAllPL = $TRUE;
	$PrintUnclearEvents = $TRUE;
	$PickMe = $FALSE;
	}

# One file, erase and write database table, print problems;
if ($PickMe == $TRUE) {
	$Write2DB = $TRUE;
	$PrintUnclearEvents = $TRUE;
	$CleanOutTables = $TRUE;
	$PickMe = $FALSE;
	}

# Definition of data structures
# PitchingLines_hash_ref
# $PitchingLine_hash_ref -> {PlayerID};
# $PitchingLine_hash_ref -> {HomeFlag};
# $PitchingLine_hash_ref -> {GSFlag};
# $PitchingLine_hash_ref -> {Outs};
# $PitchingLine_hash_ref -> {K};
# $PitchingLine_hash_ref -> {H};
# $PitchingLine_hash_ref -> {HR};
# $PitchingLine_hash_ref -> {BB};
# $PitchingLine_hash_ref -> {TB};
# $PitchingLine_hash_ref -> {R};
# $PitchingLine_hash_ref -> {ER};
# $PitchingLine_hash_ref -> {Decision};

# @PitchersResp[0] = batter
# @PitchersResp[1] pitcher responsible for least advanced runner on base, who could be on 1B, 2B, or 3B
# @PitchersResp[2] pitcher responsible for 2-least advanced runner on base, who could be on 2B or 3B
# @PitchersResp[3] pitcher responsible for 3-least advanced runner on base, who must be on 3B

#---------------------------------------------------------------------;
# Create connection
my $dbh;
my $sth_PLine;

if ($Write2DB == $TRUE) {
	$dbh = DBI->connect("dbi:mysql:$db_name","$user_name","$password")
		or die "Connection Error: $DBI::errstr\n";
	$dbh->{RaiseError} = 1;
	if ($CleanOutTables == $TRUE) {CleanOutTables($dbh)};
	$sth_PLine = PrepIns_PLine ($dbh);
	}

#---------------------------------------------------------------------;
# Read all files in directory
# Write out all game final to res.txt
# Write out unclear plays to UnparsedEvents.txt

print "GameID\tPlayerID\tHomeFlag\tGSFlag\tOuts\tH\tR\tER\tBB\tK\tHR\tTB\tDecision\tGameScore\n";

my $OutFileHandle;

if (($RunAll == $TRUE) or ($RunMany == $TRUE)){

	my $OutFileName = 'UnparsedEvents.txt';
	my $OutFileFullPath = $SrcDir . $OutFileName;

	open($OutFileHandle, '>', $OutFileFullPath) or die "Could not open file '$OutFileFullPath' $!";
	print $OutFileHandle "Event\tOutcome\tClarity\tBatter\tInning\tCount\tOuts\tB1Occ\tB2Occ\tB3Occ\tLineCount\tGameID\n";
#print $OutFileHandle "$Event\t$Outcome\t$Clarity\t$Batter\t$Inning\t$Count\t$Outs\t$B1Occ\t$B2Occ\t$B3Occ\t$LineCount\t$GameID\n";


	my $FileCnt = 1;
	opendir RSDIR, $SrcDir or die "can't open directory .: $!\n";
	while (readdir RSDIR) {
		my $RunThisFile = $FALSE;
		if (($RunAll == $TRUE) and ( $_ =~ /\.EV/ ) and ($FileCnt <=$NumFiles)) {$RunThisFile = $TRUE;}
		elsif (($RunMany == $TRUE) and ( $_ =~ /\.EV/ ) and ( $_ =~ /^201/ ) and ($FileCnt <=$NumFiles)) {$RunThisFile = $TRUE;}
		if ($RunThisFile == $TRUE) {
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
	my $InFileName;
	$InFileName = '1930BOS.EVA';
	$InFileName = '2010CLE.EVA';
	$InFileName = '2010WAS.EVN';
	$InFileName = '2011CIN.EVN';
	$InFileName = '2012SLN.EVN';
	$InFileName = '2012HOU.EVN';
	$InFileName = '2013OAK.EVA';
	$InFileName = '2013WAS.EVN';
	$InFileName = '2014PIT.EVN';
	$InFileName = '2014SLN.EVN';
	$InFileName = '2010BOS.EVA';

	my $OutFileName = substr($InFileName,0,7) . '.txt';
	my $InFileFullPath = $SrcDir . $InFileName;
	my $OutFileFullPath = $SrcDir . $OutFileName;

	open($OutFileHandle, '>', $OutFileFullPath) or die "Could not open file '$OutFileFullPath' $!";
	print $OutFileHandle "Event\tOutcome\tClarity\tBatter\tInning\tCount\tOuts\tB1Occ\tB2Occ\tB3Occ\tLineCount\tGameID\n";
#print $OutFileHandle "$Event\t$Outcome\t$Clarity\t$Batter\t$Inning\t$Count\t$Outs\t$B1Occ\t$B2Occ\t$B3Occ\t$LineCount\t$GameID\n";
	ProcessFile($InFileFullPath);
	close $OutFileHandle;
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

#my $AwayPitchingLines_hash_ref; #delete?
#my $HomePitchingLines_hash_ref; #delete?
my @PitchingLines_hash_ref_array = ();
my $GameStatus_hash_ref = ResetGame();
my $GameID = 'NULL';
my $LineCount = 0;

my $PrevInningHalf = 1;
my $InningHalf = 0;
my @PitcherNum = (0,0);
my $PitcherCount = 0;
my @PitchersResp = ($ERR,$ERR,$ERR,$ERR);
my $PitchingDecs;
while (my $row = <$InFileHandle>) {

	chomp $row;
	if ($row =~ /^id/) {
		if ($LineCount>0) { #report previous game;
			AddPitchingDecision($PitchingDecs, \@PitchingLines_hash_ref_array);
			WriteAllPitchingLines(\@PitchingLines_hash_ref_array, $GameID);
			Checks(\@PitchingLines_hash_ref_array, $GameStatus_hash_ref);
			ReportGame($GameID, $GameStatus_hash_ref);
			};
		$GameStatus_hash_ref = ResetGame();
		@PitchingLines_hash_ref_array = ();
		my $GameID_hash_ref = ParsePxP_IDRec($row);
		$GameID = $GameID_hash_ref -> {GameID};
		#if ($GameID eq 'CLE201004170') {$HighInfoMode = $TRUE;}
		if ($GameID eq 'NULL') {$HighInfoMode = $TRUE;}
			else  {$HighInfoMode = $FALSE;}
		$PrevInningHalf = 1;
		$InningHalf = 0;
		@PitcherNum = (0,0);
		$PitcherCount = 0;
		@PitchersResp = ($ERR,$ERR,$ERR,$ERR);
		}
	if ($row =~ /^play/) {
		my $Play_hash_ref = ParsePxP_PlayRec($row);
		$InningHalf = $Play_hash_ref -> {Half};
		if ($InningHalf != $PrevInningHalf) {
			$GameStatus_hash_ref = ResetInning($GameStatus_hash_ref);
			@PitchersResp = ($PitcherNum[$InningHalf],$ERR,$ERR,$ERR); #always set the responsibility of the batter to the current pitcher;
			}
		$PrevInningHalf = $InningHalf;
		my $TotRuns_prev = $GameStatus_hash_ref -> {AwayRuns} + $GameStatus_hash_ref -> {HomeRuns};
		my $Outs_prev = $GameStatus_hash_ref -> {Outs};
		my $OnBaseCount_prev = $GameStatus_hash_ref -> {B1Occ} + $GameStatus_hash_ref -> {B2Occ} + $GameStatus_hash_ref -> {B3Occ};

		($GameStatus_hash_ref, my $PAFlag, my $Pitches, my $Outcome, my $Clarity, my $EventBucket, my $StatusProblems) = InterpretEvent($Play_hash_ref, $GameStatus_hash_ref, $TRUE);
		
		if (not $Clarity){WritePA2Res($Play_hash_ref, $GameStatus_hash_ref, $Outcome, $Clarity, $LineCount, $GameID);}

		my $OnBaseCount = $GameStatus_hash_ref -> {B1Occ} + $GameStatus_hash_ref -> {B2Occ} + $GameStatus_hash_ref -> {B3Occ};
		my $dR = $GameStatus_hash_ref -> {AwayRuns} + $GameStatus_hash_ref -> {HomeRuns} - $TotRuns_prev;
		my $Outs = $GameStatus_hash_ref -> {Outs};
		my $dOuts = $Outs - $Outs_prev;

		$PitchingLines_hash_ref_array[$PitcherNum[$InningHalf]] = UpdatePitchingLine($PitchingLines_hash_ref_array[$PitcherNum[$InningHalf]], $Outcome, $dOuts);
		if ($dR > 0) {
			AssignRuns($dR, $OnBaseCount_prev, \@PitchersResp, \@PitchingLines_hash_ref_array);
			$OnBaseCount_prev = $OnBaseCount_prev - $dR;
			}
		if ($Outs == 3) {;} # end of half inning, skip the logic
		elsif ($OnBaseCount > $OnBaseCount_prev) {AddBaserunner($OnBaseCount_prev, \@PitchersResp);}
		elsif ($OnBaseCount < $OnBaseCount_prev) {RemoveBaserunners($OnBaseCount_prev, $OnBaseCount, $PAFlag, $dOuts, \@PitchersResp);}
		
		# Debug section, after all processing
		# problem with run attribution after double play
		if (0){
		#if ((4671<$LineCount) and ($LineCount<4682)){
			my %GameStatus_hash = %$GameStatus_hash_ref;
			print "DEBUG: $row, $PitcherNum[$InningHalf]";
			print ", @PitchersResp; ";
			foreach my $k (keys %GameStatus_hash) {print "$k: $GameStatus_hash{$k}; ";}
			print "\n";
			}
		}
	if (($row =~ /^start/) || ($row =~ /^sub/)) {
		my $Player_hash_ref = ParsePxP_PlayerRec($row);
		if (($Player_hash_ref -> {FieldPos}) == 1) {
			my $PlayerID = $Player_hash_ref -> {PlayerID};
			my $HomePitcherFlag = $Player_hash_ref -> {HomeFlag};
			my $NewPitcherFlag;
			if ($PitcherCount > 1) {$NewPitcherFlag = ($PlayerID ne $PitchingLines_hash_ref_array[$PitcherNum[1-$HomePitcherFlag]] -> {PlayerID});}
				else {$NewPitcherFlag = $TRUE;}
			if ($NewPitcherFlag) {
				$PitcherNum[1-$HomePitcherFlag] = $PitcherCount;
				$PitchingLines_hash_ref_array[$PitcherCount] = InitializePitchingLine($GameID, $PlayerID, $HomePitcherFlag);
				$PitchersResp[0] = $PitcherCount;
				if ($row =~ /^start/) {$PitchingLines_hash_ref_array[$PitcherCount] -> {GSFlag} = $TRUE;}
				$PitcherCount ++;
				}
			}
		}
	if ($row =~ /^data/) {
		my $PitcherER_hash_ref = ParsePxP_DataRec($row);
		AddER($PitcherER_hash_ref, \@PitchingLines_hash_ref_array);
		}
	if ($row =~ /^info/) {
		my $Info_hash_ref = ParsePxP_InfoRec($row);
		my $InfoType = $Info_hash_ref -> {InfoType};
		if ($InfoType eq "lp"){$PitchingDecs -> {lp} = $Info_hash_ref -> {InfoVal};}
		if ($InfoType eq "wp"){$PitchingDecs -> {wp} = $Info_hash_ref -> {InfoVal};}
		if ($InfoType eq "save"){$PitchingDecs -> {save} = $Info_hash_ref -> {InfoVal};}
		}
	$LineCount++;
	}
AddPitchingDecision($PitchingDecs, \@PitchingLines_hash_ref_array);
WriteAllPitchingLines(\@PitchingLines_hash_ref_array, $GameID);
Checks(\@PitchingLines_hash_ref_array, $GameStatus_hash_ref);
ReportGame($GameID, $GameStatus_hash_ref);
}

#---------------------------------------------------------------------;
sub InitializePitchingLine{
# example call: $PitchingLines_hash_ref_array[$PitcherCount] = InitializePitchingLine($GameID, $PlayerID, $HomePitcherFlag);
my ($GameID, $PlayerID, $HomePitcherFlag) = ($_[0], $_[1], $_[2]);
my $PitchingLine_hash_ref = {
	GameID  => $GameID
	, PlayerID => $PlayerID
	, HomeFlag => $HomePitcherFlag
	, GSFlag => $FALSE
	, TeamWin => 0
	, Outs => 0
	, H => 0
	, TB => 0
	, HR => 0
	, BB => 0
	, ER => 0
	, R => 0
	, K => 0
	, Decision => '.'
	};
	
if ($HighInfoMode == $TRUE) {
	#debug;
	print "End of InitializedPitchingLine\n";
	print "PlayerID: $PlayerID\n";
	}

return ($PitchingLine_hash_ref);
}

#---------------------------------------------------------------------;
sub UpdatePitchingLine{
# example call: $PitchingLines_hash_ref_array[$PitcherNum[$InningHalf]] = UpdatePitchingLine($PitchingLines_hash_ref_array[$PitcherNum[$InningHalf]], $Outcome, $dOuts);
my ($PitchingLine_hash_ref, $Outcome, $dOuts) = ($_[0], $_[1], $_[2]);

$PitchingLine_hash_ref ->{Outs} = $PitchingLine_hash_ref -> {Outs} + $dOuts;
switch ($Outcome) {
	case "S"				{$PitchingLine_hash_ref->{H} ++;$PitchingLine_hash_ref->{TB} ++;}
	case "D"				{$PitchingLine_hash_ref->{H} ++;$PitchingLine_hash_ref->{TB} += 2;}
	case "T"				{$PitchingLine_hash_ref->{H} ++;$PitchingLine_hash_ref->{TB} += 3;}
	case "HR"				{$PitchingLine_hash_ref->{H} ++;$PitchingLine_hash_ref->{TB} += 4; $PitchingLine_hash_ref->{HR} ++;}
	case ["BB","IBB","HBP"]	{$PitchingLine_hash_ref->{BB} ++;}
	case "K"				{$PitchingLine_hash_ref->{K} ++;}
	}

return ($PitchingLine_hash_ref);
}

#---------------------------------------------------------------------;
sub AddBaserunner{
# example call: AddBaserunner($OnBaseCount_prev, \@PitchersResp);
my ($OnBaseCount_prev, $PitchersResp) = ($_[0], $_[1]);

if ($HighInfoMode == $TRUE) {
	#debug;
	print "Start of AddBaserunner\n";
	print "OnBaseCount_prev, $OnBaseCount_prev\n";
	for (my $i = 0; $i < 4; $i++) {print "$i, $$PitchersResp[$i]\n";}
	}

if ($OnBaseCount_prev>2){print "ERROR: adding fourth base runner\n";}
else {for (my $i = $OnBaseCount_prev; $i >= 0 ; $i--) {$$PitchersResp[$i+1] = $$PitchersResp[$i];}}

if ($HighInfoMode == $TRUE) {
	#debug;
	print "End of AddBaserunner\n";
	for (my $i = 0; $i < 4; $i++) {print "$i, $$PitchersResp[$i]\n";}
	}

return 1;
}

#---------------------------------------------------------------------;
sub RemoveBaserunners{
# example call: RemoveBaserunners($OnBaseCount_prev, $OnBaseCount, $PAFlag, $dOuts, \@PitchersResp);
my ($OnBaseCount_prev, $OnBaseCount, $PAFlag, $dOuts, $PitchersResp) = ($_[0], $_[1], $_[2], $_[3], $_[4]);

if ($HighInfoMode == $TRUE) {
	#debug;
	print "Start of RemoveBaserunners\n";
	print "OnBaseCount, $OnBaseCount\n";
	for (my $i = 0; $i < 4; $i++) {print "$i, $$PitchersResp[$i]\n";}
	}
	
# simple cases
if ($OnBaseCount == 0) {for (my $i = 1; $i < 4; $i++) {$$PitchersResp[$i] = $ERR;}} # nobody left on, reset all bases
elsif ($dOuts == 0) {print "CHECK: runners removed without outs\n";}
# the rest
else {
	# verify - might be pretty close to correct
	# if the play is a plate appearance, pretty much any runner out are considered due to action of the batter,
	# and this does not remove responsibility from the preceding pitcher
	# Only runners removed without action of the batter are removed from the preceding batter
	my $RemoveFromBottom = $PAFlag;
	if ($RemoveFromBottom == $TRUE) {for (my $i = 1; $i <= $OnBaseCount; $i++) {$$PitchersResp[$i] = $$PitchersResp[$i+1];}}
	for (my $i = 3; $i > $OnBaseCount; $i--) {$$PitchersResp[$i] = $ERR;}
	}

if ($HighInfoMode == $TRUE) {
	#debug;
	print "End of RemoveBaserunners\n";
	for (my $i = 0; $i < 4; $i++) {print "$i, $$PitchersResp[$i]\n";}
	}

return 1;
}

#---------------------------------------------------------------------;
sub AssignRuns{
# example call: AssignRuns($dR, $OnBaseCount_prev, \@PitchersResp, \@PitchingLines_hash_ref_array);
my ($dR, $OnBaseCount_prev, $PitchersResp, $PitchingLines_hash_ref_array_ref) = ($_[0], $_[1], $_[2], $_[3]);
my $CurPitcher = $$PitchersResp[0];

for (my $i = 0; $i < $dR; $i++) {
	my $Base = $OnBaseCount_prev - $i;
	if ($$PitchersResp[$Base] == $ERR) {print "ERROR: attributing run to unassigned pitcher\n";}
	else {$$PitchingLines_hash_ref_array_ref[$$PitchersResp[$Base]] -> {R} ++;}
	$$PitchersResp[$Base] = $ERR;
	}
$$PitchersResp[0] = $CurPitcher;

return 1;
}

#---------------------------------------------------------------------;
sub AddER{
# example call: AddER($DataRec_hash_ref, \@PitchingLines_hash_ref_array);
my ($DataRec_hash_ref, $PitchingLines_hash_ref_array_ref) = ($_[0], $_[1]);
my $DRID = $DataRec_hash_ref -> {PlayerID};
foreach my $PitchingLines_hash_ref (@$PitchingLines_hash_ref_array_ref) {
	my $PLID = $PitchingLines_hash_ref -> {PlayerID};
	if ($PLID eq $DRID){$PitchingLines_hash_ref -> {ER} = $DataRec_hash_ref -> {ER};};
	}

return 1;
}

#---------------------------------------------------------------------;
sub AddPitchingDecision{
# example call: AddPitchingDecision(%PitchingDecs, \@PitchingLines_hash_ref_array);
my ($PitchingDecs, $PitchingLines_hash_ref_array_ref) = ($_[0], $_[1]);
my $wp = $PitchingDecs -> {wp};
my $lp = $PitchingDecs -> {lp};
my $saver = $PitchingDecs -> {save};

#if (not defined $wp) {$wp = 'None';}
#if (not defined $lp) {$lp = 'None';}
#if (not defined $saver) {$saver = 'None';}

foreach my $PitchingLines_hash_ref (@$PitchingLines_hash_ref_array_ref) {
	my $PLID = $PitchingLines_hash_ref -> {PlayerID};
	if ($PLID eq $wp){$PitchingLines_hash_ref -> {Decision} = 'W';}
	if ($PLID eq $lp){$PitchingLines_hash_ref -> {Decision} = 'L';}
	if ($PLID eq $saver){$PitchingLines_hash_ref -> {Decision} = 'S';}
	}

return 1;
}

#---------------------------------------------------------------------;
sub WriteAllPitchingLines{
# example call: WriteAllPitchingLines(\@PitchingLines_hash_ref_array_ref, $GameID);
my ($PitchingLines_hash_ref_array_ref, $GameID) = ($_[0], $_[1]);

foreach my $PitchingLine_hash_ref (@$PitchingLines_hash_ref_array_ref) {
	my $PlayerID = $PitchingLine_hash_ref -> {PlayerID};
	my $HomeFlag = $PitchingLine_hash_ref -> {HomeFlag};
	my $GSFlag = $PitchingLine_hash_ref -> {GSFlag};
	my $Outs = $PitchingLine_hash_ref->{Outs};
	my $K = $PitchingLine_hash_ref->{K};
	my $H = $PitchingLine_hash_ref->{H};
	my $TB = $PitchingLine_hash_ref->{TB};
	my $HR = $PitchingLine_hash_ref->{HR};
	my $BB = $PitchingLine_hash_ref->{BB};
	my $R = $PitchingLine_hash_ref->{R};
	my $ER = $PitchingLine_hash_ref->{ER};
	my $Decision = $PitchingLine_hash_ref->{Decision};
	my $GameScore = 40 + 2 * $Outs + 1 * $K - 2 * $BB - 2 * $H - 3 * $R - 6 * $HR;

	if ($PrintAllPL == $TRUE) {
		print "$GameID\t$PlayerID\t$HomeFlag\t$GSFlag\t$Outs\t$H\t$R\t$ER\t$BB\t$K\t$HR\t$TB\t$Decision\t$GameScore\n";
		}

	if ($Write2DB == $TRUE) {
		$sth_PLine->execute(
			$GameID
			, $PlayerID
			, $HomeFlag
			, $GSFlag
			, $Outs
			, $K
			, $H
			, $HR
			, $BB
			, $R
			, $ER
			, $Decision
			, $GameScore
			)
			or die "SQL Error: $DBI::errstr\n";
		}
	}
return 1;
}

#---------------------------------------------------------------------;
sub ReportGame{
# example call: ReportGame($GameID, $GameStatus_hash_ref)
my ($GameID, $GameStatus_hash_ref) = ($_[0], $_[1]);

my $ResVar;

$ResVar = $GameID;
print "$ResVar";

$ResVar = $GameStatus_hash_ref -> {AwayRuns};
print "\t$ResVar";

$ResVar = $GameStatus_hash_ref -> {HomeRuns};
print "\t$ResVar";

print "\n";
if ($PrintAllPL){print "\n";}

return 1;
}

#---------------------------------------------------------------------;
sub CleanOutTables{
# example call: CleanOutTables()
# Use existing table
# use truncate command, which resets the auto_increment counter to 0
# https://dev.mysql.com/doc/refman/5.0/en/truncate-table.html

my $dbh = $_[0];

# Clean out existing Pitching Line table
my $sql = "truncate table $PitchLineTable";
my $sth = $dbh->prepare($sql);
$sth->execute
	or die "SQL Error: $DBI::errstr\n";

return 1;
}

#---------------------------------------------------------------------;
sub PrepIns_PLine {
# example call: $sth_PLine = PrepIns_PLine ($dbh);

my $dbh = $_[0];
my $sql = qq{
	insert into $PitchLineTable (
		sGameID
		, sPitcherID
		, iHomeFlag
		, iGSFlag
		, iOuts
		, iK
		, iH
		, iHR
		, iBB
		, iR
		, iER
		, sDecision
		, iGameScore
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
		)
	};

my $sth_PLine = $dbh->prepare($sql);

return ($sth_PLine);
}

#---------------------------------------------------------------------;
sub WritePA2Res{
# example call: WritePA2Res($Play_hash_ref, $GameStatus_hash_ref, $Outcome, $Clarity, $LineCount, $GameID);
my ($Play_hash_ref, $GameStatus_hash_ref, $Outcome, $Clarity, $LineCount, $GameID) = (@_);

my $Event = $Play_hash_ref -> {Event};
my $Batter = $Play_hash_ref -> {PlayerID};
my $Inning = $Play_hash_ref -> {Inning};
my $Count = $Play_hash_ref -> {Count};
my $Half =  $Play_hash_ref -> {Half};

my $Outs = $GameStatus_hash_ref -> {Outs};
my $B1Occ = $GameStatus_hash_ref -> {B1Occ};
my $B2Occ = $GameStatus_hash_ref -> {B2Occ};
my $B3Occ = $GameStatus_hash_ref -> {B3Occ};

if ($Clarity == $FALSE) {print "Error: clarity failure: ";}
print $OutFileHandle "$Event\t$Outcome\t$Clarity\t$Batter\t$Inning\t$Count\t$Outs\t$B1Occ\t$B2Occ\t$B3Occ\t$LineCount\t$GameID\n";

return 1;
}

#---------------------------------------------------------------------;
sub Checks{
# example call: Checks(\@PitchingLines_hash_ref_array, $GameStatus_hash_ref);
my ($PitchingLines_hash_ref_array_ref, $GameStatus_hash_ref) = ($_[0], $_[1]);
my $TotR = 0;
my $TotER = 0;
my $Outs_Away = 0;
my $Outs_Home = 0;
foreach my $PitchingLine_hash_ref (@$PitchingLines_hash_ref_array_ref) {
	my $R = $PitchingLine_hash_ref->{R};
	my $ER = $PitchingLine_hash_ref->{ER};
	my $PlayerID = $PitchingLine_hash_ref -> {PlayerID};
	$TotR = $TotR + $PitchingLine_hash_ref->{R};
	$TotER = $TotER + $PitchingLine_hash_ref->{ER};
	if ($ER > $R) {print "ERROR: ER>R, $PlayerID, $R, $ER\n";}
	if ($PitchingLine_hash_ref->{HomeFlag}){$Outs_Home = $Outs_Home + $PitchingLine_hash_ref->{Outs};}
	else {$Outs_Away = $Outs_Away + $PitchingLine_hash_ref->{Outs};}
	}
my $Runs_Away = $GameStatus_hash_ref -> {AwayRuns};
my $Runs_Home = $GameStatus_hash_ref -> {HomeRuns};

#if ($TotR != ($Runs_Away + $Runs_Home)){print "TotR: $TotR\tTotER = $TotER\tRunsAway: $Runs_Away\tRunsHome:$Runs_Home\tOutsAway: $Outs_Away\tOutsHome:$Outs_Home\n";}
print "TotR: $TotR\tTotER = $TotER\tRunsAway: $Runs_Away\tRunsHome:$Runs_Home\tOutsAway: $Outs_Away\tOutsHome:$Outs_Home\n";
if ($Outs_Away % 3) {print "Incomplete away pitcher innning\n";} # debug;
if ($Outs_Home % 3) {print "WARNING: Incomplete home pitcher innning\n";} # debug;

return 1;
}

#---------------------------------------------------------------------;
;