package main;

use Test::More;

use Mojo::Base -strict;
use Mojo::Promise;
use Mojo::WebSocket::PubSub::Syntax;

use Test::Mojo;

my $syn = new Mojo::WebSocket::PubSub::Syntax;

subtest 'keepalive' => sub {
    new Mojo::Promise(
        sub {
            my ( $r, $f ) = @_;
            $syn->on( 'keepalive' => sub { $r->() } );
            Mojo::IOLoop->timer( 5 => sub { $f->() } );
            $syn->parse( $syn->keepalive );
        }
    )->then( sub { pass('received') } )->catch( sub { fail('lost') } )->wait;
};

subtest 'ping' => sub {
    my $cts;
    new Mojo::Promise(
        sub {
            my ( $r, $f ) = @_;
            $syn->on( 'ping' => sub { $r->( $_[1] ) } );
            Mojo::IOLoop->timer( 5 => sub { $f->() } );
            my $ping = $syn->ping;
            $cts = $ping->{cts};
            $syn->parse( $syn->ping );
        }
    )->then(
        sub {
            pass('received');
            ok( exists $_[0]->{cts}, 'exists client time' );
            is( $_[0]->{cts}->[0], $cts->[0], 'correct client time' );
        }
    )->catch( sub { fail('lost') } )->wait;
};

subtest 'pong' => sub {
    my $cts;
    my $sts;
    new Mojo::Promise(
        sub {
            my ( $r, $f ) = @_;
            $syn->on( 'pong' => sub { $r->( $_[1] ) } );
            Mojo::IOLoop->timer( 5 => sub { $f->() } );
            my $ping = $syn->ping;
            $cts = $ping->{cts};
            my $pong = $syn->pong($ping);
            $sts = $pong->{sts};
            $syn->parse($pong);
        }
    )->then(
        sub {
            pass('received');
            ok( exists $_[0]->{cts}, 'exists client time' );
            is( $_[0]->{cts}->[0], $cts->[0], 'correct client time' );
            ok( exists $_[0]->{sts}, 'exists server time' );
            is( $_[0]->{sts}->[0], $sts->[0], 'correct server time' );
        }
    )->catch( sub { fail('lost') } )->wait;
};

subtest 'join' => sub {
    my $ch = 'foo';
    new Mojo::Promise(
        sub {
            my ( $r, $f ) = @_;
            $syn->on( 'join' => sub { $r->( $_[1] ) } );
            Mojo::IOLoop->timer( 5 => sub { $f->() } );
            my $join = $syn->join($ch);
            $syn->parse( $join );
        }
    )->then(
        sub {
            pass('received');
            ok( exists $_[0]->{ch}, 'exists channel' );
            is( $_[0]->{ch}, $ch, 'correct channel' );
        }
    )->catch( sub { fail('lost') } )->wait;
};

subtest 'joined' => sub {
    my $ch = 'foo';
    new Mojo::Promise(
        sub {
            my ( $r, $f ) = @_;
            $syn->on( 'joined' => sub { $r->( $_[1] ) } );
            Mojo::IOLoop->timer( 5 => sub { $f->() } );
            my $join = $syn->join($ch);
            my $joined = $syn->joined($join);
            $syn->parse($joined);
        }
    )->then(
        sub {
            pass('received');
            ok( exists $_[0]->{ch}, 'exists channel' );
            is( $_[0]->{ch}, $ch, 'correct channel' );
        }
    )->catch( sub { fail('lost') } )->wait;
};

subtest 'message client to server' => sub {
    my $msg = 'Hello World!';
    new Mojo::Promise(
        sub {
            my ( $r, $f ) = @_;
            $syn->on( 'mc2s' => sub { $r->( $_[1] ) } );
            Mojo::IOLoop->timer( 5 => sub { $f->() } );
            my $mc2s = $syn->mc2s($msg);
            $syn->parse($mc2s);
        }
    )->then(
        sub {
            pass('received');
            ok( exists $_[0]->{msg}, 'exists message' );
            is( $_[0]->{msg}, $msg, 'correct message' );
        }
    )->catch( sub { fail('lost') } )->wait;
};

subtest 'message server to brodcast' => sub {
    my $msg = 'Hello World!';
    my $from = '123456789123456789';
    new Mojo::Promise(
        sub {
            my ( $r, $f ) = @_;
            $syn->on( 'ms2b' => sub { $r->( $_[1] ) } );
            Mojo::IOLoop->timer( 5 => sub { $f->() } );
            my $mc2s = $syn->mc2s($msg);
            my $ms2b = $syn->ms2b($mc2s, $from);
            $syn->parse($ms2b);
        }
    )->then(
        sub {
            pass('received');
            ok( exists $_[0]->{msg}, 'exists message' );
            is( $_[0]->{msg}, $msg, 'correct message' );
            ok( exists $_[0]->{from}, 'exists from' );
            is( $_[0]->{from}, $from, 'correct from' );
        }
    )->catch( sub { fail('lost') } )->wait;
};

done_testing();

1;
