# RetrosheetTools
I have been working with the Retrosheet data (retrosheet.org) as a way to develop my Perl and MySQL skills. I may also add R files as I move toward analyzing the data. As such, these files may contain all sorts of errors, including simple low-level bugs and high-level conceptual or stylistic errors. Please let me know if you have any suggestions.

This project contains Perl and MySQL tools that I've developed to work with the Retrosheet data files. The tools create MySQL database tables with information pulled from the Retrosheet source files. At this point, these files create the following tables:
- PlateApps: one record per plate appearance, with game ID, pitcher ID, batter ID, and information about the outcome
- Gamelogs: one record per game, with game ID and about 170 other variables, such as home and visiting team box score data
- PitchingLines: one record per pitcher per game, with game ID, pitcher ID, and about 15 other variables, such as runs and hits allowed
- EventDiag: one record per plate appearance, with game ID, text from Retrosheet source file, and diagnostic information about parsing program

The files include MySQL and Perl programs, plus a Perl modeul, RetrosheetUserModules.pm, which contains a group of subs to parse various Retrosheet data elements and to process them. The files are named with rough sequencing information, so that files starting "s0" should be run before files starting with "s1", and so on.

