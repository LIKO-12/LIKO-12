import {
    createJSONRPCErrorResponse,
    createJSONRPCRequest,
    createJSONRPCNotification,
    JSONRPCErrorException,
    JSONRPCID,
    JSONRPCParams,
    JSONRPCRequest,
    JSONRPCResponse,
} from "./models";
import { DefaultErrorCode } from "./internal";

export type SendRequest<ClientParams> = (
    payload: any,
    clientParams: ClientParams
) => PromiseLike<void>;
export type CreateID = () => JSONRPCID;

type Resolve = (response: JSONRPCResponse) => void;

type IDToDeferredMap = Map<JSONRPCID, Resolve>;

export interface JSONRPCRequester<ClientParams> {
    request(
        method: string,
        params?: JSONRPCParams,
        clientParams?: ClientParams
    ): PromiseLike<any>;
    requestAdvanced(
        request: JSONRPCRequest,
        clientParams?: ClientParams
    ): PromiseLike<JSONRPCResponse>;
    requestAdvanced(
        request: JSONRPCRequest[],
        clientParams?: ClientParams
    ): PromiseLike<JSONRPCResponse[]>;
}

export class JSONRPCClient<ClientParams = void>
    implements JSONRPCRequester<ClientParams>
{
    private idToResolveMap: IDToDeferredMap;
    private id: number;

    constructor(
        private _send: SendRequest<ClientParams>,
        private createID?: CreateID
    ) {
        this.idToResolveMap = new Map();
        this.id = 0;
    }

    private _createID(): JSONRPCID {
        if (this.createID) {
            return this.createID();
        } else {
            return ++this.id;
        }
    }

    request(
        method: string,
        params: JSONRPCParams,
        clientParams: ClientParams
    ): PromiseLike<any> {
        return this.requestWithID(method, params, clientParams, this._createID());
    }

    private async requestWithID(
        method: string,
        params: JSONRPCParams | undefined,
        clientParams: ClientParams,
        id: JSONRPCID
    ): Promise<any> {
        const request: JSONRPCRequest = createJSONRPCRequest(id, method, params);

        const response: JSONRPCResponse = await this.requestAdvanced(
            request,
            clientParams
        );
        if (response.result !== undefined && !response.error) {
            return response.result;
        } else if (response.result === undefined && response.error) {
            return Promise.reject(
                new JSONRPCErrorException(
                    response.error.message,
                    response.error.code,
                    response.error.data
                )
            );
        } else {
            return Promise.reject(new Error("An unexpected error occurred"));
        }
    }

    requestAdvanced(
        request: JSONRPCRequest,
        clientParams: ClientParams
    ): PromiseLike<JSONRPCResponse>;
    requestAdvanced(
        request: JSONRPCRequest[],
        clientParams: ClientParams
    ): PromiseLike<JSONRPCResponse[]>;
    requestAdvanced(
        requests: JSONRPCRequest | JSONRPCRequest[],
        clientParams: ClientParams
    ): PromiseLike<JSONRPCResponse | JSONRPCResponse[]> {
        const areRequestsOriginallyArray = Array.isArray(requests);
        if (!Array.isArray(requests)) {
            requests = [requests];
        }

        const requestsWithID: JSONRPCRequest[] = requests.filter((request) =>
            isDefinedAndNonNull(request.id)
        );

        const promises: PromiseLike<JSONRPCResponse>[] = requestsWithID.map(
            (request) =>
                new Promise((resolve) => this.idToResolveMap.set(request.id!, resolve))
        );

        const promise: PromiseLike<JSONRPCResponse | JSONRPCResponse[]> =
            Promise.all(promises).then((responses: JSONRPCResponse[]) => {
                if (areRequestsOriginallyArray || !responses.length) {
                    return responses;
                } else {
                    return responses[0];
                }
            });

        return this.send(
            areRequestsOriginallyArray ? requests : requests[0],
            clientParams
        ).then(
            () => promise,
            (error) => {
                requestsWithID.forEach((request) => {
                    this.receive(
                        createJSONRPCErrorResponse(
                            request.id!,
                            DefaultErrorCode,
                            (error && error.message) || "Failed to send a request"
                        )
                    );
                });
                return promise;
            }
        );
    }

    notify(
        method: string,
        params: JSONRPCParams,
        clientParams: ClientParams
    ): void {
        const request: JSONRPCRequest = createJSONRPCNotification(method, params);

        this.send(request, clientParams).then(undefined, () => undefined);
    }

    send(payload: any, clientParams: ClientParams): PromiseLike<void> {
        return this._send(payload, clientParams);
    }

    rejectAllPendingRequests(message: string): void {
        this.idToResolveMap.forEach((resolve: Resolve, id: JSONRPCID) =>
            resolve(createJSONRPCErrorResponse(id, DefaultErrorCode, message))
        );
        this.idToResolveMap.clear();
    }

    receive(responses: JSONRPCResponse | JSONRPCResponse[]): void {
        if (!Array.isArray(responses)) {
            responses = [responses];
        }

        responses.forEach((response) => {
            const resolve = this.idToResolveMap.get(response.id);
            if (resolve) {
                this.idToResolveMap.delete(response.id);
                resolve(response);
            }
        });
    }
}

function isDefinedAndNonNull<T>(this: unknown, value: T | null | undefined): value is T {
    return value !== undefined && value !== null;
}
