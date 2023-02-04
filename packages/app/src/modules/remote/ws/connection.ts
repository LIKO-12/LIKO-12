import { WebSocketHandshake } from './handshake';

export class WebSocketConnection {
    private readonly handshake;

    constructor(
        private readonly client: TCPSocket,
    ) {
        print('Got a connection!');
        print('Sock info:', ...client.getsockname());
        print('Peer info:', ...client.getpeername());

        this.handshake = new WebSocketHandshake(this.client);
    }
}