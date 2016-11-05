#!/usr/bin/perl
# RetrosheetUserModules

package user::RetrosheetUserModules;

our $VERSION = 0.9;

use 5.012;
use warnings;
use strict;
use Readonly;
#use Switch;
use Text::ParseWords;
use Exporter 'import';
our @EXPORT = ();
our @EXPORT_OK = qw( CreateOutcomeHashTable ParsePxP_Event ParseGL ParsePxP_IDRec ParsePxP_PlayRec ParsePxP_PlayerRec ParsePxP_DataRec ParsePxP_InfoRec InterpretEvent ResetGame ResetInning CheckGameStatus );

Readonly my $ERR => -1;
Readonly my $TRUE =>  1;
Readonly my $FALSE =>  0;

our $Play_hash_ref;
our $lpGameStatus_hash_ref;
our $CheckStatus;

our $EventBucket;
our $PAFlag;
our $Outcome;
our $Clarity;
our $GameStatusProblems;

our @NoRunRec;
our $Runs;

our $Outs_pre;
our $Event;
our $EventBat;
our @EventRuns;

# Definition of data structures
# $GameStatus_hash_ref -> {Outs} = 0;
# $GameStatus_hash_ref -> {BatterInInning} = 0;
# $GameStatus_hash_ref -> {B1Occ} = $FALSE;
# $GameStatus_hash_ref -> {B2Occ} = $FALSE;
# $GameStatus_hash_ref -> {B3Occ} = $FALSE;
# $GameStatus_hash_ref -> {AwayRuns} = 0;
# $GameStatus_hash_ref -> {HomeRuns} = 0;

# $DataRec_hash_ref;
# $DataRec_hash_ref -> {RecType} = $chunks[0];
# $DataRec_hash_ref -> {DataType} = $chunks[1];
# $DataRec_hash_ref -> {PlayerID} = $chunks[2];
# $DataRec_hash_ref -> {ER} = $chunks[3];

# Play_hash_ref;
# $Play_hash_ref -> {RecType} = $chunks[0];
# $Play_hash_ref -> {Inning} = $chunks[1];
# $Play_hash_ref -> {Half} = $chunks[2];
# $Play_hash_ref -> {PlayerID} = $chunks[3];
# $Play_hash_ref -> {Count} = $chunks[4];
# $Play_hash_ref -> {PitchSeq} = $chunks[5];
# $Play_hash_ref -> {Event} = $chunks[6];

#---------------------------------------------------------------------;
sub CreateOutcomeHashTable{
# example call: \@Outcome_hash_ref = CreateOutcomeHashTable();
my @OutcomeList = ();

my %OutcomeMap1 = (OutcomeAbrv => 'BB', OutcomeDesc => 'Walk');push( @OutcomeList, \%OutcomeMap1 );
my %OutcomeMap2 = (OutcomeAbrv => 'BK', OutcomeDesc => 'Balk');push( @OutcomeList, \%OutcomeMap2 );
my %OutcomeMap3 = (OutcomeAbrv => 'CI', OutcomeDesc => 'Fielder Interference');push( @OutcomeList, \%OutcomeMap3 );
my %OutcomeMap4 = (OutcomeAbrv => 'CS', OutcomeDesc => 'Caught Stealing');push( @OutcomeList, \%OutcomeMap4 );
my %OutcomeMap5 = (OutcomeAbrv => 'D', OutcomeDesc => 'Double');push( @OutcomeList, \%OutcomeMap5 );
my %OutcomeMap6 = (OutcomeAbrv => 'DI', OutcomeDesc => 'Defensive Indifference');push( @OutcomeList, \%OutcomeMap6 );
my %OutcomeMap7 = (OutcomeAbrv => 'E', OutcomeDesc => 'Error');push( @OutcomeList, \%OutcomeMap7 );
my %OutcomeMap8 = (OutcomeAbrv => 'FC', OutcomeDesc => 'Fielders Choice');push( @OutcomeList, \%OutcomeMap8 );
my %OutcomeMap9 = (OutcomeAbrv => 'FO', OutcomeDesc => 'Force Out');push( @OutcomeList, \%OutcomeMap9 );
my %OutcomeMap10 = (OutcomeAbrv => 'GDP', OutcomeDesc => 'Grounded into Double Play');push( @OutcomeList, \%OutcomeMap10 );
my %OutcomeMap11 = (OutcomeAbrv => 'GO', OutcomeDesc => 'Ground Out');push( @OutcomeList, \%OutcomeMap11 );
my %OutcomeMap12 = (OutcomeAbrv => 'GTP', OutcomeDesc => 'Grounded into Triple Play');push( @OutcomeList, \%OutcomeMap12 );
my %OutcomeMap13 = (OutcomeAbrv => 'HBP', OutcomeDesc => 'Hit By Pitch');push( @OutcomeList, \%OutcomeMap13 );
my %OutcomeMap14 = (OutcomeAbrv => 'HR', OutcomeDesc => 'Home Run');push( @OutcomeList, \%OutcomeMap14 );
my %OutcomeMap15 = (OutcomeAbrv => 'IBB', OutcomeDesc => 'Intentional Walk');push( @OutcomeList, \%OutcomeMap15 );
my %OutcomeMap16 = (OutcomeAbrv => 'K', OutcomeDesc => 'Strikeout');push( @OutcomeList, \%OutcomeMap16 );
my %OutcomeMap17 = (OutcomeAbrv => 'NP', OutcomeDesc => 'No Play');push( @OutcomeList, \%OutcomeMap17 );
my %OutcomeMap18 = (OutcomeAbrv => 'OA', OutcomeDesc => 'Other Advance');push( @OutcomeList, \%OutcomeMap18 );
my %OutcomeMap19 = (OutcomeAbrv => 'ODP', OutcomeDesc => 'Other Double Play');push( @OutcomeList, \%OutcomeMap19 );
my %OutcomeMap20 = (OutcomeAbrv => 'OTP', OutcomeDesc => 'Other Triple Play');push( @OutcomeList, \%OutcomeMap20 );
my %OutcomeMap21 = (OutcomeAbrv => 'PB', OutcomeDesc => 'Pass Ball');push( @OutcomeList, \%OutcomeMap21 );
my %OutcomeMap22 = (OutcomeAbrv => 'PO', OutcomeDesc => 'Fly or Pop Out');push( @OutcomeList, \%OutcomeMap22 );
my %OutcomeMap23 = (OutcomeAbrv => 'S', OutcomeDesc => 'Single');push( @OutcomeList, \%OutcomeMap23 );
my %OutcomeMap24 = (OutcomeAbrv => 'SB', OutcomeDesc => 'Stolen Base');push( @OutcomeList, \%OutcomeMap24 );
my %OutcomeMap25 = (OutcomeAbrv => 'SF', OutcomeDesc => 'Sacrifice Fly');push( @OutcomeList, \%OutcomeMap25 );
my %OutcomeMap26 = (OutcomeAbrv => 'SH', OutcomeDesc => 'Sacrifice Hit');push( @OutcomeList, \%OutcomeMap26 );
my %OutcomeMap27 = (OutcomeAbrv => 'T', OutcomeDesc => 'Triple');push( @OutcomeList, \%OutcomeMap27 );
my %OutcomeMap28 = (OutcomeAbrv => 'WP', OutcomeDesc => 'Wild Pitch');push( @OutcomeList, \%OutcomeMap28 );
my %OutcomeMap29 = (OutcomeAbrv => 'ONDP', OutcomeDesc => 'Other non-double play');push( @OutcomeList, \%OutcomeMap28 );
my %OutcomeMap30 = (OutcomeAbrv => 'SFFC', OutcomeDesc => 'Dropped SF turned into FC');push( @OutcomeList, \%OutcomeMap28 );
my %OutcomeMap31 = (OutcomeAbrv => 'SFDP', OutcomeDesc => 'Sacrifice Fly Double Play');push( @OutcomeList, \%OutcomeMap28 );
my %OutcomeMap32 = (OutcomeAbrv => 'SFTP', OutcomeDesc => 'Sacrifice Fly Triple Play');push( @OutcomeList, \%OutcomeMap28 );

return (\@OutcomeList);
}

#---------------------------------------------------------------------;
sub ResetGame{
# example call: $GameStatus_hash_ref = ResetGame();
my $GameStatus_hash_ref = {
	Outs => 0
	, BatterInInning => 0
	, B1Occ => $FALSE
	, B2Occ => $FALSE
	, B3Occ => $FALSE
	, HomeRuns => 0
	, AwayRuns => 0
	};

return ($GameStatus_hash_ref);
}

#---------------------------------------------------------------------;
sub ResetInning{
# example call: $GameStatus_hash_ref = ResetInning($GameStatus_hash_ref);
my $GameStatus_hash_ref = $_[0];

$GameStatus_hash_ref -> {Outs} = 0;
$GameStatus_hash_ref -> {BatterInInning} = 0;
$GameStatus_hash_ref -> {B1Occ} = $FALSE;
$GameStatus_hash_ref -> {B2Occ} = $FALSE;
$GameStatus_hash_ref -> {B3Occ} = $FALSE;

return ($GameStatus_hash_ref);
}

#---------------------------------------------------------------------;
sub ParseGL{
# example call: $GameLog_hash_ref = ParseGL($row);
# Example data: "20150405","0","Sun","SLN","NL",1,"CHN","NL",1,3,0,54,"N","","","","CHI11",35055,184,"110010000","000000000",36,10,3,0,0,3,0,0,0,4,1,11,4,1,0,0,10,4,0,0,0,0,27,8,0,1,0,0,32,5,3,0,0,0,0,0,0,2,0,12,1,0,0,0,7,6,3,3,0,0,27,8,2,0,0,0,"wintm901","Mike Winters","wegnm901","Mark Wegner","fostm901","Marty Foster","muchm901","Mike Muchlinski","","(none)","","(none)","mathm001","Mike Matheny","maddj801","Joe Maddon","waina001","Adam Wainwright","lestj001","Jon Lester","roset001","Trevor Rosenthal","hollm001","Matt Holliday","waina001","Adam Wainwright","lestj001","Jon Lester","carpm002","Matt Carpenter",5,"heywj001","Jason Heyward",9,"hollm001","Matt Holliday",7,"peraj001","Jhonny Peralta",6,"adamm002","Matt Adams",3,"moliy001","Yadier Molina",2,"wongk001","Kolten Wong",4,"jay-j001","Jon Jay",8,"waina001","Adam Wainwright",1,"fowld001","Dexter Fowler",8,"solej001","Jorge Soler",9,"rizza001","Anthony Rizzo",3,"casts001","Starlin Castro",6,"coghc001","Chris Coghlan",7,"olt-m001","Mike Olt",5,"rossd001","David Ross",2,"lestj001","Jon Lester",1,"lastt001","Tommy La Stella",4,"","Y"
my $row = $_[0];
my @chunks = quotewords(",", 0, $row);

my $GameLog_hash_ref;
$GameLog_hash_ref -> {GameDate} = substr($chunks[0], 0, 4) . '-' . substr($chunks[0], 4, 2) . '-' . substr($chunks[0], 6, 2);
$GameLog_hash_ref -> {GameSeq} = $chunks[1];
$GameLog_hash_ref -> {GameDoW} = $chunks[2];
$GameLog_hash_ref -> {AwayTeam} = $chunks[3];
$GameLog_hash_ref -> {AwayLg} = $chunks[4];
$GameLog_hash_ref -> {AwayGameNum} = $chunks[5];
$GameLog_hash_ref -> {HomeTeam} = $chunks[6];
$GameLog_hash_ref -> {HomeLg} = $chunks[7];
$GameLog_hash_ref -> {HomeGameNum} = $chunks[8];
$GameLog_hash_ref -> {AwayRuns} = $chunks[9];
$GameLog_hash_ref -> {HomeRuns} = $chunks[10];
$GameLog_hash_ref -> {TotalOuts} = $chunks[11];
$GameLog_hash_ref -> {DayNight} = $chunks[12];

return $GameLog_hash_ref;

}
#---------------------------------------------------------------------;
sub ParsePxP_IDRec{
# example call: $GameID_hash_ref = ParsePxP_IDRec($row);
# Example data: id,CIN201103310
my $row = $_[0];
my @chunks = quotewords(",", 0, $row);

my $GameID_hash_ref;
$GameID_hash_ref -> {RecType} = $chunks[0];
$GameID_hash_ref -> {GameID} = $chunks[1];

return $GameID_hash_ref;

}
#---------------------------------------------------------------------;
sub ParsePxP_PlayRec{
# example call: $Play_hash_ref = ParsePxP_PlayRec($row);
# example data: play,1,0,gardb001,11,BCX,3/G
my $row = $_[0];
my @chunks = quotewords(",", 0, $row);

my $Play_hash_ref;
$Play_hash_ref -> {RecType} = $chunks[0];
$Play_hash_ref -> {Inning} = $chunks[1];
$Play_hash_ref -> {Half} = $chunks[2];
$Play_hash_ref -> {PlayerID} = $chunks[3];
$Play_hash_ref -> {Count} = $chunks[4];
$Play_hash_ref -> {PitchSeq} = $chunks[5];
$Play_hash_ref -> {Event} = $chunks[6];

return $Play_hash_ref;

}
#---------------------------------------------------------------------;
sub ParsePxP_PlayerRec{
# example call: $Player_hash_ref = ParsePxP_PlayerRec($row);
# example data: start,calhk001,"Kole Calhoun",0,1,9
my $row = $_[0];
my @chunks = quotewords(",", 0, $row);

my $Player_hash_ref;
$Player_hash_ref -> {RecType} = $chunks[0];
$Player_hash_ref -> {PlayerID} = $chunks[1];
$Player_hash_ref -> {PlayerName} = $chunks[2];
$Player_hash_ref -> {HomeFlag} = $chunks[3];
$Player_hash_ref -> {BatOrder} = $chunks[4];
$Player_hash_ref -> {FieldPos} = $chunks[5];

return $Player_hash_ref;

}

#---------------------------------------------------------------------;
sub ParsePxP_DataRec{
# example call: $PitcherER_hash_ref = ParsePxP_Data($row);
# example data: 'data,er,axfoj001,4';
my $row = $_[0];
my @chunks = quotewords(",", 0, $row);

my $DataRec_hash_ref;
$DataRec_hash_ref -> {RecType} = $chunks[0];
$DataRec_hash_ref -> {DataType} = $chunks[1];
$DataRec_hash_ref -> {PlayerID} = $chunks[2];
$DataRec_hash_ref -> {ER} = $chunks[3];

return $DataRec_hash_ref;

}

#---------------------------------------------------------------------;
sub ParsePxP_InfoRec{
# my $Info_hash_ref = ParsePxP_InfoRec($row);
# example data: info,save,kolbd001;
my $row = $_[0];
my @chunks = quotewords(",", 0, $row);

my $Info_hash_ref;
$Info_hash_ref -> {RecType} = $chunks[0];
$Info_hash_ref -> {InfoType} = $chunks[1];
if (defined $chunks[2]) {$Info_hash_ref -> {InfoVal} = $chunks[2];}
else {$Info_hash_ref -> {InfoVal} = 'None';}

return $Info_hash_ref;

}

#---------------------------------------------------------------------;
sub ParsePxP_Event{
my $Event = $_[0];
$Event =~ s/MREV/MRV/s; #replace MREV with MRV to remove troublesome E
$Event =~ s/UREV/URV/s; #replace MREV with MRV to remove troublesome E
$Event =~ tr/[!?#]//d;; #remove stray punctuation

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
sub InterpretEvent{
# example call: ($GameStatus_hash_ref, $PAFlag, $Pitches, $Outcome, $Clarity, $EventBucket, $GameStatusProblems) = InterpretEvent($Play_hash_ref, $GameStatus_hash_ref, $CheckStatus);

($Play_hash_ref, $lpGameStatus_hash_ref, $CheckStatus) = ($_[0], $_[1], $_[2]);
#my ($Play_hash_ref, $lpGameStatus_hash_ref, $CheckStatus) = ($_[0], $_[1], $_[2]);

my $Half = $Play_hash_ref -> {Half}; #0 = top, 1 = bottom;
my $PitchSeq = $Play_hash_ref -> {PitchSeq};
my $PitchCount = $PitchSeq =~ tr/[A-Z]//;
my $Pitches = 0;
if ($PitchCount>0) {$Pitches = $PitchCount;}

#my $PAFlag = $TRUE;
#my $Outcome = "OTH";
#my $Clarity = $FALSE;
#my $EventBucket = "Nun";
#my $GameStatusProblems = $ERR;

#my @NoRunRec = ($TRUE,$TRUE,$TRUE,$TRUE);
#my $Runs = 0;

$PAFlag = $TRUE;
$Outcome = "OTH";
$Clarity = $TRUE;
$EventBucket = "Nun";
$GameStatusProblems = $ERR;

@NoRunRec = ($TRUE,$TRUE,$TRUE,$TRUE);
$Runs = 0;

$Outs_pre = $lpGameStatus_hash_ref -> {Outs};
$Event = $Play_hash_ref -> {Event};
($EventBat, @EventRuns) = ParsePxP_Event($Event);

# Process EventRun
# Deal with base-runners advancing and caught, in arbitrary order
foreach my $EventRun(@EventRuns) {
	my $StartBase = substr $EventRun, 0, 1;
	my $EndBase = substr $EventRun, 2, 1;
	
	if ($StartBase eq "B") {$NoRunRec[0] = $FALSE;}
	else {
		DecBase($StartBase, $lpGameStatus_hash_ref);
		$NoRunRec[$StartBase] = $FALSE;
		}
	if ($EventRun =~ /-/) {$Runs = IncBase($EndBase, $Runs, $lpGameStatus_hash_ref);}
	if ($EventRun =~ /X/) {
		if ($EventRun =~ /\([1-9]+\)/) {$lpGameStatus_hash_ref -> {Outs} ++;} # X and E and (d.d) implies out, with intermediate advance on error
		elsif ($EventRun =~ /E/) {$Runs = IncBase($EndBase, $Runs, $lpGameStatus_hash_ref);} # X and E without (d.) implies safe advance on error
		else {$lpGameStatus_hash_ref -> {Outs} ++;} # X without E implies out at the EndBase
		}
	}
	
# Process EventBat
# Need to worry about order
given ($EventBat) {
	# no play
	when ("NP")		{ClearNonPA("NP1");} #No play - used to mark substitutions;

	# base running captured in EventRun
	when (/^BK/)	{ClearNonPA('BK1');} #Begins with BK - Balk, relevant info in $EventRun;
	when (/^DI/)	{ClearNonPA('DI1');} #Begins with DI - Defensive indifference, relevant info in $Ev
	when (/^OA/)	{ClearNonPA('OA1');} #Begins with OA - Other advance; relevant info in $EventRun;
	when (/^PB/)	{ClearNonPA('PB1');} #Begins with PB - Pass ball, relevant info in $EventRun;
	when (/^WP/)	{ClearNonPA('WP1');} #Begins with WP - Wild pitch, relevant info in $EventRun;

	# base running captured in EventBat instead of EventRun
	when (/^CS/)	{ClearNonPA('CS1');} #Begins with CS - Caught stealing, deal with movements, outs, runs in common code below
	when (/^PO/)	{ClearNonPA('CS2');} #Begins with PO - Picked off (caught stealing at starting base), deal with movements, outs, runs in common code below
	when (/^SB/) 	{ClearNonPA('SB1');} #Begins with CS - Stolen base, deal with movements, outs, runs in common code below

	when (/^FLE/)	{ClearNonPA('E1');} #Begins with FLE - Error on foul ball;

	# Various free passes to batter
	when (/^C\//)	{BatterToFirst('CI1');} # catcher or other fielder interference, overlap with CS caught stealing
	when (/^HP/)	{BatterToFirst('HBP1');} # hit by pitch
	when (/^W/) 	{BatterToFirst('BB1');} # overlap with WP
	when (/^I/)		{BatterToFirst('IBB1');} # as of October 10, 2016, all of the values starting w I were IBB, some with added stuff (I+CS3(25)) handled elsewhere

	# hits
	when (/^S/)		{BatterToFirst('S1');} # overlap with SB stolen base, as of October 5, 2016, all of the analyzed events that start with S, except SB, should be singles
	when (/^D/) 	{$Outcome = "D"; $EventBucket = 'D1'; if ($NoRunRec[0] == $TRUE){$lpGameStatus_hash_ref -> {B2Occ} ++;}} # overlap with DI diffensive indifference, as of October 5, 2016, all of the analyzed events that start with D, except DI, should be doubles
	when (/^T/)		{$Outcome = "T"; $EventBucket = 'T1'; if ($NoRunRec[0] == $TRUE){$lpGameStatus_hash_ref -> {B3Occ} ++;}} # no known overlap, as of October 5, 2016, all of the analyzed events that start with T should be triples
	when (/^H/)		{$Outcome = "HR"; $EventBucket = 'HR1'; if ($NoRunRec[0] == $TRUE){$Runs ++;}} # overlap with HP, as of October 5, 2016, all of the analyzed events that start with H, except HP, should be home runs
	
	# simple outs
	when (/^FC/)	{BatterToFirst("FC1");} # This form records outs in EventRuns, FC does not require that defense records any outs
	when (/^K/)		{BatterOut("K1");}
	
	# Everything else starts with a digit or an E and represents some combination of outs and errors

	# Need to catch E/SH, E/SF, FC/SH here and not in SH or SF
	# May not be sifting line-outs and ground-outs properly
	# Assume all advances captured in EventRuns
	when (/^\d{0,3}E\d/) {
		# Assume B to 1B, catch other outcomes below
		if ($EventBat =~ /\/G/){$Outcome = "GO"; $EventBucket = 'EGOh';}
		elsif ($EventBat =~ /\/SF/){$Outcome = "SF"; $EventBucket = 'ESFh';}
		elsif ($EventBat =~ /\/SH/){$Outcome = "SH"; $EventBucket = 'ESHh';}
		else {$Outcome = "FO"; $EventBucket = 'EFOh';}
		if ($NoRunRec[0] == $TRUE){$lpGameStatus_hash_ref -> {B1Occ} ++;}
		}

	# NDPs - two outs, but not credited as a double play for some reason
	# Assume that all outs are recorded as (bXb) or in EventRun and check for two outs
	when (/NDP/) {
		$EventBucket = 'NDP1';
		if ($EventBat =~ /\/G/){$Outcome = "GO";}
		elsif ($EventBat =~ /\/FO/){$Outcome = "FO";}
		elsif ($EventBat =~ /\/SF/){$Outcome = "SF";}
		elsif ($EventBat =~ /\/SH/){$Outcome = "SH";}
		else {$Outcome = "ONDP";}
		if ($EventBat =~ /^[1-9]\//) {$lpGameStatus_hash_ref -> {Outs} ++;$Outcome = "FO";} # fly out
		elsif ($EventBat =~ /^[1-9]+\//) {$lpGameStatus_hash_ref -> {Outs} ++;$Outcome = "GO";} # some sort of force out on batter at first
		elsif ($EventBat =~ /\(B/) {$lpGameStatus_hash_ref -> {Outs} ++;}
		CheckEventBatForRunnerOuts();
		my $OutsRecd = $lpGameStatus_hash_ref -> {Outs} - $Outs_pre;
		if ($OutsRecd == 2) {$Clarity = $TRUE;}
			else {$Clarity = $FALSE;}
		}
		
	# SF and SH are never found in EventBat together in the same row
	# SF and IF can be found together in the same row

	# Sacrifice flies, which can include double or triple plays
	# examples
	# 8/SF/DP.3-H;2X3(865) - cannonical, with one out recorded in EventRuns
	# 9/SF/FDP.3-H;1X2(936) - minor variant of cannonical
	# 9(b)3(1)/DP/SF.3-H - all outs recorded in EventBat
	# no plays contain two outs in EventRuns
	when (/\/SF/) {
		CheckEventBatForRunnerOuts();
		if ($EventBat =~ /TP/) {
			# SF coding implies that the batter is out, but check for EventRuns record
			# omit check for <d>(B), which is implied and unstated in standard coding
			BatterOut('SFTP1');
			my $OutsRecd = $lpGameStatus_hash_ref -> {Outs} - $Outs_pre;
			if ($OutsRecd == 3) {$Clarity = $TRUE;}
				else {$Clarity = $FALSE;}
			}
		elsif ($EventBat =~ /DP/) {
			# SF coding implies that the batter is out, but check for EventRuns record
			# omit check for <d>(B), which is implied and unstated in standard coding
			BatterOut('SFDP1');
			my $OutsRecd = $lpGameStatus_hash_ref -> {Outs} - $Outs_pre;
			if ($OutsRecd == 2) {$Clarity = $TRUE;}
				else {$Clarity = $FALSE;}
			}
		elsif ($EventBat =~ /FO/) {
			# SF w FO and not DP coding implies a dropped SF with a runner forced somewhere, but probably not the batter
			if ($EventBat =~ /\(B/) {BatterOut('SFFC1');}
				else {BatterToFirst('SFFC1');}
			my $OutsRecd = $lpGameStatus_hash_ref -> {Outs} - $Outs_pre;
			if ($OutsRecd == 1) {$Clarity = $TRUE;}
				else {$Clarity = $FALSE;}
			}
		else {
			BatterOut("SF1"); # if not coded as DP, put batter out and permit any number of outs in EventRuns
			}
		}
	when (/\/IF\//) {BatterOut("PO1");} # Infield fly, put batter out and assume all runner movements captured in EventRuns
	when (/\/SH/) {BatterOut("SH3");} # Sacifice hit, put batter out and assume all runner movements captured in EventRuns
	# Simple GDP of form 64(1)3/GDP
	# also GDP of form 5(2)4(1)/GDP
	# Need to catch this before the two-digit ground outs below
	when (/[FLGP\/]DP/)  {
		if (($EventBat =~ /[FL]DP/) or ($EventBat =~ /BP/)) {$Outcome = "LDP";$EventBucket = 'LDP1';} # line out or fly out with double play
		elsif ($EventBat =~ /PDP/) {$Outcome = "BPDP";$EventBucket = 'BPDP1';} # bunt pop-up into double play
		else {$Outcome = "GDP";$EventBucket = 'GDP1';} # ground out double play
		my $RunnerOuts = $lpGameStatus_hash_ref -> {Outs} - $Outs_pre;
		my @OpenParens = $EventBat =~ /\(/g;
		my $StBsCnt = @OpenParens;
		
		if (($RunnerOuts + $StBsCnt) == 0) {
			# not enough outs, but assume batter out;
			$lpGameStatus_hash_ref -> {Outs} ++;
			$Clarity = $FALSE;
			}
		elsif (($RunnerOuts + $StBsCnt) == 1) {BatterOut($EventBucket);} # implicit batter out;
		elsif (($RunnerOuts + $StBsCnt) == 2) {BatterToFirst($EventBucket);} # outs handled explicitly in EventBat and EventRuns, so put batter on first, potentially removed below;
		else {$Clarity = $FALSE;} # too many enough outs;
		if ($StBsCnt > 0) {
			# regardless of consistency, run through the bases and assign outs;
			if ($EventBat =~ /\(B/) {$lpGameStatus_hash_ref -> {B1Occ} --;$lpGameStatus_hash_ref -> {Outs} ++;}
			CheckEventBatForRunnerOuts();
			} 
		}
	# Triple plays
	when (/[GFL\/]TP/) {
		if ($EventBat =~ /GTP/) {$Outcome = "GTP";}
			else {$Outcome = "OTP";}
		$EventBucket = $Outcome . "1";
		$lpGameStatus_hash_ref -> {Outs} = 3; # fixx - worry about LOB?
		}

	# no plays contain both (B in the EventBat and a B EventRun record
	# no plays contain both (B and /FO in the EventBat by that point in the cascade, so order may matter
	# plays that start with digits and do not include E, DP, TP, SF, IF, SH
	# example 143(B)/G
	when (/^[1-9]/) {
		CheckEventBatForRunnerOuts();
		   if ($EventBat =~ /^[1-9]$/)			{BatterOut('PO1');} # fly outs, eg 7
		elsif ($EventBat =~ /^[1-9]+$/)			{BatterOut('GO1');} # basic ground outs, eg 43, 643 with only the batter out
		elsif ($EventBat =~ /^[1-9]\/B[PL]/)	{BatterOut('PO2');} # bunt pops outs, eg 3/BP
		elsif ($EventBat =~ /^[1-9]+\/[LPF]/)	{BatterOut('PO3');} # various pop, line, or fly outs, eg 7/L
		elsif ($EventBat =~ /^[1-9]+\/[BG]/)	{BatterOut('GO2');} # ground outs, eg 43/G, 13/B, 3/G3
		elsif ($EventBat =~ /^[1-9]\//)			{BatterOut('PO4');} # fly out, eg 8/F
		elsif ($EventBat =~ /^[1-9]+\//)		{BatterOut('GO3');} # ground outs with other random modifiers, eg 43/F
		elsif ($EventBat =~ /\(B/)				{BatterOut('GO4');} # grounds outs with batter out, often put out at first by other than 3, eg 1(B)/G, 41(B)/G
		elsif ($EventBat =~ /\/FO/)				{BatterToFirst('FO1');} # force outs, eg 64(1)/FO, keep below (B) to avoid picking up strange coding with /FO but (B)
		else									{BatterToFirst('FO2');} # miscellaneous other force outs, eg, 54(1)/F
		my $OutsRecd = $lpGameStatus_hash_ref -> {Outs} - $Outs_pre;
		if ($OutsRecd == 1) {$Clarity = $TRUE;}
			else {$Clarity = $FALSE;}
		}
	default {
		$EventBucket = 'Def';
		$Clarity = $FALSE;
		}
	}

# Deal with running codings embedded in EventBat
# Include both primary coding (SB2) and secondary coding (K+SB2)
# Chop up EventBat to deal with multiple run events
if (($EventBat =~ /CS/) or ($EventBat =~ /PO/) or ($EventBat =~ /SB/)){
	my @EventBatRuns;
	if ($EventBat =~ /\;/) {@EventBatRuns = split /\;/, $EventBat;}
		else {$EventBatRuns[0] = $EventBat;}
	foreach my $EventBatRun(@EventBatRuns) {
		# Stolen bases
		# Examples: SB2, K+SB2, K+SB2;SB3
		if ($EventBatRun =~ /SB/) {
			if (($EventBatRun =~ /SB2/) and ($NoRunRec[1] == $TRUE)) {$lpGameStatus_hash_ref -> {B1Occ} --; $lpGameStatus_hash_ref -> {B2Occ} ++;}
			if (($EventBatRun =~ /SB3/) and ($NoRunRec[2] == $TRUE)) {$lpGameStatus_hash_ref -> {B2Occ} --; $lpGameStatus_hash_ref -> {B3Occ} ++;}
			if (($EventBatRun =~ /SBH/) and ($NoRunRec[3] == $TRUE)) {$lpGameStatus_hash_ref -> {B3Occ} --; $Runs ++;}
			}
			
		# Caught stealing or picked off
		# Example: K+CS2(26)
		if (($EventBatRun =~ /CS/) or ($EventBatRun =~ /PO/)){
			if ($EventBatRun =~ /E/) {
				if (($EventBatRun =~ /CS2/) and ($NoRunRec[1] == $TRUE)) {$lpGameStatus_hash_ref -> {B1Occ} --; $lpGameStatus_hash_ref -> {B2Occ} ++;}
				if (($EventBatRun =~ /CS3/) and ($NoRunRec[2] == $TRUE)) {$lpGameStatus_hash_ref -> {B2Occ} --; $lpGameStatus_hash_ref -> {B3Occ} ++;}
				if (($EventBatRun =~ /CSH/) and ($NoRunRec[3] == $TRUE)) {$lpGameStatus_hash_ref -> {B3Occ} --; $Runs ++;}
				}
			else {
				if (($NoRunRec[1] == $TRUE) and (($EventBatRun =~ /CS2/) or ($EventBatRun =~ /PO1/))) {$lpGameStatus_hash_ref -> {B1Occ} --;}
				if (($NoRunRec[2] == $TRUE) and (($EventBatRun =~ /CS3/) or ($EventBatRun =~ /PO2/))) {$lpGameStatus_hash_ref -> {B2Occ} --;}
				if (($NoRunRec[3] == $TRUE) and (($EventBatRun =~ /CSH/) or ($EventBatRun =~ /PO3/))) {$lpGameStatus_hash_ref -> {B3Occ} --;}
				$lpGameStatus_hash_ref -> {Outs} ++;
				}
			}
		}
	}

if ($Runs > 0) {
	if ($Half==0){$lpGameStatus_hash_ref -> {AwayRuns} = $lpGameStatus_hash_ref -> {AwayRuns} + $Runs;}
	else {$lpGameStatus_hash_ref -> {HomeRuns} = $lpGameStatus_hash_ref -> {HomeRuns} + $Runs;}
	}

if ($PAFlag == $TRUE) {$lpGameStatus_hash_ref -> {BatterInInning} ++;}

if ($CheckStatus == $TRUE) {$GameStatusProblems = CheckGameStatus($lpGameStatus_hash_ref);}
if ($GameStatusProblems == $TRUE) {$Clarity = $FALSE;}
return ($lpGameStatus_hash_ref, $PAFlag, $Pitches, $Outcome, $Clarity, $EventBucket, $GameStatusProblems);

}

#---------------------------------------------------------------------;
sub IncBase{
# example call: $Runs = IncBase($BaseNumber, $Runs, $lpGameStatus_hash_ref);
# fix not sure why this treatment of passing $lpGameStatus_hash_ref works, but it does
my ($BaseNumber, $Runs, $lpGameStatus_hash_ref) = ($_[0], $_[1], $_[2]);

if ($BaseNumber eq 'H'){$Runs ++;}
elsif ($BaseNumber == 1){$lpGameStatus_hash_ref -> {B1Occ}++;}
elsif ($BaseNumber == 2){$lpGameStatus_hash_ref -> {B2Occ}++;}
elsif ($BaseNumber == 3){$lpGameStatus_hash_ref -> {B3Occ}++;}

return $Runs;
}

#---------------------------------------------------------------------;
sub DecBase{
# example call: DecBase($BaseNumber, $lpGameStatus_hash_ref);
# fix not sure why this treatment of passing $lpGameStatus_hash_ref works, but it does
my ($BaseNumber, $lpGameStatus_hash_ref) = ($_[0], $_[1]);

if ($BaseNumber == 1){$lpGameStatus_hash_ref -> {B1Occ}--;}
if ($BaseNumber == 2){$lpGameStatus_hash_ref -> {B2Occ}--;}
if ($BaseNumber == 3){$lpGameStatus_hash_ref -> {B3Occ}--;}

return 1;
}
#---------------------------------------------------------------------;
sub BatterOut{
# example call:  BatterOut("Value");
my $lsEventBucket = $_[0];
$EventBucket = $lsEventBucket;
$Outcome = substr $lsEventBucket, 0, -1;
if ($NoRunRec[0] == $TRUE) {$lpGameStatus_hash_ref -> {Outs} ++;}

return 1;
}
#---------------------------------------------------------------------;
sub BatterToFirst{
# example call:  BatterToFirst("Value");
my $lsEventBucket = $_[0];

$EventBucket = $lsEventBucket;
$Outcome = substr $lsEventBucket, 0, -1;
if ($NoRunRec[0] == $TRUE) {$lpGameStatus_hash_ref -> {B1Occ} ++;}

return 1;
}
#---------------------------------------------------------------------;
sub ClearNonPA{
# example call:  ClearNonPA("Value");
my $lsEventBucket = $_[0];

$EventBucket = $lsEventBucket;
$Outcome = substr $lsEventBucket, 0, -1;
$PAFlag = $FALSE;

return 1;
}
#---------------------------------------------------------------------;
sub CheckEventBatForRunnerOuts{
# example call:  CheckEventBatForRunnerOuts();

if (($NoRunRec[1] == $TRUE) and ($EventBat =~ /\(1/)) {$lpGameStatus_hash_ref -> {B1Occ} --;$lpGameStatus_hash_ref -> {Outs} ++;}
if (($NoRunRec[2] == $TRUE) and ($EventBat =~ /\(2/)) {$lpGameStatus_hash_ref -> {B2Occ} --;$lpGameStatus_hash_ref -> {Outs} ++;}
if (($NoRunRec[3] == $TRUE) and ($EventBat =~ /\(3/)) {$lpGameStatus_hash_ref -> {B3Occ} --;$lpGameStatus_hash_ref -> {Outs} ++;}

return 1;
}
#---------------------------------------------------------------------;
sub CheckGameStatus{
# example call: $GameStatusProblems = CheckGameStatus($GameStatus_hash_ref);
my ($GameStatus_hash_ref) = $_[0];

my $StatusProblem = $FALSE;

my $Outs = $GameStatus_hash_ref -> {Outs};
my $B1Occ = $GameStatus_hash_ref -> {B1Occ};
my $B2Occ = $GameStatus_hash_ref -> {B2Occ};
my $B3Occ = $GameStatus_hash_ref -> {B3Occ};
if ($Outs > 3) {$StatusProblem = $TRUE;}
if ($Outs < 0) {$StatusProblem = $TRUE;}
if ($Outs < 3) {
	if ($B1Occ > 1) {$StatusProblem = $TRUE;}
	if ($B1Occ < 0) {$StatusProblem = $TRUE;}
	if ($B2Occ > 1) {$StatusProblem = $TRUE;}
	if ($B2Occ < 0) {$StatusProblem = $TRUE;}
	if ($B3Occ > 1) {$StatusProblem = $TRUE;}
	if ($B3Occ < 0) {$StatusProblem = $TRUE;}
	}

return $StatusProblem;
}
return 1;
