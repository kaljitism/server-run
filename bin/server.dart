import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

int _counterValue = 0;
final _clients = <WebSocketChannel>[];

// Configure routes.
final _router = Router()
  ..get('/', _rootHandler)
  ..get('/echo/<message>', _echoHandler)
  ..get('/ws', webSocketHandler(_webSocketHandler));

Response _rootHandler(Request req) {
  return Response.ok('Hello, World!\n');
}

Response _echoHandler(Request request) {
  // Echo Handler is something
  final message = request.params['message'];
  return Response.ok('$message\n');
}

void _webSocketHandler(WebSocketChannel webSocket) {
  _clients.add(webSocket);
  stdout.writeln("[CONNECTED]: $webSocket");
  webSocket.sink.add(_counterValue.toString());

  webSocket.stream.listen((dynamic message) {
    stdout.writeln("[RECEIVED]: $message");
    if (message == 'increment') {
      _counterValue++;
      for (final client in _clients) {
        client.sink.add(_counterValue.toString());
      }
    }
  }, onDone: () {
    _clients.remove(webSocket);
    stdout.writeln('[DONE]: $webSocket');
  }, onError: (error) {
    stdout.writeln('[ERROR]: ${error.toString()}');
  });
}

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final handler =
      Pipeline().addMiddleware(logRequests()).addHandler(_router.call);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
