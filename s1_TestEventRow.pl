#!/usr/bin/perl
# s1_TestEventRow

package s1_TestEventRow;

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
use user::RetrosheetUserModules qw(CheckGameStatus);

Readonly my $ERR => -1;
Readonly my $TRUE =>  1;
Readonly my $FALSE =>  0;
Readonly my $SrcDir => <replace with path to source files>;

my $GameStatus_hash_ref = ResetGame();

print "\nSelected plays\n";
my $RowStart = "play,6,0,davic003,00,1X,";
print "row, Outs_prev, Outcome, dOuts, Clarity, EventBucket\n";
print "Outs, B1Occ, B2Occ, B3Occ, AwayRuns, HomeRuns\n";
$GameStatus_hash_ref = ResetGame();TestRow($RowStart . "16(1)3/GDP", $GameStatus_hash_ref);
$GameStatus_hash_ref = ResetGame();TestRow("play,8,1,branm003,01,CX,46(1)3/GDP", $GameStatus_hash_ref);
$GameStatus_hash_ref = ResetGame();TestRow("play,10,0,hudso001,11,B1L1X,1/BP/DP.1X1(13)", $GameStatus_hash_ref);
$GameStatus_hash_ref = ResetGame();TestRow("play,5,1,sizeg001,22,SBSFBX,46(1)/FO/G.2-3;B-1", $GameStatus_hash_ref);
$GameStatus_hash_ref = ResetGame();TestRow("play,5,1,sizeg001,??,,6/LDP.1X1(63)", $GameStatus_hash_ref);
$GameStatus_hash_ref = ResetGame();TestRow("play,5,1,sizeg001,10,BX,8352(3)/LDP/L8S.1X3(2)", $GameStatus_hash_ref); # this coding is a mess and the play-by-play at http://www.baseball-reference.com/boxes/BAL/BAL199304170.shtml makes no sense
$GameStatus_hash_ref = ResetGame();TestRow("play,5,1,sizeg001,??,,63/6M", $GameStatus_hash_ref);
$GameStatus_hash_ref = ResetGame();TestRow("play,5,1,sizeg001,??,,9/DP.3XH(9365);1-2", $GameStatus_hash_ref);
$GameStatus_hash_ref = ResetGame();TestRow("play,5,1,sizeg001,??,,5(B)5(3)/BP/DP", $GameStatus_hash_ref);
$GameStatus_hash_ref = ResetGame();TestRow("play,5,1,sizeg001,??,,5(2)3/GDP.1-2", $GameStatus_hash_ref);
$GameStatus_hash_ref = ResetGame();TestRow("play,5,1,sizeg001,??,,4(1)3/GDP", $GameStatus_hash_ref);
$GameStatus_hash_ref = ResetGame();TestRow("play,5,1,sizeg001,??,,5(2)4(1)/GDP", $GameStatus_hash_ref);
$GameStatus_hash_ref = ResetGame();TestRow("play,5,1,sizeg001,??,,36(1)3(B)/GDP", $GameStatus_hash_ref);
$GameStatus_hash_ref = ResetGame();TestRow("play,5,1,sizeg001,??,,54(1)/FO/DP.2X3(45);3-H(UR)", $GameStatus_hash_ref);
$GameStatus_hash_ref = ResetGame();TestRow($RowStart . "1(B)/G", $GameStatus_hash_ref);
$GameStatus_hash_ref = ResetGame();TestRow($RowStart . "6(1)/F", $GameStatus_hash_ref);
$GameStatus_hash_ref = ResetGame();TestRow($RowStart . "3(B)4(1)/BPDP", $GameStatus_hash_ref);
$GameStatus_hash_ref = ResetGame();TestRow($RowStart . "8/", $GameStatus_hash_ref);
$GameStatus_hash_ref = ResetGame();TestRow($RowStart . "E3", $GameStatus_hash_ref);
$GameStatus_hash_ref = ResetGame();TestRow($RowStart . "14E3", $GameStatus_hash_ref);
$GameStatus_hash_ref = ResetGame();TestRow($RowStart . "PO1(E1/TH).1-3", $GameStatus_hash_ref);
$GameStatus_hash_ref = ResetGame();TestRow($RowStart . "4!!!/P", $GameStatus_hash_ref);
$GameStatus_hash_ref = ResetGame();TestRow($RowStart . "14(B)/BG", $GameStatus_hash_ref);
$GameStatus_hash_ref = ResetGame();TestRow($RowStart . "863/AP", $GameStatus_hash_ref);
$GameStatus_hash_ref = ResetGame();TestRow("play,1,1,burgs101,??,,46(1)/FO	46(1)/FO", $GameStatus_hash_ref);
#$GameStatus_hash_ref = ResetGame();TestRow($RowStart . "", $GameStatus_hash_ref);

print "\nATL198307180, start game sequence\n";
print "row, Outs_prev, Outcome, dOuts, Clarity, EventBucket\n";
print "Outs, B1Occ, B2Occ, B3Occ, AwayRuns, HomeRuns\n";
$GameStatus_hash_ref = ResetGame();
TestRow("play,2,0,ashft001,11,,S7", $GameStatus_hash_ref);
TestRow("play,2,0,oquej001,00,,S8.1-2", $GameStatus_hash_ref);
TestRow("play,2,0,gormt001,11,,14/SH.2-3;1-2", $GameStatus_hash_ref);
TestRow("play,2,0,wilsm001,12,,S9.3-H;2-H;BX3(E9)(95)", $GameStatus_hash_ref);
TestRow("play,2,0,bailb001,30,,S7", $GameStatus_hash_ref);
TestRow("play,2,0,heepd001,10,,S9.1-2", $GameStatus_hash_ref);
TestRow("play,2,0,fostg001,00,,NP", $GameStatus_hash_ref);
TestRow("play,2,0,fostg001,00,,S7.2-H;1-3", $GameStatus_hash_ref);
TestRow("play,2,0,strad001,12,,43", $GameStatus_hash_ref);

print "\nstart game sequence\n";
$GameStatus_hash_ref = ResetGame();
TestRow("play,3,0,rojam002,32,BBBCFX,1/G", $GameStatus_hash_ref);
TestRow("play,3,0,turnj001,31,BBBCB,W", $GameStatus_hash_ref);
TestRow("play,3,0,puigy001,11,FBX,S4/G.1-2", $GameStatus_hash_ref);
TestRow("play,3,0,gonza003,31,BBS*BB,W.2-3;1-2", $GameStatus_hash_ref);
TestRow("play,3,0,ramih003,10,BX,S8/L.3-H;2-H;1-3", $GameStatus_hash_ref);
TestRow("play,3,0,kempm001,31,B*BBCX,9/SF/FDP.3-H;1X2(936)", $GameStatus_hash_ref);


print "\nARI201509080, start game sequence\n";
print "row, Outs_prev, Outcome, dOuts, Clarity, EventBucket\n";
print "Outs, B1Occ, B2Occ, B3Occ, AwayRuns, HomeRuns\n";
$GameStatus_hash_ref = ResetGame();
TestRow("play,4,1,gossp001,11,.BLX,3/G", $GameStatus_hash_ref);
TestRow("play,4,1,goldp001,12,CCBX,S8/G+", $GameStatus_hash_ref);
TestRow("play,4,1,perad001,11,BFX,S46/G.1-2", $GameStatus_hash_ref);
TestRow("play,4,1,saltj001,11,*BCX,S9/L+.2-3;1-2", $GameStatus_hash_ref);
TestRow("play,4,1,lambj001,01,CX,5/P5F/NDP/SF.3-H;2XH(26)(E5/TH);1-2", $GameStatus_hash_ref);

print "\nATL198706180, start game sequence\n";
print "row, Outs_prev, Outcome, dOuts, Clarity, EventBucket\n";
print "Outs, B1Occ, B2Occ, B3Occ, AwayRuns, HomeRuns\n";
$GameStatus_hash_ref = ResetGame();
TestRow("play,3,0,davie001,,,S/6", $GameStatus_hash_ref);
TestRow("play,3,0,parkd001,,,SB2", $GameStatus_hash_ref);
TestRow("play,3,0,parkd001,,,W", $GameStatus_hash_ref);
TestRow("play,3,0,bellb001,,,S/9.2-H;1-2", $GameStatus_hash_ref);
TestRow("play,3,0,diazb001,,,9/DP.2XH(E5)(96512);1-3", $GameStatus_hash_ref);
TestRow("play,3,0,frant001,,,3/G", $GameStatus_hash_ref);

print "\nCHN190810120, start game sequence\n";
print "row, Outs_prev, Outcome, dOuts, Clarity, EventBucket\n";
print "Outs, B1Occ, B2Occ, B3Occ, AwayRuns, HomeRuns\n";
$GameStatus_hash_ref = ResetGame();
TestRow("play,4,1,shecj101,??,,K", $GameStatus_hash_ref);
TestRow("play,4,1,everj102,??,,W", $GameStatus_hash_ref);
TestRow("play,4,1,schuf103,??,,CS2(E3)", $GameStatus_hash_ref);
TestRow("play,4,1,schuf103,??,,2/FL", $GameStatus_hash_ref);
TestRow("play,4,1,chanf101,??,,S8.2-H(UR)", $GameStatus_hash_ref);
TestRow("play,4,1,steih101,??,,SB2", $GameStatus_hash_ref);
TestRow("play,4,1,steih101,??,,E5/TH1.2-H(UR)(E3/TH3);B-2", $GameStatus_hash_ref);
TestRow("play,4,1,hofms101,??,,T7.2-H(UR)", $GameStatus_hash_ref);
TestRow("play,4,1,tinkj101,??,,63", $GameStatus_hash_ref);

print "\nKCA197005230, start game sequence\n";
print "row, Outs_prev, Outcome, dOuts, Clarity, EventBucket\n";
print "Outs, B1Occ, B2Occ, B3Occ, AwayRuns, HomeRuns\n";
$GameStatus_hash_ref = ResetGame();
TestRow("play,1,0,harpt101,??,,S", $GameStatus_hash_ref);
TestRow("play,1,0,kubit101,??,,W.1-2", $GameStatus_hash_ref);
TestRow("play,1,0,savat101,??,,9.2-3", $GameStatus_hash_ref);
TestRow("play,1,0,waltd101,??,,64(1)/F.3-H", $GameStatus_hash_ref);
TestRow("play,1,0,alleh104,??,,D9.1-3", $GameStatus_hash_ref);
TestRow("play,1,0,penar101,??,,4", $GameStatus_hash_ref);

print "\nBOS197204210, start game sequence\n";
print "row, Outs_prev, Outcome, dOuts, Clarity, EventBucket\n";
print "Outs, B1Occ, B2Occ, B3Occ, AwayRuns, HomeRuns\n";
$GameStatus_hash_ref = ResetGame();
TestRow("play,3,1,culpr101,??,,W", $GameStatus_hash_ref);
TestRow("play,3,1,harpt101,??,,S8/L.1-2", $GameStatus_hash_ref);
TestRow("play,3,1,aparl101,??,,S9/G.2-3;1-2", $GameStatus_hash_ref);
TestRow("play,3,1,yastc101,??,,43.3-H;2-3;1-2", $GameStatus_hash_ref);
TestRow("play,3,1,smitr101,??,,IW", $GameStatus_hash_ref);
TestRow("play,3,1,petrr101,??,,85(2)/FO/SF.3-H;1-2", $GameStatus_hash_ref);
TestRow("play,3,1,cated101,??,,64(1)/FO", $GameStatus_hash_ref);

print "\nCHA198806040, start game sequence\n";
print "row, Outs_prev, Outcome, dOuts, Clarity, EventBucket\n";
print "Outs, B1Occ, B2Occ, B3Occ, AwayRuns, HomeRuns\n";
$GameStatus_hash_ref = ResetGame();
TestRow("play,7,0,incap001,12,CFBFX,S8/L89", $GameStatus_hash_ref);
TestRow("play,7,0,obrip001,31,CBBBB,W.1-2", $GameStatus_hash_ref);
TestRow("play,7,0,mcdoo001,01,CX,53/SH/BG5S.2-3;1-2", $GameStatus_hash_ref);
TestRow("play,7,0,petrg001,30,IIII,I", $GameStatus_hash_ref);
TestRow("play,7,0,buecs001,00,X,54(1)/L5.3-H;2-3;B-1", $GameStatus_hash_ref);
TestRow("play,7,0,wilkc001,01,FX,6/L", $GameStatus_hash_ref);

print "\nOAK199609040, start game sequence\n";
print "row, Outs_prev, Outcome, dOuts, Clarity, EventBucket\n";
print "Outs, B1Occ, B2Occ, B3Occ, AwayRuns, HomeRuns\n";
$GameStatus_hash_ref = ResetGame();
TestRow("play,5,0,fielc001,10,BX,S7/F7D", $GameStatus_hash_ref);
TestRow("play,5,0,martt002,01,SX,36(1)/FO/G34/R3(NDP)", $GameStatus_hash_ref);
TestRow("play,5,0,willb002,10,BX,31/G34S.1-2", $GameStatus_hash_ref);
TestRow("play,5,0,duncm001,01,SX,8/F8RD", $GameStatus_hash_ref);

print "\nCAL198706090, start game sequence\n";
print "row, Outs_prev, Outcome, dOuts, Clarity, EventBucket\n";
print "Outs, B1Occ, B2Occ, B3Occ, AwayRuns, HomeRuns\n";
$GameStatus_hash_ref = ResetGame();
TestRow("play,4,0,tablp001,,,E4.B-1", $GameStatus_hash_ref);
TestRow("play,4,0,cartj001,,,S.1-2", $GameStatus_hash_ref);
TestRow("play,4,0,hallm001,,,S.2-3;1-2", $GameStatus_hash_ref);
TestRow("play,4,0,bernt001,,,8/SF.3-H(UR);2-3;1-2", $GameStatus_hash_ref);
TestRow("play,4,0,snydc001,,,I", $GameStatus_hash_ref);
TestRow("play,4,0,jacob001,,,S.3-H;2-H;1-3;B-2", $GameStatus_hash_ref);
TestRow("play,4,0,dempr001,,,POCS3(1526);CSH(654)/DP", $GameStatus_hash_ref);

print "\nPHI191510090, start game sequence\n";
print "row, Outs_prev, Outcome, dOuts, Clarity, EventBucket\n";
print "Outs, B1Occ, B2Occ, B3Occ, AwayRuns, HomeRuns\n";
$GameStatus_hash_ref = ResetGame();
TestRow("play,1,0,hooph101,??,,W", $GameStatus_hash_ref);
TestRow("play,1,0,scote101,??,,3/BP", $GameStatus_hash_ref);
TestRow("play,1,0,speat101,??,,S9.1-3", $GameStatus_hash_ref);
TestRow("play,1,0,hobld101,??,,CS2(24);CSH(4E2).3-H(UR)", $GameStatus_hash_ref);
TestRow("play,1,0,hobld101,??,,S8", $GameStatus_hash_ref);
TestRow("play,1,0,lewid101,??,,CS2(24)", $GameStatus_hash_ref);

print "\nBOS201005030, start game sequence\n";
print "row, Outs_prev, Outcome, dOuts, Clarity, EventBucket\n";
print "Outs, B1Occ, B2Occ, B3Occ, AwayRuns, HomeRuns\n";
$GameStatus_hash_ref = ResetGame();
TestRow("play,4,0,huntt001,32,BFBFBFFB,W", $GameStatus_hash_ref);
TestRow("play,4,0,morak001,10,B111N,POCS2(16)", $GameStatus_hash_ref);
TestRow("play,4,0,morak001,22,B111N.SBFX,S18/G+", $GameStatus_hash_ref);
TestRow("play,4,0,matsh001,00,X,S8/L.1-2", $GameStatus_hash_ref);
TestRow("play,4,0,rivej001,32,BFBSFBB,W.2-3;1-2", $GameStatus_hash_ref);
TestRow("play,4,0,iztum001,00,X,D8/L.3-H;2-H;1-3", $GameStatus_hash_ref);
TestRow("play,4,0,kendh001,00,X,53/G.3-H", $GameStatus_hash_ref);
TestRow("play,4,0,napom001,22,BBSSS,K", $GameStatus_hash_ref);


#---------------------------------------------------------------------;
sub TestRow{
my $row = $_[0];
my $GameStatus_hash_ref = $_[1];

my $PAFlag;
my $Pitches;
my $Outcome;
my $EventBucket;
my $Clarity;
my $StatusProblems;

my $Outs_prev = $GameStatus_hash_ref -> {Outs};
my $Play_hash_ref = ParsePxP_PlayRec($row);
($GameStatus_hash_ref, $PAFlag, $Pitches, $Outcome, $Clarity, $EventBucket, $StatusProblems) = InterpretEvent($Play_hash_ref, $GameStatus_hash_ref, $TRUE);
my $Outs = $GameStatus_hash_ref -> {Outs};
my $dOuts = $Outs - $Outs_prev;
print "$row, $Outs_prev, $Outcome, $dOuts, $Clarity, $EventBucket\n";

my %GameStatus_hash = %$GameStatus_hash_ref;
foreach my $k (keys %GameStatus_hash) {print "$k: $GameStatus_hash{$k}; ";}
print "\n";

return 1;
}
