import { addJob } from './async-jobs-worker';
import { DataFrame } from './dataframe';
import { WebSocketHandshake } from './handshake';

export class WebSocketConnection {
    private handshake: WebSocketHandshake | undefined;

    constructor(
        private readonly client: TCPSocket,
    ) {
        client.settimeout(0);

        print('Got a connection!');
        print('Sock info:', ...client.getsockname());
        print('Peer info:', ...client.getpeername());

        this.run().catch(error);
    }

    private async run() {
        this.handshake = await WebSocketHandshake.perform(this.client);
        await this.receive();
        this.client.close();
    }

    readBytes(count: number): Promise<string> {
        return new Promise((resolve, reject) => {
            addJob(() => {
                const [bytes, err] = this.client.receive(count);
                if (err === 'timeout') return false;

                if (bytes === undefined) reject(err);
                else if (bytes.length !== count) reject("received content doesn't match the requested length");
                else resolve(bytes);

                return true;
            });
        });
    }

    async receive() {
        const frame = await DataFrame.receiveFrame(this);

        print('Received a frame!');
        print('fin', frame.fin, 'rsv1', frame.rsv1, 'rsv2', frame.rsv2, 'rsv3', frame.rsv3);
        print('opcode', frame.opcode);
        if (frame.maskingKey !== undefined) print('masking key', ...frame.maskingKey);
        print('payload', frame.payload);
    }
}