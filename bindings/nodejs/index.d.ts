declare module 'ultsql' {
  export interface UltSQLClientOptions {
    auto_start?: boolean;
    autoStart?: boolean;
    host?: string;
    port?: number;
    passphrase?: string;
    timeout?: number;
    binaryPath?: string;
    quiet?: boolean;
  }

  export interface OpenOptions extends UltSQLClientOptions {}

  export interface ConnectionStatus {
    status: 'online' | 'offline';
    host: string;
    port: number;
    url: string;
    target: string;
    auto_start: boolean;
    pid: number | null;
    server_info: any;
  }

  export class UltSQLClient {
    constructor(target?: string | UltSQLClientOptions, options?: UltSQLClientOptions);
    target: string;
    host: string;
    port: number;
    autoStart: boolean;
    status(): Promise<ConnectionStatus>;
    sql<T = any>(sqlQuery: string): Promise<{ columns: string[]; count: number; rows: T[][]; message: string; dbms_output?: string[] }>;
    execute<T = any>(sqlQuery: string): Promise<{ columns: string[]; count: number; rows: T[][]; message: string; dbms_output?: string[] }>;
    query<T = any>(tableName: string): Promise<{ table: string; columns: string[]; count: number; rows: T[] }>;
    insert(tableName: string, recordObject: Record<string, any>): Promise<{ status: string; count: number; message: string }>;
    insertBatch(tableName: string, recordsArray: Record<string, any>[]): Promise<{ status: string; count: number; message: string }>;
    truncate(tableName: string): Promise<{ status: string; message: string }>;
    openapiSpec(): Promise<Record<string, any>>;
    stop(): void;
    close(): void;
  }

  export class UltSQL {
    static Client: typeof UltSQLClient;
    static open(dbPath?: string, options?: OpenOptions): Promise<UltSQLClient>;
  }

  export function open(dbPath?: string, options?: OpenOptions): Promise<UltSQLClient>;
  export function getBinaryPath(): string;

  export default UltSQLClient;
}
