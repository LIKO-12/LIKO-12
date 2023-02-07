import { addJob } from './async-jobs-worker';
import { DataFrame } from './dataframe';
import { WebSocketHandshake } from './handshake';

export enum WebSocketStatus {
    Initializing,
    Ready,
    Closed,
}

export class WebSocketConnection {
    private handshake: WebSocketHandshake | undefined;
    private dead = false;

    get state(): WebSocketStatus {
        if (this.dead) return WebSocketStatus.Closed;
        if (this.handshake) return WebSocketStatus.Ready;
        return WebSocketStatus.Initializing;
    }

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

    private ongoingRawReceive = false;

    receiveRawData(count: number): Promise<string> {
        if (this.state !== WebSocketStatus.Ready) throw 'The connection is not ready!';

        if (this.ongoingRawReceive) throw 'The connection is busy with another receive operation.';
        this.ongoingRawReceive = true;

        return new Promise((resolve, reject) => {
            addJob(() => {
                const [bytes, err] = this.client.receive(count);
                if (err === 'timeout') return false;
                
                this.ongoingRawReceive = false;

                if (bytes === undefined) reject(err);
                else if (bytes.length !== count) reject("received content doesn't match the requested length");
                else resolve(bytes);

                return true;
            });
        });
    }

    private ongoingRawSend = false;

    sendRawData(data: string): Promise<void> {
        if (this.state !== WebSocketStatus.Ready) throw 'The connection is busy with another send operation.';

        if (this.ongoingRawSend) throw 'The connection is busy with another send operation.';
        this.ongoingRawSend = true;

        let lastByteSent = 0;
        return new Promise((resolve, reject) => {
            addJob(() => {
                const [bytesSent, err, fragmentSent] = this.client.send(data, lastByteSent + 1);
                if (err === 'timeout') {
                    lastByteSent = fragmentSent;
                    return false;
                }

                this.ongoingRawSend  = false;

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