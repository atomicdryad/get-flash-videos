# Part of get-flash-videos. See get_flash_videos for copyright.
package FlashVideo::Site::Nationalgeographic;

use strict;
use URI;
use FlashVideo::Utils;
use Data::Dumper;

sub find_video {
  my ($self, $browser, $embed_url) = @_;

  my $url;my $title;my $iter=0;
    while ( $iter++ < 3 && ($browser->response->code =~ /^30[12]/) && ( $browser->response->header("Location") =~ /^(.+)$/ ) ) {
      print STDERR "  Redirect $embed_url -> $1\n";
      $embed_url=$1;
      $browser->get($embed_url);
    }
#response->code; response->header("Content-type")

#$Dumper($browser);
  my (%hash) = $browser->content =~ m,data-options *= *'{(.+?"slug".+?)}', && $1 =~ m,"(.+?)": ?"(.+?)",g;
  debug Dumper(\%hash)."\n";
  if($hash{slug} ne "") {
    $url=$hash{slug};
  } elsif ($browser->content=~ m,"(https?://.+?\.(?:flv|mp4|mov|avi))",mi) {
    $url = $1;
    print STDERR "Could not get video url from JSON, found with regex\n"
  } elsif ($browser->content=~ m,slug : "http://.+?(/video/player/data/xml/.+\.smil)",mi) {
    my $smil= "http://".URI->new($embed_url)->host.$1;
    print STDERR "Found smil: $smil\n";
    ($title) = $browser->content =~ m,(?:<meta.+?og:title.+?content="(.+?)(?: \|.+)?"),si;
    $browser->get($smil);
    my ($base)=$browser->content =~ m,<meta.+?base.*?=["'](https?://.+?)["'],si;
    my ($vid)=$browser->content =~ m,<video.+?src=["'](.+?)["'],si;
    if(!$base || ! $vid) {
      die "Bad smil: $smil\n".$browser->content."\n$base $vid\n";
    }
    $url=$base.'/'.$vid;
  } else {
    die "Unable to extract the video url\n".$browser->content;;
  }
  ($title)=$hash{title} ||
    $browser->content =~ m,(?:<meta.+?og:title.+?content="(.+?)(?: \|.+)?"),si ||
    $url =~ m,/([^/]+)$,
  if(!$title);
  print STDERR "\t  URL: $url\n\tTITLE: $title\n\t SIZE: unknown (Not really 2GB)\n";
  return $url, title_to_filename($title);
}

sub can_handle {
  my($self, $browser, $url) = @_;
  return 0; # Akamai is evil http://forum.xbmc.org/showthread.php?tid=137245
  return $url =~ m,://(channel|video)\.nationalgeographic\.com/,;
}
1;
