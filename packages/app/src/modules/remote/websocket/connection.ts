import { Queue } from 'core/queue';
import { addJob } from './async-jobs-worker';
import { DataFrame } from './dataframe';
import { WebSocketHandshake } from './handshake';
import { Notification } from './notifier';

export enum WebSocketStatus {
    Initializing,
    Ready,
    Closed,
}

// TODO: Auto-close connection on quit event.
// TODO: Send proper close codes when failure happens.
// FIXME: Handle the received close frames.

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
        this.run().catch(error);
    }

    private sendNotification?: Notification;

    private controlFramesSendQueue = new Queue<DataFrame>();
    private dataFramesSendQueue = new Queue<DataFrame>();

    private async run() {
        this.handshake = await WebSocketHandshake.perform(this.client);

        this.runReceiverLoop().catch(error);
        this.runSenderLoop().catch(error);

        this.dataFramesSendQueue.push(DataFrame.createTextFrame('Hello from server!'));
        this.dataFramesSendQueue.push(DataFrame.createTextFrame('Hello from server2!'));
        DataFrame.createBinaryFrames('Fragmented Data', 5).forEach((frame) =>
            this.dataFramesSendQueue.push(frame));
        
        this.controlFramesSendQueue.push(DataFrame.createPingFrame('Ping!'));

        this.sendNotification?.trigger();
    }

    private async runReceiverLoop() {
        while (true) {
            const frame = await this.receiveFrame();
            print('Received:', frame.payload);
        }
    }

    private async runSenderLoop() {
        while (true) {
            while (!this.controlFramesSendQueue.isEmpty() || !this.dataFramesSendQueue.isEmpty()) {
                const controlFrame = this.controlFramesSendQueue.pop();
                if (controlFrame !== undefined) await this.sendFrame(controlFrame);

                const dataFrame = this.dataFramesSendQueue.pop();
                if (dataFrame !== undefined) await this.sendFrame(dataFrame);
            }

            const notification = new Notification();
            this.sendNotification = notification;
            await notification.promise;
        }
    }

    //#region Raw I/O

    private ongoingRawReceive = false;

    private receiveRawData(count: number): Promise<string> {
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

    private sendRawData(data: string): Promise<void> {
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

                this.ongoingRawSend = false;

                if (bytesSent === undefined) reject(err);
                else if (bytesSent !== data.length) reject('bytes count did not match!');
                else resolve();

                return true;
            });
        });
    }

    //#endregion

    private receiveFrame(): Promise<DataFrame> {
        return DataFrame.parse((length) => this.receiveRawData(length));
    }

    private sendFrame(frame: DataFrame): Promise<void> {
        return this.sendRawData(frame.encode());
    }
}