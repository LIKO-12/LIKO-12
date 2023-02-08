import { Queue } from 'core/queue';
import { addJob } from './async-jobs-worker';
import { DataFrame, OpCode } from './dataframe';
import { WebSocketHandshake } from './handshake';
import { Notification } from './notifier';

export enum WebSocketStatus {
    Initializing,
    Ready,
    Closed,
}

// TODO: Buffer the fragments received frames and join them.
// TODO: Create an events system.
// TODO: Handle connection close triggered by client.
// TODO: Implement clean close triggered by server.
// TODO: Gracefully close the server.
// TODO: Implement automatic pong for any ping.
// TODO: Implement a heartbeat to check the client and auto-close a zombie connection.
// TODO: Clean close the connection with proper code when a failure happens.
// TODO: Add configuration for the default fragmentation of sent messages.
// TODO: Handle unknown frames (possibly close the connection).

// NOTE: Control frames can't be fragmented (as mentioned in the specification).

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
    
    //#region I/O Loops

    private sendNotification?: Notification;

    private controlFramesSendQueue = new Queue<DataFrame>();
    private dataFramesSendQueue = new Queue<DataFrame>();

    private async run() {
        this.handshake = await WebSocketHandshake.perform(this.client);

        this.runReceiverLoop().catch(error);
        this.runSenderLoop().catch(error);
    }

    private async runReceiverLoop() {
        let fragmentsBuffer: DataFrame[] = [];

        while (true) {
            const frame = await DataFrame.parse((length) => this.receiveRawData(length));;

            if (frame.isControl) {
                if (!frame.fin) throw "invalid frame. control frames can't be fragmented.";
                this.processControlFrame(frame);

            } else {
                if (fragmentsBuffer.length === 0 && frame.fin) {
                    // consume the non-fragmented frame.
                    this.processDataFrame(frame.opcode, frame.payload);
                    
                } else {
                    if (fragmentsBuffer.length === 0 && frame.opcode === OpCode.Continuation) throw 'invalid frame.';
                    else if (fragmentsBuffer.length !== 0 && frame.opcode !== OpCode.Continuation) throw 'invalid frame.';

                    fragmentsBuffer.push(frame);

                    // The end of the fragmented message.
                    if (frame.fin) {
                        this.processDataFrame(
                            fragmentsBuffer[0].opcode,
                            fragmentsBuffer.map(frame => frame.payload).join(''),
                        );

                        fragmentsBuffer = [];
                    }
                }
            }
        }
    }

    private async runSenderLoop() {
        while (true) {
            while (!this.controlFramesSendQueue.isEmpty() || !this.dataFramesSendQueue.isEmpty()) {
                const controlFrame = this.controlFramesSendQueue.pop();
                if (controlFrame !== undefined) await this.sendRawData(controlFrame.encode());

                const dataFrame = this.dataFramesSendQueue.pop();
                if (dataFrame !== undefined) await this.sendRawData(dataFrame.encode());
            }

            const notification = new Notification();
            this.sendNotification = notification;
            await notification.promise;
        }
    }

    //#endregion

    /**
     * Process a received control frame.
     */
    private processControlFrame(frame: DataFrame): void {
        if (frame.opcode === OpCode.Ping) {
            // TODO: Send the response.
        }

        if (frame.opcode === OpCode.Pong) {
            // TODO: Reset the termination timer.
        }

        if (frame.opcode === OpCode.Close) {
            // TODO: Clean close the connection.
        }
    }

    /**
     * Process a received data frame.
     * 
     * The frame object is not passed here because a message can be fragmented over multiple frames.
     * And for simplicity that detail has been abstracted out and thus this method should handle the general case. 
     */
    private processDataFrame(opcode: OpCode, content: string): void {
        if (opcode === OpCode.Text) print(`Received text message of ${content.length} characters.`);
        if (opcode === OpCode.Binary) print(`Received binary message of ${content.length} bytes.`);
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

}