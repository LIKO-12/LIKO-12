import { MachineModule, Graphics } from '@liko-12/app';

type ModuleAPI<M extends MachineModule> = ReturnType<M['createAPI']>;

export type GraphicsAPI = ModuleAPI<Graphics>;

