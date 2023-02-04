import { DataFrame } from './dataframe';
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

    readBytes(count: number): string {
        const [bytes, err] = this.client.receive(count);
        if (bytes === undefined) throw err;
        if (bytes.length !== count) throw "received content doesn't match the requested length";
        return bytes;
    }

    receive() {
        const frame = DataFrame.receiveFrame(this);
        
        print('Received a frame!');
        print('fin', frame.fin, 'rsv1', frame.rsv1, 'rsv2', frame.rsv2, 'rsv3', frame.rsv3);
        print('opcode', frame.opcode);
        if (frame.maskingKey !== undefined) print('masking key', ...frame.maskingKey);
        print('payload', frame.payload);
    }
}