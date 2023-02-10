import {
    JSONRPCMethod,
    JSONRPCServer,
    JSONRPCServerMiddleware,
    SimpleJSONRPCMethod,
} from "./server";
import { JSONRPCClient, JSONRPCRequester } from "./client";
import {
    ErrorListener,
    isJSONRPCRequest,
    isJSONRPCRequests,
    isJSONRPCResponse,
    isJSONRPCResponses,
    JSONRPCParams,
    JSONRPCRequest,
    JSONRPCResponse,
} from "./models";

export interface JSONRPCServerAndClientOptions {
    errorListener?: ErrorListener;
}

export class JSONRPCServerAndClient<ServerParams = void, ClientParams = void> {
    private readonly errorListener: ErrorListener;

    constructor(
        public server: JSONRPCServer<ServerParams>,
        public client: JSONRPCClient<ClientParams>,
        options: JSONRPCServerAndClientOptions = {}
    ) {
        this.errorListener = options.errorListener ?? ((message, data) => print('JSON-RPC Error:', message, data));
    }

    applyServerMiddleware(
        ...middlewares: JSONRPCServerMiddleware<ServerParams>[]
    ): void {
        this.server.applyMiddleware(...middlewares);
    }

    hasMethod(name: string): boolean {
        return this.server.hasMethod(name);
    }

    addMethod(name: string, method: SimpleJSONRPCMethod<ServerParams>): void {
        this.server.addMethod(name, method);
    }

    addMethodAdvanced(name: string, method: JSONRPCMethod<ServerParams>): void {
        this.server.addMethodAdvanced(name, method);
    }

    request(
        method: string,
        params: JSONRPCParams,
        clientParams: ClientParams
    ): PromiseLike<any> {
        return this.client.request(method, params, clientParams);
    }

    requestAdvanced(
        jsonRPCRequest: JSONRPCRequest,
        clientParams: ClientParams
    ): PromiseLike<JSONRPCResponse>;
    requestAdvanced(
        jsonRPCRequest: JSONRPCRequest[],
        clientParams: ClientParams
    ): PromiseLike<JSONRPCResponse[]>;
    requestAdvanced(
        jsonRPCRequest: JSONRPCRequest | JSONRPCRequest[],
        clientParams: ClientParams
    ): PromiseLike<JSONRPCResponse | JSONRPCResponse[]> {
        return this.client.requestAdvanced(jsonRPCRequest as any, clientParams);
    }

    notify(
        method: string,
        params: JSONRPCParams,
        clientParams: ClientParams
    ): void {
        this.client.notify(method, params, clientParams);
    }

    rejectAllPendingRequests(message: string): void {
        this.client.rejectAllPendingRequests(message);
    }

    async receiveAndSend(
        payload: any,
        serverParams: ServerParams,
        clientParams: ClientParams
    ): Promise<void> {
        if (isJSONRPCResponse(payload) || isJSONRPCResponses(payload)) {
            this.client.receive(payload);
        } else if (isJSONRPCRequest(payload) || isJSONRPCRequests(payload)) {
            const response: JSONRPCResponse | JSONRPCResponse[] | null =
                await this.server.receive(payload, serverParams);
            if (response) {
                return this.client.send(response, clientParams);
            }
        } else {
            const message = "Received an invalid JSON-RPC message";
            this.errorListener(message, payload);
            return Promise.reject(new Error(message));
        }
    }
}
