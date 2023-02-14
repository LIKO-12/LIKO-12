import ts from 'typescript';
import { cloneNode } from 'ts-clone-node';

interface PluginOptions { }

/**
 * Get the JSDoc of a node if it has one.
 */
function getJSDoc(node: ts.Node): ts.JSDoc | undefined {
    for (const child of node.getChildren())
        if (ts.isJSDoc(child)) return child;
    return undefined;
}

/**
 * Checks if an AST node has a specific JSDoc tag attached to it.
 */
function hasJSDocTag(checker: ts.TypeChecker, node: ts.Node, tagName: string): boolean {
    return checker.getTypeAtLocation(node).symbol
        ?.getJsDocTags().map(tag => tag.name).includes(tagName);
}

export default function factory(program: ts.Program, { }: PluginOptions) {
    const checker = program.getTypeChecker();

    return (context: ts.TransformationContext): ts.Transformer<ts.SourceFile> => {
        const f = context.factory;

        return (sourceFile: ts.SourceFile): ts.SourceFile => {
            const visitor: ts.Visitor = (node) => {
                if (ts.isInterfaceDeclaration(node) && hasJSDocTag(checker, node, 'transformer_globalize')) {
                    const interfaceType = checker.getTypeAtLocation(node);

                    const replacement: ts.Node[] = [];

                    const properties = interfaceType.getProperties();
                    for (const property of properties) {
                        if ((property.flags & ts.SymbolFlags.Method) === 0) continue;
                        const signatures = property.declarations ?? [];


                        for (const signature of signatures) {
                            if (!ts.isMethodSignature(signature)) continue;

                            const jsDoc = getJSDoc(signature);
                            if (jsDoc) replacement.push(cloneNode(jsDoc, { factory: f, preserveComments: false }));

                            replacement.push(
                                f.createFunctionDeclaration(
                                    [f.createToken(ts.SyntaxKind.DeclareKeyword)],
                                    undefined,
                                    f.createIdentifier(signature.name.getText()),
                                    signature.typeParameters?.map(param => cloneNode(param, { factory: f })),
                                    signature.parameters?.map(param => cloneNode(param, { factory: f })),
                                    signature.type ? cloneNode(signature.type, { factory: f }) : undefined,
                                    undefined
                                )
                            );
                        }
                    }

                    return replacement;
                }

                return ts.visitEachChild(node, visitor, context);
            };

            return ts.visitNode(sourceFile, visitor);
        };
    }
}