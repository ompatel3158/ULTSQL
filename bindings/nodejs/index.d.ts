declare module 'ultsql' {
  export interface UltSQLClientOptions {
    host?: string;
    port?: number;
  }

  export interface OpenOptions {
    host?: string;
    port?: number;
    passphrase?: string;
    timeout?: number;
    binaryPath?: string;
  }

  export class UltSQLClient {
    constructor(options?: UltSQLClientOptions | string);
    host: string;
    port: number;
    sql<T = any>(sqlQuery: string): Promise<{ columns: string[]; count: number; rows: T[][]; message: string; dbms_output?: string[] }>;
    execute<T = any>(sqlQuery: string): Promise<{ columns: string[]; count: number; rows: T[][]; message: string; dbms_output?: string[] }>;
    query<T = any>(tableName: string): Promise<{ table: string; columns: string[]; count: number; rows: T[] }>;
    insert(tableName: string, recordObject: Record<string, any>): Promise<{ status: string; count: number; message: string }>;
    insertBatch(tableName: string, recordsArray: Record<string, any>[]): Promise<{ status: string; count: number; message: string }>;
    truncate(tableName: string): Promise<{ status: string; message: string }>;
    openapiSpec(): Promise<Record<string, any>>;
    close(): void;
  }

  export function open(dbPath?: string, options?: OpenOptions): Promise<UltSQLClient>;
  export function getBinaryPath(): string;

  export default UltSQLClient;
}
