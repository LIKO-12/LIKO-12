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
     * Can be only used once then the notifier has to be replaced.
     */
    trigger(): void {
        const resolver = this.resolver;
        this.resolver = undefined;

        if (!resolver) throw 'already notified.';
        resolver();
    }

    /**
     * 
     */
    get triggered() { return this.resolver === undefined }
}