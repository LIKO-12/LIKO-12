/**
 * A one time use notifier.
 */
export class Notification {
    private resolver?: () => void;

    /**
     * A promise resolved when the notifier is triggered.
     */
    readonly promise = new Promise<void>((resolve) => this.resolver = resolve);

    /**
     * Only effective the first call.
     */
    trigger(): void {
        this.resolver?.();
        this.resolver = undefined;
    }

    /**
     * 
     */
    get triggered() { return this.resolver === undefined }
}