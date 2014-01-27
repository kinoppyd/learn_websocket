#!/usr/bin/env perl
use Mojolicious::Lite;

# Documentation browser under "/perldoc"
plugin 'PODRenderer';

get '/' => sub {
  my $self = shift;
  $self->render('index');
};

my $clients = {};

websocket '/send' => sub {
    my $self = shift;

    my $id = sprintf "%s", $self->tx;
    $clients->{$id} = $self->tx;

    $self->on(message => sub {
            my ($self, $message) = @_;
            for my $usr (keys %$clients){
                $clients->{$usr}->send(
                    Mojo::JSON->new->encode({
                            message=>$message
                        })
                );
            }
        });

    $self->on(finished => sub{
            delete $clients->{$id};
        }
    );
};

app->start;
__DATA__

@@ index.html.ep
% layout 'default';
% title 'Welcome';
<p><input type="text" id="message" /></p>
<div id="container">
    <div class="item">item1</div>
    <div class="item">item2</div>
    <div class="item">item3</div>
</div>

@@ layouts/default.html.ep
<!DOCTYPE html>
<head>
    <%= include 'styles.css' %>
    <script src="//ajax.googleapis.com/ajax/libs/jquery/2.0.3/jquery.min.js"></script>
    <script src="//cdnjs.cloudflare.com/ajax/libs/masonry/3.1.2/masonry.pkgd.min.js"></script>
    <%= include 'script.js' %>
</head>
<html>
  <head><title><%= title %></title></head>
  <body><%= content %></body>
</html>

@@ styles.css.html.ep
%= stylesheet begin
.item {
    width: 200px;
    height: 250px;
    color: #cccccc;
    background: #888888;
    margin: 5px;
    padding: 5px;
    float: left;
}
.item.w2 { width: 400px; }
#container{
    border: 1px solid #dadada;
}
%= end

@@ script.js.html.ep
%= javascript begin
$(
        function (){

            $('#container')
            .masonry({
                itemSelector: '.item',
                isAnimated: true,
            });
            $('#message').focus();

            var $ws = new WebSocket('ws://192.168.0.7/send');
            $ws.onopen = function () {
            }
            $ws.onmessage = function (msg){
                var $res = JSON.parse(msg.data);
                var $msg = $res.message;
                $('#container')
                .prepend($('<div class="item">'+$msg+'</div>'))
                .masonry('reloadItems')
                .fadeIn()
                .masonry();
            }
            $('#message').keydown( function(e) {
                if (e.keyCode == 13 && $('#message').val() ){
                    $ws.send($('#message').val());
                    $('#message').val('');
                }
            });
        }

 );

%= end
