use strict;
use IO::Handle;
use vars qw($VERSION %IRSSI);

use Irssi;
$VERSION = '0.3.3';
%IRSSI = (
	authors     => 'Jeroen Coekaerts, Koenraad Heijlen',
	contact     => 'vipie@ulyssis.org, jeroen@coekaerts.be',
	name        => 'osd',
	description => 'An OnScreenDisplay (osd) it show\'s who is talking to you, on what IRC Network.',
	license     => 'BSD',
	url         => 'http://vipie.studentenweb.org/dev/irssi/',
	changed     => '2006-01-29'
);

#--------------------------------------------------------------------
# Changelog
#
# 2008-01-25 (James Vasile)
#  - Prevent audio alert from playing too often
#
# 2006-01-29  (James Vasile)
#  - Added an ignore list
#  - Added ability to play auditory alerts via mpg321.
#  - Added alternate terms on which to highlight
#
# 2004-01-09 
#  - fix a typo in the help (M.G.Kishalmi)
# TODO :
#
# * a setting that let's you display the text? (exploits?!)
#
#--------------------------------------------------------------------


#--------------------------------------------------------------------
# Global Public Variables
#--------------------------------------------------------------------
my %myHELP = ();
my $song_command = '/usr/bin/aplay';  # we set this here because setting it
                              # in irssi would open a security hole.
my $last_song_time = 0; # so we don't play the song too often
#my %song_last;

#--------------------------------------------------------------------
# Help function
#--------------------------------------------------------------------
sub cmd_help { 
	my ($about) = @_;

	%myHELP = (
		osd_test => "
osd_test

Displays a small test message on screen
",

		osd_reload => "
osd_reload

Restarts the osd_cat program, it's especially need when
have CHANGED settings. They DO NOT take effect UNTIL you RELOAD.
",

		osd => "
OSD 

You can display on screen who is paging/msg'ing you on IRC.

When you CHANGE the settings you SHOULD use /osd_reload to let these changes
take effect.

Settings:
---------

* osd_color  	(default: blue)
Currently the setting is: " . Irssi::settings_get_str('osd_color') . "

It should be a valid X color, the list in normally located in /etc/X11/rgb.txt.

* osd_font  	(default: -*-helvetica-medium-r-\*-\*-\*-320-\*-\*-\*-\*-\*-\*)
Currently the setting is: " . Irssi::settings_get_str('osd_font') . "

These fonts are available when you installed the microsoft font pack :-)
-microsoft-tahoma-bold-r-normal-*-\*-320-\*-\*-p-\*-\*-\*
-microsoft-verdana-bold-r-normal-\*-\*-320-\*-\*-p-\*-\*-\*

This font is available on every linux install with the adobe fonts. 
-*-helvetica-medium-r-\*-\*-\*-320-\*-\*-\*-\*-\*-\*

*  osd_align	(default: right)
Currently the setting is: " . Irssi::settings_get_str('osd_align') . "

left|right|center (horizontal alignment)

* osd_place	(default: top)
Currently the setting is: " . Irssi::settings_get_str('osd_place') . "

top|bottom|middle (vertical alginment)

* osd_offset	(default: 100)
Currently the setting is: " . Irssi::settings_get_str('osd_offset') . "

The vertical offset from the screen edge set in osd_place.

* osd_indent	(default: 100)
Currently the setting is: " . Irssi::settings_get_str('osd_indent') . "

The horizontal offset from the screen edge set in osd_align.

* osd_shadow	(default: 0)
Currently the setting is: " . Irssi::settings_get_str('osd_shadow') . "

Set the shadow offset, if the offset is 0, the shadow is disabled.

* osd_delay	(default: 4)
Currently the setting is: " . Irssi::settings_get_str('osd_delay') . "

How many seconds should the message remain on screen.

* osd_age	(default: 4)
Currently the setting is: " . Irssi::settings_get_str('osd_age') . "

Time in seconds before old scroll lines are discarded.

* osd_lines	(default: 5)
Currently the setting is: " . Irssi::settings_get_str('osd_lines') . "

Number of lines to display on screen at one time.

* osd_DISPLAY	(default: :0.0)
Currently the setting is: " . Irssi::settings_get_str('osd_DISPLAY') . "

On what \$DISPLAY should the osd connect. (this makes tunneling possible)

* osd_showactivechannel	(default: yes)
Currently the setting is: " . Irssi::settings_get_str('osd_showactivechannel') . "

When set to yes, OSD will be triggered even if the channel is the active channel.
When set to yes, OSD will be triggered if you send a message from your own nick.

* osd_highlight (default: <blank>)
Currently the setting is: " . Irssi::settings_get_str('osd_highlight') . "
A list of alternate terms on which to highlight and trigger OSD.  Separate them with pipes.

* osd_ignore	(default: <blank>)
Currently the setting is: " . Irssi::settings_get_str('osd_ignore') . "
A list of nicks (separated by whitespace) to which you do not want this script to respond.

* osd_song	(default: <blank>)
Currently the setting is: " . Irssi::settings_get_str('osd_song') . "
If set to a path to an mp3 file, OSD will play that file when it is triggered.

* osd_song_start	(default: 0)
Currently the setting is: " . Irssi::settings_get_str('osd_song_start') . "
Set to the frame at which you want mpg321 to start playing when OSD is triggered.  This option is useful for playing just a snippet of a longer song.

* osd_song_stop	(default: 0)
Currently the setting is: " . Irssi::settings_get_str('osd_song_stop') . "
Set to the frame at which you want mpg321 to stop playing when OSD is triggered.  This option is useful for playing just a snippet of a longer song.

You can test the OSD settings with the 'osd_test' command!
Do 'osd_test' to test them.

If you don't want to use mpg321, you can edit the script to use a different executable, but it might not work, and the osd_song_start and osd_song_stop options should then be set to 0.

",
);

	if ( $about =~ /(osd_reload|osd_test|osd)/i ) { 
		Irssi::print($myHELP{lc($1)});
	} 
}

#--------------------------------------------------------------------
# Irssi::Settings
#--------------------------------------------------------------------

Irssi::settings_add_str('OSD', 'osd_color', "blue");

#These fonts are available when you installed the microsoft font pack :-)
#Irssi::settings_add_str('OSD', 'osd_font', "-microsoft-tahoma-bold-r-normal-\*-\*-320-\*-\*-p-\*-\*-\*");
#Irssi::settings_add_str('OSD', 'osd_font', "-microsoft-verdana-bold-r-normal-\*-\*-320-\*-\*-p-\*-\*-\*");
#This font is available on every linux install with the adobe fonts. 
Irssi::settings_add_str('OSD', 'osd_font', "-*-*-medium-r-\*-\*-\*-320-\*-\*-\*-\*-\*-\*");

Irssi::settings_add_str('OSD', 'osd_age', "4");
Irssi::settings_add_str('OSD', 'osd_align', "right");
Irssi::settings_add_str('OSD', 'osd_delay', "4");
Irssi::settings_add_str('OSD', 'osd_indent', "100");
Irssi::settings_add_str('OSD', 'osd_lines', "5");
Irssi::settings_add_str('OSD', 'osd_offset', "100");
Irssi::settings_add_str('OSD', 'osd_place', "top");
Irssi::settings_add_str('OSD', 'osd_shadow', "0");
Irssi::settings_add_str('OSD', 'osd_DISPLAY', ":0.0");
Irssi::settings_add_str('OSD', 'osd_showactivechannel', "yes");
Irssi::settings_add_str('OSD', 'osd_highlight', "");
Irssi::settings_add_str('OSD', 'osd_ignore', "");
Irssi::settings_add_str('OSD', 'osd_song', "");
Irssi::settings_add_str('OSD', 'osd_song_start', "0");
Irssi::settings_add_str('OSD', 'osd_song_stop', "0");
Irssi::settings_add_str('OSD', 'osd_song_timeout', "10");

#--------------------------------------------------------------------
# initialize the pipe, test it.
#--------------------------------------------------------------------

sub init {
	pipe_open();
	osdprint("OSD Loaded.");

  ## Make sure mpg321 is there if we need it.
  ## Set $song_command to '' if the test fails.
  if (Irssi::settings_get_str('osd_song')) {
    my $original_command = $song_command;
    #$song_command = `which $song_command`;
    chomp $song_command;

    if ($song_command) {
      `$song_command --version 2>/dev/null &` or
        print "Testing '$song_command' failed.  ".
          "Is '$song_command' installed, executable, and in your path?";
    } else {
      print "Testing '$original_command' failed.  ".
          "Check that '$original_command' is installed, and in your path.";
    }
  }
}

#--------------------------------------------------------------------
# open the OSD pipe
#--------------------------------------------------------------------

sub pipe_open {
	my $place;		
	my $version;
	my $command;

	$version = `osd_cat -h 2>&1` or die("The OSD program can't be started, check if you have osd_cat installed AND in your path.");
	$version =~ /Version:\s*(.*)\s*/;
	$version = $1;
	#Irssi::print "Version: $version";

	if ( $version =~ /^2.*/ ) { 
		# the --pos argument seems to be broken on 2.0.X
		if ( Irssi::settings_get_str('osd_place') eq "top" ) { 
			$place = "-p top"; 
		} elsif ( Irssi::settings_get_str('osd_place') eq "bottom") { 
			$place = "-p bottom"; 
		} else { 
			$place = "-p middle"; 
		}
	} else {
		if ( Irssi::settings_get_str('osd_place') eq "top" ) { 
			$place = "--top"; 
		} else { 
			$place = "--bottom"; 
		}
	}
	
	$command = "|DISPLAY=".Irssi::settings_get_str('osd_display') .
		" osd_cat $place " .
		" --color=".Irssi::settings_get_str('osd_color').
		" --delay=".Irssi::settings_get_str('osd_delay').
		" --age=".Irssi::settings_get_str('osd_age').
		" --font=".quotemeta(Irssi::settings_get_str('osd_font')).
		" --offset=".Irssi::settings_get_str('osd_offset').
		" --shadow=".Irssi::settings_get_str('osd_shadow'). 
		" --lines=".Irssi::settings_get_str('osd_lines').
		" --align=".Irssi::settings_get_str('osd_align');

	if ( $version =~ /^2.*/ ) {
		$command .= " --indent=".Irssi::settings_get_str('osd_indent');
	}
	open( OSDPIPE, $command ) 
		or print "The OSD program can't be started, check if you have osd_cat installed AND in your path.";
	OSDPIPE->autoflush(1);
}

#--------------------------------------------------------------------
# Private message parsing
#--------------------------------------------------------------------

sub priv_msg {
	my ($server,$msg,$nick,$address,$target) = @_;
	if ((Irssi::settings_get_str('osd_showactivechannel') =~ /yes/) or
      not (Irssi::active_win()->get_active_name() eq "$nick") ) {
      return if &ignore($nick);
      osdprint($server->{chatnet}.":$nick");
      &songplay;
    }
}

#--------------------------------------------------------------------
# Public message parsing
#--------------------------------------------------------------------

sub pub_msg {
	my ($server,$msg,$nick,$address, $channel) = @_;
	my $show;

	if (Irssi::settings_get_str('osd_showactivechannel') =~ /yes/) {
		$show = 1;
	} elsif(uc(Irssi::active_win()->get_active_name()) eq uc($channel)) {
		$show = 0;
	}

	if ($show) {
		my $onick= quotemeta "$server->{nick}";
    my $match = $onick;
    my $highlight = Irssi::settings_get_str('highlight');
    $highlight and $match .= '|'.$highlight;
		#my $pat ='(\:|\,|\s)'; # option...
		#if($msg =~ /^$onick\s*$pat/i){
    if ($msg =~ /$match/i) {
      return if &ignore($nick);
      osdprint("$channel".":$nick".":$msg");
      osdprint($match);
      &songplay;
    }
	}
}

#--------------------------------------------------------------------
# Ignore
#--------------------------------------------------------------------

sub ignore {
  my $nick=shift;
  return Irssi::settings_get_str('osd_ignore') =~ /\b$nick\b/;
}

#--------------------------------------------------------------------
# Play MP3 Snippet
#--------------------------------------------------------------------

sub songplay {
  &playsong(Irssi::settings_get_str('osd_song'),
            Irssi::settings_get_str('osd_song_start'),
            Irssi::settings_get_str('osd_song_stop'));
}

sub playsong {
  my ($song, $start, $end) = @_;

  ## Don't play song too often.  It's annoying.
  #Irssi::print($last_song_time);
  time - $last_song_time > 5 or return;
  $last_song_time = time;

  ## Did $song_command pass the init tests?
  $song_command or return;

  ## Make sure song exists.
  my $test_song = $song;
  $test_song =~ s/\\//g;
  -e $test_song or (Irssi::print("Couldn't find $song") and return);

  ## Start and end of snippet
  $start = ($start ? "-k$start" : '');
  $end = ($end ? "-n$end" : '');

  ## We've done all the checks we can.  Play or quietly fail.
  $song and system("$song_command $start $end $song 2> /dev/null &");
  Irssi::print("$song_command $start $end $song 2> /dev/null &");
}

#--------------------------------------------------------------------
# The actual printing
#--------------------------------------------------------------------

sub osdprint {
  my ($text) = @_;
  if (not (OSDPIPE->opened())) {pipe_open();}
  print OSDPIPE "$text\n";
  OSDPIPE->flush();
}

#--------------------------------------------------------------------
# A test command.
#--------------------------------------------------------------------

sub cmd_osd_test {
  osdprint("Testing OSD");
  &songplay;
}

#--------------------------------------------------------------------
# A command to close and reopen OSDPIPE
#  so options take effect without needing to unload/reload the script
#--------------------------------------------------------------------

sub cmd_osd_reload {
	close(OSDPIPE);
	pipe_open();
	osdprint("Reloaded OSD");
}

#--------------------------------------------------------------------
# Irssi::signal_add_last / Irssi::command_bind
#--------------------------------------------------------------------

Irssi::signal_add_last("message public", "pub_msg");
Irssi::signal_add_last("message private", "priv_msg");

Irssi::command_bind("osd_reload","cmd_osd_reload", "OSD");
Irssi::command_bind("osd_test","cmd_osd_test", "OSD");
Irssi::command_bind("help","cmd_help", "Irssi commands");

#--------------------------------------------------------------------
# The command that's executed at load time.
#--------------------------------------------------------------------

init();

#--------------------------------------------------------------------
# This text is printed at Load time.
#--------------------------------------------------------------------

Irssi::print("Use /help osd for more information."); 


#- end
