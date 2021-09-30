package Skel;

use Mojo::Base 'Mojolicious';

sub startup {
    my $s = shift;
    $s->secrets( ['I love Mojolicious'] );
}

package main;
use Test::More;
use Mojo::Base -strict;
use Test::Mojo;
use Mojo::WebSocket::PubSub::Syntax;

my $t   = Test::Mojo->new('Skel');
my $syn = new Mojo::WebSocket::PubSub::Syntax;

my $app = $t->app;
my $r   = $app->routes;

$app->plugin('Mojolicious::Plugin::PubSub::WebSocket');

use DDP;

sub j {
    return { json => shift };
}

subtest 'keepalive' => sub {
    $t->websocket_ok('/psws')->send_ok( j $syn->keepalive )
      ->finish_ok->finished_ok(1005);
};

subtest 'ping' => sub {
    my $ping = $syn->ping;
    my $cts  = $ping->{cts};
    $t->websocket_ok('/psws')->send_ok( j $ping)->message_ok('got reply')
      ->json_message_is( '/t'   => 'o',  'Correct reply type' )
      ->json_message_is( '/cts' => $cts, 'Correct time in reply' )
      ->finish_ok->finished_ok(1005);
};

subtest 'join channel' => sub {
    my $ch = 'channel1';
    $t->websocket_ok('/psws')->send_ok( j $syn->listen($ch) )
      ->message_ok('got reply')
      ->json_message_is( '/t'  => 'd', 'Correct reply type' )
      ->json_message_is( '/ch' => $ch, 'Correct channel in reply' )
      ->finish_ok->finished_ok(1005);
};

subtest 'channel com' => sub {
    my $ch   = 'channel1';
    my $smsg = j $syn->listen($ch);
    my $w1   = $t->websocket_ok('/psws')->send_ok($smsg)
      ->message_ok('First client subscribe to channel');
    my $w2 = $t->websocket_ok('/psws')->send_ok($smsg)
      ->message_ok('Second client subscribe to channel');

    my $msg = 'Hello World';
    $w1->send_ok( j $syn->notify($msg) );
    $w2->message_ok('Got channel message')
      ->json_message_is( '/msg' => $msg, 'Correct message' );

    $_->finish_ok->finished_ok(1005) foreach ( $w1, $w2 );
};

subtest 'multiple subscribers' => sub {
    my $ch   = 'channel1';
    my $smsg = j $syn->listen($ch);
    my @s;
    my $i = 0;
    push @s,
      $t->websocket_ok('/psws')->send_ok($smsg)
      ->message_ok( "Subscriber n. " . $i++ . " enter to channel" )
      for ( 1 .. 10 );

    my $notifier = shift @s;

    my $msg = 'Hello World';

    my $p = Mojo::Promise->new(
        sub {
            my $r = shift;
            $s[1]->message_ok("Subscriber msg rcvd");
        }
    );


    # Mojo::Promise->new->resolve->then(
    #     sub {
    #         $notifier->send_ok( j $syn->notify($msg), "Subscriber 1 msg ok" );
    #     }
    # )->catch( sub { } );
    # Mojo::IOLoop->timer(2 =>  sub {
    #          $notifier->send_ok( j $syn->notify($msg), "Subscriber 1 msg ok" );
    #      });
    # say "Is running: " . Mojo::IOLoop->is_running;
    # my @ps;
    # @ps = map{ Mojo::Promise->new(
    #     sub {
    #         my $r = shift;
    #         $_->message_ok("Subscriber msg rcvd");
    #         $r->();
    #     }
    # )}  @s;
    # push @ps, Mojo::Promise->new->resolve->then( sub {
    #          $notifier->send_ok( j $syn->notify($msg), "Subscriber 1 msg ok" );
    #      });
    # push @ps, Mojo::Promise->new(sub {});
    # use DDP;
    # p @ps;
    # my $p = Mojo::Promise->all(@ps)->wait;

    # my $p = Mojo::Promise->map(
    #     { concurrency => 0 },
    #     sub {
    #         Mojo::Promise->new(
    #             sub {
    #                 my $r = shift;
    #                 $_->message_ok("Subscriber msg rcvd");
    #                 $r->();
    #             }
    #         );
    #     },
    #     @s
    # );

};

# $t->get_ok("/version")->status_is(200)->json_is( '/class' => $package )
#   ->json_is( '/version' => $version );

done_testing();
