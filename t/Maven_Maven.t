use strict;
use warnings;

use Test::More;

BEGIN { use_ok('Maven::Maven') }

use Data::Dumper;
use File::Basename;
use File::Spec;

#use Log::Any::Adapter;
#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init( $DEBUG );
#Log::Any::Adapter->set('Log::Log4perl');
#my $logger = Log::Log4perl->get_logger( "Maven_Maven.t" );
#$logger->info( 'logging for Maven_Maven.t' );

my $test_dir = dirname( File::Spec->rel2abs( $0 ) );
my $maven;

$maven = Maven::Maven->new( 
    M2_HOME => File::Spec->catdir( $test_dir, 'M2_HOME' ),
    'user.home' => File::Spec->catdir( $test_dir, 'HOME' ) );

my @active_profiles = map {$_->get_id()} @{$maven->{active_profiles}};
is_deeply( \@active_profiles,
    ['userSettings','globalActiveProfile'],
    'active profiles' );
    
my $user_home = $maven->get_property( 'user.home' );
my $local_repo_url = "file://$user_home/.m2/repository";
my $maven_central_url = 'http://repo.maven.apache.org/maven2';
my @repositories = map {$_->get_url()} @{$maven->get_repositories()->{repositories}};
is_deeply( \@repositories,
    [
        $local_repo_url,
        'http://maven.pastdev.com/nexus/groups/pastdev',
        'http://repo.maven.apache.org/maven2'
    ],
    'repositories' );
    
my $foo_pom = $maven->get_repositories()->resolve( 'com.pastdev:foo:pom:1.0.1' );
is( $foo_pom->get_url(), "$local_repo_url/com/pastdev/foo/1.0.1/foo-1.0.1.pom",
    'resolve foo pom' );
    
SKIP: {
    eval { require LWP::UserAgent };

    skip "LWP::UserAgent not installed", 2 if $@;

    my $agent = LWP::UserAgent->new();
    $agent->timeout( 1 );
    $agent->env_proxy();
    if ( $agent->head( $maven_central_url )->is_success() ) {
        my $jta_jar = $maven->get_repositories()->resolve( 'javax.transaction:jta:1.1' );
        ok( $jta_jar, 'resolve jta jar' );
        is( $jta_jar && $jta_jar->get_url(), "$maven_central_url/javax/transaction/jta/1.1/jta-1.1.jar",
            'jta jar url' );

        $jta_jar = $maven->get_repositories()->resolve( 'javax.transaction:jta:9.9.9' );
        ok( !$jta_jar, 'resolve invalid jta jar' );
    }
};

$maven = Maven::Maven->new( 
    M2_HOME => File::Spec->catdir( $test_dir, 'no_active_profiles/M2_HOME' ),
    'user.home' => File::Spec->catdir( $test_dir, 'no_active_profiles/HOME' ) );

done_testing();
