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

        const testingFrame = new DataFrame(true, false, false, false, 1, undefined, 'Hello from Server!');
        await this.sendRawData(testingFrame.encode());

        this.client.close();
    }

    readRawData(count: number): Promise<string> {
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

    sendRawData(data: string): Promise<void> {
        let lastByteSent = 0;
        return new Promise((resolve, reject) => {
            addJob(() => {
                const [bytesSent, err, fragmentSent] = this.client.send(data, lastByteSent + 1);
                if (err === 'timeout') {
                    lastByteSent = fragmentSent;
                    return false;
                }

                if (bytesSent === undefined) reject(err);
                else if (bytesSent !== data.length) reject('bytes count did not match!');
                else resolve();

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