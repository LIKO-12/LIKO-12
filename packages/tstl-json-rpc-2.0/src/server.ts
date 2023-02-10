import {
    JSONRPCRequest,
    JSONRPCResponse,
    JSONRPCParams,
    JSONRPCID,
    JSONRPCErrorCode,
    JSONRPCErrorException,
    createJSONRPCErrorResponse,
    createJSONRPCSuccessResponse,
    isJSONRPCRequest,
    isJSONRPCID,
    JSONRPCErrorResponse,
    JSONRPCSuccessResponse,
    ErrorListener,
} from "./models";
import { DefaultErrorCode } from "./internal";

export type SimpleJSONRPCMethod<ServerParams = void> = (
    params: JSONRPCParams,
    serverParams: ServerParams
) => any;
export type JSONRPCMethod<ServerParams = void> = (
    request: JSONRPCRequest,
    serverParams: ServerParams
) => JSONRPCResponsePromise;
export type JSONRPCResponsePromise = PromiseLike<JSONRPCResponse | null>;

export type JSONRPCServerMiddlewareNext<ServerParams> = (
    request: JSONRPCRequest,
    serverParams: ServerParams
) => JSONRPCResponsePromise;
export type JSONRPCServerMiddleware<ServerParams> = (
    next: JSONRPCServerMiddlewareNext<ServerParams>,
    request: JSONRPCRequest,
    serverParams: ServerParams
) => JSONRPCResponsePromise;

type NameToMethodDictionary<ServerParams> = {
    [name: string]: JSONRPCMethod<ServerParams>;
};

const createParseErrorResponse = (): JSONRPCResponse =>
    createJSONRPCErrorResponse(null, JSONRPCErrorCode.ParseError, "Parse error");

const createInvalidRequestResponse = (request: any): JSONRPCResponse =>
    createJSONRPCErrorResponse(
        isJSONRPCID(request.id) ? request.id : null,
        JSONRPCErrorCode.InvalidRequest,
        "Invalid Request"
    );

const createMethodNotFoundResponse = (id: JSONRPCID): JSONRPCResponse =>
    createJSONRPCErrorResponse(
        id,
        JSONRPCErrorCode.MethodNotFound,
        "Method not found"
    );

export interface JSONRPCServerOptions {
    errorListener?: ErrorListener;
}

export class JSONRPCServer<ServerParams = void> {
    private nameToMethodDictionary: NameToMethodDictionary<ServerParams>;
    private middleware: JSONRPCServerMiddleware<ServerParams> | null;
    private readonly errorListener: ErrorListener;

    public mapErrorToJSONRPCErrorResponse: (
        id: JSONRPCID,
        error: any
    ) => JSONRPCErrorResponse = defaultMapErrorToJSONRPCErrorResponse;

    constructor(options: JSONRPCServerOptions = {}) {
        this.nameToMethodDictionary = {};
        this.middleware = null;
        this.errorListener = options.errorListener ?? ((message, data) => print('JSON-RPC Error:', message, data));
    }

    hasMethod(name: string): boolean {
        return !!this.nameToMethodDictionary[name];
    }

    addMethod(name: string, method: SimpleJSONRPCMethod<ServerParams>): void {
        this.addMethodAdvanced(name, this.toJSONRPCMethod(method));
    }

    private toJSONRPCMethod(
        method: SimpleJSONRPCMethod<ServerParams>
    ): JSONRPCMethod<ServerParams> {
        return (
            request: JSONRPCRequest,
            serverParams: ServerParams
        ): JSONRPCResponsePromise => {
            const response = method(request.params, serverParams);
            return Promise.resolve(response).then((result: any) =>
                mapResultToJSONRPCResponse(request.id, result)
            );
        };
    }

    addMethodAdvanced(name: string, method: JSONRPCMethod<ServerParams>): void {
        this.nameToMethodDictionary = {
            ...this.nameToMethodDictionary,
            [name]: method,
        };
    }

    receiveJSON(
        json: string,
        serverParams?: ServerParams
    ): PromiseLike<JSONRPCResponse | JSONRPCResponse[] | null> {
        const request: JSONRPCRequest | JSONRPCRequest[] | null =
            this.tryParseRequestJSON(json);
        if (request) {
            return this.receive(request, serverParams);
        } else {
            return Promise.resolve(createParseErrorResponse());
        }
    }

    private tryParseRequestJSON(json: string): JSONRPCRequest | null {
        try {
            return JSON.parse(json);
        } catch {
            return null;
        }
    }

    receive(
        request: JSONRPCRequest,
        serverParams?: ServerParams
    ): PromiseLike<JSONRPCResponse | null>;
    receive(
        request: JSONRPCRequest | JSONRPCRequest[],
        serverParams?: ServerParams
    ): PromiseLike<JSONRPCResponse | JSONRPCResponse[] | null>;
    receive(
        request: JSONRPCRequest | JSONRPCRequest[],
        serverParams?: ServerParams
    ): PromiseLike<JSONRPCResponse | JSONRPCResponse[] | null> {
        if (Array.isArray(request)) {
            return this.receiveMultiple(request, serverParams);
        } else {
            return this.receiveSingle(request, serverParams);
        }
    }

    private async receiveMultiple(
        requests: JSONRPCRequest[],
        serverParams?: ServerParams
    ): Promise<JSONRPCResponse | JSONRPCResponse[] | null> {
        const responses: JSONRPCResponse[] = (
            await Promise.all(
                requests.map((request) => this.receiveSingle(request, serverParams))
            )
        ).filter(isNonNull);

        if (responses.length === 1) {
            return responses[0];
        } else if (responses.length !== 0) {
            return responses;
        } else {
            return null;
        }
    }

    private async receiveSingle(
        request: JSONRPCRequest,
        serverParams?: ServerParams
    ): Promise<JSONRPCResponse | null> {
        const method = this.nameToMethodDictionary[request.method];

        if (!isJSONRPCRequest(request)) {
            return createInvalidRequestResponse(request);
        } else {
            const response: JSONRPCResponse | null = await this.callMethod(
                method,
                request,
                serverParams
            );
            return mapResponse(request, response);
        }
    }

    applyMiddleware(
        ...middlewares: JSONRPCServerMiddleware<ServerParams>[]
    ): void {
        if (this.middleware) {
            this.middleware = this.combineMiddlewares([
                this.middleware,
                ...middlewares,
            ]);
        } else {
            this.middleware = this.combineMiddlewares(middlewares);
        }
    }

    private combineMiddlewares(
        middlewares: JSONRPCServerMiddleware<ServerParams>[]
    ): JSONRPCServerMiddleware<ServerParams> | null {
        if (!middlewares.length) {
            return null;
        } else {
            return middlewares.reduce(this.middlewareReducer);
        }
    }

    private middlewareReducer(
        prevMiddleware: JSONRPCServerMiddleware<ServerParams>,
        nextMiddleware: JSONRPCServerMiddleware<ServerParams>
    ): JSONRPCServerMiddleware<ServerParams> {
        return (
            next: JSONRPCServerMiddlewareNext<ServerParams>,
            request: JSONRPCRequest,
            serverParams: ServerParams
        ): JSONRPCResponsePromise => {
            return prevMiddleware(
                (request, serverParams) => nextMiddleware(next, request, serverParams),
                request,
                serverParams
            );
        };
    }

    private callMethod(
        method: JSONRPCMethod<ServerParams> | undefined,
        request: JSONRPCRequest,
        serverParams: ServerParams | undefined
    ): JSONRPCResponsePromise {
        const callMethod: JSONRPCServerMiddlewareNext<ServerParams> = (
            request: JSONRPCRequest,
            serverParams: ServerParams
        ): JSONRPCResponsePromise => {
            if (method) {
                return method(request, serverParams);
            } else if (request.id !== undefined) {
                return Promise.resolve(createMethodNotFoundResponse(request.id));
            } else {
                return Promise.resolve(null);
            }
        };

        const onError = (error: any): JSONRPCResponsePromise => {
            this.errorListener(
                `An unexpected error occurred while executing "${request.method}" JSON-RPC method:`,
                error
            );
            return Promise.resolve(
                this.mapErrorToJSONRPCErrorResponseIfNecessary(request.id, error)
            );
        };

        try {
            return (this.middleware || noopMiddleware)(
                callMethod,
                request,
                serverParams
            ).then(undefined, onError);
        } catch (error) {
            return onError(error);
        }
    }

    private mapErrorToJSONRPCErrorResponseIfNecessary(
        id: JSONRPCID | undefined,
        error: any
    ): JSONRPCErrorResponse | null {
        if (id !== undefined) {
            return this.mapErrorToJSONRPCErrorResponse(id, error);
        } else {
            return null;
        }
    }
}

function isNonNull<T>(this: unknown, value: T | null): value is T {
    return value !== null;
};

const noopMiddleware: JSONRPCServerMiddleware<any> = (
    next,
    request,
    serverParams
) => next(request, serverParams);

const mapResultToJSONRPCResponse = (
    id: JSONRPCID | undefined,
    result: any
): JSONRPCSuccessResponse | null => {
    if (id !== undefined) {
        return createJSONRPCSuccessResponse(id, result);
    } else {
        return null;
    }
};

const defaultMapErrorToJSONRPCErrorResponse = (
    id: JSONRPCID,
    error: any
): JSONRPCErrorResponse => {
    let message: string = error?.message ?? "An unexpected error occurred";
    let code: number = DefaultErrorCode;
    let data: any;

    if (error instanceof JSONRPCErrorException) {
        code = error.code;
        data = error.data;
    }

    return createJSONRPCErrorResponse(id, code, message, data);
};

const mapResponse = (
    request: JSONRPCRequest,
    response: JSONRPCResponse | null
): JSONRPCResponse | null => {
    if (response) {
        return response;
    } else if (request.id !== undefined) {
        return createJSONRPCErrorResponse(
            request.id,
            JSONRPCErrorCode.InternalError,
            "Internal error"
        );
    } else {
        return null;
    }
};
