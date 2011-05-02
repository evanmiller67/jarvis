#!/usr/bin/perl
$ENV{'PATH'}='/usr/local/bin:/usr/bin:/bin';
$ENV{'IFS'}=' \t\n';
################################################################################
# Add local libraries
BEGIN { 
        use Cwd;
        my $path=$0;
        $path=~s/\/[^\/]*$//;
        chdir($path);
        my $libdir=cwd()."/lib";
        my $cpanlib=cwd()."/cpan";
        my $libdirs= [
                       "$cpanlib/lib/perl5/site_perl/5.8.8/i386-linux-thread-multi",
                       "$cpanlib/lib/perl5/5.8.8/i386-linux-thread-multi/",
                       "$cpanlib/lib/perl5/site_perl/5.8.8/",
                       "$cpanlib/lib/perl5/5.8.8/",
                       "$libdir",
                     ];
        # add all of these to our library search path
        foreach my $dir (@{$libdirs}){ unshift @INC, $dir if -d $dir; };
      }
################################################################################
# Include our dependencies
use Data::Dumper;
use Jarvis::IRC;
use Jarvis::Jabber;
#use Jarvis::Persona::Minimal;
#use Jarvis::Persona::MegaHAL;
use Jarvis::Persona::System;
use Jarvis::Persona::Crunchy;
use Jarvis::Persona::Jarvis;
use POE::Builder;
use Sys::Hostname::Long;
use Template;
use Cwd;
################################################################################
sub daemonize {
    defined( my $pid = fork() ) or die "Can't fork: $!\n";
    exit if $pid;
    setsid or die "Can't start a new session: $!\n";
}
################################################################################
$|++;
my $path=$0; $path=~s/\/[^\/]*$//; chdir($path); my $personas=cwd()."/persona.d";
# disable jabber if we have no xmpp creds
my $enable_jabber=1;
if(!defined($ENV{'XMPP_PASSWORD'})){
    $enable_jabber=0;
    print STDERR "no XMPP_PASSWORD, disabling XMPP\n";
}

# get a handle for our builder
my $poe = new POE::Builder({ 'debug' => '0','trace' => '0' });
exit unless $poe;
################################################################################
# Template our YAML configs
my $config = { INCLUDE_PATH => [ '/etc/jarvis/personas.d', $personas ], INTERPOLATE  => 1 };
my $template = Template->new($config);
################################################################################
# get our fqd, hostname, and domain name
my $fqdn     = hostname_long;
my $hostname = $fqdn;         $hostname=~s/\..*$//;
my $domain   = $fqdn;         $domain=~s/^[^\.]*\.//;
my $vars = {
               'SECRET'        => ${ENV{'SECRET'}},
               'HOSTNAME'      => $hostname,
               'FQDN'          => $fqdn,
               'IRC_SERVER'    => '127.0.0.1',
               'DOMAIN'        => $domain,
               'XMPP_PASSWORD' => ${ENV{'XMPP_PASSWORD'}},
           };
my $yaml;
# Set up our sessions 
$template->process('system', $vars, \$yaml) || die $template->error();
my $persona = YAML::Load($yaml);
$poe->yaml_sess(YAML::Dump( $persona->{'persona'} ));
foreach my $connector (@{ $persona->{'connectors'} }){
print STDERR YAML::Dump($connector);
    $poe->yaml_sess(YAML::Dump($connector));
}
################################################################################
# fire up the kernel
POE::Kernel->run();
